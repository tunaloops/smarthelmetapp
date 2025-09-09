import 'dart:async';
import 'package:flutter/material.dart';
import '../services/alert_manager.dart';
import '../services/data_handler.dart';
import '../services/database_helper.dart';
import '../services/ai_detection.dart'; // CrashDetectionService
import '../services/bluetooth_manager.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class LiveMonitoringScreen extends StatefulWidget {
  const LiveMonitoringScreen({super.key});

  @override
  State<LiveMonitoringScreen> createState() => _LiveMonitoringScreenState();
}

class _LiveMonitoringScreenState extends State<LiveMonitoringScreen> {
  // Current sensor values (for UI display only)
  double ax = 0.0, ay = 0.0, az = 0.0;
  double gx = 0.0, gy = 0.0, gz = 0.0;

  String axStr = "-", ayStr = "-", azStr = "-";
  String gxStr = "-", gyStr = "-", gzStr = "-";

  bool isConnected = false;
  String connectionStatus = "Disconnected";

  final CrashDetectionService _crashDetection = CrashDetectionService();
  BluetoothDataHandler? _dataHandler;
  StreamSubscription<Map<String, dynamic>>? _dataSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;

  bool autoDetectionEnabled = true;
  Timer? _autoDetectionTimer;

  @override
  void initState() {
    super.initState();
    _initializeBluetoothConnection();
    _startAutoDetection();
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    _connectionSubscription?.cancel();
    _autoDetectionTimer?.cancel();
    _dataHandler?.dispose();
    super.dispose();
  }

  void _initializeBluetoothConnection() {
    _connectionSubscription =
        BluetoothManager().connectionStateStream.listen((state) {
          setState(() {
            isConnected = state == BluetoothConnectionState.connected;
            connectionStatus = isConnected ? "Connected" : "Disconnected";
          });

          if (isConnected) {
            _setupDataHandler();
          } else {
            _dataSubscription?.cancel();
            _dataHandler?.dispose();
            _dataHandler = null;
            setState(() {
              ax = ay = az = gx = gy = gz = 0.0;
              axStr = ayStr = azStr = gxStr = gyStr = gzStr = "-";
            });
          }
        });

    if (BluetoothManager().connectedDevice != null) {
      setState(() {
        isConnected = true;
        connectionStatus = "Connected";
      });
      _setupDataHandler();
    }
  }

  void _setupDataHandler() async {
    if (BluetoothManager().targetCharacteristic != null) {
      try {
        _dataHandler = BluetoothDataHandler();
        await _dataHandler!
            .initializeDataReception(BluetoothManager().targetCharacteristic!);

        _dataSubscription = _dataHandler!.csvDataStream.listen((latestData) {
          if (mounted) {
            _updateSensorValues(latestData);

            _crashDetection.addSensorReading(
              ax: ax, ay: ay, az: az,
              gx: gx, gy: gy, gz: gz,
            );
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Data reception initialized")),
          );
        }
      } catch (e) {
        print("Error setting up data handler: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("❌ Data setup failed: $e")),
          );
        }
      }
    }
  }

  void _updateSensorValues(Map<String, dynamic> data) {
    setState(() {
      ax = data['accel_x']?.toDouble() ?? 0.0;
      ay = data['accel_y']?.toDouble() ?? 0.0;
      az = data['accel_z']?.toDouble() ?? 0.0;
      gx = data['gyro_x']?.toDouble() ?? 0.0;
      gy = data['gyro_y']?.toDouble() ?? 0.0;
      gz = data['gyro_z']?.toDouble() ?? 0.0;

      axStr = ax.toStringAsFixed(2);
      ayStr = ay.toStringAsFixed(2);
      azStr = az.toStringAsFixed(2);
      gxStr = gx.toStringAsFixed(2);
      gyStr = gy.toStringAsFixed(2);
      gzStr = gz.toStringAsFixed(2);
    });
  }

  void _startAutoDetection() {
    _autoDetectionTimer =
        Timer.periodic(const Duration(seconds: 2), (timer) async {
          if (autoDetectionEnabled && isConnected) {
            await _checkForCrashSilent();
          }
        });
  }

  Future<void> _simulateCrash() async {
    final contacts = await DatabaseHelper().getContacts();
    if (contacts.isNotEmpty) {
      final alertManager = AlertManager();
      try {
        await alertManager.sendEmergencyAlerts(contacts);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("🚨 Crash simulated — alerts sent!")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("❌ Failed to send alerts: $e")),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ No emergency contacts saved!")),
        );
      }
    }
  }

  Future<void> _triggerEmergencyAlert() async {
    final contacts = await DatabaseHelper().getContacts();
    if (contacts.isNotEmpty) {
      final alertManager = AlertManager();
      try {
        await alertManager.sendEmergencyAlerts(contacts);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("🚨 CRASH DETECTED - Emergency alerts sent!")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("❌ Failed to send alerts: $e")),
          );
        }
      }
    }
  }

  // 🔄 Use new detectCrash pipeline
  Future<void> _checkForCrash() async {
    try {
      bool crashDetected = await _crashDetection.detectCrash();
      if (crashDetected) {
        print("🚨 CRASH DETECTED by AI model!");
        await _triggerEmergencyAlert();
      } else {
        print("✅ Normal movement detected by AI model");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ AI says: Normal movement")),
          );
        }
      }
    } catch (e) {
      print("❌ Error checking for crash: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ AI model error: $e")),
        );
      }
    }
  }

  Future<void> _checkForCrashSilent() async {
    try {
      bool crashDetected = await _crashDetection.detectCrash();
      if (crashDetected) {
        print("🚨 AUTOMATIC CRASH DETECTED by AI model!");
        await _triggerEmergencyAlert();
      }
    } catch (e) {
      print("❌ Error in automatic crash detection: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Monitoring'),
        backgroundColor: isConnected ? Colors.green : Colors.red,
        actions: [
          Switch(
            value: autoDetectionEnabled,
            onChanged: (value) {
              setState(() {
                autoDetectionEnabled = value;
              });
            },
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.auto_fix_high),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection Status Card
            Card(
              color: isConnected ? Colors.green.shade50 : Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      isConnected
                          ? Icons.bluetooth_connected
                          : Icons.bluetooth_disabled,
                      color: isConnected ? Colors.green : Colors.red,
                      size: 30,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          connectionStatus,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isConnected ? Colors.green : Colors.red,
                          ),
                        ),
                        Text(
                          autoDetectionEnabled
                              ? "Auto-detection ON"
                              : "Auto-detection OFF",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Sensor Data Cards
            Expanded(
              child: Column(
                children: [
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.speed, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                'Accelerometer (m/s²)',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildSensorValue('X', axStr, Colors.red),
                              _buildSensorValue('Y', ayStr, Colors.green),
                              _buildSensorValue('Z', azStr, Colors.blue),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.rotate_right, color: Colors.orange),
                              SizedBox(width: 8),
                              Text(
                                'Gyroscope (°/s)',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildSensorValue('X', gxStr, Colors.red),
                              _buildSensorValue('Y', gyStr, Colors.green),
                              _buildSensorValue('Z', gzStr, Colors.blue),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Action Buttons
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isConnected ? _checkForCrash : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text(
                      "🤖 Test AI Detection",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _simulateCrash,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text(
                      "🚨 Simulate Crash",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorValue(String axis, String value, Color color) {
    return Column(
      children: [
        Text(
          axis,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
        ),
      ],
    );
  }
}
