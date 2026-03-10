package com.safealert.safe_alert

import android.app.*
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.location.Location
import android.location.LocationManager
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.os.Vibrator
import android.os.VibrationEffect
import android.telephony.SmsManager
import android.util.Log
import androidx.core.app.NotificationCompat
import java.net.HttpURLConnection
import java.net.URL
import kotlin.math.abs
import kotlin.math.sqrt

class ShakeDetectionService : Service(), SensorEventListener {

    companion object {
        const val TAG = "ShakeService"
        const val CHANNEL_ID = "shake_detection_channel"
        const val NOTIFICATION_ID = 1001
        const val ACTION_STOP = "com.safealert.STOP_SHAKE_SERVICE"

        const val EXTRA_SUPABASE_URL = "supabase_url"
        const val EXTRA_SUPABASE_KEY = "supabase_key"

        // Fixed shake detection parameters - requires strong intentional shakes
        private const val SHAKE_THRESHOLD = 18.0f  // Higher threshold to ignore small vibrations
        private const val SHAKES_NEEDED = 3
        private const val SHAKE_WINDOW_MS = 2000L  // 3 shakes must happen within 2 seconds
        private const val TRIGGER_COOLDOWN_MS = 30000L  // 30s cooldown between triggers
        private const val MIN_SHAKE_INTERVAL_MS = 300L  // 300ms debounce to require distinct shakes
    }

    private var sensorManager: SensorManager? = null
    private var accelerometer: Sensor? = null
    private var shakeThreshold: Float = SHAKE_THRESHOLD

    // Shake detection state - uses force magnitude
    private var shakeCount: Int = 0
    private var firstShakeTime: Long = 0
    private var lastShakeTime: Long = 0
    private var lastTriggerTime: Long = 0

