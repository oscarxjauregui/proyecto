import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

class ThemeProvider with ChangeNotifier {
  late ThemeData _themeData;

  ThemeProvider() {
    _themeData = ThemeData.light();
  }

  ThemeData getTheme() => _themeData;

  void setThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        _themeData = ThemeData.dark();
        break;
      case ThemeMode.light:
        _themeData = ThemeData.light();
        break;
      case ThemeMode.system:
        Brightness platformBrightness =
            SchedulerBinding.instance!.platformDispatcher.platformBrightness;
        _themeData = platformBrightness == Brightness.dark
            ? ThemeData.dark()
            : ThemeData.light();
        break;
    }
    notifyListeners();
  }
}
