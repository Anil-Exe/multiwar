import 'dart:async';
import 'package:flutter/material.dart';
import '../models/base_model.dart';
import '../models/unit_model.dart';
import '../core/enums.dart';
import '../services/ai_service.dart';

class GameController extends ChangeNotifier {
  // Üsler
  late BaseModel leftBase;
  late BaseModel rightBase;

  // Kaynak Sistemi
  int leftGold = 0;
  int rightGold = 0;
  final int maxGold = 1500;
  final int baseGoldPerSecond = 50;

  // Sahnedeki Askerler
  List<UnitModel> activeUnits = [];

  // Oyun Modu ve AI Servisi
  bool isSinglePlayer = true;
  final AIService _aiService = AIService();

  // Yapay Zeka Zorluğu
  AIDifficulty aiDifficulty = AIDifficulty.normal;

  // Görsel Efektler (Oklar ve Kıvılcımlar)
  List<VisualEffect> activeEffects = [];

  // Oyun Döngüsü
  bool isPlaying = false;
  Timer? _gameTimer;
  int _tickCounter = 0;
  int _gameUptimeSeconds = 0; // Oyun süresini takip etmek için
  int _lastClashTick = 0; // Titreşimlerin üst üste binmemesi için zamanlayıcı

  // Etkileşim Geri Bildirimleri (Callback'ler)
  VoidCallback? onUnitSpawned;
  VoidCallback? onCombatClash;
  VoidCallback? onGameOver;

  // Boost / Challenge Sistemi
  double leftBoostEnergy = 0.0;
  double rightBoostEnergy = 0.0;
  final double maxBoostEnergy = 100.0;

  int leftBoostTicks = 0; // Kalan Boost süresi (Tick cinsinden)
  int rightBoostTicks = 0;
  final int boostDuration = 600; // 60 FPS * 10 saniye = 600 Tick

  // Oyun Sonu Kontrolü
  bool get isGameOver => leftBase.isDead || rightBase.isDead;
  String get winnerMessage {
    if (!isGameOver) return "";
    if (rightBase.isDead) return isSinglePlayer ? "KAZANDIN!" : "SOL OYUNCU KAZANDI!";
    return isSinglePlayer ? "KAYBETTİN!" : "SAĞ OYUNCU KAZANDI!";
  }

  GameController() {
    _initializeGame();
  }

  // Mod Seçimini Ayarla
  void setGameMode(bool singlePlayer) {
    isSinglePlayer = singlePlayer;
  }

  void setAIDifficulty(AIDifficulty diff) {
    aiDifficulty = diff;
  }

  void _initializeGame() {
    leftBase = BaseModel(isLeft: true);
    rightBase = BaseModel(isLeft: false);
    leftGold = 0;
    rightGold = 0;
    _tickCounter = 0;
    _gameUptimeSeconds = 0;
    leftBoostEnergy = 0.0; rightBoostEnergy = 0.0;
    leftBoostTicks = 0; rightBoostTicks = 0;
    activeEffects.clear();
    activeUnits.clear();
  }

