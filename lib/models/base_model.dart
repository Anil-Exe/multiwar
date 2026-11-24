class BaseModel {
  double maxHealth;
  double currentHealth;
  final bool isLeft;

  BaseModel({
    required this.isLeft,
    this.maxHealth = 1000.0,
  }) : currentHealth = maxHealth;

  // Hasar alma fonksiyonu
  void takeDamage(double damage) {
    currentHealth -= damage;
    if (currentHealth < 0) currentHealth = 0;
  }

  bool get isDead => currentHealth <= 0;
}