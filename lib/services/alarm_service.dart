import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  Future<void> triggerAlarm() async {
    if (_isPlaying) return;

    _isPlaying = true;

    // Start vibration pattern
    _startVibration();

    // Play alarm sound
    await _playAlarmSound();
  }

  Future<void> _startVibration() async {
    bool? hasVibrator = await Vibration.hasVibrator();

    if (hasVibrator == true) {
      // Vibrate in pattern: [wait, vibrate, wait, vibrate, ...]
      // Pattern: 500ms on, 200ms off, repeated
      Vibration.vibrate(
        pattern: [0, 500, 200, 500, 200, 500, 200],
        intensities: [0, 255, 0, 255, 0, 255, 0],
        repeat: 0, // Index to repeat from (0 = repeat all)
      );
    }
  }

  Future<void> _playAlarmSound() async {
    try {
      // Play system alarm sound (requires asset)
      // Or use a generated tone
      await _audioPlayer.play(AssetSource('/assets/sounds/alarm.mp3'));
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);
    } catch (e) {
      print("Error playing alarm: $e");
      // Fallback: just vibrate
    }
  }

  Future<void> stopAlarm() async {
    _isPlaying = false;

    // Stop vibration
    await Vibration.cancel();

    // Stop audio
    await _audioPlayer.stop();
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}