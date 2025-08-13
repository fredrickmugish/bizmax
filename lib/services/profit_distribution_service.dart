import '../models/profit_distribution.dart';
import '../models/business_metrics.dart';

class ProfitDistributionService {
  static final ProfitDistributionService _instance = ProfitDistributionService._internal();
  factory ProfitDistributionService() => _instance;
  static ProfitDistributionService get instance => _instance;
  ProfitDistributionService._internal();

  /// Calculate recommended profit distribution based on current business metrics
  ProfitDistribution calculateRecommendedDistribution(BusinessMetrics metrics) {
    // Use net profit for distribution (after all expenses)
    final netProfit = metrics.totalNetProfit;
    
    if (netProfit <= 0) {
      // If no profit, return zero distribution
      return ProfitDistribution(
        totalProfit: 0,
        reinvestmentAmount: 0,
        businessSavingsAmount: 0,
        businessExpensesAmount: 0,
        personalExpensesAmount: 0,
      );
    }

    // Calculate distribution based on business health
    final businessHealth = _calculateBusinessHealth(metrics);
    
    // Start with minimum 20% reinvestment
    double reinvestmentPercentage = ProfitDistribution.minimumReinvestmentPercentage;
    
    // Distribute remaining percentage based on business health
    double businessSavingsPercentage = ProfitDistribution.defaultBusinessSavingsPercentage;
    double businessExpensesPercentage = ProfitDistribution.defaultBusinessExpensesPercentage;
    double personalExpensesPercentage = ProfitDistribution.defaultPersonalExpensesPercentage;

    if (businessHealth == 'poor') {
      // If business health is poor, increase reinvestment and savings
      reinvestmentPercentage = 30; // Higher reinvestment for struggling business
      businessSavingsPercentage = 40; // Higher savings for emergencies
      businessExpensesPercentage = 20;
      personalExpensesPercentage = 10; // Minimal personal expenses when business is struggling
    } else if (businessHealth == 'excellent') {
      // If business health is excellent, allow more personal expenses
      reinvestmentPercentage = 20; // Keep at minimum
      businessSavingsPercentage = 25;
      businessExpensesPercentage = 25;
      personalExpensesPercentage = 30; // More personal expenses when business is doing well
    }

    return ProfitDistribution(
      totalProfit: netProfit,
      reinvestmentAmount: netProfit * (reinvestmentPercentage / 100),
      businessSavingsAmount: netProfit * (businessSavingsPercentage / 100),
      businessExpensesAmount: netProfit * (businessExpensesPercentage / 100),
      personalExpensesAmount: netProfit * (personalExpensesPercentage / 100),
    );
  }

  /// Calculate business health score to adjust distribution recommendations
  String _calculateBusinessHealth(BusinessMetrics metrics) {
    if (metrics.totalRevenue == 0) return 'poor';

    // Calculate profit margin
    final profitMargin = (metrics.totalNetProfit / metrics.totalRevenue) * 100;
    
    // Calculate stock health
    final stockHealth = metrics.totalProducts != null && metrics.totalProducts! > 0 
        ? (metrics.totalProducts! - metrics.lowStockItems) / metrics.totalProducts!
        : 0;

    // Determine business health
    if (profitMargin >= 20 && stockHealth >= 0.9) {
      return 'excellent';
    } else if (profitMargin >= 10 && stockHealth >= 0.7) {
      return 'good';
    } else if (profitMargin >= 0 && stockHealth >= 0.5) {
      return 'fair';
    } else {
      return 'poor';
    }
  }

