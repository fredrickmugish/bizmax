import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/records_provider.dart';
import '../utils/currency_formatter.dart';
import '../providers/auth_provider.dart';

class RecordsSummaryCard extends StatelessWidget {
  final bool showPurchases;
  final bool showExpenses;
  final List records;
  const RecordsSummaryCard({Key? key, this.showPurchases = true, this.showExpenses = true, required this.records}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final role = user != null ? user['role'] : null;
    final isOwner = role == 'owner';
    double totalSales = 0;
    double totalPurchases = 0;
    double totalExpenses = 0;
    for (final record in records) {
      if (record.type == 'sale') {
        totalSales += record.amount;
      } else if (record.type == 'purchase') {
        totalPurchases += record.amount;
      } else if (record.type == 'expense') {
        totalExpenses += record.amount;
      }
    }
    final onlyMauzo = !showPurchases && !showExpenses;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              'Mauzo',
              CurrencyFormatter.format(totalSales),
              Icons.trending_up,
              Colors.green,
              onlyMauzo: onlyMauzo,
            ),
          ),
          if (showPurchases) ...[
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryItem(
                'Manunuzi',
                CurrencyFormatter.format(totalPurchases),
                Icons.shopping_cart,
                Colors.blue,
              ),
            ),
          ],
          if (showExpenses) ...[
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryItem(
                'Matumizi',
                CurrencyFormatter.format(totalExpenses),
                Icons.trending_down,
                Colors.red,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon, Color color, {bool onlyMauzo = false}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: onlyMauzo ? 30 : 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: onlyMauzo ? 18 : 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: onlyMauzo ? 14 : 12,
                color: Colors.grey,
                fontWeight: onlyMauzo ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
