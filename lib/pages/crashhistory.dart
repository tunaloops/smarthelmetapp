import 'package:flutter/material.dart';

class CrashHistoryScreen extends StatefulWidget {
  const CrashHistoryScreen({super.key});

  @override
  State<CrashHistoryScreen> createState() => _CrashHistoryScreenState();
}

class _CrashHistoryScreenState extends State<CrashHistoryScreen> {
  List<String> logs = [
    'Crash at 10:21 am - Location xyz',
    'Crash at 4:21 am - Location xyz'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
          itemCount: logs.length,
          itemBuilder: (_, index) => ListTile(
            leading: Icon(Icons.warning, color: Colors.red),
            title: Text(logs[index]),
          )),
    );
  }
}
