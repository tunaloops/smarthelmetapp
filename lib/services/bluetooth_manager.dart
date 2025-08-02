import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// Singleton BluetoothManager for handling ESP32-based smart helmet communication
class BluetoothManager {
  // Singleton instance
  static final BluetoothManager _instance = BluetoothManager._internal();
  factory BluetoothManager() => _instance;
  BluetoothManager._internal();

  // StreamController for connection status updates
  final StreamController<BluetoothConnectionState> _connectionStateController =
  StreamController.broadcast();

  // Public stream for UI to listen to connection state changes
  Stream<BluetoothConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  // Current connected device
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _targetCharacteristic;

  // UUIDs for the smart helmet service and characteristic (replace with actual UUIDs)
  static const String _serviceUuid = "YOUR_ESP32_SERVICE_UUID";
  static const String _characteristicUuid = "YOUR_ESP32_CHARACTERISTIC_UUID";

  // Current connection state
  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.disconnected;

  // Check if Bluetooth is enabled
  Future<bool> isBluetoothEnabled() async {
    try {
      return await FlutterBluePlus.isSupported && await FlutterBluePlus.isOn;
    } catch (e) {
      return false;
    }
  }

  // Start scanning for nearby Bluetooth devices
  Future<void> startScan({Duration timeout = const Duration(seconds: 10)}) async {
    try {
      if (await isBluetoothEnabled()) {
        await FlutterBluePlus.startScan(timeout: timeout);
      } else {
        throw Exception('Bluetooth is disabled or not supported');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Stop scanning for devices
  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      rethrow;
    }
  }

  // Stream of scan results for UI to display available devices
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  // Connect to a specific Bluetooth device
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(timeout: const Duration(seconds: 15));
      _connectedDevice = device;

      // Set up connection state listener
      device.connectionState.listen((state) {
        _connectionState = state;
        _connectionStateController.add(state);

        // Discover services when connected
        if (state == BluetoothConnectionState.connected) {
          _discoverServices(device);
        }
      });
    } catch (e) {
      _connectionStateController.add(BluetoothConnectionState.disconnected);
      rethrow;
    }
  }

  // Discover services and characteristics of the connected device
  Future<void> _discoverServices(BluetoothDevice device) async {
    try {
      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        if (service.serviceUuid.toString() == _serviceUuid) {
          for (var characteristic in service.characteristics) {
            if (characteristic.characteristicUuid.toString() == _characteristicUuid) {
              _targetCharacteristic = characteristic;
              // Enable notifications for sensor data
              if (characteristic.properties.notify) {
                await characteristic.setNotifyValue(true);
              }
              break;
            }
          }
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  // Read sensor data from the characteristic
  Future<List<int>> readSensorData() async {
    if (_targetCharacteristic == null) {
      throw Exception('No characteristic found');
    }
    try {
      return await _targetCharacteristic!.read();
    } catch (e) {
      rethrow;
    }
  }

  // Write data to the characteristic (e.g., for helmet configuration)
  Future<void> writeData(List<int> data) async {
    if (_targetCharacteristic == null) {
      throw Exception('No characteristic found');
    }
    try {
      await _targetCharacteristic!.write(data, withoutResponse: false);
    } catch (e) {
      rethrow;
    }
  }

  // Stream for receiving sensor data notifications
  Stream<List<int>> get sensorDataStream {
    if (_targetCharacteristic == null) {
      throw Exception('No characteristic found');
    }
    return _targetCharacteristic!.lastValueStream;
  }

  // Disconnect from the current device
  Future<void> disconnect() async {
    try {
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
        _connectedDevice = null;
        _targetCharacteristic = null;
        _connectionStateController.add(BluetoothConnectionState.disconnected);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Clean up resources
  void dispose() {
    _connectionStateController.close();
  }

  // Get current connection state
  BluetoothConnectionState get currentConnectionState => _connectionState;
}