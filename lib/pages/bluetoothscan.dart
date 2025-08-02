import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:untitled/services/bluetooth_manager.dart';

class BluetoothScanScreen extends StatefulWidget {
  const BluetoothScanScreen({super.key});

  @override
  State<BluetoothScanScreen> createState() => _BluetoothScanScreenState();
}

class _BluetoothScanScreenState extends State<BluetoothScanScreen> {
  List<ScanResult> _devices = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _initializeBluetooth();
    BluetoothManager().connectionStateStream.listen((state) {
      if (state == BluetoothConnectionState.disconnected && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device disconnected')),
        );
      }
    });
  }

  Future<void> _initializeBluetooth() async {
    try {
      if (await Permission.bluetoothScan.request().isGranted &&
          await Permission.bluetoothConnect.request().isGranted &&
          await Permission.locationWhenInUse.request().isGranted) {
        if (await BluetoothManager().isBluetoothEnabled()) {
          await BluetoothManager().startScan();
          BluetoothManager().scanResults.listen((results) {
            if (_debounce?.isActive ?? false) _debounce!.cancel();
            _debounce = Timer(const Duration(milliseconds: 500), () {
              setState(() {
                // Show all devices
                _devices = results;
                // Commented out filter to show only helmet devices (can be re-enabled later)
                // _devices = results.where((result) {
                //   return result.advertisementData.serviceUuids
                //       .contains('YOUR_ESP32_SERVICE_UUID');
                // }).toList();
              });
            });
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enable Bluetooth')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bluetooth permissions denied')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting scan: $e')),
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    BluetoothManager().stopScan();
    BluetoothManager().dispose();
    super.dispose();
  }

  void _connectToDevice(BluetoothDevice device) async {
    try {
      // Check if device advertises the helmet service UUID
      final scanResult = _devices.firstWhere(
            (result) => result.device.id == device.id,
        orElse: () => throw Exception('Device not found in scan results'),
      );
      if (!scanResult.advertisementData.serviceUuids
          .contains('YOUR_ESP32_SERVICE_UUID')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Selected device may not be a compatible helmet')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connecting...')),
      );
      await BluetoothManager().connectToDevice(device);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connected successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Helmet')),
      body: _devices.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _devices.length,
        itemBuilder: (context, index) {
          final result = _devices[index];
          final isHelmet = result.advertisementData.serviceUuids
              .contains('YOUR_ESP32_SERVICE_UUID');
          return ListTile(
            title: Text(
              result.device.name.isNotEmpty
                  ? result.device.name
                  : 'Unnamed Device',
              style: TextStyle(
                fontWeight: isHelmet ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text(
                '${result.device.id.id} (RSSI: ${result.rssi} dBm)'),
            trailing: isHelmet
                ? const Icon(Icons.verified, color: Colors.green)
                : null,
            onTap: () => _connectToDevice(result.device),
          );
        },
      ),
    );
  }
}