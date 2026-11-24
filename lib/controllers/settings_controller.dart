import 'package:flutter/material.dart';

class SettingsController extends ChangeNotifier {
  bool _isSoundEnabled = true;
  bool _isMusicEnabled = true;
  bool _isVibrationEnabled = true;

  bool get isSoundEnabled => _isSoundEnabled;
  bool get isMusicEnabled => _isMusicEnabled;
  bool get isVibrationEnabled => _isVibrationEnabled;

  void toggleSound(bool value) {
    _isSoundEnabled = value;
    notifyListeners();
  }

  void toggleMusic(bool value) {
    _isMusicEnabled = value;
    notifyListeners();
  }

  void toggleVibration(bool value) {
    _isVibrationEnabled = value;
    notifyListeners();
  }
}