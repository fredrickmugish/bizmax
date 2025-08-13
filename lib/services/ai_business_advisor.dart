import 'dart:math';
import '../models/business_metrics.dart';
import '../models/business_record.dart';
import '../models/inventory_item.dart';

class AIBusinessAdvisor {
  static final AIBusinessAdvisor _instance = AIBusinessAdvisor._internal();
  factory AIBusinessAdvisor() => _instance;
  AIBusinessAdvisor._internal();

  // Business Health Analysis
  BusinessHealthAnalysis analyzeBusinessHealth(BusinessMetrics metrics, List<BusinessRecord> recentRecords) {
    final analysis = BusinessHealthAnalysis();
    
    // Profitability Analysis
    analysis.profitabilityScore = _calculateProfitabilityScore(metrics);
    analysis.profitabilityTrend = _analyzeProfitabilityTrend(recentRecords);
    
    // Cash Flow Analysis
    analysis.cashFlowScore = _calculateCashFlowScore(metrics, recentRecords);
    analysis.cashFlowTrend = _analyzeCashFlowTrend(recentRecords);
    
    // Inventory Analysis
    analysis.inventoryEfficiency = _calculateInventoryEfficiency(metrics);
    analysis.stockTurnoverRate = _calculateStockTurnoverRate(recentRecords);
    
    // Customer Analysis
    analysis.customerRetentionRate = _calculateCustomerRetentionRate(recentRecords);
    analysis.customerSatisfactionScore = _calculateCustomerSatisfactionScore(recentRecords);
    
    // Generate Recommendations
    analysis.recommendations = _generateRecommendations(analysis);
    
    return analysis;
  }

  // Smart Pricing Recommendations
  List<PricingRecommendation> getPricingRecommendations(List<InventoryItem> products, List<BusinessRecord> salesHistory) {
    final recommendations = <PricingRecommendation>[];
    
    for (final product in products) {
      final productSales = salesHistory.where((record) => 
        record.inventoryItemId == product.id && record.type == 'sale'
      ).toList();
      
      if (productSales.isNotEmpty) {
        final avgSellingPrice = productSales.map((s) => s.amount).reduce((a, b) => a + b) / productSales.length;
        final profitMargin = ((avgSellingPrice - product.buyingPrice) / avgSellingPrice) * 100;
        
        String recommendation;
        double suggestedPrice;
        
        if (profitMargin < 20) {
          recommendation = 'Ongeza bei kidogo ili kuboresha faida';
          suggestedPrice = product.buyingPrice * 1.3; // 30% markup
        } else if (profitMargin > 50) {
          recommendation = 'Bei yako ni juu sana, punguza kidogo ili kuongeza mauzo';
          suggestedPrice = product.buyingPrice * 1.25; // 25% markup
        } else {
          recommendation = 'Bei yako ni nzuri, endelea hivyo';
          suggestedPrice = avgSellingPrice;
        }
        
        recommendations.add(PricingRecommendation(
          productId: product.id,
          productName: product.name,
          currentPrice: avgSellingPrice,
          suggestedPrice: suggestedPrice,
          recommendation: recommendation,
          profitMargin: profitMargin,
        ));
      }
    }
    
    return recommendations;
  }

  // Demand Forecasting
  DemandForecast forecastDemand(InventoryItem product, List<BusinessRecord> salesHistory) {
    final productSales = salesHistory.where((record) => 
      record.inventoryItemId == product.id && record.type == 'sale'
    ).toList();
    
    if (productSales.length < 7) {
      return DemandForecast(
        productId: product.id,
        productName: product.name,
        forecastedDemand: product.minimumStock,
        confidence: 0.5,
        recommendation: 'Hakuna data ya kutosha kwa utabiri sahihi',
      );
    }
    
    // Simple moving average for demand forecasting
    final dailySales = <int>[];
    final now = DateTime.now();
    
    for (int i = 30; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final daySales = productSales.where((sale) => 
        sale.date.year == date.year && 
        sale.date.month == date.month && 
        sale.date.day == date.day
      ).fold(0, (sum, sale) => sum + (sale.quantity ?? 1));
      
      dailySales.add(daySales);
    }
    
    final avgDailySales = dailySales.reduce((a, b) => a + b) / dailySales.length;
    final forecastedDemand = (avgDailySales * 30).round(); // 30-day forecast
    
    return DemandForecast(
      productId: product.id,
      productName: product.name,
      forecastedDemand: forecastedDemand,
      confidence: 0.8,
      recommendation: 'Ununua ${forecastedDemand} kwa mwezi ujao',
    );
  }

