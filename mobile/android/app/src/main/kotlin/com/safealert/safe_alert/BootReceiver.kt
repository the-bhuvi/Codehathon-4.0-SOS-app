package com.safealert.safe_alert

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.content.ContextCompat

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == "android.intent.action.QUICKBOOT_POWERON") {

            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val enabled = prefs.getBoolean("flutter.shake_panic_enabled", true)

            if (!enabled) {
                Log.d("BootReceiver", "Shake panic disabled, not starting service")
                return
            }

            // Check location permission before starting foreground service
            val hasLocation = ContextCompat.checkSelfPermission(
                context, android.Manifest.permission.ACCESS_FINE_LOCATION
            ) == PackageManager.PERMISSION_GRANTED
            if (!hasLocation) {
                Log.d("BootReceiver", "Location permission not granted, skipping service start")
                return
            }

            Log.d("BootReceiver", "Boot completed, restarting shake detection service")

            try {
                val serviceIntent = Intent(context, ShakeDetectionService::class.java)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }
            } catch (e: Exception) {
                Log.e("BootReceiver", "Failed to start shake service", e)
            }
        }
    }
}