  /// Get detailed recommendations for profit distribution
  List<String> getDetailedRecommendations(BusinessMetrics metrics) {
    final recommendations = <String>[];
    final distribution = calculateRecommendedDistribution(metrics);

    if (metrics.totalNetProfit <= 0) {
      recommendations.add('Hakuna faida ya sasa. Fokus kwenye kuongeza mauzo na kupunguza matumizi.');
      return recommendations;
    }

    // Add minimum reinvestment note
    recommendations.add('📋 ${ProfitDistribution.minimumReinvestmentPercentage}% ya faida lazima itumike kwa mtaji wa maendeleo (Sheria ya Biashara). Unaweza kuongeza zaidi kulingana na mahitaji ya biashara.');

    // Add distribution recommendations
    recommendations.addAll(distribution.recommendations);

    // Add business-specific recommendations
    if (metrics.lowStockItems > 0) {
      recommendations.add('Kuna bidhaa ${metrics.lowStockItems} zenye stock chini. Ongeza mtaji wa kununua bidhaa.');
    }

    if (metrics.totalRevenue > 0) {
      final profitMargin = (metrics.totalNetProfit / metrics.totalRevenue) * 100;
      if (profitMargin < 10) {
        recommendations.add('Faida ni chini ya 10%. Ongeza bei au punguza matumizi.');
      } else if (profitMargin > 30) {
        recommendations.add('Faida ni nzuri (${profitMargin.toStringAsFixed(1)}%). Unaweza kuongeza uwekezaji.');
      }
    }

    // Add seasonal recommendations
    final currentMonth = DateTime.now().month;
    if (currentMonth >= 11 || currentMonth <= 2) {
      recommendations.add('Msimu wa Krismasi. Ongeza akiba kwa ajili ya mauzo makubwa.');
    } else if (currentMonth >= 3 && currentMonth <= 5) {
      recommendations.add('Msimu wa mvua. Weka akiba kwa ajili ya matumizi za ukarabati.');
    }

    return recommendations;
  }

  /// Validate custom distribution percentages
  bool validateDistributionPercentages({
    required double reinvestmentPercentage,
    required double businessSavingsPercentage,
    required double businessExpensesPercentage,
    required double personalExpensesPercentage,
  }) {
    // Check if reinvestment meets minimum requirement
    if (reinvestmentPercentage < ProfitDistribution.minimumReinvestmentPercentage) {
      return false;
    }
    
    // Calculate total of all categories (should be 100%)
    final totalPercentage = reinvestmentPercentage + businessSavingsPercentage + businessExpensesPercentage + personalExpensesPercentage;
    
    return (totalPercentage - 100).abs() <= 0.01; // Allow small rounding errors
  }

  /// Get warning messages for poor distribution choices
  List<String> getDistributionWarnings({
    required double reinvestmentPercentage,
    required double businessSavingsPercentage,
    required double businessExpensesPercentage,
    required double personalExpensesPercentage,
  }) {
    final warnings = <String>[];

    // Check minimum reinvestment
    if (reinvestmentPercentage < ProfitDistribution.minimumReinvestmentPercentage) {
      warnings.add('🚨 Mtaji wa maendeleo lazima uwe angalau ${ProfitDistribution.minimumReinvestmentPercentage}% (Sheria ya Biashara).');
    }

    // Check if all categories add up to exactly 100%
    final totalPercentage = reinvestmentPercentage + businessSavingsPercentage + businessExpensesPercentage + personalExpensesPercentage;
    
    if ((totalPercentage - 100).abs() > 0.01) {
      if (totalPercentage > 100) {
        warnings.add('🚨 Jumla ya faida inazidi 100% (${totalPercentage.toStringAsFixed(1)}%). Punguza kategoria moja au zaidi.');
      } else {
        warnings.add('🚨 Jumla ya faida ni chini ya 100% (${totalPercentage.toStringAsFixed(1)}%). Ongeza kategoria moja au zaidi.');
      }
    }

    if (businessSavingsPercentage < 5) {
      warnings.add('⚠️ Akiba ya biashara ni chini sana. Unaweza kukumbwa na shida.');
    }

    if (personalExpensesPercentage > 35) {
      warnings.add('⚠️ Matumizi binafsi ni mengi sana. Hii inaweza kuharibu biashara.');
    }

    if (businessSavingsPercentage > 50) {
      warnings.add('⚠️ Akiba ya biashara ni mkubwa sana. Unaweza kuongeza matumizi binafsi.');
    }

    return warnings;
  }

  /// Calculate monthly distribution for planning
  Map<String, double> calculateMonthlyDistribution(BusinessMetrics metrics) {
    final monthlyProfit = metrics.periodNetProfit;
    final distribution = calculateRecommendedDistribution(metrics);
    
    // Scale down to monthly amounts
    final monthlyScale = monthlyProfit / distribution.totalProfit;
    
    return {
      'reinvestment': distribution.reinvestmentAmount * monthlyScale,
      'business_savings': distribution.businessSavingsAmount * monthlyScale,
      'business_expenses': distribution.businessExpensesAmount * monthlyScale,
      'personal_expenses': distribution.personalExpensesAmount * monthlyScale,
    };
  }
} 