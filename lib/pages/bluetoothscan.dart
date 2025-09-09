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
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSub;
  bool _isScanning = false;

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
      // Request runtime permissions (Android 12+ requires scan/connect)
      final scanOk = await Permission.bluetoothScan.request().isGranted;
      final connectOk = await Permission.bluetoothConnect.request().isGranted;
      // Location is still commonly required for scanning on many Android versions
      final locOk = await Permission.locationWhenInUse.request().isGranted;

      if (!(scanOk && connectOk && locOk)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bluetooth permissions denied')),
        );
        return;
      }

      final supported = await FlutterBluePlus.isSupported;
      if (!supported) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bluetooth not supported on this device')),
        );
        return;
      }

      // Watch adapter power state (optional UX)
      _adapterStateSub = FlutterBluePlus.adapterState.listen((s) {
        if (s != BluetoothAdapterState.on) {
          setState(() {
            _devices = [];
            _isScanning = false;
          });
        }
      });

      final isOn = await FlutterBluePlus.isOn;
      if (!isOn) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please turn on Bluetooth')),
        );
        return;
      }

      await _startScan();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting scan: $e')),
      );
    }
  }

  Future<void> _startScan() async {
    try {
      setState(() {
        _devices = [];
        _isScanning = true;
      });

      // Start scan (adjust timeout as you like)
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

      // Listen to results
      _scanSub?.cancel();
      _scanSub = FlutterBluePlus.scanResults.listen((results) {
        // Debounce UI updates to avoid excessive rebuilds
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          setState(() {
            _devices = results;
          });
        });
      }, onDone: () {
        if (mounted) {
          setState(() => _isScanning = false);
        }
      });

    } catch (e) {
      if (!mounted) return;
      setState(() => _isScanning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scan failed: $e')),
      );
    }
  }

  Future<void> _stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
    if (mounted) setState(() => _isScanning = false);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scanSub?.cancel();
    _adapterStateSub?.cancel();
    _stopScan();
    // Removed: BluetoothManager().dispose();  // not needed, and may kill connection streams globally
    super.dispose();
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await _stopScan();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connecting...')),
        );
      }

      await BluetoothManager().connectToDevice(device);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connected successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanningWidget = _isScanning
        ? const Padding(
      padding: EdgeInsets.only(right: 16.0),
      child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
    )
        : IconButton(
      tooltip: 'Rescan',
      icon: const Icon(Icons.refresh),
      onPressed: _startScan,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Helmet'),
        actions: [scanningWidget],
      ),
      body: _devices.isEmpty
          ? Center(
        child: _isScanning
            ? const Text('Scanning for devices...')
            : const Text('No devices found. Tap refresh to rescan.'),
      )
          : ListView.builder(
        itemCount: _devices.length,
        itemBuilder: (context, index) {
          final result = _devices[index];
          final name = (result.device.name.isNotEmpty)
              ? result.device.name
              : 'Unnamed Device';
          return ListTile(
            leading: const Icon(Icons.bluetooth),
            title: Text(name),
            subtitle: Text('${result.device.id.id}  •  RSSI: ${result.rssi} dBm'),
            onTap: () => _connectToDevice(result.device),
          );
        },
      ),
    );
  }
}
