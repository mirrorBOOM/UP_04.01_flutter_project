class WorkoutCategory {
  final String id;
  final String name;
  final String description;

  const WorkoutCategory({
    required this.id,
    required this.name,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
  };

  factory WorkoutCategory.fromJson(Map<String, dynamic> json) => WorkoutCategory(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    description: json['description'] as String? ?? '',
  );
}