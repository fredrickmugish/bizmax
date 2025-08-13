import 'package:flutter/material.dart';
import '../models/business_record.dart';
import '../utils/currency_formatter.dart';
import '../utils/app_utils.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cached_network_image/cached_network_image.dart'; // Import CachedNetworkImage

class RecordListItem extends StatelessWidget {
  final BusinessRecord record;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const RecordListItem({
    Key? key,
    required this.record,
    this.onTap,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 700;
    final horizontalPadding = isWeb ? 24.0 : 10.0;
    final iconRadius = isWeb ? 20.0 : 16.0; // reduced
    final iconSize = isWeb ? 22.0 : 18.0;   // reduced
    final descriptionFontSize = isWeb ? 16.0 : 14.0; // slightly reduced
    final subtitleFontSize = isWeb ? 13.0 : 12.0;
    final amountFontSize = isWeb ? 14.0 : 12.0;
    final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
    String? imageUrl;
    if ((record.type == 'sale' || record.type == 'purchase') && record.inventoryItemId != null) {
      final product = inventoryProvider.getItemById(record.inventoryItemId!);
      if (product != null && product.productImage != null && product.productImage!.isNotEmpty) {
        imageUrl = product.productImage;
        // If running on web and imageUrl is a relative path, prepend backend URL
        if (kIsWeb && imageUrl != null && imageUrl.startsWith('/')) {
          imageUrl = 'https://fortex.co.tz' + imageUrl;
        }
      }
    }
    return Card(
      margin: EdgeInsets.symmetric(horizontal: isWeb ? 16 : 8, vertical: isWeb ? 6 : 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: isWeb ? 10 : 6), // reduced vertical padding
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (imageUrl != null)
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  imageBuilder: (context, imageProvider) => CircleAvatar(
                    radius: iconRadius,
                    backgroundImage: imageProvider,
                    backgroundColor: _getTypeColor().withOpacity(0.15),
                  ),
                  placeholder: (context, url) => CircleAvatar(
                    radius: iconRadius,
                    backgroundColor: _getTypeColor().withOpacity(0.15),
                    child: const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(strokeWidth: 2.0),
                    ),
                  ),
                  errorWidget: (context, url, error) => CircleAvatar(
                    radius: iconRadius,
                    backgroundColor: _getTypeColor().withOpacity(0.15),
                    child: Icon(
                      _getTypeIcon(),
                      color: _getTypeColor(),
                      size: iconSize,
                    ),
                  ),
                )
              else
                CircleAvatar(
                  radius: iconRadius,
                  backgroundColor: _getTypeColor().withOpacity(0.15),
                  child: Icon(
                    _getTypeIcon(),
                    color: _getTypeColor(),
                    size: iconSize,
                  ),
                ),
              SizedBox(width: isWeb ? 16 : 8),
              // Description and subtitle, vertically centered with icon
              Expanded(
                child: _getSubtitle().isEmpty
                    ? Text(
                        record.description,
                        style: TextStyle(
                          fontSize: descriptionFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                      )
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              record.description,
                              style: TextStyle(
                                fontSize: descriptionFontSize,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                            ),
                            SizedBox(height: isWeb ? 2 : 1),
                            Text(
                              _getSubtitle(),
                              style: TextStyle(
                                fontSize: subtitleFontSize,
                                color: Colors.grey,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
              ),
              SizedBox(width: isWeb ? 14 : 8),
              Text(
                CurrencyFormatter.format(record.amount),
                style: TextStyle(
                  fontSize: amountFontSize,
                  color: record.type == 'sale'
                      ? Colors.green[700]
                      : record.type == 'purchase'
                          ? Colors.blue[700]
                          : Colors.red[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: isWeb ? 10 : 6),
              Icon(Icons.arrow_forward_ios, size: isWeb ? 18 : 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor() {
    switch (record.type) {
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

  IconData _getTypeIcon() {
    switch (record.type) {
      case 'sale':
        return Icons.trending_up;
      case 'purchase':
        return Icons.shopping_cart;
      case 'expense':
        return Icons.trending_down;
      default:
        return Icons.receipt;
    }
  }

  String _getSubtitle() {
    String subtitle = '';
    if (record.quantity != null) {
      subtitle += 'Idadi: ${record.quantity}';
    }
    if (record.customerName != null) {
      if (subtitle.isNotEmpty) subtitle += ' • ';
      subtitle += 'Mteja: ${record.customerName}';
    } else if (record.supplierName != null) {
      if (subtitle.isNotEmpty) subtitle += ' • ';
      subtitle += 'Msambazaji: ${record.supplierName}';
    } else if (record.category != null) {
      if (subtitle.isNotEmpty) subtitle += ' • ';
      subtitle += 'Kategoria: ${record.category}';
    }
    return subtitle;
  }
}
