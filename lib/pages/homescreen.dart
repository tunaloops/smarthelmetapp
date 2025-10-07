import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'livemonitor.dart';
import 'contacts.dart';
import 'crashhistory.dart';
import 'settings.dart';

class Homescreen extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier;

  const Homescreen({super.key, required this.themeNotifier});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const Dashboard(),
      const LiveMonitoringScreen(),
      const EmergencyContactsScreen(),
      const CrashHistoryScreen(),
      SettingsScreen(themeNotifier: widget.themeNotifier),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.monitor_heart), label: 'Live'),
          BottomNavigationBarItem(icon: Icon(Icons.contacts), label: 'Contacts'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
