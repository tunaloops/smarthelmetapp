package com.example.untitled

import android.Manifest
import android.content.pm.PackageManager
import android.telephony.SmsManager
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "sms_channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "sendSMS" -> {
                    val phone = call.argument<String>("phone")
                    val message = call.argument<String>("message")

                    println("🔍 Android: Received SMS request")
                    println("🔍 Android: Phone: $phone")
                    println("🔍 Android: Message: $message")

                    if (phone != null && message != null) {
                        sendSMS(phone, message, result)
                    } else {
                        println("❌ Android: Phone or message is null")
                        result.error("INVALID_ARGUMENT", "Phone or message is null", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun sendSMS(phoneNumber: String, message: String, result: MethodChannel.Result) {
        println("🔍 Android: Starting SMS send process")

        // Check if SMS permission is granted
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.SEND_SMS)
            != PackageManager.PERMISSION_GRANTED) {
            println("❌ Android: SMS permission not granted")
            result.error("PERMISSION_DENIED", "SMS permission not granted", null)
            return
        }

        println("✅ Android: SMS permission is granted")

        try {
            val smsManager = SmsManager.getDefault()
            println("🔍 Android: Got SmsManager instance")

            // Clean phone number (remove any spaces, dashes, etc.)
            val cleanPhone = phoneNumber.replace(Regex("[^+\\d]"), "")
            println("🔍 Android: Cleaned phone number: $cleanPhone")

            // Split long messages if necessary
            val parts = smsManager.divideMessage(message)
            println("🔍 Android: Message parts: ${parts.size}")

            if (parts.size == 1) {
                println("📤 Android: Sending single SMS")
                smsManager.sendTextMessage(cleanPhone, null, message, null, null)
            } else {
                println("📤 Android: Sending multipart SMS (${parts.size} parts)")
                smsManager.sendMultipartTextMessage(cleanPhone, null, parts, null, null)
            }

            println("✅ Android: SMS sent successfully")
            result.success(true)

        } catch (e: Exception) {
            println("❌ Android: SMS sending failed: ${e.message}")
            println("❌ Android: Exception type: ${e.javaClass.simpleName}")
            e.printStackTrace()
            result.error("SMS_FAILED", "Failed to send SMS: ${e.message}", null)
        }
    }
}