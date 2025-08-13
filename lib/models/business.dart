class Business {
  final String id;
  final String name;
  final String role;

  Business({required this.id, required this.name, required this.role});

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'].toString(),
      name: json['name'],
      role: json['pivot']?['role'] ?? 'owner',
    );
  }
} 