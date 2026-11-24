import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/theme_controller.dart';
import '../core/enums.dart';

class ThemeSelectionScreen extends StatelessWidget {
  const ThemeSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Tema Seçimi')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Aktif Tema: ${themeController.themeName}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            _buildThemeCard(
              context,
              title: 'Orta Çağ',
              theme: GameTheme.medieval,
              currentTheme: themeController.currentTheme,
              color: Colors.brown,
              icon: Icons.shield,
              onTap: () => themeController.setTheme(GameTheme.medieval),
            ),
            const SizedBox(height: 16),
            _buildThemeCard(
              context,
              title: 'Modern Dünya',
              theme: GameTheme.modern,
              currentTheme: themeController.currentTheme,
              color: Colors.blueGrey,
              icon: Icons.rocket_launch,
              onTap: () => themeController.setTheme(GameTheme.modern),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeCard(BuildContext context, {required String title, required GameTheme theme, required GameTheme currentTheme, required Color color, required IconData icon, required VoidCallback onTap}) {
    final isSelected = theme == currentTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(isSelected ? 0.9 : 0.4),
          border: Border.all(color: isSelected ? Colors.amber : Colors.transparent, width: 3),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_circle, color: Colors.amber, size: 32),
          ],
        ),
      ),
    );
  }
}
