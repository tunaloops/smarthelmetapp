import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart';

class CrashDetectionService {
  static final CrashDetectionService _instance = CrashDetectionService._internal();
  factory CrashDetectionService() => _instance;
  CrashDetectionService._internal();

  Interpreter? _interpreter;
  bool _isModelLoaded = false;

  // Scaler parameters (from scaler.json)
  List<double> _featureMeans = [];
  List<double> _featureScales = [];

  // Raw sensor buffer
  List<List<double>> _sensorBuffer = [];
  static const int _sampleRate = 100; // Hz
  static const int _windowSeconds = 2;
  static const int _windowSize = _sampleRate * _windowSeconds; // 200 samples

  // Crash detection parameters
  int _consecutiveCrashPredictions = 0;
  static const int _requiredConsecutivePredictions = 2;
  DateTime? _lastCrashTime;
  static const Duration _crashCooldown = Duration(seconds: 30);
  double _crashThreshold = 0.5;


  // === Load model + scaler ===
  Future<void> loadModel() async {
    try {
      print("Loading crash detection model...");
      _interpreter = await Interpreter.fromAsset('assets/models/crash_model.tflite');
      _isModelLoaded = true;
      print("Model loaded successfully");

      // Load scaler.json
      String jsonString = await rootBundle.loadString('assets/models/scaler.json');
      Map<String, dynamic> scaler = jsonDecode(jsonString);
      _featureMeans = List<double>.from(scaler["mean"]);
      _featureScales = List<double>.from(scaler["scale"]);

      print("Scaler loaded with ${_featureMeans.length} features");

      if (_featureMeans.length != 53) {
        throw Exception("Expected 53 features, got ${_featureMeans.length}");
      }

    } catch (e) {
      print("Error loading model or scaler: $e");
      _isModelLoaded = false;
    }
  }

  // Add separate logging buffer
  List<List<double>> _logBuffer = [];
  static const int _logDurationSeconds = 120; // 2 minutes
  static const int _maxLogSize = _sampleRate * _logDurationSeconds; // 12,000 samples

  // === Add sensor reading (must be in m/s² for accel, °/s for gyro) ===
  void addSensorReading({
    required double ax, required double ay, required double az,
    required double gx, required double gy, required double gz,
  }) {
   List<double> reading = ([ax, ay, az, gx, gy, gz]);
  _sensorBuffer.add(reading);
    if (_sensorBuffer.length > _windowSize) {
      _sensorBuffer.removeAt(0);
    }

    _logBuffer.add(reading);
    if (_logBuffer.length > _maxLogSize){
      _logBuffer.removeAt(0);
    }
  }

  // === Extract 53 features ===
  List<double> _extractFeatures() {
    if (_sensorBuffer.length < _windowSize) {
      throw Exception("Not enough samples in buffer yet");
    }

    List<double> features = [];

    // 1. Basic stats for each axis (6 axes × 5 stats = 30 features)
    for (int i = 0; i < 6; i++) {
      List<double> axisData = _sensorBuffer.map((row) => row[i]).toList();

      double mean = axisData.reduce((a, b) => a + b) / axisData.length;
      double variance = axisData.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) / axisData.length;
      double std = math.sqrt(variance);
      double minVal = axisData.reduce(math.min);
      double maxVal = axisData.reduce(math.max);
      double energy = axisData.map((x) => x * x).reduce((a, b) => a + b) / axisData.length;

      features.addAll([mean, std, minVal, maxVal, energy]);
    }

    // 2. Acceleration magnitude features (4 features)
    List<double> accMag = _sensorBuffer.map((row) {
      return math.sqrt(row[0] * row[0] + row[1] * row[1] + row[2] * row[2]);
    }).toList();

    double accMagMean = accMag.reduce((a, b) => a + b) / accMag.length;
    double accMagVariance = accMag.map((x) => math.pow(x - accMagMean, 2)).reduce((a, b) => a + b) / accMag.length;
    double accMagStd = math.sqrt(accMagVariance);
    double accMagMax = accMag.reduce(math.max);
    double accMagMin = accMag.reduce(math.min);

    features.addAll([accMagMean, accMagStd, accMagMax, accMagMin]);

    // 3. Gyroscope magnitude features (4 features)
    List<double> gyroMag = _sensorBuffer.map((row) {
      return math.sqrt(row[3] * row[3] + row[4] * row[4] + row[5] * row[5]);
    }).toList();

    double gyroMagMean = gyroMag.reduce((a, b) => a + b) / gyroMag.length;
    double gyroMagVariance = gyroMag.map((x) => math.pow(x - gyroMagMean, 2)).reduce((a, b) => a + b) / gyroMag.length;
    double gyroMagStd = math.sqrt(gyroMagVariance);
    double gyroMagMax = gyroMag.reduce(math.max);
    double gyroMagMin = gyroMag.reduce(math.min);

    features.addAll([gyroMagMean, gyroMagStd, gyroMagMax, gyroMagMin]);

