class PurchaseItem {
  final String inventoryItemId;
  final String itemName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  PurchaseItem({
    required this.inventoryItemId,
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory PurchaseItem.fromJson(Map<String, dynamic> json) {
    return PurchaseItem(
      inventoryItemId: json['inventory_item_id'],
      itemName: json['item_name'],
      quantity: json['quantity'],
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
      totalPrice: (json['total_price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'inventory_item_id': inventoryItemId,
      'item_name': itemName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
    };
  }
}
