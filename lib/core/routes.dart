import 'package:flutter/material.dart';
import 'constants.dart';
import '../screens/splash_screen.dart';
import '../screens/main_menu_screen.dart';
import '../screens/mode_selection_screen.dart';
import '../screens/theme_selection_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/game_screen.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case AppRoutes.mainMenu:
        return MaterialPageRoute(builder: (_) => const MainMenuScreen());
      case AppRoutes.modeSelection:
        return MaterialPageRoute(builder: (_) => const ModeSelectionScreen());
      case AppRoutes.themeSelection:
        return MaterialPageRoute(builder: (_) => const ThemeSelectionScreen());
      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case AppRoutes.game:
        return MaterialPageRoute(builder: (_) => const GameScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Hata')),
            body: const Center(child: Text('Sayfa bulunamadı!')),
          ),
        );
    }
  }
}
