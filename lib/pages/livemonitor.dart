import 'package:flutter/material.dart';

class LiveMonitoringScreen extends StatefulWidget {
  const LiveMonitoringScreen({super.key});

  @override
  State<LiveMonitoringScreen> createState() => _LiveMonitoringScreenState();
}

class _LiveMonitoringScreenState extends State<LiveMonitoringScreen> {
  String ax = "-", ay = "-", az = "-";
  String bx = "-", by = "-", bz = "-";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(padding: EdgeInsets.all(20.0),
      child: Column(
        children: [
          Text('Accelerometer: Ax: $ax Ay: $ay Az: $az'),
          SizedBox(height: 10.0),
          Text('Gyroscope: Rx: $bx Ry: $by Rz: $bz'),
          SizedBox(height: 30.0),
          ElevatedButton(onPressed: () {},
              child: Text("Refresh Data")
          )
        ],
      ),),
    );
  }
}
