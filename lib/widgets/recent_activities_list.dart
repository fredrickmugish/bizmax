import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/records_provider.dart';
import '../providers/inventory_provider.dart';
import '../utils/currency_formatter.dart';
import '../utils/app_routes.dart';

class RecentActivitiesList extends StatelessWidget {
  const RecentActivitiesList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<RecordsProvider, InventoryProvider>(
      builder: (context, recordsProvider, inventoryProvider, child) {
        final recentRecords = recordsProvider.allRecords.take(5).toList();

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 400) {
                      // Stack vertically for very small screens
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Shughuli za Hivi Karibuni',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, AppRoutes.records);
                              },
                              child: const Text('Ona Zote'),
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Row for normal/large screens
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Shughuli za Hivi Karibuni',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, AppRoutes.records);
                            },
                            child: const Text('Ona Zote'),
                          ),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                if (recentRecords.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Hakuna shughuli za hivi karibuni',
                            style: TextStyle(color: Colors.grey),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Ongeza rekodi ya kwanza yako',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...recentRecords.map((record) {
                    String? imageUrl;
                    if (record.inventoryItemId != null) {
                      final product = inventoryProvider.getItemById(record.inventoryItemId!);
                      if (product != null && product.productImage != null && product.productImage!.isNotEmpty) {
                        imageUrl = product.productImage;
                      }
                    }
                    return _buildActivityItem(
                    record.description,
                    CurrencyFormatter.format(record.amount),
                      _formatTimeAgo(record.createdAt),
                    _getTypeIcon(record.type),
                    _getTypeColor(record.type),
                      imageUrl: imageUrl,
                    );
                  }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityItem(
    String title,
    String amount,
    String time,
    IconData icon,
    Color color, {
    String? imageUrl,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty)
            CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(imageUrl),
              backgroundColor: color.withOpacity(0.1),
            )
          else
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'sale':
        return Icons.point_of_sale;
      case 'purchase':
        return Icons.shopping_cart;
      case 'expense':
        return Icons.money_off;
      default:
        return Icons.receipt;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'sale':
        return Colors.green;
      case 'purchase':
        return Colors.blue;
      case 'expense':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final localDate = date.toLocal();
    final difference = now.difference(localDate);

    if (difference.inDays > 0) {
      return '${difference.inDays} siku zilizopita';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} masaa zilizopita';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika zilizopita';
    } else {
      return 'Sasa hivi';
    }
  }
}
