import 'package:flutter/material.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final bool isConnected = false;

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
          SizedBox(height: 10.0),
          Text(
            isConnected ? 'Helmet connected' : 'Not connected',
            style: TextStyle(fontSize: 18.0)
          ),
          ElevatedButton(onPressed: () => Navigator.pushNamed(context, '/scan'), child: Text('Connect Helmet'))
        ],
      ),
    );
  }
}
