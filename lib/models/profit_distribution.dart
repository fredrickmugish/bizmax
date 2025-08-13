import 'package:flutter/material.dart';

class ProfitDistribution {
  final double totalProfit;
  final double reinvestmentAmount; // MINIMUM 20% - Mtaji wa Maendeleo
  final double businessSavingsAmount; // Flexible - Akiba ya Biashara
  final double businessExpensesAmount; // Flexible - Matumizi ya Biashara
  final double personalExpensesAmount; // Flexible - Matumizi Binafsi
  
  // Distribution percentages (with minimum 20% reinvestment)
  static const double minimumReinvestmentPercentage = 20.0; // MINIMUM (not fixed)
  static const double defaultReinvestmentPercentage = 20.0; // Default starting point
  static const double defaultBusinessSavingsPercentage = 35.0; // Adjusted for remaining 80%
  static const double defaultBusinessExpensesPercentage = 25.0; // Adjusted for remaining 80%
  static const double defaultPersonalExpensesPercentage = 20.0; // Adjusted for remaining 80%

  ProfitDistribution({
    required this.totalProfit,
    required this.reinvestmentAmount,
    required this.businessSavingsAmount,
    required this.businessExpensesAmount,
    required this.personalExpensesAmount,
  });

  factory ProfitDistribution.fromProfit(double profit) {
    return ProfitDistribution(
      totalProfit: profit,
      reinvestmentAmount: profit * (defaultReinvestmentPercentage / 100),
      businessSavingsAmount: profit * (defaultBusinessSavingsPercentage / 100),
      businessExpensesAmount: profit * (defaultBusinessExpensesPercentage / 100),
      personalExpensesAmount: profit * (defaultPersonalExpensesPercentage / 100),
    );
  }

  factory ProfitDistribution.custom({
    required double totalProfit,
    required double reinvestmentPercentage,
    required double businessSavingsPercentage,
    required double businessExpensesPercentage,
    required double personalExpensesPercentage,
  }) {
    // Enforce minimum 20% reinvestment
    final enforcedReinvestmentPercentage = reinvestmentPercentage >= minimumReinvestmentPercentage 
        ? reinvestmentPercentage 
        : minimumReinvestmentPercentage;
    
    // Calculate remaining percentage for other categories
    final remainingPercentage = 100 - enforcedReinvestmentPercentage;
    final otherCategoriesTotal = businessSavingsPercentage + businessExpensesPercentage + personalExpensesPercentage;
    
    // Normalize other categories to fit within remaining percentage
    final normalizationFactor = remainingPercentage / otherCategoriesTotal;
    
    final normalizedBusinessSavings = businessSavingsPercentage * normalizationFactor;
    final normalizedBusinessExpenses = businessExpensesPercentage * normalizationFactor;
    final normalizedPersonalExpenses = personalExpensesPercentage * normalizationFactor;

    return ProfitDistribution(
      totalProfit: totalProfit,
      reinvestmentAmount: totalProfit * (enforcedReinvestmentPercentage / 100),
      businessSavingsAmount: totalProfit * (normalizedBusinessSavings / 100),
      businessExpensesAmount: totalProfit * (normalizedBusinessExpenses / 100),
      personalExpensesAmount: totalProfit * (normalizedPersonalExpenses / 100),
    );
  }

  // Getters for percentages
  double get reinvestmentPercentage => (reinvestmentAmount / totalProfit) * 100;
  double get businessSavingsPercentage => (businessSavingsAmount / totalProfit) * 100;
  double get businessExpensesPercentage => (businessExpensesAmount / totalProfit) * 100;
  double get personalExpensesPercentage => (personalExpensesAmount / totalProfit) * 100;

  // Validation
  bool get isValid => totalProfit >= 0;
  bool get followsRecommendations {
    return reinvestmentPercentage >= minimumReinvestmentPercentage && 
           businessSavingsPercentage >= 10 && 
           businessSavingsPercentage <= 50 &&
           businessExpensesPercentage >= 10 && 
           businessExpensesPercentage <= 40 &&
           personalExpensesPercentage >= 5 && 
           personalExpensesPercentage <= 35;
  }

