/// Represents one customer connection (a mobile number can have several —
/// e.g. home + shop — each with its own User ID / plan / expiry).
class Account {
  final String userId;
  final String name;
  final String nameHi;
  final String mobile;
  final String plan; // 'lite' | 'pro' | 'boost'
  final String expiry; // yyyy-MM-dd
  final String address;
  final String addressHi;

  Account({
    required this.userId,
    required this.name,
    required this.nameHi,
    required this.mobile,
    required this.plan,
    required this.expiry,
    required this.address,
    required this.addressHi,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      userId: (json['userId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      nameHi: (json['nameHi'] ?? '').toString(),
      mobile: (json['mobile'] ?? '').toString(),
      plan: (json['plan'] ?? '').toString().toLowerCase(),
      expiry: (json['expiry'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      addressHi: (json['addressHi'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'name': name,
        'nameHi': nameHi,
        'mobile': mobile,
        'plan': plan,
        'expiry': expiry,
        'address': address,
        'addressHi': addressHi,
      };

  DateTime? get expiryDate {
    try {
      return DateTime.parse(expiry);
    } catch (_) {
      return null;
    }
  }

  /// Days remaining until expiry (negative if already expired).
  int get daysLeft {
    final d = expiryDate;
    if (d == null) return 0;
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    return d.difference(todayOnly).inDays;
  }
}
