import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothManager {
  static final BluetoothManager _instance = BluetoothManager._internal();
  factory BluetoothManager() => _instance;
  BluetoothManager._internal();

  static const String _serviceUuid = "12345678-1234-1234-1234-1234567890ab";
  static const String _characteristicUuid = "abcd1234-5678-1234-5678-abcdef123456";

  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? targetCharacteristic;

  final StreamController<BluetoothConnectionState> _connectionStateController =
  StreamController<BluetoothConnectionState>.broadcast();
  Stream<BluetoothConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  Future<void> connectToDevice(BluetoothDevice device) async {
    connectedDevice = device;

    await device.connect();
    _connectionStateController.add(BluetoothConnectionState.connected);

    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      if (service.uuid.toString() == _serviceUuid) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid.toString() == _characteristicUuid) {
            targetCharacteristic = characteristic;
          }
        }
      }
    }

    device.connectionState.listen((state) {
      _connectionStateController.add(state);
      if (state != BluetoothConnectionState.connected) {
        connectedDevice = null;
        targetCharacteristic = null;
      }
    });
  }

  Future<void> disconnect() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
      connectedDevice = null;
      targetCharacteristic = null;
    }
  }
}
