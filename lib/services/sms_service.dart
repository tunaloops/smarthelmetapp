import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class SmsService {
  static const MethodChannel _channel = MethodChannel('sms_channel');

  Future<void> sendAlert(String phone, String message) async {
    print("🔍 Starting SMS send to: $phone");
    print("🔍 Message: $message");

    // Check permissions first
    final smsPermission = await Permission.sms.status;
    print("🔍 SMS Permission status: $smsPermission");

    if (!smsPermission.isGranted) {
      print("❌ SMS permission not granted, requesting...");
      final result = await Permission.sms.request();
      print("🔍 SMS permission request result: $result");
      if (!result.isGranted) {
        throw Exception("SMS permission denied");
      }
    }

    try {
      print("📤 Attempting to send SMS via platform channel...");
      final bool result = await _channel.invokeMethod('sendSMS', {
        'phone': phone,
        'message': message,
      });

      if (result) {
        print("✅ SMS sent successfully via platform channel");
      } else {
        throw Exception("SMS sending failed via platform channel");
      }
    } on PlatformException catch (e) {
      print("❌ Platform exception: ${e.message}");
      throw Exception("SMS failed: ${e.message}");
    } catch (e) {
      print("❌ SMS sending failed: $e");
      rethrow;
    }
  }
}