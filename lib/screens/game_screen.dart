import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../controllers/game_controller.dart';
import '../controllers/settings_controller.dart';
import '../controllers/theme_controller.dart';
import '../core/enums.dart';
import '../models/unit_model.dart';
import 'bouncing_button.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _isCountingDown = true;
  String _countdownText = '3';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startCountdown();
    });
  }

  void _startCountdown() async {
    final gameController = Provider.of<GameController>(context, listen: false);
    final settings = Provider.of<SettingsController>(context, listen: false);

    // Ses ve Titreşim geri bildirimlerini bağla
    gameController.onUnitSpawned = () {
      if (settings.isSoundEnabled) SystemSound.play(SystemSoundType.click);
    };
    gameController.onCombatClash = () {
      if (settings.isVibrationEnabled) HapticFeedback.lightImpact();
    };
    gameController.onGameOver = () {
      if (settings.isVibrationEnabled) HapticFeedback.heavyImpact();
    };

    // Geri sayım döngüsü
    final steps = ['3', '2', '1', 'BAŞLA!'];
    for (var step in steps) {
      if (!mounted) return;
      setState(() => _countdownText = step);
      
      if (settings.isSoundEnabled && step != 'BAŞLA!') {
        SystemSound.play(SystemSoundType.click);
      }
      await Future.delayed(const Duration(seconds: 1));
    }

    if (!mounted) return;
    setState(() => _isCountingDown = false);
    gameController.startGame();
  }

  @override
  void deactivate() {
    // Ekrandan (sayfadan) çıkılırken oyun döngüsünü durdur ve değerleri sıfırla
    final gameController = Provider.of<GameController>(context, listen: false);
    gameController.onUnitSpawned = null;
    gameController.onCombatClash = null;
    gameController.onGameOver = null;
    gameController.resetGame();
    
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final gameController = Provider.of<GameController>(context);
    final themeController = Provider.of<ThemeController>(context);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Oyun Arka Planı (Gökyüzü)
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(themeController.currentTheme == GameTheme.medieval ? 'assets/images/bg_medieval.png' : 'assets/images/bg_modern.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            Column(
              children: [
                _buildTopBar(gameController),
                // Savaş Alanı Katmanı
                Expanded(child: _buildBattlefield(gameController, themeController)),
                // Alt UI Katmanı (Birim Üretme Butonları)
                _buildBottomControls(gameController, themeController),
              ],
            ),

            Positioned(
              top: 16,
              left: 16,
              child: Container(
                decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),

            // Duraklatma (Pause) Butonu
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                child: IconButton(
                  icon: Icon(gameController.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 30),
                  onPressed: () {
                    if (gameController.isPlaying) gameController.pauseGame();
                    else gameController.startGame();
                  },
                ),
              ),
            ),

            // Oyun Sonu Ekranı (Overlay)
            if (gameController.isGameOver)
              Positioned.fill(
                child: Container(
                  color: Colors.black87,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('OYUN BİTTİ', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
                        const SizedBox(height: 16),
                        Text(gameController.winnerMessage, style: const TextStyle(fontSize: 28, color: Colors.amber, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 40),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Padding(padding: EdgeInsets.all(12), child: Text('Tekrar Oyna', style: TextStyle(fontSize: 18))),
                          onPressed: () {
                            gameController.resetGame();
                            setState(() => _isCountingDown = true);
                            _startCountdown();
                          },
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.home),
                          label: const Padding(padding: EdgeInsets.all(12), child: Text('Ana Menüye Dön', style: TextStyle(fontSize: 18))),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade800),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Geri Sayım Ekranı (Overlay)
            if (_isCountingDown)
              Positioned.fill(
                child: Container(
                  color: Colors.black54, // Arka planı hafif karartır
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                      child: Text(
                        _countdownText,
                        key: ValueKey<String>(_countdownText),
                        style: const TextStyle(
                          fontSize: 100,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                          shadows: [Shadow(color: Colors.black, blurRadius: 20)],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(GameController controller) {
    return Container(
      padding: const EdgeInsets.only(left: 60, right: 16, top: 16, bottom: 16),
      color: Colors.black12,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Sol Oyuncu 
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sol Üs: ${controller.leftBase.currentHealth.toInt()}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
              Text('Gold: ${controller.leftGold}', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              _buildBoostBar(controller, true),
            ],
          ),
          // Sağ Oyuncu (Yapay Zeka)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Sağ Üs: ${controller.rightBase.currentHealth.toInt()}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)),
              Text('Gold: ${controller.rightGold}', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              _buildBoostBar(controller, false),
            ],
          ),
        ],
      ),
    );
  }

  // Savaş Alanı Çizimi
  Widget _buildBattlefield(GameController controller, ThemeController themeController) {
    bool isMedieval = themeController.currentTheme == GameTheme.medieval;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Zemin (Toprak veya Asfalt)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: isMedieval ? Colors.brown.shade800 : Colors.grey.shade800,
                  border: Border(top: BorderSide(color: isMedieval ? Colors.green.shade800 : Colors.grey.shade600, width: 4)),
                ),
              ),
            ),

            // Sol Üs Çizimi
            Positioned(
              bottom: 40,
              left: 0,
              child: Column(
                children: [
                  _buildHealthBar(controller.leftBase.currentHealth, controller.leftBase.maxHealth, width: 60, height: 8),
                  const SizedBox(height: 8),
                  _buildImage(
                    isMedieval ? 'assets/images/base_medieval.png' : 'assets/images/base_modern.png',
                    Icon(isMedieval ? Icons.account_balance : Icons.domain, color: Colors.redAccent, size: 60),
                    width: 100, height: 120, // Üs boyutunu büyük ayarladık
                  ),
                ],
              ),
            ),
            // Sağ Üs Çizimi
            Positioned(
              bottom: 40,
              right: 0,
              child: Column(
                children: [
                  _buildHealthBar(controller.rightBase.currentHealth, controller.rightBase.maxHealth, width: 60, height: 8),
                  const SizedBox(height: 8),
                  _buildImage(
                    isMedieval ? 'assets/images/base_medieval.png' : 'assets/images/base_modern.png',
                    Icon(isMedieval ? Icons.account_balance : Icons.domain, color: Colors.blueAccent, size: 60),
                    width: 100, height: 120, // Üs boyutunu büyük ayarladık
                  ),
                ],
              ),
            ),

            // Askerleri Çiz
            ...controller.activeUnits.map((unit) {
              // 0-100 koordinat sistemini ekran genişliğine dönüştürüyoruz
              double rawLeftPosition = (unit.xPosition / 100) * constraints.maxWidth;
              
              // Vuruş Animasyonu (Saldırırken ileri-geri titreşim)
              double attackOffset = 0;
              if (unit.state == UnitState.attacking) {
                attackOffset = (unit.currentCooldown * 15 % 6);
                if (!unit.isLeft) attackOffset = -attackOffset; // Sağ taraf ters yöne titrer
              }

              // Asker Boyutlarını İstediğin Gibi Ayarlama
              double unitW = 50;
              double unitH = 50;
              if (themeController.currentTheme == GameTheme.medieval) {
                if (unit.type == UnitType.ranged) { unitW = 75; unitH = 75; }
                else if (unit.type == UnitType.tank) { unitW = 85; unitH = 85; }
              } else if (themeController.currentTheme == GameTheme.modern) {
                if (unit.type == UnitType.tank) { unitW = 85; unitH = 85; }
              }

              return Positioned(
                bottom: 40, // Yerin tam üstü
                left: rawLeftPosition - (unitW / 2) + attackOffset, // Merkeze oturtmak için genişliğin yarısını çıkarıyoruz
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Asker Can Barı
                    _buildHealthBar(unit.currentHealth, unit.maxHealth, width: 40, height: 5),
                    const SizedBox(height: 2),
                    // Asker Resmi (Etrafındaki yuvarlağı ve arka planı sildik, boyutu büyüttük)
                    Transform.flip(
                      flipX: !unit.isLeft, // Sağ takımın (düşmanın) askerleri sola doğru baksın
                      child: _buildImage(
                        'assets/images/${themeController.currentTheme.name}_${unit.type.name}.png',
                        Icon(_getUnitIcon(unit.type, themeController.currentTheme), color: unit.isLeft ? Colors.redAccent : Colors.blueAccent, size: 40),
                        width: unitW, height: unitH, // Ayarlanan özel boyutları buraya verdik
                        ),
                    ),
                  ],
                ),
              );
            }).toList(),

            // Efektleri (Oklar ve Kıvılcımlar) Çiz
            ...controller.activeEffects.map((effect) {
              double rawLeftPosition = (effect.xPosition / 100) * constraints.maxWidth;
              
              return Positioned(
                bottom: 55, // Askerlerin silah hizası
                left: rawLeftPosition - 20,
                child: Transform.flip(
                  flipX: !effect.isLeft, // Sağdan geliyorsa oku sola çevir
                  child: effect.isArrow
                      ? _buildImage(
                          'assets/images/arrow.png',
                          const Icon(Icons.arrow_right_alt, color: Colors.black, size: 30),
                          width: 40, height: 20, // Ok boyutu büyütüldü
                        )
                      : _buildImage(
                          'assets/images/spark.png',
                          const Icon(Icons.flash_on, color: Colors.orange, size: 30),
                          width: 40, height: 40, // Kıvılcım boyutu büyütüldü
                        ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  IconData _getUnitIcon(UnitType type, GameTheme theme) {
    if (theme == GameTheme.medieval) {
      switch (type) {
        case UnitType.basic: return Icons.person; // Kılıçlı
        case UnitType.ranged: return Icons.sports_martial_arts; // Okçu
        case UnitType.tank: return Icons.shield; // Şövalye
        case UnitType.special: return Icons.flash_on; // Atlı
        case UnitType.elite: return Icons.fort; // Kuşatma
      }
    } else {
      switch (type) {
        case UnitType.basic: return Icons.person_outline; // Er
        case UnitType.ranged: return Icons.gps_fixed; // Roketçi / Keskin Nişancı
        case UnitType.tank: return Icons.security; // Kalkanlı
        case UnitType.special: return Icons.flight; // Drone
        case UnitType.elite: return Icons.local_fire_department; // Ağır Tank
      }
    }
  }

  // Birim Üretim Kontrolleri
  Widget _buildBottomControls(GameController controller, ThemeController theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      color: theme.currentTheme == GameTheme.medieval ? Colors.brown.shade900 : Colors.grey.shade900,
      child: Row(
        children: [
          // Sol Oyuncu Butonları
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.start,
              spacing: 4,
              runSpacing: 4,
              children: UnitType.values.map((type) => _buildSpawnButton(controller, true, type, theme)).toList(),
            ),
          ),
          // Sağ Oyuncu Butonları (Local Multiplayer için)
          Expanded(
            child: controller.isSinglePlayer
                ? const Center(
                    child: Text(
                      'AI KONTROL EDİYOR',
                      style: TextStyle(
                          color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                  )
                : Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 4,
                    runSpacing: 4,
                    children: UnitType.values
                        .map((type) => _buildSpawnButton(controller, false, type, theme))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  // Tekil Asker Üretme Butonu
  Widget _buildSpawnButton(GameController controller, bool isLeft, UnitType type, ThemeController theme) {
    final cost = UnitModel.getCost(type);
    final currentGold = isLeft ? controller.leftGold : controller.rightGold;
    final canAfford = currentGold >= cost;

    return BouncingButton(
      onTap: canAfford ? () => controller.spawnUnit(isLeft, type) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: canAfford 
                ? (isLeft ? [Colors.red.shade300, Colors.red.shade700] : [Colors.blue.shade300, Colors.blue.shade700]) 
                : [Colors.grey.shade600, Colors.grey.shade800],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: canAfford ? Colors.white : Colors.grey, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // İkon Yerine Eklediğin Gerçek Asker PNG'sini Gösteriyoruz
            _buildImage(
              'assets/images/${theme.currentTheme.name}_${type.name}.png',
              Icon(_getUnitIcon(type, theme.currentTheme), color: Colors.white, size: 24),
              width: 30, height: 30,
            ),
            const SizedBox(height: 4),
            Text('$cost G', style: TextStyle(fontSize: 12, color: canAfford ? Colors.yellowAccent : Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // Can Barı Çizen Yardımcı Widget
  Widget _buildHealthBar(double currentHealth, double maxHealth, {required double width, required double height}) {
    double percentage = (currentHealth / maxHealth).clamp(0.0, 1.0);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.red, // Arka plan (Boş can)
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: Colors.black, width: 0.5),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: width * percentage,
          color: Colors.greenAccent, // Dolu can
        ),
      ),
    );
  }

  // Boost Barı Yardımcı Widget'ı
  Widget _buildBoostBar(GameController controller, bool isLeft) {
    double energy = isLeft ? controller.leftBoostEnergy : controller.rightBoostEnergy;
    bool isBoostActive = (isLeft ? controller.leftBoostTicks : controller.rightBoostTicks) > 0;
    bool canActivate = energy >= controller.maxBoostEnergy;

    return Column(
      crossAxisAlignment: isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(
          isBoostActive ? '🔥 BOOST AKTİF!' : 'Boost Enerjisi',
          style: TextStyle(color: isBoostActive ? Colors.deepOrange : Colors.grey.shade700, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        InkWell(
          // Sol oyuncuysa ve bar doluysa tıklayıp aktif edebilir
          onTap: (isLeft && canActivate && !isBoostActive) ? () => controller.activateBoost(true) : null,
          child: Container(
            width: 80,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: canActivate ? Colors.orange : Colors.grey, width: canActivate ? 2 : 1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: isBoostActive ? 1.0 : energy / controller.maxBoostEnergy,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(isBoostActive ? Colors.orange : (canActivate ? Colors.orangeAccent : Colors.blueGrey)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Resim veya Fallback İkon Yükleyici Yardımcı Metot
  Widget _buildImage(String path, Widget fallbackIcon, {double width = 50, double height = 50}) {
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => fallbackIcon,
    );
  }
}
