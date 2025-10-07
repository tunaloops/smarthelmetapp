import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/pages/bluetoothscan.dart';
import 'package:untitled/pages/livemonitor.dart';
import 'package:untitled/pages/homescreen.dart';
import 'package:untitled/pages/contacts.dart';
import 'package:untitled/pages/settings.dart';
import 'package:untitled/pages/crashhistory.dart';
import 'package:untitled/services/ai_detection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await requestBluetoothPermissions();
  await CrashDetectionService().loadModel();

  final prefs = await SharedPreferences.getInstance();
  final savedTheme = prefs.getString('themeMode') ?? 'light';
  final initialTheme = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;

  runApp(SmartHelmetApp(initialTheme: initialTheme));
}

Future<void> requestBluetoothPermissions() async {
  await [
    Permission.bluetooth,
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.location,
    Permission.sms,
    Permission.phone,
  ].request();
}

class SmartHelmetApp extends StatefulWidget {
  final ThemeMode initialTheme;

  const SmartHelmetApp({super.key, required this.initialTheme});

  @override
  State<SmartHelmetApp> createState() => _SmartHelmetAppState();
}

class _SmartHelmetAppState extends State<SmartHelmetApp> {
  late final ValueNotifier<ThemeMode> _themeNotifier;

  @override
  void initState() {
    super.initState();
    _themeNotifier = ValueNotifier(widget.initialTheme);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Smart Helmet',
          theme: ThemeData(
            primarySwatch: Colors.indigo,
            scaffoldBackgroundColor: Colors.white,
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Colors.white,
              selectedItemColor: Colors.indigo,
              unselectedItemColor: Colors.grey,
              showUnselectedLabels: true,
              type: BottomNavigationBarType.fixed,
              elevation: 12, // adds the separation shadow
            ),
          ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              primarySwatch: Colors.indigo,
              bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                backgroundColor: Color(0xFF121212),
                selectedItemColor: Colors.indigoAccent,
                unselectedItemColor: Colors.grey,
                elevation: 12,
              ),
            ),
          themeMode: themeMode,
          home: Homescreen(themeNotifier: _themeNotifier),
          routes: {
            '/scan': (context) => const BluetoothScanScreen(),
            '/live': (_) => const LiveMonitoringScreen(),
            '/contacts': (_) => const EmergencyContactsScreen(),
            '/settings': (_) => SettingsScreen(themeNotifier: _themeNotifier),
            '/history': (_) => const CrashHistoryScreen(),
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _themeNotifier.dispose();
    super.dispose();
  }
}
