class EquipmentInventory {
  final String id;
  final String title;
  final String hallId;
  final String? hallName;
  final int quantity;
  final String condition;

  const EquipmentInventory({
    required this.id,
    required this.title,
    required this.hallId,
    this.hallName,
    required this.quantity,
    required this.condition,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'hall': hallId,
    'quantity': quantity,
    'condition': condition,
  };

  factory EquipmentInventory.fromJson(Map<String, dynamic> json) {
    String? hName;
    if (json['expand'] is Map && json['expand']['hall'] is Map) {
      hName = json['expand']['hall']['name'] as String?;
    }

    return EquipmentInventory(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      hallId: json['hall'] as String? ?? '',
      hallName: hName,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      condition: json['condition'] as String? ?? 'GOOD',
    );
  }
}