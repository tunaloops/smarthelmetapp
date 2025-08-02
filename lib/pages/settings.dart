import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool alertsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SwitchListTile(
          title: Text('Enable crash alerts'),
          value: alertsEnabled,
          onChanged: (val) {
            setState(() => alertsEnabled = val);
          },
      ),
    );
  }
}
