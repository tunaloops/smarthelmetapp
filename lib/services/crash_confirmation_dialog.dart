import 'dart:async';
import 'package:flutter/material.dart';

class CrashConfirmationDialog extends StatefulWidget {
  final double probability;
  final VoidCallback onConfirm;
  final VoidCallback onTimeout;

  const CrashConfirmationDialog({
    Key? key,
    required this.probability,
    required this.onConfirm,
    required this.onTimeout,
  }) : super(key: key);

  @override
  State<CrashConfirmationDialog> createState() => _CrashConfirmationDialogState();
}

class _CrashConfirmationDialogState extends State<CrashConfirmationDialog> {
  static const int countdownSeconds = 30;
  int remainingSeconds = countdownSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        remainingSeconds--;
      });

      if (remainingSeconds <= 0) {
        timer.cancel();
        widget.onTimeout();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.red.shade50,
      title: Row(
        children: [
          Icon(Icons.warning, color: Colors.red, size: 40),
          const SizedBox(width: 10),
          Text(
            'CRASH DETECTED',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Are you okay?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Text(
            'Emergency contacts will be alerted in:',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 10),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red,
            ),
            child: Center(
              child: Text(
                '$remainingSeconds',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Confidence: ${(widget.probability * 100).toStringAsFixed(1)}%',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: widget.onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 20),
            ),
            child: Text(
              "I'M OK - CANCEL ALERT",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}