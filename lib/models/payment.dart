class Payment {
  final String date;
  final String plan;
  final int amount;
  final bool verified;

  Payment({
    required this.date,
    required this.plan,
    required this.amount,
    required this.verified,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      date: (json['date'] ?? '').toString(),
      plan: (json['plan'] ?? '').toString(),
      amount: (json['amount'] is int) ? json['amount'] as int : int.tryParse('${json['amount']}') ?? 0,
      verified: json['verified'] == true,
    );
  }
}
