import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/enums.dart';
import 'package:provider/provider.dart';
import '../controllers/game_controller.dart';

class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mod Seçimi')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                _showDifficultyDialog(context);
              },
              child: const Text('Singleplayer (vs AI)'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Provider.of<GameController>(context, listen: false).setGameMode(false);
                Navigator.pushNamed(context, AppRoutes.game);
              },
              child: const Text('Local Multiplayer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDifficultyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Zorluk Seçimi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AIDifficulty.values.map((diff) {
            String label = diff == AIDifficulty.easy ? "Kolay" : 
                           diff == AIDifficulty.normal ? "Normal" : "Zor";
            return ListTile(
              title: Text(label),
              onTap: () {
                Navigator.pop(ctx); // Dialog'u kapat
                final gc = Provider.of<GameController>(context, listen: false);
                gc.setGameMode(true);
                gc.setAIDifficulty(diff);
                Navigator.pushNamed(context, AppRoutes.game);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
