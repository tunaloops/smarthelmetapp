import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../services/ai_detection.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final bool isConnected = false;

  Future<void> _exportAndShareCSV() async {
    try {
      // Export file using your service
      await CrashDetectionService().exportBufferToCSV();

      // Get app documents directory
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/sensor_buffer.csv');

      if (await file.exists()) {
        await Share.shareXFiles([XFile(file.path)], text: "Here is my sensor data");

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ CSV exported and shared")),
          );
        }
      } else {
        print("❌ CSV not found at ${file.path}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("❌ CSV file not found")),
          );
        }
      }
    } catch (e) {
      print("❌ Error sharing CSV: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
            size: 100.0,
            color: isConnected ? Colors.blue : Colors.blueGrey,
          ),
          const SizedBox(height: 10.0),
          Text(
            isConnected ? 'Helmet connected' : 'Not connected',
            style: const TextStyle(fontSize: 18.0),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/scan'),
            child: const Text('Connect Helmet'),
          ),
          const SizedBox(height: 20.0),
          ElevatedButton(
            onPressed: _exportAndShareCSV,
            child: const Text("Export & Share CSV"),
          ),
        ],
      ),
    );
  }
}