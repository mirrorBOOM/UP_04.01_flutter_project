class Client {
  final String id;
  final String fullName;
  final String email;
  final String phone;

  const Client({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
  });

  Map<String, dynamic> toJson() => {
    'full_name': fullName,
    'email': email,
    'phone': phone,
  };

  factory Client.fromJson(Map<String, dynamic> json) => Client(
    id: json['id'] as String? ?? '',
    fullName: json['full_name'] as String? ?? '',
    email: json['email'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
  );
}