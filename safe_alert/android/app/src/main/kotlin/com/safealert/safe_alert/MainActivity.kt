package com.safealert.safe_alert

import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.telephony.SmsManager
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val SMS_CHANNEL = "com.safealert/sms"
    private val SHAKE_CHANNEL = "com.safealert/shake_service"

    private var shakeChannel: MethodChannel? = null
    private var pendingShakeTrigger = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Allow showing over lock screen
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            val km = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
            km.requestDismissKeyguard(this, null)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
            )
        }

        // Check if launched from shake trigger
        if (intent?.getBooleanExtra("SHAKE_TRIGGERED", false) == true) {
            pendingShakeTrigger = true
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Handle when app is already running and shake triggers again
        if (intent.getBooleanExtra("SHAKE_TRIGGERED", false)) {
            shakeChannel?.invokeMethod("onShakeTriggered", null)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // SMS platform channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "sendSMS") {
                    val phone = call.argument<String>("phone")
                    val message = call.argument<String>("message")

                    if (phone == null || message == null) {
                        result.error("INVALID_ARGS", "Phone and message are required", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val smsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            getSystemService(SmsManager::class.java)
                        } else {
                            @Suppress("DEPRECATION")
                            SmsManager.getDefault()
                        }

                        val parts = smsManager.divideMessage(message)
                        if (parts.size > 1) {
                            smsManager.sendMultipartTextMessage(phone, null, parts, null, null)
                        } else {
                            smsManager.sendTextMessage(phone, null, message, null, null)
                        }

                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SMS_FAILED", e.message, null)
                    }
                } else {
                    result.notImplemented()
                }
            }

        // Shake detection service platform channel
        shakeChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHAKE_CHANNEL)
        shakeChannel!!.setMethodCallHandler { call, result ->
                when (call.method) {
                    "startService" -> {
                        val supabaseUrl = call.argument<String>("supabaseUrl") ?: ""
                        val supabaseKey = call.argument<String>("supabaseKey") ?: ""

                        val intent = Intent(this, ShakeDetectionService::class.java).apply {
                            putExtra(ShakeDetectionService.EXTRA_SUPABASE_URL, supabaseUrl)
                            putExtra(ShakeDetectionService.EXTRA_SUPABASE_KEY, supabaseKey)
                        }

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }

                        result.success(true)
                    }
                    "stopService" -> {
                        val intent = Intent(this, ShakeDetectionService::class.java).apply {
                            action = ShakeDetectionService.ACTION_STOP
                        }
                        startService(intent)
                        result.success(true)
                    }
                    "isRunning" -> {
                        val running = isServiceRunning(ShakeDetectionService::class.java)
                        result.success(running)
                    }
                    "checkPendingTrigger" -> {
                        val wasPending = pendingShakeTrigger
                        pendingShakeTrigger = false
                        result.success(wasPending)
                    }
                    else -> result.notImplemented()
                }
            }

        // If there was a pending shake trigger, notify Flutter after engine is ready
        if (pendingShakeTrigger) {
            flutterEngine.dartExecutor.binaryMessenger.let {
                // Small delay to ensure Flutter is ready
                window.decorView.postDelayed({
                    shakeChannel?.invokeMethod("onShakeTriggered", null)
                    pendingShakeTrigger = false
                }, 1500)
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun isServiceRunning(serviceClass: Class<*>): Boolean {
        val manager = getSystemService(ACTIVITY_SERVICE) as android.app.ActivityManager
        for (service in manager.getRunningServices(Integer.MAX_VALUE)) {
            if (serviceClass.name == service.service.className) {
                return true
            }
        }
        return false
    }
}