  // Seasonal Analysis
  SeasonalAnalysis analyzeSeasonality(List<BusinessRecord> salesHistory) {
    final monthlySales = <int, double>{};
    
    for (int month = 1; month <= 12; month++) {
      final monthSales = salesHistory.where((sale) => 
        sale.type == 'sale' && sale.date.month == month
      ).fold(0.0, (sum, sale) => sum + sale.amount);
      
      monthlySales[month] = monthSales;
    }
    
    final avgSales = monthlySales.values.reduce((a, b) => a + b) / 12;
    final peakMonth = monthlySales.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    final lowMonth = monthlySales.entries.reduce((a, b) => a.value < b.value ? a : b).key;
    
    return SeasonalAnalysis(
      peakMonth: peakMonth,
      lowMonth: lowMonth,
      averageSales: avgSales,
      seasonalityStrength: _calculateSeasonalityStrength(monthlySales, avgSales),
      recommendations: _generateSeasonalRecommendations(peakMonth, lowMonth),
    );
  }

  // Helper methods
  double _calculateProfitabilityScore(BusinessMetrics metrics) {
    if (metrics.totalRevenue == 0) return 0;
    
    final grossProfitMargin = (metrics.totalGrossProfit / metrics.totalRevenue) * 100;
    final netProfitMargin = (metrics.totalNetProfit / metrics.totalRevenue) * 100;
    
    // Score based on profit margins
    double score = 0;
    if (grossProfitMargin >= 30) score += 40;
    else if (grossProfitMargin >= 20) score += 30;
    else if (grossProfitMargin >= 10) score += 20;
    else score += 10;
    
    if (netProfitMargin >= 15) score += 60;
    else if (netProfitMargin >= 10) score += 40;
    else if (netProfitMargin >= 5) score += 20;
    else score += 10;
    
    return score;
  }

  String _analyzeProfitabilityTrend(List<BusinessRecord> recentRecords) {
    if (recentRecords.length < 14) return 'Hakuna data ya kutosha';
    
    final recent = recentRecords.take(7).where((r) => r.type == 'sale').fold(0.0, (sum, r) => sum + r.amount);
    final previous = recentRecords.skip(7).take(7).where((r) => r.type == 'sale').fold(0.0, (sum, r) => sum + r.amount);
    
    if (recent > previous * 1.1) return 'Faida inaongezeka';
    if (recent < previous * 0.9) return 'Faida inapungua';
    return 'Faida imesimama';
  }

  double _calculateCashFlowScore(BusinessMetrics metrics, List<BusinessRecord> recentRecords) {
    final creditSales = recentRecords.where((r) => r.type == 'sale' && r.isCreditSale).length;
    final totalSales = recentRecords.where((r) => r.type == 'sale').length;
    
    if (totalSales == 0) return 100;
    
    final creditRatio = creditSales / totalSales;
    double score = 100;
    
    if (creditRatio > 0.5) score -= 30;
    else if (creditRatio > 0.3) score -= 20;
    else if (creditRatio > 0.1) score -= 10;
    
    return score;
  }

  String _analyzeCashFlowTrend(List<BusinessRecord> recentRecords) {
    final creditSales = recentRecords.where((r) => r.type == 'sale' && r.isCreditSale).length;
    final totalSales = recentRecords.where((r) => r.type == 'sale').length;
    
    if (totalSales == 0) return 'Hakuna mauzo';
    
    final creditRatio = creditSales / totalSales;
    
    if (creditRatio > 0.5) return 'Mauzo ya mkopo ni mengi - punguza';
    if (creditRatio > 0.3) return 'Mauzo ya mkopo ni kiasi - bora';
    return 'Mauzo ya mkopo ni chache - nzuri';
  }

  double _calculateInventoryEfficiency(BusinessMetrics metrics) {
    if (metrics.totalProducts == null || metrics.totalProducts == 0) return 0;
    
    final lowStockRatio = metrics.lowStockItems / metrics.totalProducts!;
    return (1 - lowStockRatio) * 100;
  }

  double _calculateStockTurnoverRate(List<BusinessRecord> salesHistory) {
    final sales = salesHistory.where((r) => r.type == 'sale').length;
    return sales / 30; // Average daily sales
  }

