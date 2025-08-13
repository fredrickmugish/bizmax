import 'package:hive/hive.dart';

part 'inventory_item.g.dart';

@HiveType(typeId: 2)
class InventoryItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final String? category;

  @HiveField(4)
  final String unit;

  @HiveField(5)
  final double buyingPrice;

  @HiveField(6)
  final double? wholesalePrice;

  @HiveField(7)
  final double? retailPrice;

  @HiveField(8)
  final double sellingPrice;

  @HiveField(9)
  final String? unitDimensions;

  @HiveField(10)
  final double unitQuantity;

  @HiveField(11)
  final int currentStock;

  @HiveField(12)
  final int minimumStock;

  @HiveField(13)
  final bool isActive;

  @HiveField(14)
  final DateTime createdAt;

  @HiveField(15)
  final DateTime updatedAt;

  @HiveField(16)
  final String? productImage;

  @HiveField(17)
  final bool isDirty;

  @HiveField(18)
  final bool? isDeleted;

  // Computed properties
  int get quantity => currentStock;
  int get minStockLevel => minimumStock;

  InventoryItem({
    required this.id,
    required this.name,
    this.description,
    this.category,
    required this.unit,
    required this.buyingPrice,
    this.wholesalePrice,
    this.retailPrice,
    required this.sellingPrice,
    this.unitDimensions,
    this.unitQuantity = 1.0,
    required this.currentStock,
    required this.minimumStock,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.productImage,
    this.isDirty = false,
    this.isDeleted = false,
  });

  // Helper getters for pricing
  double get effectiveWholesalePrice => wholesalePrice ?? sellingPrice;
  double get effectiveRetailPrice => retailPrice ?? sellingPrice;

  // Helper getters for unit display
  String get formattedUnit {
    // Ensure unitDimensions and unit are not null when concatenating
    return unitDimensions != null && unitDimensions!.isNotEmpty
        ? unitDimensions!
        : (unit.isNotEmpty ? unit : 'N/A Unit'); // Fallback if both are empty
  }

  String get fullUnitDescription {
    if (unitQuantity > 1) {
      return "$unitQuantity $formattedUnit";
    }
    return formattedUnit;
  }

  // Helper getters for profit margins
  double get wholesaleProfitMargin {
    if (effectiveWholesalePrice <= 0 || buyingPrice <= 0) return 0;
    return ((effectiveWholesalePrice - buyingPrice) / effectiveWholesalePrice) * 100;
  }

  double get retailProfitMargin {
    if (effectiveRetailPrice <= 0 || buyingPrice <= 0) return 0;
    return ((effectiveRetailPrice - buyingPrice) / effectiveRetailPrice) * 100;
  }

  InventoryItem copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? unit,
    double? buyingPrice,
    double? wholesalePrice,
    double? retailPrice,
    double? sellingPrice,
    String? unitDimensions,
    double? unitQuantity,
    int? currentStock,
    int? minimumStock,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? productImage,
    bool? isDirty,
    bool? isDeleted,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      buyingPrice: buyingPrice ?? this.buyingPrice,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      retailPrice: retailPrice ?? this.retailPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      unitDimensions: unitDimensions ?? this.unitDimensions,
      unitQuantity: unitQuantity ?? this.unitQuantity,
      currentStock: currentStock ?? this.currentStock,
      minimumStock: minimumStock ?? this.minimumStock,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      productImage: productImage ?? this.productImage,
      isDirty: isDirty ?? this.isDirty,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'unit': unit,
      'buying_price': buyingPrice,
      'wholesale_price': wholesalePrice,
      'retail_price': retailPrice,
      'selling_price': sellingPrice,
      'unit_dimensions': unitDimensions,
      'unit_quantity': unitQuantity,
      'current_stock': currentStock,
      'minimum_stock': minimumStock,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'product_image': productImage,
      'is_dirty': isDirty,
      'is_deleted': isDeleted,
    };
  }

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse DateTime
    DateTime _parseDateTime(dynamic value) {
      try {
        if (value is String && value.isNotEmpty) {
          return DateTime.parse(value);
        }
      } catch (e) {
        // Log the error for debugging purposes
        // ignore: avoid_print
        print('Error parsing DateTime: $value. Using DateTime.now() fallback. Error: $e');
      }
      return DateTime.now(); // Fallback to current time if parsing fails or value is null/empty
    }

    // Try multiple possible field names for the image
    String? imageUrl = json['product_image'] ?? json['image'] ?? json['image_url'];
    // If the image is a relative path, prepend the base URL
    if (imageUrl != null && !imageUrl.startsWith('http')) {
      if (imageUrl.startsWith('/')) {
        imageUrl = 'https://fortex.co.tz' + imageUrl;
      } else {
        imageUrl = 'https://fortex.co.tz/storage/' + imageUrl;
      }
    }

    return InventoryItem(
      id: json['id']?.toString() ?? '', // Ensure ID is never null
      name: json['name']?.toString() ?? '', // Ensure name is never null
      description: json['description']?.toString(), // Ensure description is String?
      category: json['category']?.toString(), // Ensure category is String?
      unit: json['unit']?.toString() ?? '', // Ensure unit is never null
      buyingPrice: double.tryParse(json['buying_price']?.toString() ?? '0') ?? 0.0,
      wholesalePrice: double.tryParse(json['wholesale_price']?.toString() ?? ''), // nullable
      retailPrice: double.tryParse(json['retail_price']?.toString() ?? ''), // nullable
      sellingPrice: double.tryParse(json['selling_price']?.toString() ?? '0') ?? 0.0,
      unitDimensions: json['unit_dimensions']?.toString(), // Ensure unitDimensions is String?
      unitQuantity: double.tryParse(json['unit_quantity']?.toString() ?? '1.0') ?? 1.0,
      currentStock: int.tryParse(json['current_stock']?.toString() ?? '0') ?? 0,
      minimumStock: int.tryParse(json['minimum_stock']?.toString() ?? '0') ?? 0,
      isActive: json['is_active'] as bool? ?? true, // Safely cast to bool, default to true
      createdAt: _parseDateTime(json['created_at']), // Using the safe parser
      updatedAt: _parseDateTime(json['updated_at']), // Using the safe parser
      productImage: imageUrl,
      isDirty: json['is_dirty'] as bool? ?? false,
      isDeleted: json['is_deleted'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'InventoryItem(id: $id, name: $name, category: $category, currentStock: $currentStock, wholesalePrice: $wholesalePrice, retailPrice: $retailPrice, unitDimensions: $unitDimensions, isDeleted: $isDeleted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InventoryItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
