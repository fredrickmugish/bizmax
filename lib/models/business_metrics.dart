// lib/models/business_metrics.dart

import 'package:flutter/material.dart'; // Keeping for completeness if it's used elsewhere

class BusinessMetrics {
  final double totalRevenue;
  final double totalExpenses;
  final double totalProfit;
  final double todayRevenue;
  final double todayExpenses;
  final double todayPurchases;
  final double todayProfit;
  final double monthlyRevenue;
  final double monthlyProfit;
  final int lowStockItems;
  final int pendingOrders;
  final int totalCustomers;

  // New fields for accurate profit calculations
  final double totalCostOfGoodsSold;
  final double totalGrossProfit; // Faida ya Mauzo
  final double totalNetProfit; // Faida baada ya Matumizi
  final double periodCostOfGoodsSold;
  final double periodGrossProfit;
  final double periodNetProfit;
  final double todayCostOfGoodsSold;
  final double todayGrossProfit;
  final double todayNetProfit;
  final double periodExpenses;

  // Purchase funding metrics
  final double totalPurchasesRevenueFunded;
  final double totalPurchasesPersonalFunded;
  final double periodPurchasesRevenueFunded;
  final double periodPurchasesPersonalFunded;

  // API-specific fields
  final double? totalSales;
  final double? totalPurchases;
  final int? totalProducts; // Made nullable in your original
  final double? inventoryValue; // Made nullable in your original
  final String? businessHealthScore; // Made nullable in your original
  final List<String>? recommendations; // Made nullable in your original

  BusinessMetrics({
    required this.totalRevenue,
    required this.totalExpenses,
    required this.totalProfit,
    required this.todayRevenue,
    required this.todayExpenses,
    required this.todayPurchases,
    required this.todayProfit,
    required this.monthlyRevenue,
    required this.monthlyProfit,
    required this.lowStockItems,
    required this.pendingOrders,
    required this.totalCustomers,
    required this.totalCostOfGoodsSold,
    required this.totalGrossProfit,
    required this.totalNetProfit,
    required this.periodCostOfGoodsSold,
    required this.periodGrossProfit,
    required this.periodNetProfit,
    required this.todayCostOfGoodsSold,
    required this.todayGrossProfit,
    required this.todayNetProfit,
    required this.periodExpenses,
    required this.totalPurchasesRevenueFunded,
    required this.totalPurchasesPersonalFunded,
    required this.periodPurchasesRevenueFunded,
    required this.periodPurchasesPersonalFunded,
    this.totalSales,
    this.totalPurchases,
    this.totalProducts,
    this.inventoryValue,
    this.businessHealthScore,
    this.recommendations,
  });

  factory BusinessMetrics.empty() {
    return BusinessMetrics(
      totalRevenue: 0.0,
      totalExpenses: 0.0,
      totalProfit: 0.0,
      todayRevenue: 0.0,
      todayExpenses: 0.0,
      todayPurchases: 0.0,
      todayProfit: 0.0,
      monthlyRevenue: 0.0,
      monthlyProfit: 0.0,
      lowStockItems: 0,
      pendingOrders: 0,
      totalCustomers: 0,
      totalCostOfGoodsSold: 0.0,
      totalGrossProfit: 0.0,
      totalNetProfit: 0.0,
      periodCostOfGoodsSold: 0.0,
      periodGrossProfit: 0.0,
      periodNetProfit: 0.0,
      todayCostOfGoodsSold: 0.0,
      todayGrossProfit: 0.0,
      todayNetProfit: 0.0,
      periodExpenses: 0.0,
      totalPurchasesRevenueFunded: 0.0,
      totalPurchasesPersonalFunded: 0.0,
      periodPurchasesRevenueFunded: 0.0,
      periodPurchasesPersonalFunded: 0.0,
      // Ensure nullable fields also have appropriate defaults for empty(), if desired
      totalSales: 0.0,
      totalPurchases: 0.0,
      totalProducts: 0,
      inventoryValue: 0.0,
      businessHealthScore: 'N/A',
      recommendations: const [], // Empty list for empty state
    );
  }

  factory BusinessMetrics.fromApiJson(Map<String, dynamic> json) {
    // Helper function for safe double parsing
    double _parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      final str = value.toString();
      if (str.isEmpty || str == 'null') return 0.0;
      return double.tryParse(str) ?? 0.0;
    }