  double _calculateCustomerRetentionRate(List<BusinessRecord> salesHistory) {
    final customers = salesHistory.where((r) => r.type == 'sale' && r.customerName != null)
        .map((r) => r.customerName!)
        .toSet();
    
    final repeatCustomers = customers.where((customer) {
      final customerSales = salesHistory.where((r) => 
        r.type == 'sale' && r.customerName == customer
      ).length;
      return customerSales > 1;
    }).length;
    
    if (customers.isEmpty) return 0;
    return (repeatCustomers / customers.length) * 100;
  }

  double _calculateCustomerSatisfactionScore(List<BusinessRecord> salesHistory) {
    // Simple heuristic based on credit sales ratio (lower is better)
    final creditSales = salesHistory.where((r) => r.type == 'sale' && r.isCreditSale).length;
    final totalSales = salesHistory.where((r) => r.type == 'sale').length;
    
    if (totalSales == 0) return 100;
    
    final creditRatio = creditSales / totalSales;
    return (1 - creditRatio) * 100;
  }

  List<String> _generateRecommendations(BusinessHealthAnalysis analysis) {
    final recommendations = <String>[];
    
    if (analysis.profitabilityScore < 50) {
      recommendations.add('• Ongeza bei ya bidhaa zako au punguza matumizi');
      recommendations.add('• Fanya utafiti wa bei za soko');
    }
    
    if (analysis.cashFlowScore < 70) {
      recommendations.add('• Punguza mauzo ya mkopo');
      recommendations.add('• Ongeza mauzo ya fedha taslimu');
    }
    
    if (analysis.inventoryEfficiency < 80) {
      recommendations.add('• Rekebisha hifadhi ya bidhaa');
      recommendations.add('• Ununua bidhaa zinazohitajika');
    }
    
    if (analysis.customerRetentionRate < 30) {
      recommendations.add('• Boresha huduma kwa wateja');
      recommendations.add('• Toa punguzo kwa wateja wa mara kwa mara');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('• Biashara yako inaendelea vizuri!');
      recommendations.add('• Endelea kufuatilia na kuboresha');
    }
    
    return recommendations;
  }

  double _calculateSeasonalityStrength(Map<int, double> monthlySales, double avgSales) {
    double variance = 0;
    for (final sales in monthlySales.values) {
      variance += pow(sales - avgSales, 2);
    }
    variance /= 12;
    
    return sqrt(variance) / avgSales;
  }

  List<String> _generateSeasonalRecommendations(int peakMonth, int lowMonth) {
    final monthNames = [
      'Januari', 'Februari', 'Machi', 'Aprili', 'Mei', 'Juni',
      'Julai', 'Agosti', 'Septemba', 'Oktoba', 'Novemba', 'Desemba'
    ];
    
    return [
      '• Mwezi wa juu: ${monthNames[peakMonth - 1]} - Ongeza hifadhi',
      '• Mwezi wa chini: ${monthNames[lowMonth - 1]} - Punguza hifadhi',
      '• Fanya mpango wa msimu',
    ];
  }
}

// Data classes for analysis results
class BusinessHealthAnalysis {
  double profitabilityScore = 0;
  String profitabilityTrend = '';
  double cashFlowScore = 0;
  String cashFlowTrend = '';
  double inventoryEfficiency = 0;
  double stockTurnoverRate = 0;
  double customerRetentionRate = 0;
  double customerSatisfactionScore = 0;
  List<String> recommendations = [];
}

class PricingRecommendation {
  final String productId;
  final String productName;
  final double currentPrice;
  final double suggestedPrice;
  final String recommendation;
  final double profitMargin;

  PricingRecommendation({
    required this.productId,
    required this.productName,
    required this.currentPrice,
    required this.suggestedPrice,
    required this.recommendation,
    required this.profitMargin,
  });
}

class DemandForecast {
  final String productId;
  final String productName;
  final int forecastedDemand;
  final double confidence;
  final String recommendation;

  DemandForecast({
    required this.productId,
    required this.productName,
    required this.forecastedDemand,
    required this.confidence,
    required this.recommendation,
  });
}

class SeasonalAnalysis {
  final int peakMonth;
  final int lowMonth;
  final double averageSales;
  final double seasonalityStrength;
  final List<String> recommendations;

  SeasonalAnalysis({
    required this.peakMonth,
    required this.lowMonth,
    required this.averageSales,
    required this.seasonalityStrength,
    required this.recommendations,
  });
} 