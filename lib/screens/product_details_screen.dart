import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/inventory_item.dart';
import 'package:flutter/foundation.dart';

import 'package:cached_network_image/cached_network_image.dart';

class ProductDetailsScreen extends StatelessWidget {
  final InventoryItem product;

  const ProductDetailsScreen({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        automaticallyImplyLeading: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editProduct(context),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareProduct(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(context),
            const SizedBox(height: 16),
            _buildPriceCard(context),
            const SizedBox(height: 16),
            _buildStockCard(context),
            const SizedBox(height: 16),
            _buildDetailsCard(context),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _updateStock(context),
        icon: const Icon(Icons.inventory),
        label: const Text('Update Stock'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(product.category),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: (product.productImage != null && product.productImage!.isNotEmpty)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: product.productImage!,
                            fit: BoxFit.cover,
                            width: 60,
                            height: 60,
                            placeholder: (context, url) => const CircularProgressIndicator(),
                            errorWidget: (context, url, error) => const Icon(
                              Icons.broken_image,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.inventory_2,
                          color: Colors.white,
                          size: 30,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // **FIX for Header Card Category Display:**
                      // Only display Text if category is not null and not empty.
                      // Provide a SizedBox for consistent spacing if category is absent.
                      if (product.category != null && product.category!.isNotEmpty)
                        Text(
                          product.category!, // Safe to use ! after null and empty check
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        )
                      else
                        const SizedBox(height: 14), // Approx height of category text to maintain layout
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profit = product.sellingPrice - product.buyingPrice;
    final profitMargin = product.sellingPrice > 0 ? (profit / product.sellingPrice) * 100 : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Price',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPriceItem(
                    'Buying Price',
                    product.buyingPrice,
                    Colors.red,
                    l10n.currency,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPriceItem(
                    'Selling Price',
                    product.sellingPrice,
                    Colors.green,
                    l10n.currency,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPriceItem(
                    'Profit per Unit',
                    profit,
                    Colors.blue,
                    l10n.currency,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profit Margin',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${profitMargin.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceItem(String label, double amount, Color color, String currency) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$currency ${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLowStock = product.currentStock <= product.minimumStock;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Stock',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (isLowStock)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Low Stock',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStockItem(
                    'Current Stock',
                    '${product.currentStock} ${product.unit}',
                    isLowStock ? Colors.red : Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStockItem(
                    'Minimum Stock',
                    '${product.minimumStock} ${product.unit}',
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: product.minimumStock > 0 ? product.currentStock / (product.minimumStock * 2) : 1.0,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                isLowStock ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Product Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Product Name', product.name),
            // **FIX for Details Card Category Row:**
            // Conditionally display the entire detail row for category
            if (product.category != null && product.category!.isNotEmpty)
              _buildDetailRow('Category', product.category!), // Safe to use !
            _buildDetailRow('Unit', product.unit),
            _buildDetailRow('Created', _formatDate(product.createdAt)),
            _buildDetailRow('Updated', _formatDate(product.updatedAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // Still handles nullable String for internal color logic
  Color _getCategoryColor(String? category) {
    if (category == null || category.isEmpty) {
      return Colors.grey;
    }
    switch (category.toLowerCase()) {
      case 'food':
      case 'chakula':
        return Colors.orange;
      case 'beverages':
      case 'vinywaji':
        return Colors.blue;
      case 'clothing':
      case 'nguo':
        return Colors.purple;
      case 'electronics':
      case 'elektroniki':
        return Colors.green;
      case 'home':
      case 'nyumbani':
        return Colors.brown;
      case 'health':
      case 'afya':
        return Colors.red;
      case 'sports':
      case 'michezo':
        return Colors.teal;
      case 'books':
      case 'vitabu':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _editProduct(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddProductScreen(product: product),
      ),
    );
  }

  void _shareProduct(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = '''
Product Name: ${product.name}
Category: ${product.category ?? ''} 
Buying Price: ${l10n.currency} ${product.buyingPrice}
Selling Price: ${l10n.currency} ${product.sellingPrice}
Current Stock: ${product.currentStock} ${product.unit}
''';

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share feature will be added soon')),
    );
  }

  void _updateStock(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Stock update feature will be added soon')),
    );
  }
}