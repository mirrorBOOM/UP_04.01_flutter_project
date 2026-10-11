class Trainer {
  final String id;
  final String fullName;
  final String specialization;
  final int experienceYears;
  final String category;
  final int hourlyRate;

  const Trainer({
    required this.id,
    required this.fullName,
    required this.specialization,
    required this.experienceYears,
    required this.category,
    required this.hourlyRate,
  });

  Map<String, dynamic> toJson() => {
    'full_name': fullName,
    'specialization': specialization,
    'experience_years': experienceYears,
    'category': category,
    'hourly_rate': hourlyRate,
  };

  factory Trainer.fromJson(Map<String, dynamic> json) => Trainer(
    id: json['id'] as String? ?? '',
    fullName: json['full_name'] as String? ?? '',
    specialization: json['specialization'] as String? ?? '',
    experienceYears: (json['experience_years'] as num?)?.toInt() ?? 0,
    category: json['category'] as String? ?? 'PRO',
    hourlyRate: (json['hourly_rate'] as num?)?.toInt() ?? 1500,
  );
}