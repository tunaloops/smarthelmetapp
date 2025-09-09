import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothDataHandler {
  BluetoothCharacteristic? _dataCharacteristic;
  StreamSubscription<List<int>>? _dataSubscription;
  final StreamController<Map<String, dynamic>> _csvDataController =
  StreamController<Map<String, dynamic>>.broadcast();

  String _dataBuffer = "";

  Stream<Map<String, dynamic>> get csvDataStream => _csvDataController.stream;

  Future<void> initializeDataReception(BluetoothCharacteristic characteristic) async {
    _dataCharacteristic = characteristic;
    await characteristic.setNotifyValue(true);

    _dataSubscription = characteristic.value.listen(_handleIncomingData);
  }

  void _handleIncomingData(List<int> value) {
    String incoming = utf8.decode(value);
    _dataBuffer += incoming;

    // Handle both \n and \r\n
    List<String> lines = _dataBuffer.replaceAll('\r', '').split('\n');

    for (int i = 0; i < lines.length - 1; i++) {
      final line = lines[i].trim();
      if (line.isNotEmpty) {
        final parsed = _parseCsvLine(line);
        if (parsed != null) {
          _csvDataController.add(parsed);
        }
      }
    }

    // Keep incomplete line
    _dataBuffer = lines.last;
  }

  Map<String, dynamic>? _parseCsvLine(String line) {
    try {
      final parts = line.split(',');
      if (parts.length == 6) {
        return {
          'accel_x': double.tryParse(parts[0]) ?? 0.0,
          'accel_y': double.tryParse(parts[1]) ?? 0.0,
          'accel_z': double.tryParse(parts[2]) ?? 0.0,
          'gyro_x': double.tryParse(parts[3]) ?? 0.0,
          'gyro_y': double.tryParse(parts[4]) ?? 0.0,
          'gyro_z': double.tryParse(parts[5]) ?? 0.0,
        };
      }
    } catch (e) {
      print("CSV parse error: $e");
    }
    return null;
  }

  void dispose() {
    _dataSubscription?.cancel();
    _csvDataController.close();
  }
}
