import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/business_provider.dart';
import '../utils/currency_formatter.dart';

class BusinessHealthIndicator extends StatelessWidget {
  const BusinessHealthIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<BusinessProvider>(
      builder: (context, provider, child) {
        final healthScore = _calculateHealthScore(provider);
        final healthStatus = _getHealthStatus(healthScore);
        final healthColor = _getHealthColor(healthScore);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.health_and_safety,
                      color: healthColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Hali ya Biashara',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: healthColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: healthColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        healthStatus,
                        style: TextStyle(
                          color: healthColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (provider.totalRevenue == 0 && provider.totalExpenses == 0)
                  const Column(
                    children: [
                      Icon(
                        Icons.trending_up,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Anza kuongeza rekodi za biashara yako',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tutakuonyesha hali ya biashara yako',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      LinearProgressIndicator(
                        value: healthScore / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(healthColor),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildHealthMetric(
                            'Faida ya Leo',
                            CurrencyFormatter.format(provider.todayProfit),
                            provider.todayProfit >= 0 ? Colors.green : Colors.red,
                          ),
                          _buildHealthMetric(
                            'Bidhaa Chini',
                            '${provider.lowStockItems}',
                            provider.lowStockItems > 0 ? Colors.orange : Colors.green,
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHealthMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
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
    );
  }

  double _calculateHealthScore(provider) {
    if (provider.totalRevenue == 0) return 0;
    
    double score = 0;
    
    // Today's profit performance (40% of score)
    if (provider.todayProfit > 0) {
      score += 40;
    } else if (provider.todayProfit == 0) {
      score += 20;
    } else {
      score += 0; // Negative profit
    }
    
    // Profit margin (30% of score)
    if (provider.totalRevenue > 0) {
      final profitMargin = (provider.totalProfit / provider.totalRevenue) * 100;
      if (profitMargin > 20) {
        score += 30;
      } else if (profitMargin > 10) {
        score += 20;
      } else if (profitMargin > 0) {
        score += 10;
      }
    }
    
    // Stock management (20% of score)
    if (provider.lowStockItems == 0) {
      score += 20;
    } else if (provider.lowStockItems <= 2) {
      score += 15;
    } else if (provider.lowStockItems <= 5) {
      score += 10;
    }
    
    // Revenue activity (10% of score)
    if (provider.todayRevenue > 0) {
      score += 10;
    } else if (provider.monthlyRevenue > 0) {
      score += 5;
    }
    
    return score.clamp(0, 100);
  }

  String _getHealthStatus(double score) {
    if (score >= 80) return 'Nzuri Sana';
    if (score >= 60) return 'Nzuri';
    if (score >= 40) return 'Wastani';
    if (score >= 20) return 'Mbaya';
    return 'Anza Biashara';
  }

  Color _getHealthColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.orange;
    if (score >= 20) return Colors.red;
    return Colors.grey;
  }
}
