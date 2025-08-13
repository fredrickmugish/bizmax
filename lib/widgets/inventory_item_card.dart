import 'package:flutter/material.dart';
import '../models/inventory_item.dart';
import '../utils/currency_formatter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:cached_network_image/cached_network_image.dart';

class InventoryItemCard extends StatelessWidget {
  final InventoryItem product;
  final VoidCallback? onTap;

  const InventoryItemCard({
    Key? key,
    required this.product,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isLowStock = product.currentStock <= product.minimumStock;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center, // Keep row items vertically centered
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(product.category),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: (product.productImage != null && product.productImage!.isNotEmpty)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: (product.productImage != null && kIsWeb && product.productImage!.startsWith('/'))
                              ? 'https://fortex.co.tz' + product.productImage!
                              : (product.productImage ?? ''),
                            fit: BoxFit.cover,
                            width: 48,
                            height: 48,
                            placeholder: (context, url) => const CircularProgressIndicator(),
                            errorWidget: (context, url, error) => const Icon(
                              Icons.broken_image,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.inventory_2,
                          color: Colors.white,
                          size: 28,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column( // This outer Column now manages vertical space for all its children
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: product.category == null || product.category!.isEmpty
                        ? MainAxisAlignment.center // Center align if no category
                        : MainAxisAlignment.start, // Top align if category is present
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Conditional display for category
                      if (product.category != null && product.category!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0), // Small space after name if category is present
                          child: Text(
                            product.category!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      // Using Spacer to push quantity up/down, or SizedBox for specific spacing
                      product.category == null || product.category!.isEmpty
                          ? const SizedBox(height: 4) // Smaller gap if no category
                          : const SizedBox(height: 4), // Consistent gap if category is present
                      Text(
                        'Idadi: ${product.currentStock} ${product.fullUnitDescription}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isLowStock ? Colors.red : Colors.grey[700],
                          fontWeight: isLowStock ? FontWeight.bold : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (product.wholesalePrice != null)
                        Text('Jumla: @TSH ${product.wholesalePrice!.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 13, color: Colors.blue)),
                      if (product.retailPrice != null)
                        Text('Reja: @TSH ${product.retailPrice!.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 13, color: Colors.blue)),
                      if (product.wholesalePrice == null && product.retailPrice == null)
                        Text('Mauzo: @TSH ${product.sellingPrice.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 13, color: Colors.blue)),
                      const SizedBox(height: 6),
                      if (isLowStock)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Pungufu',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String? category) {
    if (category == null || category.isEmpty) {
      return Colors.grey;
    }
    switch (category.toLowerCase()) {
      case 'chakula':
      case 'food':
        return Colors.orange;
      case 'vinywaji':
      case 'beverages':
        return Colors.blue;
      case 'nguo':
      case 'clothing':
        return Colors.purple;
      case 'elektroniki':
      case 'electronics':
        return Colors.green;
      case 'nyumbani':
      case 'home':
        return Colors.brown;
      case 'afya':
      case 'health':
        return Colors.red;
      case 'michezo':
      case 'sports':
        return Colors.teal;
      case 'vitabu':
      case 'books':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  Widget _buildInfoItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}