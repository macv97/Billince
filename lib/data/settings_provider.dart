import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ColorBlindnessMode { none, protanopia, deuteranopia, tritanopia }

class SettingsProvider extends ChangeNotifier {
  SharedPreferences? _prefs;

  String _language = 'es';
  ThemeMode _themeMode = ThemeMode.system;
  Color _interfaceColor = const Color(0xFF0F172A);
  ColorBlindnessMode _colorBlindnessMode = ColorBlindnessMode.none;
  double _textScaleFactor = 1.0;
  bool _useBiometrics = false;

  String get language => _language;
  ThemeMode get themeMode => _themeMode;
  Color get interfaceColor => _interfaceColor;
  ColorBlindnessMode get colorBlindnessMode => _colorBlindnessMode;
  double get textScaleFactor => _textScaleFactor;
  bool get useBiometrics => _useBiometrics;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    _language = _prefs?.getString('language') ?? 'es';
    
    final themeIndex = _prefs?.getInt('themeMode') ?? 0;
    _themeMode = ThemeMode.values[themeIndex];
    
    final colorValue = _prefs?.getInt('interfaceColor') ?? 0xFF0F172A;
    _interfaceColor = Color(colorValue);
    
    final cbIndex = _prefs?.getInt('colorBlindnessMode') ?? 0;
    _colorBlindnessMode = ColorBlindnessMode.values[cbIndex];
    
    _textScaleFactor = _prefs?.getDouble('textScaleFactor') ?? 1.0;
    _useBiometrics = _prefs?.getBool('useBiometrics') ?? false;
    
    notifyListeners();
  }

  void setLanguage(String lang) {
    _language = lang;
    _prefs?.setString('language', lang);
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _prefs?.setInt('themeMode', mode.index);
    notifyListeners();
  }

  void setInterfaceColor(Color color) {
    _interfaceColor = color;
    _prefs?.setInt('interfaceColor', color.value);
    notifyListeners();
  }

  void setColorBlindnessMode(ColorBlindnessMode mode) {
    _colorBlindnessMode = mode;
    _prefs?.setInt('colorBlindnessMode', mode.index);
    notifyListeners();
  }

  void setTextScaleFactor(double scale) {
    _textScaleFactor = scale;
    _prefs?.setDouble('textScaleFactor', scale);
    notifyListeners();
  }

  void setUseBiometrics(bool useBio) {
    _useBiometrics = useBio;
    _prefs?.setBool('useBiometrics', useBio);
    notifyListeners();
  }
}
