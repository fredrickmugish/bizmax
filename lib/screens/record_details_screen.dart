import 'package:flutter/material.dart';
import '../models/business_record.dart';
import '../providers/business_provider.dart';
import '../services/receipt_service.dart';
import '../utils/currency_formatter.dart';
import '../utils/app_utils.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/records_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart'; // Import ApiService
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/database_service.dart'; // Import DatabaseService
import '../utils/app_routes.dart';
import 'package:flutter/foundation.dart';
import '../widgets/sidebar_scaffold.dart';

import 'package:cached_network_image/cached_network_image.dart';

class RecordDetailsScreen extends StatelessWidget {
  final BusinessRecord record;

  const RecordDetailsScreen({Key? key, required this.record}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final content = Scaffold(
      appBar: AppBar(
        title: const Text('Maelezo ya Rekodi'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.print, color: Colors.white),
            onPressed: () async {
              final authProvider = context.read<AuthProvider>();
              final businessProvider = context.read<BusinessProvider>();
              final apiService = ApiService();
              final databaseService = DatabaseService.instance; // Get instance of DatabaseService

              List<BusinessRecord> recordsToPrint = [];

              if (record.transactionId != null && record.transactionId!.isNotEmpty) {
                final connectivityResult = await Connectivity().checkConnectivity();

                if (connectivityResult != ConnectivityResult.none) {
                  // Online: Fetch from API
                  try {
                    final fetchedRecords = await apiService.getBusinessRecordsByTransactionId(record.transactionId!);
                    recordsToPrint = fetchedRecords.map((json) => BusinessRecord.fromJson(json)).toList();
                  } catch (e) {
                    // Fallback to local if API fails
                    print('Failed to fetch records from API, falling back to local: $e');
                    recordsToPrint = await databaseService.getBusinessRecordsByTransactionId(record.transactionId!); // Use local DB
                  }
                } else {
                  // Offline: Fetch from local DB
                  recordsToPrint = await databaseService.getBusinessRecordsByTransactionId(record.transactionId!); // Use local DB
                }
              } else {
                // If no transaction ID, just print this single record
                recordsToPrint = [record];
              }
              ReceiptService.generateAndPrintReceipt(recordsToPrint, authProvider, businessProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: () => _confirmDeleteRecord(context),
          ),
        ],
        automaticallyImplyLeading: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(context),
            const SizedBox(height: 16),
            _buildDetailsCard(context),
            if (record.isCredit) ...[
              const SizedBox(height: 16),
              _buildCreditDetailsCard(context),
            ],
            if (record.notes != null) ...[
              const SizedBox(height: 16),
              _buildNotesCard(context),
            ],
          ],
        ),
      ),
    );

    return content;
  }

  Widget _buildHeaderCard(BuildContext context) {
    final product = record.inventoryItemId != null
        ? Provider.of<InventoryProvider>(context, listen: false).getItemById(record.inventoryItemId!)
        : null;
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                (product != null && product.productImage != null && product.productImage!.isNotEmpty)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: (kIsWeb && product.productImage!.startsWith('/'))
                              ? 'https://fortex.co.tz' + product.productImage!
                              : product.productImage!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const CircularProgressIndicator(),
                          errorWidget: (context, url, error) => Container(
                            width: 56,
                            height: 56,
                            color: _getTypeColor().withOpacity(0.1),
                            child: Icon(_getTypeIcon(), color: _getTypeColor(), size: 32),
                          ),
                        ),
                      )
                    : Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getTypeColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getTypeIcon(),
                    color: _getTypeColor(),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTypeLabel(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        record.quantity != null
                          ? '${record.description} (${record.quantity})'
                          : record.description,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Amount display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getTypeColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getTypeColor().withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    record.isCredit ? 'Kilicholipwa' : 'Kiasi',
                    style: TextStyle(
                      fontSize: 14,
                      color: _getTypeColor(),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(record.amount),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _getTypeColor(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context) {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final isOwner = user != null ? user['role'] == 'owner' : false;

    String salespersonLabel = 'Muuzaji';
    if (record.type == 'purchase') {
      salespersonLabel = 'Mnunuzi';
    } else if (record.type == 'expense') {
      salespersonLabel = 'Mhusika';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Maelezo ya Jumla',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Tarehe', _formatDate(record.date)),
            _buildDetailRow('Aina ya Rekodi', _getTypeLabel()),
            if (record.type == 'sale' && record.saleType != null)
              _buildDetailRow('Aina ya Mauzo', _getSaleTypeLabel(record.saleType!)),
            if (record.type == 'sale' && record.quantity != null && record.quantity! > 0)
              _buildDetailRow(
                'Bei ya Bidhaa',
                '${CurrencyFormatter.format(record.amount / record.quantity!)} @ 1',
              ),
            if (record.category != null)
              _buildDetailRow('Kategoria', record.category!),
            if (record.customerName != null)
              _buildDetailRow('Mteja', record.customerName!),
            if (record.supplierName != null)
              _buildDetailRow('Msambazaji', record.supplierName!),
            // NEW: Funding Source for Purchases
            if (record.type == 'purchase' && record.fundingSource != null)
              _buildDetailRow('Chanzo cha fedha', _getFundingSourceLabel(record.fundingSource!)),
            // Show salesperson info only for owners
            if (isOwner && record.user != null)
              _buildDetailRow(salespersonLabel, record.salespersonName),
            _buildDetailRow('Imeongezwa', AppUtils.formatDateTimeEastAfrica(record.createdAt)),
            if (record.updatedAt != record.createdAt)
              _buildDetailRow('Imesasishwa', AppUtils.formatDateTimeEastAfrica(record.updatedAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditDetailsCard(BuildContext context) {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.credit_card, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Text(
                  'Maelezo ya Mkopo',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Payment status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getPaymentStatusColor(),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                record.paymentStatus ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Payment breakdown
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                children: [
                  _buildPaymentRow(
                    'Jumla ya Mauzo:',
                    CurrencyFormatter.format(record.saleTotal),
                    Colors.black,
                  ),
                  const SizedBox(height: 8),
                  _buildPaymentRow(
                    'Kilicholipwa:',
                    CurrencyFormatter.format(record.paidAmount),
                    Colors.green,
                  ),
                  const Divider(),
                  _buildPaymentRow(
                    'Deni Lililobaki:',
                    CurrencyFormatter.format(record.remainingDebt),
                    record.remainingDebt > 0 ? Colors.red : Colors.green,
                    isDebt: true,
                  ),
                ],
              ),
            ),
            
            // Payment progress
            if (record.saleTotal > 0) ...[
              const SizedBox(height: 16),
              Text(
                'Maendeleo ya Malipo',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: record.paidAmount / record.saleTotal,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  record.remainingDebt <= 0 ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${((record.paidAmount / record.saleTotal) * 100).toStringAsFixed(1)}% yamelipwa',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRow(String label, String amount, Color color, {bool isDebt = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isDebt ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isDebt ? 16 : 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildNotesCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Maelezo ya Ziada',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              record.notes!,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon() {
    switch (record.type) {
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

  Color _getPaymentStatusColor() {
    if (record.remainingDebt <= 0) return Colors.green;
    if (record.paidAmount > 0) return Colors.orange;
    return Colors.red;
  }

  String _getTypeLabel() {
    switch (record.type) {
      case 'sale':
        return record.isCredit ? 'Mauzo ya Mkopo' : 'Mauzo ya Fedha Taslimu';
      case 'purchase':
        return 'Manunuzi';
      case 'expense':
        return 'Matumizi';
      default:
        return 'Rekodi';
    }
  }

  String _getSaleTypeLabel(String saleType) {
    switch (saleType) {
      case 'wholesale':
        return 'Mauzo ya Jumla';
      case 'retail':
        return 'Mauzo ya Rejareja';
      case 'discount':
        return 'Mauzo ya Punguzo';
      default:
        return saleType;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getFundingSourceLabel(String fundingSource) {
    switch (fundingSource) {
      case 'revenue':
        return 'Mauzo ya biashara'; // Business Sales
      case 'personal':
        return 'Fedha ya binafsi'; // Personal Funds
      default:
        return fundingSource;
    }
  }

  void _confirmDeleteRecord(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Futa Rekodi'),
        content: Text('Je, una uhakika unataka kufuta rekodi ya "${record.description}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ghairi'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await context.read<RecordsProvider>().deleteRecord(record.id);
                if (Navigator.canPop(context)) {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close details screen
                }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
                    content: Text('Rekodi imefutwa!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Hitilafu: ${e.toString()}'),
                    backgroundColor: Colors.red,
      ),
    );
  }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Futa'),
          ),
        ],
      ),
    );
  }
}
