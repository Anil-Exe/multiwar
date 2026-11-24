import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settingsController = Provider.of<SettingsController>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SwitchListTile(
            title: const Text('Oyun Sesleri'),
            subtitle: const Text('Buton ve çarpışma sesleri'),
            value: settingsController.isSoundEnabled,
            onChanged: (value) => settingsController.toggleSound(value),
            secondary: const Icon(Icons.volume_up),
          ),
          SwitchListTile(
            title: const Text('Müzik'),
            subtitle: const Text('Arka plan müziği'),
            value: settingsController.isMusicEnabled,
            onChanged: (value) => settingsController.toggleMusic(value),
            secondary: const Icon(Icons.music_note),
          ),
          SwitchListTile(
            title: const Text('Titreşim'),
            subtitle: const Text('Darbelerde titreşim'),
            value: settingsController.isVibrationEnabled,
            onChanged: (value) => settingsController.toggleVibration(value),
            secondary: const Icon(Icons.vibration),
          ),
          // İleride Dil ve Kalite ayarları da buraya eklenebilir
        ],
      ),
    );
  }
}
