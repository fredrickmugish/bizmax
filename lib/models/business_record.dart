// lib/models/business_record.dart

import 'package:hive/hive.dart';
import 'package:flutter/material.dart'; // Keep for completeness if needed elsewhere

part 'business_record.g.dart';

@HiveType(typeId: 1)
class BusinessRecord extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String type; // 'sale', 'purchase', 'expense'
  @HiveField(2)
  final String description;
  @HiveField(3)
  final double amount; // For sales: this is the paid amount (income) or transaction value.
                       // For profit calculation, when type is 'sale', this represents the selling price per unit *if quantity is > 1*.
                       // If quantity is 1, it's the total selling price.
  @HiveField(4)
  final DateTime date;
  @HiveField(5)
  final String? category;
  @HiveField(6)
  final String? notes;
  @HiveField(7)
  final String? customerName;
  @HiveField(8)
  final String? supplierName;
  @HiveField(9)
  final String? inventoryItemId;
  @HiveField(10)
  final int? quantity; // Already present, representing the number of units

  // --- START OF MODIFICATION: ADDING costOfGoodsSold ---
  @HiveField(11)
  final double? costOfGoodsSold; // The buying price/cost for 'sale' records (per unit if quantity > 1)
  // --- END OF MODIFICATION ---

  // --- START OF MODIFICATION: ADDING fundingSource ---
  @HiveField(12)
  final String? fundingSource; // 'revenue' or 'personal' for purchases
  // --- END OF MODIFICATION ---

  @HiveField(13)
  final double unitPrice; // Add this field

  @HiveField(14)
  final DateTime createdAt;
  @HiveField(15)
  final DateTime updatedAt;

  // Credit management fields
  @HiveField(16)
  final bool isCreditSale;
  @HiveField(17)
  final double? totalAmount; // Total sale amount for credit sales (full selling price)
  @HiveField(18)
  final double? amountPaid; // Amount actually paid for credit sales
  @HiveField(19)
  final double? debtAmount; // Remaining debt for credit sales

  // User information (salesperson who created the record)
  @HiveField(20)
  final Map<String, dynamic>? user;

  @HiveField(21)
  final bool isDirty;

  @HiveField(22)
  final String? saleType; // 'wholesale', 'retail', or 'discount'

  @HiveField(23)
  final String? transactionId; // New field for grouping sales

  @HiveField(24) // New field for soft delete
  final bool? isDeleted;

  BusinessRecord({
    required this.id,
    required this.type,
    required this.description,
    required this.amount,
    required this.date,
    this.category,
    this.notes,
    this.customerName,
    this.supplierName,
    this.inventoryItemId,
    this.quantity,
    this.costOfGoodsSold,
    this.fundingSource,
    required this.unitPrice, // Add this to constructor
    required this.createdAt,
    required this.updatedAt,
    required this.isCreditSale,
    this.totalAmount,
    this.amountPaid,
    this.debtAmount,
    this.user,
    this.isDirty = false,
    this.saleType,
    this.transactionId,
    this.isDeleted = false, // Default to false
  });

  // Helper getters for credit management
  bool get isCredit => isCreditSale == true;
  bool get hasDebt => (debtAmount ?? 0) > 0;
  bool get isPaidInFull => !hasDebt;
  double get remainingDebt => debtAmount ?? 0;
  double get paidAmount => amountPaid ?? amount;
  double get saleTotal => totalAmount ?? amount; // This is the total revenue for the sale record

  // Payment status
  String get paymentStatus {
    if (type == 'sale') {
      if (!isCredit) return 'Fedha Taslimu';
      if (isPaidInFull) return 'Amelipa Kamili';
      if (paidAmount > 0) return 'Amelipa Sehemu';
      return 'Hajalipa';
    } else if (type == 'purchase') {
      if (!isCredit) return 'Fedha Taslimu';
      if (isPaidInFull) return 'Umeshalipa';
      if (paidAmount > 0) return 'Sehemu';
      return 'Hujalipa';
    }
    return 'N/A';
  }

  // --- START OF MODIFICATION: ADDING FUNDING SOURCE GETTERS ---
  bool get isRevenueFunded => fundingSource == 'revenue';
  bool get isPersonalFunded => fundingSource == 'personal';
  String get fundingSourceLabel {
    switch (fundingSource) {
      case 'revenue':
        return 'Mauzo ya Biashara';
      case 'personal':
        return 'Fedha ya Kibinafsi';
      default:
        return 'N/A';
    }
  }
  // --- END OF MODIFICATION ---

  // Salesperson information
  String get salespersonName => user?['name']?.toString() ?? 'Mtu Asiyejulikana'; // Added .toString() for robustness
  String get salespersonEmail => user?['email']?.toString() ?? ''; // Added .toString() for robustness

  BusinessRecord copyWith({
    String? id,
    String? type,
    String? description,
    double? amount,
    DateTime? date,
    String? category,
    String? notes,
    String? customerName,
    String? supplierName,
    String? inventoryItemId,
    int? quantity,
    double? costOfGoodsSold,
    String? fundingSource,
    double? unitPrice,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isCreditSale,
    double? totalAmount,
    double? amountPaid,
    double? debtAmount,
    Map<String, dynamic>? user,
    bool? isDirty,
    String? saleType,
    String? transactionId,
    bool? isDeleted,
  }) {
    return BusinessRecord(
      id: id ?? this.id,
      type: type ?? this.type,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      customerName: customerName ?? this.customerName,
      supplierName: supplierName ?? this.supplierName,
      inventoryItemId: inventoryItemId ?? this.inventoryItemId,
      quantity: quantity ?? this.quantity,
      costOfGoodsSold: costOfGoodsSold ?? this.costOfGoodsSold,
      fundingSource: fundingSource ?? this.fundingSource,
      unitPrice: unitPrice ?? this.unitPrice,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isCreditSale: isCreditSale ?? this.isCreditSale,
      totalAmount: totalAmount ?? this.totalAmount,
      amountPaid: amountPaid ?? this.amountPaid,
      debtAmount: debtAmount ?? this.debtAmount,
      user: user ?? this.user,
      isDirty: isDirty ?? this.isDirty,
      saleType: saleType ?? this.saleType,
      transactionId: transactionId ?? this.transactionId,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
      'notes': notes,
      'customer_name': customerName,
      'supplier_name': supplierName,
      'product_id': inventoryItemId,
      'quantity': quantity,
      'cost_of_goods_sold': costOfGoodsSold,
      'funding_source': fundingSource,
      'unit_price': unitPrice,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_credit_sale': isCreditSale,
      'total_amount': totalAmount,
      'amount_paid': amountPaid,
      'debt_amount': debtAmount,
      'user': user,
      'is_dirty': isDirty,
      'sale_type': saleType,
      'transaction_id': transactionId,
      'is_deleted': isDeleted,
    };
  }

  factory BusinessRecord.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse UTC dates and convert to local time
    DateTime _parseAndConvertToLocal(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty || dateStr == 'null') {
        return DateTime.now(); // Fallback for missing date
      }
      try {
        return DateTime.parse(dateStr).toLocal();
      } catch (e) {
        // Log the error for debugging purposes
        // ignore: avoid_print
        print('Error parsing DateTime for BusinessRecord: $dateStr. Using DateTime.now() fallback. Error: $e');
        return DateTime.now();
      }
    }

    // Helper function for safe string parsing
    String? _parseNullableString(dynamic value) {
      if (value == null) return null;
      final str = value.toString();
      if (str.isEmpty || str == 'null') return null;
      return str;
    }

    // Helper function for safe non-null string parsing
    String _parseString(dynamic value, [String defaultValue = '']) {
      if (value == null) return defaultValue;
      final str = value.toString();
      if (str == 'null') return defaultValue;
      return str;
    }

    return BusinessRecord(
      id: _parseString(json['id']),
      type: _parseString(json['type'], '').toLowerCase(),
      description: _parseString(json['description']),
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      date: _parseAndConvertToLocal(json['date']?.toString()),
      category: _parseNullableString(json['category']),
      notes: _parseNullableString(json['notes']),
      customerName: _parseNullableString(json['customer_name']),
      supplierName: _parseNullableString(json['supplier_name']),
      inventoryItemId: _parseNullableString(json['product_id']),
      quantity: int.tryParse(json['quantity']?.toString() ?? ''),
      costOfGoodsSold: double.tryParse(json['cost_of_goods_sold']?.toString() ?? ''),
      fundingSource: _parseNullableString(json['funding_source']),
      unitPrice: double.tryParse(json['unit_price']?.toString() ?? '0') ?? 0.0,
      createdAt: _parseAndConvertToLocal(json['created_at']?.toString()),
      updatedAt: _parseAndConvertToLocal(json['updated_at']?.toString()),
      isCreditSale: json['is_credit_sale'] == true || json['is_credit_sale'] == 1,
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? ''),
      amountPaid: double.tryParse(json['amount_paid']?.toString() ?? ''),
      debtAmount: double.tryParse(json['debt_amount']?.toString() ?? ''),
      user: json['user'] is Map<String, dynamic> ? json['user'] : null,
      isDirty: json['is_dirty'] as bool? ?? false,
      saleType: _parseNullableString(json['sale_type']),
      transactionId: _parseNullableString(json['transaction_id']),
      isDeleted: json['is_deleted'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'BusinessRecord(id: $id, type: $type, description: $description, amount: $amount, costOfGoodsSold: $costOfGoodsSold, fundingSource: $fundingSource, quantity: $quantity, customerName: $customerName, paymentStatus: $paymentStatus, saleType: $saleType, isDeleted: $isDeleted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BusinessRecord && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
