import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier;

  const SettingsScreen({super.key, required this.themeNotifier});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.themeNotifier.value == ThemeMode.dark;
  }

  Future<void> _saveThemePreference(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', isDark ? 'dark' : 'light');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: SwitchListTile(
        title: const Text('Dark Mode'),
        subtitle: const Text('Switch between light and dark themes'),
        value: _isDarkMode,
        onChanged: (val) async {
          setState(() => _isDarkMode = val);
          widget.themeNotifier.value =
          val ? ThemeMode.dark : ThemeMode.light;
          await _saveThemePreference(val);
        },
      ),
    );
  }
}
