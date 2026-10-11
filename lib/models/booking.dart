class Booking {
  final String id;
  final String clientId;
  final String? clientName;
  final String workoutId;
  final String? workoutTitle;
  final String bookingDate;
  final String status;

  const Booking({
    required this.id,
    required this.clientId,
    this.clientName,
    required this.workoutId,
    this.workoutTitle,
    required this.bookingDate,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
    'client': clientId,
    'workout': workoutId,
    'booking_date': bookingDate,
    'status': status,
  };

  factory Booking.fromJson(Map<String, dynamic> json) {
    String? cName;
    String? wTitle;

    if (json['expand'] is Map) {
      final expand = json['expand'] as Map;
      if (expand['client'] is Map) cName = expand['client']['full_name'] as String?;
      if (expand['workout'] is Map) wTitle = expand['workout']['title'] as String?;
    }

    return Booking(
      id: json['id'] as String? ?? '',
      clientId: json['client'] as String? ?? '',
      clientName: cName,
      workoutId: json['workout'] as String? ?? '',
      workoutTitle: wTitle,
      bookingDate: json['booking_date'] as String? ?? '',
      status: json['status'] as String? ?? 'CONFIRMED',
    );
  }
}