  void startGame() {
    if (isPlaying) return;
    isPlaying = true;

    // Oyun Döngüsü: 60 FPS hedeflenerek yaklaşık 16ms'de bir güncellenir.
    _gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      _updateFrame();
    });
    notifyListeners();
  }

  void pauseGame() {
    isPlaying = false;
    _gameTimer?.cancel();
    notifyListeners();
  }

  void resetGame() {
    pauseGame();
    _initializeGame();
    notifyListeners();
  }

  void _updateFrame() {
    if (!isPlaying) return;
    _tickCounter++;

    // Boost sürelerini azalt
    if (leftBoostTicks > 0) leftBoostTicks--;
    if (rightBoostTicks > 0) rightBoostTicks--;

    // 60 Tick (yaklaşık 1 saniye) olduğunda altınları artır.
    if (_tickCounter >= 60) {
      _gameUptimeSeconds++;
      _generateGold();
      _tickCounter = 0;
    }

    // Efektlerin (Ok ve Kıvılcım) sürelerini azalt ve hareket ettir
    for (var effect in activeEffects) {
      effect.lifeTime -= 0.016;
      if (effect.isArrow) {
        effect.xPosition += (effect.isLeft ? 80 : -80) * 0.016; // Ok uçuş hızı
      }
    }
    activeEffects.removeWhere((e) => e.lifeTime <= 0); // Süresi biten efekti sil

    // Ölen askerleri temizle
    activeUnits.removeWhere((unit) => unit.state == UnitState.dead);

    // Eğer Singleplayer modundaysak Yapay Zekayı tetikle
    if (isSinglePlayer) {
      _aiService.performAction(this);
    }

    // Çarpışma, Hasar ve Hareket sistemini çalıştır
    _resolveCombat();

    notifyListeners(); // Saniyede 60 kez UI'ı güncelle.
  }

  void activateBoost(bool isLeft) {
    if (isLeft && leftBoostEnergy >= maxBoostEnergy && leftBoostTicks <= 0) {
      leftBoostEnergy = 0.0;
      leftBoostTicks = boostDuration;
      notifyListeners();
    } else if (!isLeft && rightBoostEnergy >= maxBoostEnergy && rightBoostTicks <= 0) {
      rightBoostEnergy = 0.0;
      rightBoostTicks = boostDuration;
      notifyListeners();
    }
  }

  void _addBoostEnergy(bool isLeft, double amount) {
    if (isLeft && leftBoostTicks <= 0) {
      leftBoostEnergy = (leftBoostEnergy + amount).clamp(0.0, maxBoostEnergy);
    } else if (!isLeft && rightBoostTicks <= 0) {
      rightBoostEnergy = (rightBoostEnergy + amount).clamp(0.0, maxBoostEnergy);
    }
  }

  void _resolveCombat() {
    const double deltaTime = 0.016; // Yaklaşık 16ms periyodu saniye cinsinden
    const double speedMultiplier = 5.0; // 0-100 koordinat sistemi için görsel hız çarpanı

    for (var unit in activeUnits) {
      // Askerin saldırı bekleme süresini (cooldown) düşür
      if (unit.currentCooldown > 0) {
        unit.currentCooldown -= deltaTime;
      }

      // En yakın hedefi bulma mantığı
      UnitModel? targetUnit;
      double minDistance = 999.0;

      for (var enemy in activeUnits) {
        if (unit.isLeft != enemy.isLeft && enemy.state != UnitState.dead) {
          // Sadece kendi önündeki düşmanlara bak (sol ise kendinden büyük x, sağ ise küçük x)
          double dist = unit.isLeft 
              ? (enemy.xPosition - unit.xPosition) 
              : (unit.xPosition - enemy.xPosition);
          
          if (dist > 0 && dist < minDistance) {
            minDistance = dist;
            targetUnit = enemy;
          }
        }
      }

      // Üsse olan mesafe
      double distToBase = unit.isLeft ? (100.0 - unit.xPosition) : (unit.xPosition - 0.0);
      // Gerçekçi duruş için menzile hafif bir gövde payı (2.0 birim) ekliyoruz
      double effectiveRange = unit.attackRange + 2.0;

      if (targetUnit != null && minDistance <= effectiveRange) {
        // Düşman askeri menzile girdi -> Saldır!
        unit.state = UnitState.attacking;
        if (unit.currentCooldown <= 0) {
          targetUnit.takeDamage(unit.damage);
          
          // Düşman ölürse Boost enerjisi kazan
          if (targetUnit.state == UnitState.dead) {
            _addBoostEnergy(unit.isLeft, 15.0);
          }
          
          // VURUŞ EFEKTİ OLUŞTURMA
          if (unit.type == UnitType.ranged) {
            // Menzilli ise Ok fırlat
            activeEffects.add(VisualEffect(xPosition: unit.xPosition, isArrow: true, isLeft: unit.isLeft, lifeTime: 0.5));
          } else {
            // Yakın dövüş ise düşman üzerinde Kıvılcım çıkart
            activeEffects.add(VisualEffect(xPosition: targetUnit.xPosition, isArrow: false, isLeft: unit.isLeft, lifeTime: 0.2));
          }

          unit.currentCooldown = unit.attackCooldown;

          // Ses / Titreşim geri bildirimi için aralığı kısıtlıyoruz
          if (_tickCounter - _lastClashTick > 15 || _tickCounter < _lastClashTick) {
            onCombatClash?.call();
            _lastClashTick = _tickCounter;
          }
        }
      } else if (distToBase <= effectiveRange) {
        // Düşman üssü menzile girdi -> Üsse Saldır!
        unit.state = UnitState.attacking;
        if (unit.currentCooldown <= 0) {
          if (unit.isLeft) rightBase.takeDamage(unit.damage);
          else leftBase.takeDamage(unit.damage);

          if (unit.type == UnitType.ranged) {
            activeEffects.add(VisualEffect(xPosition: unit.xPosition, isArrow: true, isLeft: unit.isLeft, lifeTime: 0.5));
          } else {
            double basePos = unit.isLeft ? 100.0 : 0.0;
            activeEffects.add(VisualEffect(xPosition: basePos, isArrow: false, isLeft: unit.isLeft, lifeTime: 0.2));
          }

          unit.currentCooldown = unit.attackCooldown;
        }
      } else {
        // Hedef yoksa ileri yürü!
        unit.state = UnitState.moving;
        unit.xPosition += (unit.isLeft ? 1 : -1) * (unit.movementSpeed * speedMultiplier * deltaTime);
        
        // Sınırları aşmasını koruma amaçlı engelle
        if (unit.xPosition < 0) unit.xPosition = 0;
        if (unit.xPosition > 100) unit.xPosition = 100;
      }
    }

    // Üslerden biri yıkıldıysa oyunu otomatik duraklat
    if (leftBase.isDead || rightBase.isDead) {
      if (isPlaying) onGameOver?.call(); // Sadece ilk bittiğinde tetikle
      pauseGame();
    }
  }

  void _generateGold() {
    // Her 30 saniyede bir, altın üretimini kalıcı olarak 10 artırır (Oyunun çıkmaza girmesini kesin olarak çözer)
    int escalationBonus = (_gameUptimeSeconds ~/ 30) * 10;
    int currentBaseGold = baseGoldPerSecond + escalationBonus;

    int leftAdded = leftBoostTicks > 0 ? currentBaseGold * 2 : currentBaseGold;
    int rightAdded = rightBoostTicks > 0 ? currentBaseGold * 2 : currentBaseGold;

    if (leftGold < maxGold) {
      leftGold += leftAdded;
      if (leftGold > maxGold) leftGold = maxGold;
    }
    if (rightGold < maxGold) {
      rightGold += rightAdded;
      if (rightGold > maxGold) rightGold = maxGold;
    }
  }

  // Birim Üretme Fonksiyonu
  void spawnUnit(bool isLeft, UnitType type) {
    int cost = UnitModel.getCost(type);
    
    if (isLeft && leftGold >= cost) {
      leftGold -= cost;
      _addBoostEnergy(true, 5.0); // Asker basınca enerji ver
      activeUnits.add(UnitModel.create(isLeft: true, type: type));
      onUnitSpawned?.call();
      notifyListeners();
    } else if (!isLeft && rightGold >= cost) {
      rightGold -= cost;
      _addBoostEnergy(false, 5.0); // Asker basınca enerji ver
      activeUnits.add(UnitModel.create(isLeft: false, type: type));
      onUnitSpawned?.call();
      notifyListeners();
    }
    // Eğer altın yetmiyorsa hiçbir şey yapmıyoruz. (İleride yetersiz bakiye sesi eklenebilir)
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }
}

class VisualEffect {
  double xPosition;
  final bool isArrow;
  final bool isLeft;
  double lifeTime;

  VisualEffect({
    required this.xPosition,
    required this.isArrow,
    required this.isLeft,
    required this.lifeTime,
  });
}