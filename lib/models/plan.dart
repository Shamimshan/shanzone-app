class Plan {
  final String key; // 'lite' | 'pro' | 'boost'
  final String nameKey; // localization key
  final String speed;
  final int amount;

  const Plan({
    required this.key,
    required this.nameKey,
    required this.speed,
    required this.amount,
  });

  static const List<Plan> all = [
    Plan(key: 'lite', nameKey: 'lite', speed: '30 Mbps', amount: 599),
    Plan(key: 'pro', nameKey: 'pro', speed: '50 Mbps', amount: 799),
    Plan(key: 'boost', nameKey: 'boost', speed: '100 Mbps', amount: 1150),
  ];

  static Plan byKey(String key) =>
      all.firstWhere((p) => p.key == key, orElse: () => all.first);
}