    // Supabase config
    private var supabaseUrl: String = ""
    private var supabaseKey: String = ""

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        accelerometer = sensorManager?.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            return START_NOT_STICKY
        }

        supabaseUrl = intent?.getStringExtra(EXTRA_SUPABASE_URL) ?: ""
        supabaseKey = intent?.getStringExtra(EXTRA_SUPABASE_KEY) ?: ""

        // Fallback: read from SharedPreferences
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        if (supabaseUrl.isEmpty()) {
            supabaseUrl = prefs.getString("flutter.supabase_url", "") ?: ""
        }
        if (supabaseKey.isEmpty()) {
            supabaseKey = prefs.getString("flutter.supabase_key", "") ?: ""
        }

        // Read shake sensitivity setting (low=16, medium=18, high=22) - higher values = harder to trigger
        val sensitivity = prefs.getString("flutter.shake_sensitivity", "medium") ?: "medium"
        shakeThreshold = when (sensitivity) {
            "low" -> 16.0f    // easier to trigger but still requires intentional shake
            "high" -> 22.0f   // harder to trigger, requires very strong shakes
            else -> 18.0f     // medium - good balance, ignores normal movement
        }

        // Build stop action
        val stopIntent = Intent(this, ShakeDetectionService::class.java).apply {
            action = ACTION_STOP
        }
        val stopPendingIntent = PendingIntent.getService(
            this, 0, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Launch app on notification tap
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val launchPendingIntent = PendingIntent.getActivity(
            this, 0, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("SafeAlert Protection Active")
            .setContentText("Shake phone to trigger SOS – works even when locked")
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setOngoing(true)
            .setContentIntent(launchPendingIntent)
            .addAction(android.R.drawable.ic_delete, "Stop", stopPendingIntent)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                startForeground(NOTIFICATION_ID, notification, android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION)
            } catch (e: SecurityException) {
                Log.e(TAG, "Missing location permission for foreground service, stopping", e)
                stopSelf()
                return START_NOT_STICKY
            }
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }

        // Register accelerometer at GAME rate for reliable shake detection
        accelerometer?.let {
            sensorManager?.registerListener(this, it, SensorManager.SENSOR_DELAY_GAME)
        }

        Log.d(TAG, "Shake detection service started (threshold=$shakeThreshold, shakes=$SHAKES_NEEDED, window=${SHAKE_WINDOW_MS}ms)")
        return START_STICKY
    }

    override fun onSensorChanged(event: SensorEvent?) {
        if (event?.sensor?.type != Sensor.TYPE_ACCELEROMETER) return

        val x = event.values[0]
        val y = event.values[1]
        val z = event.values[2]

        // Calculate total force magnitude (includes gravity ~9.8)
        val force = sqrt((x * x + y * y + z * z).toDouble()).toFloat()

        if (force > shakeThreshold) {
            val now = System.currentTimeMillis()

            // Debounce: ignore if too close to last shake event
            if (now - lastShakeTime < MIN_SHAKE_INTERVAL_MS) return

            // Reset counter if outside the shake window
            if (shakeCount == 0 || now - firstShakeTime > SHAKE_WINDOW_MS) {
                shakeCount = 1
                firstShakeTime = now
            } else {
                shakeCount++
            }
            lastShakeTime = now

            Log.d(TAG, "Shake #$shakeCount force=${"%.2f".format(force)}")

            if (shakeCount >= SHAKES_NEEDED) {
                shakeCount = 0

                // Cooldown to prevent rapid re-triggers
                if (now - lastTriggerTime < TRIGGER_COOLDOWN_MS) {
                    Log.d(TAG, "Cooldown active, ignoring trigger")
                    return
                }
                lastTriggerTime = now

                triggerPanicAlert()
            }
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    private fun triggerPanicAlert() {
        Log.d(TAG, "=== PANIC ALERT TRIGGERED! ===")

        // Vibrate to confirm trigger
        vibrateDevice()

        // Wake up screen and launch the app immediately
        wakeAndLaunchApp()

        Thread {
            try {
                // 1. Capture GPS location
                val location = getLastKnownLocation()
                val lat = location?.latitude ?: 0.0
                val lng = location?.longitude ?: 0.0

                // 2. Read user profile from SharedPreferences
                val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val userName = prefs.getString("flutter.user_full_name", "") ?: ""
                val userPhone = prefs.getString("flutter.user_phone", "") ?: ""
                val emergencyContactName = prefs.getString("flutter.emergency_contact_name", "") ?: ""
                val emergencyContactPhone = prefs.getString("flutter.emergency_contact_phone", "") ?: ""
                val bloodGroup = prefs.getString("flutter.blood_group", "") ?: ""
                val medicalConditions = prefs.getString("flutter.medical_conditions", "") ?: ""

                // Use UTC timestamp in ISO8601 format for consistency with backend
                val timestamp = java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", java.util.Locale.US).apply {
                    timeZone = java.util.TimeZone.getTimeZone("UTC")
                }.format(java.util.Date())

                val message = "PANIC ALERT - Automatic shake trigger!"

                // 3. Insert into Supabase
                insertToSupabase(lat, lng, message, userName, userPhone,
                    emergencyContactName, emergencyContactPhone,
                    bloodGroup, medicalConditions, timestamp)

                // 4. Send SMS to emergency contacts
                sendEmergencySMS(userName, message, lat, lng, timestamp,
                    emergencyContactPhone, prefs)

                Log.d(TAG, "Panic alert processed successfully")
            } catch (e: Exception) {
                Log.e(TAG, "Error processing panic alert", e)
            }
        }.start()
    }

    private fun vibrateDevice() {
        try {
            val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                // Three quick pulses to confirm panic trigger
                val pattern = longArrayOf(0, 300, 200, 300, 200, 500)
                vibrator.vibrate(VibrationEffect.createWaveform(pattern, -1))
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(longArrayOf(0, 300, 200, 300, 200, 500), -1)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Vibration failed", e)
        }
    }

    @Suppress("DEPRECATION")
    private fun wakeAndLaunchApp() {
        try {
            // Wake up the screen
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            val wakeLock = pm.newWakeLock(
                PowerManager.FULL_WAKE_LOCK or
                PowerManager.ACQUIRE_CAUSES_WAKEUP or
                PowerManager.ON_AFTER_RELEASE,
                "SafeAlert:PanicWakeLock"
            )
            wakeLock.acquire(10000) // Hold for 10 seconds

            // Launch the app with panic trigger flag
            val launchIntent = Intent(this, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
                putExtra("SHAKE_TRIGGERED", true)
            }
            startActivity(launchIntent)

            Log.d(TAG, "App launched from panic trigger")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to wake/launch app", e)
        }
    }

    @Suppress("MissingPermission")
    private fun getLastKnownLocation(): Location? {
        return try {
            val locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
            val gpsLocation = locationManager.getLastKnownLocation(LocationManager.GPS_PROVIDER)
            val networkLocation = locationManager.getLastKnownLocation(LocationManager.NETWORK_PROVIDER)

            // Prefer GPS, fall back to network
            when {
                gpsLocation != null && networkLocation != null -> {
                    if (gpsLocation.time > networkLocation.time) gpsLocation else networkLocation
                }
                gpsLocation != null -> gpsLocation
                networkLocation != null -> networkLocation
                else -> null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error getting location", e)
            null
        }
    }

    private fun insertToSupabase(
        lat: Double, lng: Double, message: String,
        userName: String, userPhone: String,
        emergencyContactName: String, emergencyContactPhone: String,
        bloodGroup: String, medicalConditions: String,
        timestamp: String
    ) {
        if (supabaseUrl.isEmpty() || supabaseKey.isEmpty()) {
            Log.w(TAG, "Supabase config missing, skipping insert")
            return
        }

        try {
            val url = URL("$supabaseUrl/rest/v1/incidents")
            val conn = url.openConnection() as HttpURLConnection
            conn.requestMethod = "POST"
            conn.setRequestProperty("Content-Type", "application/json")
            conn.setRequestProperty("apikey", supabaseKey)
            conn.setRequestProperty("Authorization", "Bearer $supabaseKey")
            conn.setRequestProperty("Prefer", "return=minimal")
            conn.doOutput = true
            conn.connectTimeout = 10000
            conn.readTimeout = 10000

            val json = buildString {
                append("{")
                append("\"lat\":$lat,")
                append("\"lng\":$lng,")
                append("\"message\":\"${escapeJson(message)}\",")
                append("\"severity\":\"HIGH\",")
                append("\"status\":\"active\",")
                append("\"emergency_type\":\"panic\",")
                append("\"agency\":\"Police\",")
                if (userName.isNotEmpty()) append("\"user_name\":\"${escapeJson(userName)}\",")
                if (userPhone.isNotEmpty()) append("\"user_phone\":\"${escapeJson(userPhone)}\",")
                if (emergencyContactName.isNotEmpty()) append("\"emergency_contact_name\":\"${escapeJson(emergencyContactName)}\",")
                if (emergencyContactPhone.isNotEmpty()) append("\"emergency_contact_phone\":\"${escapeJson(emergencyContactPhone)}\",")
                if (bloodGroup.isNotEmpty()) append("\"blood_group\":\"${escapeJson(bloodGroup)}\",")
                if (medicalConditions.isNotEmpty()) append("\"medical_conditions\":\"${escapeJson(medicalConditions)}\"")
                // Don't send created_at - let database use server timestamp (DEFAULT now())
                append("}")
            }

            conn.outputStream.bufferedWriter().use { it.write(json) }

            val responseCode = conn.responseCode
            Log.d(TAG, "Supabase insert response: $responseCode")
            conn.disconnect()
        } catch (e: Exception) {
            Log.e(TAG, "Supabase insert failed", e)
        }
    }

    private fun sendEmergencySMS(
        userName: String, message: String,
        lat: Double, lng: Double, timestamp: String,
        emergencyContactPhone: String,
        prefs: SharedPreferences
    ) {
        val phones = mutableSetOf<String>()
        if (emergencyContactPhone.isNotEmpty()) phones.add(emergencyContactPhone)

        // Also read contacts list from SharedPreferences
        val contactsJson = prefs.getString("flutter.emergency_contacts", null)
        if (contactsJson != null) {
            try {
                // Simple JSON array parsing for phone numbers
                val phonePattern = "\"phone\"\\s*:\\s*\"([^\"]+)\"".toRegex()
                phonePattern.findAll(contactsJson).forEach { match ->
                    phones.add(match.groupValues[1])
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error parsing contacts", e)
            }
        }

        if (phones.isEmpty()) {
            Log.d(TAG, "No emergency contacts configured, skipping SMS")
            return
        }

        val displayName = if (userName.isNotEmpty()) userName else "SafeAlert User"
        val locationLink = "https://maps.google.com/?q=$lat,$lng"
        val smsBody = "SOS ALERT\nName: $displayName\nEmergency: $message\nLocation: $locationLink\nTime: $timestamp"

        val smsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            getSystemService(SmsManager::class.java)
        } else {
            @Suppress("DEPRECATION")
            SmsManager.getDefault()
        }

        for (phone in phones) {
            try {
                val parts = smsManager.divideMessage(smsBody)
                if (parts.size > 1) {
                    smsManager.sendMultipartTextMessage(phone, null, parts, null, null)
                } else {
                    smsManager.sendTextMessage(phone, null, smsBody, null, null)
                }
                Log.d(TAG, "SMS sent to $phone")
            } catch (e: Exception) {
                Log.e(TAG, "SMS failed for $phone", e)
            }
        }
    }

    private fun escapeJson(value: String): String {
        return value.replace("\\", "\\\\")
            .replace("\"", "\\\"")
            .replace("\n", "\\n")
            .replace("\r", "\\r")
            .replace("\t", "\\t")
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Shake Detection Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Keeps emergency shake detection active in background"
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        sensorManager?.unregisterListener(this)
        Log.d(TAG, "Shake detection service stopped")
        super.onDestroy()
    }
}
