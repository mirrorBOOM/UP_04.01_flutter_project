class GymHall {
  final String id;
  final String name;
  final int capacity;
  final int floor;

  const GymHall({
    required this.id,
    required this.name,
    required this.capacity,
    required this.floor,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'capacity': capacity,
    'floor': floor,
  };

  factory GymHall.fromJson(Map<String, dynamic> json) => GymHall(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    capacity: (json['capacity'] as num?)?.toInt() ?? 0,
    floor: (json['floor'] as num?)?.toInt() ?? 1,
  );
}