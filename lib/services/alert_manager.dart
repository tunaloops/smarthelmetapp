import 'package:untitled/services/sms_service.dart';

import '../models/emergency_contact.dart';
import '../services/database_helper.dart';
import '../models/crash_log.dart';
import 'package:intl/intl.dart';
import 'location_service.dart'; // for formatting time

class AlertManager {
  final SmsService _smsService = SmsService();
  final LocationService _locationService = LocationService();
  final dbHelper = DatabaseHelper();

  Future<void> sendEmergencyAlerts(List<EmergencyContact> contacts) async {
    try {
      final position = await _locationService.getLocation();
      final locationLink = "https://maps.google.com/?q=${position.latitude},${position.longitude}";
      final message = "🚨 Crash detected! Location: $locationLink";

      // Save crash log
      final timestamp = DateFormat('yyyy-MM-dd – kk:mm').format(DateTime.now());
      await dbHelper.insertCrashLog(
        CrashLog(timestamp: timestamp, location: locationLink),
      );

      // Send SMS alerts
      for (final contact in contacts) {
        await _smsService.sendAlert(contact.phone, message);
      }
    } catch (e) {
      print("Failed to send alerts: $e");
      rethrow; // Add this line
    }
  }}