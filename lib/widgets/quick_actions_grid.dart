import 'package:flutter/material.dart';
import '../utils/app_routes.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import '../screens/main_navigation_screen.dart';


class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({Key? key}) : super(key: key);

  Future<void> _navigateToAddSale(BuildContext context) async {
    final provider = context.read<InventoryProvider>();
    if (provider.items.isEmpty) {
      await provider.loadInventory();
    }
    Navigator.pushNamed(context, AppRoutes.addSale);
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _buildWebLayout(context);
    } else {
      return _buildMobileLayout(context);
    }
  }

  Widget _buildWebLayout(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmallWeb = width < 700;
    final isMediumWeb = width >= 700 && width < 1000;
    int crossAxisCount = 4;
    double aspectRatio = 1.1;
    double cardHeight = 170;
    double iconSize = 32;
    double textSize = 16;
    double cardPadding = 20;
    if (isSmallWeb) {
      crossAxisCount = 2;
      aspectRatio = 0.8;
      cardHeight = 170;
      iconSize = 28;
      textSize = 15;
      cardPadding = 12;
    } else if (isMediumWeb) {
      crossAxisCount = 3;
      aspectRatio = 0.7;
      cardHeight = 200;
      iconSize = 30;
      textSize = 14.5;
      cardPadding = 16;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: aspectRatio,
          children: [
            _buildWebActionCard(context, 'Ongeza Mauzo', Icons.point_of_sale, Colors.green, () => _navigateToAddSale(context), cardHeight, iconSize, textSize, cardPadding),
            _buildWebActionCard(context, 'Ongeza Bidhaa', Icons.add_box, Colors.blue, () => Navigator.pushNamed(context, AppRoutes.addProduct), cardHeight, iconSize, textSize, cardPadding),
            _buildWebActionCard(context, 'Madeni', Icons.credit_card, Colors.orange, () => Navigator.pushNamed(context, AppRoutes.debtManagement), cardHeight, iconSize, textSize, cardPadding),
            _buildWebActionCard(context, 'Ripoti', Icons.analytics, Colors.purple, () => Navigator.pushNamed(context, AppRoutes.reports), cardHeight, iconSize, textSize, cardPadding),
            _buildWebActionCard(context, 'Faida kwa Bidhaa', Icons.trending_up, Colors.deepPurple, () => Navigator.pushNamed(context, AppRoutes.productProfit), cardHeight, iconSize, textSize, cardPadding),
            /*
            _buildWebActionCard(context, 'Ugawaji wa Faida', Icons.pie_chart, Colors.teal, () => Navigator.pushNamed(context, AppRoutes.profitDistribution), cardHeight, iconSize, textSize, cardPadding),
            */
            _buildWebActionCard(context, 'Wateja', Icons.people, Colors.indigo, () => Navigator.pushNamed(context, AppRoutes.wateja), cardHeight, iconSize, textSize, cardPadding),
            _buildWebActionCard(context, 'Notebook', Icons.sticky_note_2, Colors.lightBlue, () => Navigator.pushNamed(context, AppRoutes.notes), cardHeight, iconSize, textSize, cardPadding),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildMobileActionCard(
          context,
          'Ongeza Mauzo',
          Icons.point_of_sale,
          Colors.green,
          () => _navigateToAddSale(context),
        ),
        _buildMobileActionCard(
          context,
          'Ongeza Bidhaa',
          Icons.add_box,
          Colors.blue,
          () => Navigator.pushNamed(context, AppRoutes.addProduct),
        ),
        _buildMobileActionCard(
          context,
          'Madeni',
          Icons.credit_card,
          Colors.orange,
          () => Navigator.pushNamed(context, AppRoutes.debtManagement),
        ),
        _buildMobileActionCard(
          context,
          'Ripoti',
          Icons.analytics,
          Colors.purple,
          () => Navigator.pushNamed(context, AppRoutes.reports),
        ),
        _buildMobileActionCard(
          context,
          'Faida kwa\nBidhaa',
          Icons.trending_up,
          Colors.deepPurple,
          () => Navigator.pushNamed(context, AppRoutes.productProfit),
        ),
        /*
        _buildMobileActionCard(
          context,
          'Ugawaji wa\nFaida',
          Icons.pie_chart,
          Colors.teal,
          () => Navigator.pushNamed(context, AppRoutes.profitDistribution),
        ),
        */
        _buildMobileActionCard(
          context,
          'Wateja',
          Icons.people,
          Colors.indigo,
          () => Navigator.pushNamed(context, AppRoutes.wateja),
        ),
        _buildMobileActionCard(
          context,
          'Notebook',
          Icons.sticky_note_2,
          Colors.lightBlue,
          () => Navigator.pushNamed(context, AppRoutes.notes),
        ),
      ],
    );
  }

  Widget _buildWebActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
    double cardHeight,
    double iconSize,
    double textSize,
    double cardPadding,
  ) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Card(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(cardPadding),
            height: cardHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(iconSize * 0.36),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: iconSize),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                        fontSize: textSize,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      color: Colors.white,
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12), // Slightly less padding for more text space
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 16), // Reduce spacing to allow more room for text
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 3, // Allow up to 3 lines
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
        