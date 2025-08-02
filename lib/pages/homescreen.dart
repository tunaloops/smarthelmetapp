import 'package:flutter/material.dart';
import 'package:untitled/pages/contacts.dart';
import 'package:untitled/pages/crashhistory.dart';
import 'package:untitled/pages/dashboard.dart';
import 'package:untitled/pages/livemonitor.dart';
import 'package:untitled/pages/settings.dart';
import 'package:permission_handler/permission_handler.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    Dashboard(),
    LiveMonitoringScreen(),
    EmergencyContactsScreen(),
    CrashHistoryScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Smart Helmet'),
        backgroundColor: Colors.indigo,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.blueGrey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_sharp), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.motorcycle_rounded), label: 'Live'),
          BottomNavigationBarItem(icon: Icon(Icons.contacts), label: 'Contacts'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
