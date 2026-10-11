class MembershipCard {
  final String id;
  final String cardNumber;
  final String clientId;
  final String? clientName;
  final String validUntil;
  final String status;
  final int balanceVisits;

  const MembershipCard({
    required this.id,
    required this.cardNumber,
    required this.clientId,
    this.clientName,
    required this.validUntil,
    required this.status,
    required this.balanceVisits,
  });

  bool get isActive => status == 'ACTIVE';

  Map<String, dynamic> toJson() => {
    'card_number': cardNumber,
    'client': clientId,
    'valid_until': validUntil,
    'status': status,
    'balance_visits': balanceVisits,
  };

  factory MembershipCard.fromJson(Map<String, dynamic> json) {
    String? cName;
    if (json['expand'] is Map && json['expand']['client'] is Map) {
      cName = json['expand']['client']['full_name'] as String?;
    }

    return MembershipCard(
      id: json['id'] as String? ?? '',
      cardNumber: json['card_number'] as String? ?? '',
      clientId: json['client'] as String? ?? '',
      clientName: cName,
      validUntil: json['valid_until'] as String? ?? '',
      status: json['status'] as String? ?? 'ACTIVE',
      balanceVisits: (json['balance_visits'] as num?)?.toInt() ?? 0,
    );
  }
}