import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/business_provider.dart';
import '../providers/inventory_provider.dart';
import '../utils/currency_formatter.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb

class BusinessMetricsCards extends StatelessWidget {
  const BusinessMetricsCards({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<BusinessProvider, InventoryProvider>(
      builder: (context, businessProvider, inventoryProvider, child) {
        // Calculate low stock items from inventory provider for consistency
        final lowStockItems = inventoryProvider.items
            .where((item) => item.quantity <= item.minStockLevel)
            .length;
            
        if (kIsWeb) {
          final isSmallWeb = MediaQuery.of(context).size.width < 840;
          if (isSmallWeb) {
            // Stack cards vertically, full width, center content
            return _buildMobileLayout(context, businessProvider, lowStockItems);
          }
          return _buildWebLayout(context, businessProvider, inventoryProvider, lowStockItems);
        } else {
          return _buildMobileLayout(context, businessProvider, lowStockItems);
        }
      },
    );
  }

  Widget _buildWebLayout(BuildContext context, BusinessProvider businessProvider, InventoryProvider inventoryProvider, int lowStockItems) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: _buildMetricCard(
              context,
              'Mauzo ya Leo',
              CurrencyFormatter.format(businessProvider.todayRevenue),
              Icons.account_balance_wallet,
              Colors.green,
              businessProvider.todayRevenue == 0 ? 'Hakuna mauzo ya leo' : null,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: _buildMetricCard(
              context,
              'Matumizi ya Leo',
              CurrencyFormatter.format(businessProvider.todayExpenses),
              Icons.receipt_long,
              Colors.red,
              businessProvider.todayExpenses == 0 ? 'Hakuna matumizi ya leo' : null,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: _buildMetricCard(
              context,
              'Faida ya Leo',
              CurrencyFormatter.format(businessProvider.metrics.todayGrossProfit),
              Icons.trending_up,
              businessProvider.metrics.todayGrossProfit >= 0 ? Colors.green : Colors.red,
              businessProvider.metrics.todayGrossProfit == 0 ? 'Hakuna faida ya leo' : null,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: _buildMetricCard(
              context,
              'Bidhaa Pungufu',
              '$lowStockItems',
              Icons.inventory_2,
              lowStockItems > 0 ? Colors.orange : Colors.green,
              lowStockItems == 0 ? 'Hifadhi ni nzuri' : 'Ongeza hifadhi',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, BusinessProvider businessProvider, int lowStockItems) {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  context,
                  'Mauzo ya Leo',
                  CurrencyFormatter.format(businessProvider.todayRevenue),
                  Icons.account_balance_wallet,
                  Colors.green,
                  businessProvider.todayRevenue == 0 ? 'Hakuna mauzo ya leo' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  context,
                  'Matumizi ya Leo',
                  CurrencyFormatter.format(businessProvider.todayExpenses),
                  Icons.receipt_long,
                  Colors.red,
                  businessProvider.todayExpenses == 0 ? 'Hakuna matumizi ya leo' : null,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  context,
                  'Faida ya Leo',
                  CurrencyFormatter.format(businessProvider.metrics.todayGrossProfit),
                  Icons.trending_up,
                  businessProvider.metrics.todayGrossProfit >= 0 ? Colors.green : Colors.red,
                  businessProvider.metrics.todayGrossProfit == 0 ? 'Hakuna faida ya leo' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  context,
                  'Bidhaa Pungufu',
                  '$lowStockItems',
                  Icons.inventory_2,
                  lowStockItems > 0 ? Colors.orange : Colors.green,
                  lowStockItems == 0 ? 'Hifadhi ni nzuri' : 'Ongeza hifadhi',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    String? emptyMessage,
    {bool center = false}
  ) {
    return kIsWeb
        ? _buildWebMetricCard(context, title, value, icon, color, emptyMessage, center: center)
        : _buildMobileMetricCard(context, title, value, icon, color, emptyMessage);
  }

  Widget _buildWebMetricCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    String? emptyMessage,
    {bool center = false}
  ) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Add subtle feedback
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: center ? MainAxisAlignment.center : MainAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    if (!center) const Spacer(),
                    if (emptyMessage != null)
                      Icon(
                        Icons.info_outline,
                        color: Colors.grey[400],
                        size: 18,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    textAlign: center ? TextAlign.center : TextAlign.left,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: center ? TextAlign.center : TextAlign.left,
                  ),
                ),
                if (emptyMessage != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    emptyMessage,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: center ? TextAlign.center : TextAlign.left,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileMetricCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    String? emptyMessage,
  ) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                if (emptyMessage != null)
                  Icon(
                    Icons.info_outline,
                    color: Colors.grey[400],
                    size: 16,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (emptyMessage != null) ...[
              const SizedBox(height: 4),
              Text(
                emptyMessage,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
