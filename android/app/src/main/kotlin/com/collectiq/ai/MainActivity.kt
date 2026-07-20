package com.collectiq.ai

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        super.onCreate(savedInstanceState)
    }

    private var permissionResult: MethodChannel.Result? = null
    private var authLinkChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        authLinkChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            AUTH_LINK_CHANNEL,
        )
        authLinkChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialLink" -> result.success(authLinkFromIntent(intent))
                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NOTIFICATION_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "initialize" -> {
                    ensureNotificationChannel()
                    result.success(null)
                }

                "getPermissionStatus" -> {
                    result.success(notificationPermissionStatus())
                }

                "requestPermission" -> {
                    requestNotificationPermission(result)
                }

                "showPriceAlertNotification" -> {
                    showPriceAlertNotification(call, result)
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val authLink = authLinkFromIntent(intent)
        if (authLink != null) {
            authLinkChannel?.invokeMethod("authLink", authLink)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == POST_NOTIFICATIONS_REQUEST_CODE) {
            permissionResult?.success(notificationPermissionStatus())
            permissionResult = null
        }
    }

    private fun requestNotificationPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            result.success("granted")
            return
        }

        if (notificationPermissionStatus() == "granted") {
            result.success("granted")
            return
        }

        if (permissionResult != null) {
            result.success("unknown")
            return
        }

        permissionResult = result
        requestPermissions(
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            POST_NOTIFICATIONS_REQUEST_CODE,
        )
    }

    private fun showPriceAlertNotification(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        ensureNotificationChannel()
        if (notificationPermissionStatus() != "granted") {
            result.success(
                mapOf(
                    "status" to "permissionDenied",
                    "message" to "Notification permission is required.",
                ),
            )
            return
        }

        val title = call.argument<String>("title") ?: "Price alert triggered"
        val body = call.argument<String>("body") ?: "A collectible price alert triggered."
        val id = call.argument<Int>("id") ?: body.hashCode()
        val notificationManager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val launchIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            id,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, PRICE_ALERT_CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        val notification = builder
            .setSmallIcon(applicationInfo.icon)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(Notification.BigTextStyle().bigText(body))
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .build()

        notificationManager.notify(id, notification)
        result.success(
            mapOf(
                "status" to "delivered",
                "message" to body,
            ),
        )
    }

    private fun ensureNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }

        val notificationManager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val existing = notificationManager.getNotificationChannel(PRICE_ALERT_CHANNEL_ID)
        if (existing != null) {
            return
        }

        val channel = NotificationChannel(
            PRICE_ALERT_CHANNEL_ID,
            "Price Alerts",
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description = "Local notifications for triggered CollectIQ AI price alerts."
        }
        notificationManager.createNotificationChannel(channel)
    }

    private fun notificationPermissionStatus(): String {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            return "granted"
        }

        return if (
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            "granted"
        } else {
            "denied"
        }
    }

    companion object {
        private const val AUTH_LINK_CHANNEL = "collectiq_ai/auth_links"
        private const val NOTIFICATION_CHANNEL = "collectiq_ai/notifications"
        private const val PRICE_ALERT_CHANNEL_ID = "collectiq_price_alerts"
        private const val POST_NOTIFICATIONS_REQUEST_CODE = 4301
    }

    private fun authLinkFromIntent(intent: Intent?): String? {
        if (intent?.action != Intent.ACTION_VIEW) {
            return null
        }
        val data = intent.data ?: return null
        if (data.host != "auth" || data.path != "/callback") {
            return null
        }
        return data.toString()
    }
}
