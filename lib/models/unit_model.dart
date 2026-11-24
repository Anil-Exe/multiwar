import '../core/enums.dart';

class UnitModel {
  final String id;
  final bool isLeft;
  final UnitType type;
  
  // Ekrandaki konumu (0.0 sol üs, 100.0 sağ üs)
  double xPosition;
  
  double maxHealth;
  double currentHealth;
  double damage;
  double attackRange;
  double attackCooldown;
  double currentCooldown = 0.0;
  double movementSpeed;
  int cost;
  
  UnitState state = UnitState.moving;

  UnitModel({
    required this.id,
    required this.isLeft,
    required this.type,
    required this.xPosition,
    required this.maxHealth,
    required this.currentHealth,
    required this.damage,
    required this.attackRange,
    required this.attackCooldown,
    required this.movementSpeed,
    required this.cost,
  });

  // Birim tipine göre maliyeti döndüren yardımcı fonksiyon
  static int getCost(UnitType type) {
    switch (type) {
      case UnitType.basic: return 100;
      case UnitType.ranged: return 150; // Menzillileri daha ulaşılabilir yapıyoruz
      case UnitType.tank: return 250;
      case UnitType.special: return 350;
      case UnitType.elite: return 500;
    }
  }

  // Fabrika (Factory) metodu: Seçilen tipe göre birim istatistiklerini oluşturur
  factory UnitModel.create({required bool isLeft, required UnitType type}) {
    String id = DateTime.now().microsecondsSinceEpoch.toString();
    // Sol takım %5'ten, sağ takım %95'ten oyuna başlar
    double startX = isLeft ? 5.0 : 95.0; 
    int cost = getCost(type);

    switch (type) {
      case UnitType.basic:
        // Temel er (dengeli, ucuz)
        return UnitModel(id: id, isLeft: isLeft, type: type, xPosition: startX, maxHealth: 100, currentHealth: 100, damage: 15, attackRange: 5, attackCooldown: 1.0, movementSpeed: 2.0, cost: cost);
      case UnitType.ranged:
        // Okçu / Bombacı (Canı az ama hasarı ve menzili yükseltildi)
        return UnitModel(id: id, isLeft: isLeft, type: type, xPosition: startX, maxHealth: 60, currentHealth: 60, damage: 35, attackRange: 35, attackCooldown: 1.2, movementSpeed: 1.5, cost: cost);
      case UnitType.tank:
        // Dayanıklı birlik (Duvar görevi görür)
        return UnitModel(id: id, isLeft: isLeft, type: type, xPosition: startX, maxHealth: 400, currentHealth: 400, damage: 10, attackRange: 5, attackCooldown: 2.0, movementSpeed: 1.0, cost: cost);
      case UnitType.special:
        // Özel birim (hızlı ve vur-kaç tarzı)
        return UnitModel(id: id, isLeft: isLeft, type: type, xPosition: startX, maxHealth: 150, currentHealth: 150, damage: 40, attackRange: 8, attackCooldown: 1.0, movementSpeed: 3.0, cost: cost);
      case UnitType.elite:
        // Elit şövalye / roketçi (çok güçlü ama pahalı)
        return UnitModel(id: id, isLeft: isLeft, type: type, xPosition: startX, maxHealth: 600, currentHealth: 600, damage: 60, attackRange: 5, attackCooldown: 1.5, movementSpeed: 1.8, cost: cost);
    }
  }

  // Hasar alma fonksiyonu
  void takeDamage(double damageAmount) {
    currentHealth -= damageAmount;
    if (currentHealth <= 0) state = UnitState.dead;
  }
}