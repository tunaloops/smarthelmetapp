import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:untitled/pages/bluetoothscan.dart';
import 'package:untitled/pages/livemonitor.dart';
import 'package:untitled/pages/homescreen.dart';
import 'package:untitled/pages/contacts.dart';
import 'package:untitled/pages/settings.dart';
import 'package:untitled/pages/crashhistory.dart';

Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();

  await requestBluetoothPermissions();

  runApp(SmartHelmetApp());
}

Future<void> requestBluetoothPermissions() async{
  await [
    Permission.bluetooth,
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.location,
  ].request();
}

class SmartHelmetApp extends StatelessWidget {
  const SmartHelmetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Helmet',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: Homescreen(),
      routes: {
        '/scan': (context) => BluetoothScanScreen(),
        '/live': (_) => LiveMonitoringScreen(),
        '/contacts': (_) => EmergencyContactsScreen(),
        '/settings': (_) => SettingsScreen(),
        '/history': (_) => CrashHistoryScreen(),
      },
    );
  }
}