  // Recommendations
  List<String> get recommendations {
    final recommendations = <String>[];
    
    if (reinvestmentPercentage < minimumReinvestmentPercentage) {
      recommendations.add('Mtaji wa maendeleo lazima uwe angalau ${minimumReinvestmentPercentage}% kwa ukuaji wa biashara');
    }
    
    if (businessSavingsPercentage < 10) {
      recommendations.add('Weka akiba ya biashara ya angalau 10% kwa dharura');
    }
    
    if (personalExpensesPercentage > 35) {
      recommendations.add('Punguza matumizi binafsi chini ya 35% kwa ukuaji wa biashara');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('Ugawaji wa faida unaofuata miongozo ya kitaalamu!');
    }
    
    return recommendations;
  }

  Map<String, dynamic> toJson() {
    return {
      'total_profit': totalProfit,
      'reinvestment_amount': reinvestmentAmount,
      'business_savings_amount': businessSavingsAmount,
      'business_expenses_amount': businessExpensesAmount,
      'personal_expenses_amount': personalExpensesAmount,
      'reinvestment_percentage': reinvestmentPercentage,
      'business_savings_percentage': businessSavingsPercentage,
      'business_expenses_percentage': businessExpensesPercentage,
      'personal_expenses_percentage': personalExpensesPercentage,
    };
  }

  factory ProfitDistribution.fromJson(Map<String, dynamic> json) {
    return ProfitDistribution(
      totalProfit: json['total_profit']?.toDouble() ?? 0.0,
      reinvestmentAmount: json['reinvestment_amount']?.toDouble() ?? 0.0,
      businessSavingsAmount: json['business_savings_amount']?.toDouble() ?? 0.0,
      businessExpensesAmount: json['business_expenses_amount']?.toDouble() ?? 0.0,
      personalExpensesAmount: json['personal_expenses_amount']?.toDouble() ?? 0.0,
    );
  }
}

// Distribution categories with descriptions
class DistributionCategory {
  final String name;
  final String description;
  final String icon;
  final Color color;
  final List<String> examples;

  const DistributionCategory({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.examples,
  });
}

class DistributionCategories {
  static const reinvestment = DistributionCategory(
    name: 'Mtaji wa Maendeleo',
    description: 'Kununua bidhaa zaidi, kuboresha huduma, kufungua tawi au kuongeza vifaa',
    icon: 'trending_up',
    color: Colors.green,
    examples: [
      'Kununua bidhaa zaidi',
      'Kuboresha huduma',
      'Kufungua tawi jipya',
      'Kuongeza vifaa na teknolojia',
      'Kufanya matangazo',
    ],
  );

  static const businessSavings = DistributionCategory(
    name: 'Akiba ya Biashara',
    description: 'Emergency fund, kukabiliana na hasara au matumizi zisizotarajiwa',
    icon: 'savings',
    color: Colors.blue,
    examples: [
      'Emergency fund',
      'Kukabiliana na hasara',
      'Matumizi zisizotarajiwa',
      'Muda wa shida',
      'Uwekezaji wa baadaye',
    ],
  );

  static const businessExpenses = DistributionCategory(
    name: 'Matumizi ya Biashara',
    description: 'Kodi, mishahara, umeme, na matumizi zingine za biashara',
    icon: 'business',
    color: Colors.orange,
    examples: [
      'Kodi na ushuru',
      'Mishahara ya wafanyakazi',
      'Umeme na maji',
      'Ukarabati na matengenezo',
      'Bima ya biashara',
    ],
  );

  static const personalExpenses = DistributionCategory(
    name: 'Matumizi Binafsi',
    description: 'Matumizi ya mmiliki wa biashara na familia',
    icon: 'person',
    color: Colors.purple,
    examples: [
      'Matumizi ya familia',
      'Malipo ya nyumba',
      'Matumizi za afya',
      'Elimu ya watoto',
      'Matumizi ya kibinafsi',
    ],
  );

  static List<DistributionCategory> getAll() {
    return [reinvestment, businessSavings, businessExpenses, personalExpenses];
  }
} 