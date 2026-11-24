import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../controllers/theme_controller.dart';
import '../core/enums.dart';
import 'bouncing_button.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);

    return Scaffold(
      backgroundColor: themeController.backgroundColor,
      body: Container(
        decoration: BoxDecoration(
          color: themeController.backgroundColor,
          image: DecorationImage(
            image: AssetImage(themeController.currentTheme == GameTheme.medieval ? 'assets/images/bg_medieval.png' : 'assets/images/bg_modern.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken), // Arkaplanı biraz karartır, yazılar okunur
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  themeController.currentTheme == GameTheme.medieval ? Icons.shield : Icons.rocket_launch,
                  size: 100,
                  color: Colors.white70,
                ),
                const SizedBox(height: 16),
                const Text(
                  'MULTIWAR',
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 4),
                ),
                const SizedBox(height: 48),
                _buildMenuButton(context, 'Savaşa Başla', AppRoutes.modeSelection, themeController.primaryColor),
                const SizedBox(height: 16),
                _buildMenuButton(context, 'Tema Seç', AppRoutes.themeSelection, themeController.primaryColor),
                const SizedBox(height: 16),
                _buildMenuButton(context, 'Ayarlar', AppRoutes.settings, themeController.primaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, String text, String route, Color color) {
    return BouncingButton(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        width: 250,
        height: 55,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white70, width: 2),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 3))],
        ),
        child: Center(child: Text(text, style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold))),
      ),
    );
  }
}
