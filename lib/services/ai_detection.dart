import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:convert'; // for JSON
import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart';

class CrashDetectionService {
  static final CrashDetectionService _instance = CrashDetectionService._internal();
  factory CrashDetectionService() => _instance;
  CrashDetectionService._internal();

  Interpreter? _interpreter;
  bool _isModelLoaded = false;

  // === Scaler parameters (from scaler.json) ===
  List<double> _featureMeans = [];
  List<double> _featureScales = [];

  // === Raw sensor buffer ===
  List<List<double>> _sensorBuffer = [];
  static const int _sampleRate = 100; // Hz (after downsampling)
  static const int _windowSeconds = 2;
  static const int _windowSize = _sampleRate * _windowSeconds; // 200 samples

  // Crash detection parameters
  int _consecutiveCrashPredictions = 0;
  static const int _requiredConsecutivePredictions = 2;
  DateTime? _lastCrashTime;
  static const Duration _crashCooldown = Duration(seconds: 30);
  double _crashThreshold = 0.5;

  // === Step 1: Load model + scaler.json ===
  Future<void> loadModel() async {
    try {
      print("🤖 Loading crash detection model...");
      _interpreter = await Interpreter.fromAsset('assets/models/crash_model.tflite');
      _isModelLoaded = true;
      print("✅ Model loaded successfully");

      // Load scaler.json from assets
      String jsonString = await rootBundle.loadString('assets/models/scaler.json');
      Map<String, dynamic> scaler = jsonDecode(jsonString);
      _featureMeans = List<double>.from(scaler["mean"]);
      _featureScales = List<double>.from(scaler["scale"]);

      print("✅ Scaler loaded with ${_featureMeans.length} features");

    } catch (e) {
      print("❌ Error loading model or scaler: $e");
      _isModelLoaded = false;
    }
  }

  // === Step 2: Add sensor reading to buffer ===
  void addSensorReading({
    required double ax, required double ay, required double az,
    required double gx, required double gy, required double gz,
  }) {
    _sensorBuffer.add([ax, ay, az, gx, gy, gz]);

    // Keep buffer size within window size
    if (_sensorBuffer.length > _windowSize) {
      _sensorBuffer.removeAt(0);
    }
  }

  // === Step 3: Extract features from current buffer ===
  List<double> _extractFeatures() {
    if (_sensorBuffer.length < _windowSize) {
      throw Exception("Not enough samples in buffer yet");
    }

    List<double> features = [];

    // For each of the 6 axes, compute mean, std, min, max, energy
    for (int i = 0; i < 6; i++) {
      List<double> axisData = _sensorBuffer.map((row) => row[i]).toList();

      double mean = axisData.reduce((a, b) => a + b) / axisData.length;
      double std = math.sqrt(
          axisData.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) /
              axisData.length);
      double minVal = axisData.reduce(math.min);
      double maxVal = axisData.reduce(math.max);
      double energy =
          axisData.map((x) => x * x).reduce((a, b) => a + b) / axisData.length;

      features.addAll([mean, std, minVal, maxVal, energy]);
    }

    return features; // 30 features
  }

  // === Step 4: Apply scaling (StandardScaler) ===
  List<double> _scaleFeatures(List<double> features) {
    List<double> scaled = [];
    for (int i = 0; i < features.length; i++) {
      scaled.add((features[i] - _featureMeans[i]) / _featureScales[i]);
    }
    return scaled;
  }

  // === Step 5: Run inference ===
  Future<double> predictCrash() async {
    if (!_isModelLoaded || _interpreter == null) {
      await loadModel();
      if (!_isModelLoaded) throw Exception("Model not loaded");
    }

    if (_sensorBuffer.length < _windowSize) {
      print("⏳ Waiting for enough sensor data...");
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
      print("🎯 Crash probability: ${crashProbability.toStringAsFixed(3)}");

      return crashProbability;
    } catch (e) {
      print("❌ Prediction error: $e");
      return 0.0;
    }
  }

  // === Step 6: High-level detection with confidence logic ===
  Future<bool> detectCrash() async {
    // Check cooldown
    if (_lastCrashTime != null) {
      Duration since = DateTime.now().difference(_lastCrashTime!);
      if (since < _crashCooldown) {
        print("⏰ Cooldown active (${_crashCooldown.inSeconds - since.inSeconds}s left)");
        return false;
      }
    }

    double probability = await predictCrash();
    bool isCrash = probability >= _crashThreshold;

    if (isCrash) {
      _consecutiveCrashPredictions++;
      if (_consecutiveCrashPredictions >= _requiredConsecutivePredictions) {
        _lastCrashTime = DateTime.now();
        _consecutiveCrashPredictions = 0;
        print("🚨 HIGH CONFIDENCE CRASH DETECTED!");
        return true;
      }
    } else {
      _consecutiveCrashPredictions = 0;
    }

    return false;
  }

  // === Utility methods ===
  void reset() {
    _sensorBuffer.clear();
    _consecutiveCrashPredictions = 0;
    _lastCrashTime = null;
  }

  void dispose() {
    _interpreter?.close();
    _isModelLoaded = false;
    _sensorBuffer.clear();
  }
}