    // Helper function for safe int parsing
    int _parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toInt();
      final str = value.toString();
      if (str.isEmpty || str == 'null') return 0;
      return int.tryParse(str) ?? 0;
    }

    // Helper function for safe string parsing
    String? _parseString(dynamic value) {
      if (value == null) return null;
      final str = value.toString();
      if (str.isEmpty || str == 'null') return null;
      return str;
    }

    return BusinessMetrics(
      // Revenue metrics
      totalRevenue: _parseDouble(json['total_revenue']),
      todayRevenue: _parseDouble(json['today_revenue']),
      monthlyRevenue: _parseDouble(json['period_revenue']),

      // Purchase metrics
      todayPurchases: _parseDouble(json['today_purchases']),

      // Cost of Goods Sold metrics
      totalCostOfGoodsSold: _parseDouble(json['total_cost_of_goods_sold']),
      periodCostOfGoodsSold: _parseDouble(json['period_cost_of_goods_sold']),
      todayCostOfGoodsSold: _parseDouble(json['today_cost_of_goods_sold']),

      // Gross Profit metrics (Faida ya Mauzo)
      totalGrossProfit: _parseDouble(json['total_gross_profit']),
      periodGrossProfit: _parseDouble(json['period_gross_profit']),
      todayGrossProfit: _parseDouble(json['today_gross_profit']),

      // Expense metrics
      totalExpenses: _parseDouble(json['total_expenses']),
      todayExpenses: _parseDouble(json['today_expenses']),
      periodExpenses: _parseDouble(json['period_expenses']),

      // Purchase funding metrics
      totalPurchasesRevenueFunded: _parseDouble(json['total_purchases_revenue_funded']),
      totalPurchasesPersonalFunded: _parseDouble(json['total_purchases_personal_funded']),
      periodPurchasesRevenueFunded: _parseDouble(json['period_purchases_revenue_funded']),
      periodPurchasesPersonalFunded: _parseDouble(json['period_purchases_personal_funded']),

      // Net Profit metrics (Faida baada ya Matumizi)
      totalNetProfit: _parseDouble(json['total_net_profit']),
      periodNetProfit: _parseDouble(json['period_net_profit']),
      todayNetProfit: _parseDouble(json['today_net_profit']),

      // Legacy fields for backward compatibility (ensure these are still desired in the model)
      totalProfit: _parseDouble(json['total_profit']),
      todayProfit: _parseDouble(json['today_profit']),
      monthlyProfit: _parseDouble(json['period_profit']),

      // Inventory metrics - improved parsing
      lowStockItems: _parseInt(json['low_stock_items']),
      totalProducts: _parseInt(json['total_products']), // Fix applied here
      inventoryValue: double.tryParse(json['total_stock_value']?.toString() ?? ''), // nullable double can be null if parsing fails

      // These fields might not be in the backend JSON; provide safe defaults
      pendingOrders: _parseInt(json['pending_orders']),
      totalCustomers: _parseInt(json['total_customers']),

      // API-specific fields - improved parsing
      totalSales: _parseDouble(json['total_revenue']), // Redundant if totalRevenue is used elsewhere
      totalPurchases: _parseDouble(json['total_purchases']), // Should align with your purchase metrics
      businessHealthScore: _parseString(json['business_health_score']),
      recommendations: (json['recommendations'] as List?)
          ?.map((item) => _parseString(item))
          .whereType<String>() // Filter out any nulls
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_revenue': totalRevenue,
      'total_expenses': totalExpenses,
      'total_profit': totalProfit,
      'today_revenue': todayRevenue,
      'today_expenses': todayExpenses,
      'today_purchases': todayPurchases,
      'today_profit': todayProfit,
      'monthly_revenue': monthlyRevenue,
      'monthly_profit': monthlyProfit,
      'low_stock_items': lowStockItems,
      'pending_orders': pendingOrders,
      'total_customers': totalCustomers,
      'total_cost_of_goods_sold': totalCostOfGoodsSold,
      'total_gross_profit': totalGrossProfit,
      'total_net_profit': totalNetProfit,
      'period_cost_of_goods_sold': periodCostOfGoodsSold,
      'period_gross_profit': periodGrossProfit,
      'period_net_profit': periodNetProfit,
      'today_cost_of_goods_sold': todayCostOfGoodsSold,
      'today_gross_profit': todayGrossProfit,
      'today_net_profit': todayNetProfit,
      'period_expenses': periodExpenses,
      'total_purchases_revenue_funded': totalPurchasesRevenueFunded,
      'total_purchases_personal_funded': totalPurchasesPersonalFunded,
      'period_purchases_revenue_funded': periodPurchasesRevenueFunded,
      'period_purchases_personal_funded': periodPurchasesPersonalFunded,
      'total_sales': totalSales,
      'total_purchases': totalPurchases,
      'total_products': totalProducts,
      'inventory_value': inventoryValue,
      'business_health_score': businessHealthScore,
      'recommendations': recommendations,
    };
  }
}