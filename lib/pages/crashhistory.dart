import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../models/crash_log.dart';

class CrashHistoryScreen extends StatefulWidget {
  const CrashHistoryScreen({super.key});

  @override
  State<CrashHistoryScreen> createState() => _CrashHistoryScreenState();
}

class _CrashHistoryScreenState extends State<CrashHistoryScreen> {
  List<CrashLog> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final logs = await DatabaseHelper().getCrashLogs();
    setState(() {
      _logs = logs;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Crash History")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
          ? const Center(child: Text("No crash history found."))
          : RefreshIndicator(
        onRefresh: _loadLogs,
        child: ListView.builder(
          itemCount: _logs.length,
          itemBuilder: (_, index) {
            final log = _logs[index];
            return ListTile(
              leading: const Icon(Icons.warning, color: Colors.red),
              title: Text("Crash at ${log.timestamp}"),
              subtitle: Text("Location: ${log.location}"),
            );
          },
        ),
      ),
    );
  }
}