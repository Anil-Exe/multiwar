import 'dart:math';
import '../core/enums.dart';
import '../models/unit_model.dart';
import '../controllers/game_controller.dart';

class AIService {
  final Random _random = Random();
  int _aiTickCounter = 0;

  void performAction(GameController controller) {
    _aiTickCounter++;
    
    // Zorluğa göre karar verme hızı (Hard: Hızlı, Easy: Yavaş)
    int interval = controller.aiDifficulty == AIDifficulty.hard ? 30 : 
                   (controller.aiDifficulty == AIDifficulty.easy ? 120 : 60);
    if (_aiTickCounter < interval) return;
    _aiTickCounter = 0;

    int currentGold = controller.rightGold;

    // Sahadaki asker durumunu analiz et
    int enemyCount = controller.activeUnits.where((u) => u.isLeft).length; // Oyuncunun askerleri
    int myCount = controller.activeUnits.where((u) => !u.isLeft).length;   // AI'ın askerleri

    // Yapay Zeka Boost Enerjisi dolduysa hemen kullansın
    if (controller.rightBoostEnergy >= controller.maxBoostEnergy) {
      controller.activateBoost(false);
    }

    // Alınabilecek birimleri bul
    List<UnitType> affordableUnits = UnitType.values.where((type) {
      return UnitModel.getCost(type) <= currentGold;
    }).toList();

    if (affordableUnits.isEmpty) return;

    bool shouldSpawn = false;
    UnitType? selectedType;

    // Sadece ciddi bir sayı farkı varsa savunmaya (paniğe) girer. (Eskiden 1 farkta bile kitleniyordu)
    if (enemyCount > myCount + 2) {
      // SAVUNMA MODU: Düşman baskın. Savunma için Basic VEYA Ranged kullanır.
      shouldSpawn = true;
      var defenseTypes = affordableUnits.where((u) => u == UnitType.basic || u == UnitType.ranged).toList();
      if (defenseTypes.isNotEmpty) {
        selectedType = defenseTypes[_random.nextInt(defenseTypes.length)];
      } else {
        selectedType = affordableUnits.first; 
      }
    } else {
      // SALDIRI/BASKI MODU
      if (controller.aiDifficulty == AIDifficulty.easy) {
        shouldSpawn = _random.nextDouble() > 0.4; // Kolay AI biraz daha yavaş basar
        if (shouldSpawn) selectedType = affordableUnits.first;
      } else if (controller.aiDifficulty == AIDifficulty.hard) {
        shouldSpawn = currentGold >= 500 || _random.nextDouble() > 0.6; // Zor AI parayı Elitler için biriktirir
        if (shouldSpawn) selectedType = affordableUnits.last;
      } else {
        shouldSpawn = _random.nextDouble() > 0.3 || currentGold >= 300; 
        if (shouldSpawn) {
          selectedType = affordableUnits[_random.nextInt(affordableUnits.length)];
        }
      }
    }

    if (shouldSpawn && selectedType != null) {
      controller.spawnUnit(false, selectedType);
    }
  }
}