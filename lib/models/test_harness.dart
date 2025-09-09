import 'dart:async';
import 'dart:math';
import '../services/ai_detection.dart';

class TestHarness {
  final CrashDetectionService _crashDetection = CrashDetectionService();
  Timer? _timer;
  final Random _random = Random();

  // Start streaming fake sensor data
  void start({bool simulateCrash = false}) {
    _timer?.cancel();
    int tick = 0;

    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) async {
      tick++;

      // Normal values (like gentle riding)
      double ax = 0.0 + _random.nextDouble() * 2;
      double ay = 9.8 + (_random.nextDouble() - 0.5); // gravity dominant
      double az = 0.0 + _random.nextDouble() * 2;
      double gx = _random.nextDouble() * 5;
      double gy = _random.nextDouble() * 5;
      double gz = _random.nextDouble() * 5;

      // Inject a "crash" spike after some time
      if (simulateCrash && tick > 500 && tick < 520) {
        ax = 20 + _random.nextDouble() * 5;
        ay = 20 + _random.nextDouble() * 5;
        az = 20 + _random.nextDouble() * 5;
        gx = 200 + _random.nextDouble() * 50;
        gy = 200 + _random.nextDouble() * 50;
        gz = 200 + _random.nextDouble() * 50;
      }

      // Feed into crash detection buffer
      _crashDetection.addSensorReading(
        ax: ax, ay: ay, az: az,
        gx: gx, gy: gy, gz: gz,
      );

      // Check every 200ms for detection
      if (tick % 20 == 0) {
        bool crash = await _crashDetection.detectCrash();
        if (crash) {
          print("🚨 CRASH DETECTED (simulated) 🚨");
        }
      }
    });

    print("▶️ Test harness started (simulateCrash=$simulateCrash)");
  }

  // Stop simulation
  void stop() {
    _timer?.cancel();
    _crashDetection.reset();
    print("⏹️ Test harness stopped");
  }
}
