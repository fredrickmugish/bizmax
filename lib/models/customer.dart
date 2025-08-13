import 'package:hive/hive.dart';

part 'customer.g.dart';

@HiveType(typeId: 3)
class Customer extends HiveObject {
  @HiveField(0)
  final String? id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String phone;

  @HiveField(3)
  final bool isDirty;

  @HiveField(4)
  final bool isDeleted;

  Customer({
    this.id,
    required this.name,
    required this.phone,
    this.isDirty = false,
    this.isDeleted = false,
  });

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        id: json['id']?.toString(),
        name: json['name'],
        phone: json['phone'] ?? '',
        isDirty: false,
        isDeleted: false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'is_dirty': isDirty,
        'is_deleted': isDeleted,
      };

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    bool? isDirty,
    bool? isDeleted,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      isDirty: isDirty ?? this.isDirty,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
} 