    // 4. Jerk features (3 features)
    List<double> jerk = [];
    for (int i = 1; i < accMag.length; i++) {
      jerk.add((accMag[i] - accMag[i - 1]).abs());
    }

    double jerkMean = jerk.reduce((a, b) => a + b) / jerk.length;
    double jerkMax = jerk.reduce(math.max);
    double jerkVariance = jerk.map((x) => math.pow(x - jerkMean, 2)).reduce((a, b) => a + b) / jerk.length;
    double jerkStd = math.sqrt(jerkVariance);

    features.addAll([jerkMean, jerkMax, jerkStd]);

    // 5. Zero crossing rate for each axis (6 features)
    for (int i = 0; i < 6; i++) {
      List<double> axisData = _sensorBuffer.map((row) => row[i]).toList();
      int zeroCrossings = 0;

      for (int j = 1; j < axisData.length; j++) {
        if ((axisData[j - 1] >= 0 && axisData[j] < 0) ||
            (axisData[j - 1] < 0 && axisData[j] >= 0)) {
          zeroCrossings++;
        }
      }

      features.add(zeroCrossings.toDouble());
    }

    // 6. Peak-to-peak amplitude for each axis (6 features)
    for (int i = 0; i < 6; i++) {
      List<double> axisData = _sensorBuffer.map((row) => row[i]).toList();
      double ptp = axisData.reduce(math.max) - axisData.reduce(math.min);
      features.add(ptp);
    }

    // Total: 30 + 4 + 4 + 3 + 6 + 6 = 53 features
    return features;
  }

  // === Export buffer to CSV for debugging ===
  Future<void> exportBufferToCSV() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/sensor_buffer.csv');

      String csvData = "ax,ay,az,gx,gy,gz\n";
      for (var row in _logBuffer) {
        csvData += row.map((v) => v.toString()).join(",") + "\n";
      }

      await file.writeAsString(csvData);
      print("Exported ${_logBuffer.length} samples (${(_logBuffer.length / _sampleRate).toStringAsFixed(1)}s)");
    } catch (e) {
      print("Error exporting buffer: $e");
    }
  }

  // === Apply scaling ===
  List<double> _scaleFeatures(List<double> features) {
    List<double> scaled = [];
    for (int i = 0; i < features.length; i++) {
      scaled.add((features[i] - _featureMeans[i]) / _featureScales[i]);
    }
    return scaled;
  }

  // === Run inference ===
  Future<double> predictCrash() async {
    if (!_isModelLoaded || _interpreter == null) {
      await loadModel();
      if (!_isModelLoaded) throw Exception("Model not loaded");
    }

    if (_sensorBuffer.length < _windowSize) {
      int needed = _windowSize - _sensorBuffer.length;
      print("Waiting for sensor data... $needed more samples needed");
      return 0.0;
    }

    try {
      // Extract and scale features
      List<double> rawFeatures = _extractFeatures();
      List<double> scaledFeatures = _scaleFeatures(rawFeatures);

      // Prepare input tensor
      var input = Float32List.fromList(scaledFeatures).reshape([1, scaledFeatures.length]);
      var output = Float32List(1).reshape([1, 1]);

      // Run inference
      _interpreter!.run(input, output);

      double crashProbability = output[0][0];
      print("Crash probability: ${crashProbability.toStringAsFixed(3)}");

      return crashProbability;
    } catch (e) {
      print("Prediction error: $e");
      return 0.0;
    }
  }

  // === High-level detection with confirmation ===
  Future<Map<String, dynamic>> detectCrash() async {
    // Check cooldown
    if (_lastCrashTime != null) {
      Duration since = DateTime.now().difference(_lastCrashTime!);
      if (since < _crashCooldown) {
        print("Cooldown active (${_crashCooldown.inSeconds - since.inSeconds}s left)");
        return {'detected': false, 'reason': 'cooldown'};
      }
    }

    double probability = await predictCrash();
    bool isCrash = probability >= _crashThreshold;

    if (isCrash) {
      _consecutiveCrashPredictions++;
      if (_consecutiveCrashPredictions >= _requiredConsecutivePredictions) {
        _lastCrashTime = DateTime.now();
        _consecutiveCrashPredictions = 0;
        print("CRASH DETECTED! Probability: ${probability.toStringAsFixed(3)}");

        // Return detection with data for confirmation UI
        return {
          'detected': true,
          'probability': probability,
          'timestamp': DateTime.now().toIso8601String(),
          'needsConfirmation': true, // Show confirmation dialog to rider
        };
      }
    } else {
      _consecutiveCrashPredictions = 0;
    }

    return {'detected': false, 'probability': probability};
  }

  // === Utility methods ===
  void reset() {
    _sensorBuffer.clear();
    _logBuffer.clear();
    _consecutiveCrashPredictions = 0;
    _lastCrashTime = null;
  }

  void dispose() {
    _interpreter?.close();
    _isModelLoaded = false;
    _sensorBuffer.clear();
    _logBuffer.clear();
  }

  int get bufferSize => _sensorBuffer.length;
  int get logBufferSize => _logBuffer.length;
  bool get isModelLoaded => _isModelLoaded;
}