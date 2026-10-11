class Workout {
  final String id;
  final String title;
  final String code;
  final int durationMinutes;
  final int caloriesBurned;
  final int intensity;
  final String hallId;
  final String? hallName;
  final String trainerId;
  final String? trainerName;
  final List<String> categoryIds;
  final List<String>? categoryNames;
  final int capacityTotal;
  final int capacityAvailable;
  final bool isDeleted;

  const Workout({
    required this.id,
    required this.title,
    required this.code,
    required this.durationMinutes,
    required this.caloriesBurned,
    required this.intensity,
    required this.hallId,
    this.hallName,
    required this.trainerId,
    this.trainerName,
    required this.categoryIds,
    this.categoryNames,
    required this.capacityTotal,
    required this.capacityAvailable,
    this.isDeleted = false,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'code': code,
    'duration_minutes': durationMinutes,
    'calories_burned': caloriesBurned,
    'intensity': intensity,
    'hall': hallId,
    'trainer': trainerId,
    'categories': categoryIds,
    'capacity_total': capacityTotal,
    'capacity_available': capacityAvailable,
    'is_deleted': isDeleted,
  };

  factory Workout.fromJson(Map<String, dynamic> json) {
    String? hName;
    String? tName;
    List<String>? catNames;

    if (json['expand'] is Map) {
      final expand = json['expand'] as Map;
      if (expand['hall'] is Map) hName = expand['hall']['name'] as String?;
      if (expand['trainer'] is Map) tName = expand['trainer']['full_name'] as String?;
      if (expand['categories'] is List) {
        catNames = (expand['categories'] as List)
            .whereType<Map>()
            .map((c) => c['name'] as String? ?? '')
            .toList();
      }
    }

    return Workout(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      code: json['code'] as String? ?? '',
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 0,
      caloriesBurned: (json['calories_burned'] as num?)?.toInt() ?? 0,
      intensity: (json['intensity'] as num?)?.toInt() ?? 1,
      hallId: json['hall'] as String? ?? '',
      hallName: hName,
      trainerId: json['trainer'] as String? ?? '',
      trainerName: tName,
      categoryIds: (json['categories'] as List?)?.cast<String>() ?? const [],
      categoryNames: catNames,
      capacityTotal: (json['capacity_total'] as num?)?.toInt() ?? 15,
      capacityAvailable: (json['capacity_available'] as num?)?.toInt() ?? 15,
      isDeleted: json['is_deleted'] as bool? ?? false,
    );
  }

  Workout copyWith({
    String? title,
    String? code,
    int? durationMinutes,
    int? caloriesBurned,
    int? intensity,
    String? hallId,
    String? trainerId,
    List<String>? categoryIds,
    int? capacityTotal,
    int? capacityAvailable,
    bool? isDeleted,
  }) {
    return Workout(
      id: id,
      title: title ?? this.title,
      code: code ?? this.code,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      intensity: intensity ?? this.intensity,
      hallId: hallId ?? this.hallId,
      trainerId: trainerId ?? this.trainerId,
      categoryIds: categoryIds ?? this.categoryIds,
      capacityTotal: capacityTotal ?? this.capacityTotal,
      capacityAvailable: capacityAvailable ?? this.capacityAvailable,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}