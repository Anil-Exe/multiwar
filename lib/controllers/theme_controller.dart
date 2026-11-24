import 'package:flutter/material.dart';
import '../core/enums.dart';

class ThemeController extends ChangeNotifier {
  GameTheme _currentTheme = GameTheme.medieval;

  GameTheme get currentTheme => _currentTheme;

  void setTheme(GameTheme theme) {
    if (_currentTheme != theme) {
      _currentTheme = theme;
      notifyListeners();
    }
  }

  // Tema bazlı genel renkleri buradan yönetebiliriz.
  Color get primaryColor {
    return _currentTheme == GameTheme.medieval ? Colors.brown : Colors.blueGrey;
  }

  Color get backgroundColor {
    return _currentTheme == GameTheme.medieval ? Colors.green.shade800 : Colors.grey.shade900;
  }

  String get themeName {
    return _currentTheme == GameTheme.medieval ? 'Orta Çağ' : 'Modern Dünya';
  }
}