import 'package:flutter/foundation.dart';
import '../models/business_metrics.dart';
import '../providers/records_provider.dart';
import '../providers/inventory_provider.dart';
import '../utils/app_utils.dart';
import 'package:flutter/material.dart'; // Added for BuildContext
import 'package:provider/provider.dart'; // Added for Provider
import '../providers/business_provider.dart'; // Added for BusinessProvider

class ReportsProvider extends ChangeNotifier {
  RecordsProvider? _recordsProvider;
  InventoryProvider? _inventoryProvider;

  BusinessMetrics _metrics = BusinessMetrics.empty();
  List<Map<String, dynamic>> _monthlyTrends = [];
  Map<String, double> _revenueByPeriod = {};
  Map<String, double> _purchasesByPeriod = {};
  Map<String, double> _expensesByPeriod = {};
  Map<String, double> _expensesByCategory = {};
  List<Map<String, dynamic>> _topSellingProducts = [];
  List<Map<String, dynamic>> _topPurchases = [];
  bool _isLoading = false;

  // Date range filtering properties (similar to RecordsProvider)
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showTodayOnly = true;

  // Custom date range properties for 'Muda maalum'
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  ReportsProvider() {
    // Initialize with today's date range (similar to RecordsProvider)
    final today = AppUtils.getEastAfricaTime();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    _startDate = startOfDay;
    _endDate = endOfDay;
    _showTodayOnly = true;
  }

  BusinessMetrics get metrics => _metrics;
  List<Map<String, dynamic>> get monthlyTrends => _monthlyTrends;
  Map<String, double> get revenueByPeriod => _revenueByPeriod;
  Map<String, double> get purchasesByPeriod => _purchasesByPeriod;
  Map<String, double> get expensesByPeriod => _expensesByPeriod;
  Map<String, double> get expensesByCategory => _expensesByCategory;
  List<Map<String, dynamic>> get topSellingProducts => _topSellingProducts;
  List<Map<String, dynamic>> get topPurchases => _topPurchases;
  bool get isLoading => _isLoading;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  bool get showTodayOnly => _showTodayOnly;
  DateTime? get customStartDate => _customStartDate;
  DateTime? get customEndDate => _customEndDate;

  void update(RecordsProvider recordsProvider) {
    _recordsProvider = recordsProvider;
    _recordsProvider!.addListener(loadReports);
    loadReports();
  }

  Future<void> loadReports({String selectedPeriod = 'Mwezi huu'}) async {
    _isLoading = true;
    notifyListeners(); // Notify listeners that loading has started

    try {
      print('ReportsProvider: Starting to load reports for period: $selectedPeriod');
      if (_recordsProvider == null) {
        print('ReportsProvider: RecordsProvider not set, cannot load reports');
        _isLoading = false; // Ensure loading is false if early exit
        notifyListeners();
        return;
      }

      // Fetch and calculate all data
      final newMetrics = await _calculateBusinessMetricsFromRecords(selectedPeriod);
      final newMonthlyTrends = await _calculateMonthlyTrendsFromRecords();
      final (startDate, endDate) = _getDateRangeForPeriod(selectedPeriod);
      final newRevenueByPeriod = await _calculateRevenueByPeriodFromRecords(startDate, endDate);
      final newPurchasesByPeriod = await _calculatePurchasesByPeriodFromRecords(startDate, endDate);
      final newExpensesByPeriod = await _calculateExpensesByPeriodFromRecords(startDate, endDate);
      final newExpensesByCategory = await _calculateExpensesByCategoryFromRecords(selectedPeriod);
      final newTopSellingProducts = await _calculateTopSellingProductsFromRecords(selectedPeriod);
      final newTopPurchases = await _calculateTopPurchasesFromRecords(selectedPeriod);

      // Only clear and assign data after all calculations are successful
      _metrics = newMetrics;
      _monthlyTrends = newMonthlyTrends;
      _revenueByPeriod = newRevenueByPeriod;
      _purchasesByPeriod = newPurchasesByPeriod;
      _expensesByPeriod = newExpensesByPeriod;
      _expensesByCategory = newExpensesByCategory;
      _topSellingProducts = newTopSellingProducts;
      _topPurchases = newTopPurchases;

    } catch (e) {
      print('ReportsProvider: Error loading reports: $e');
    } finally {
      _isLoading = false;
      notifyListeners(); // Notify listeners that loading has completed
      print('ReportsProvider: Reports loading completed');
    }
  }

  Future<BusinessMetrics> _calculateBusinessMetricsFromRecords(String period) async {
    try {
      print('ReportsProvider: Calculating business metrics from records for period: $period');
      final records = _recordsProvider!.allRecords;
      print('ReportsProvider: Retrieved ${records.length} records from RecordsProvider');

      final (startDate, endDate) = _getDateRangeForPeriod(period);
      final filteredRecords = records.where((record) => 
        record.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
        record.date.isBefore(endDate.add(const Duration(days: 1)))
      ).toList();

      print('ReportsProvider: Filtered to ${filteredRecords.length} records for period: $period');

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final monthStart = DateTime(now.year, now.month, 1);

      // Calculate totals for the selected period
      double totalRevenue = 0;
      double totalExpenses = 0;
      double totalPurchases = 0;
      double totalCostOfGoodsSold = 0; // This will still be total COGS, not just for profit-eligible sales
      double totalPurchasesRevenueFunded = 0;
      double todayRevenue = 0;
      double todayExpenses = 0;
      double todayPurchases = 0;
      double todayCostOfGoodsSold = 0; // This will still be total COGS, not just for profit-eligible sales
      double monthlyRevenue = 0;

      double calculatedTotalGrossProfit = 0;
      double calculatedTodayGrossProfit = 0;

      for (final record in filteredRecords) {
        if (record.type == 'sale') {
          totalRevenue += record.amount;
          totalCostOfGoodsSold += record.costOfGoodsSold ?? 0; // Accumulate total COGS

          double cogs = record.costOfGoodsSold ?? 0;
          // If COGS is not set, try to calculate from product (similar to backend)
          // This assumes that the BusinessRecord has enough information to derive COGS
          // If record.quantity is null, default to 1 to avoid division by zero or incorrect calculation
          if (cogs == 0 && record.unitPrice != 0 && record.quantity != null) {
            cogs = record.unitPrice * record.quantity!;
          }
          double saleRevenue = record.saleTotal;
          double profitForThisRecord = 0;

          if (!record.isCredit) {
            // Cash sale: full profit
            profitForThisRecord = saleRevenue - cogs;
          } else {
            // Credit sale: profit only if paidAmount > COGS
            double paid = record.paidAmount;
            if (paid > cogs) {
              profitForThisRecord = (paid - cogs).clamp(0, saleRevenue - cogs);
            }
          }
          calculatedTotalGrossProfit += profitForThisRecord;

          if (record.date.isAfter(today.subtract(const Duration(days: 1)))) {
            todayRevenue += record.amount;
            todayCostOfGoodsSold += record.costOfGoodsSold ?? 0; // Accumulate today's total COGS

            double todayProfitForThisRecord = 0;
            if (!record.isCredit) {
              todayProfitForThisRecord = saleRevenue - cogs;
            } else {
              double paid = record.paidAmount;
              if (paid > cogs) {
                todayProfitForThisRecord = (paid - cogs).clamp(0, saleRevenue - cogs);
              }
            }
            calculatedTodayGrossProfit += todayProfitForThisRecord;
          }
          if (record.date.isAfter(monthStart.subtract(const Duration(days: 1)))) {
            monthlyRevenue += record.amount;
          }
        } else if (record.type == 'purchase') {
          totalPurchases += record.amount;
          // Check if purchase is funded from revenue
          if (record.fundingSource == 'revenue') {
            totalPurchasesRevenueFunded += record.amount;
          }

          if (record.date.isAfter(today.subtract(const Duration(days: 1)))) {
            todayPurchases += record.amount;
          }
        } else if (record.type == 'expense') {
          totalExpenses += record.amount;
          if (record.date.isAfter(today.subtract(const Duration(days: 1)))) {
            todayExpenses += record.amount;
          }
        }
      }

      print('ReportsProvider: Calculated for period $period - Total Revenue: $totalRevenue, Total Expenses: $totalExpenses, Total Purchases: $totalPurchases, Cost of Goods Sold: $totalCostOfGoodsSold, Revenue Funded Purchases: $totalPurchasesRevenueFunded');

      return BusinessMetrics(
        totalRevenue: totalRevenue,
        totalExpenses: totalExpenses,
        totalProfit: calculatedTotalGrossProfit - totalExpenses, // Net profit
        todayRevenue: todayRevenue,
        todayExpenses: todayExpenses,
        todayPurchases: todayPurchases,
        todayProfit: todayRevenue - todayExpenses,
        monthlyRevenue: monthlyRevenue,
        monthlyProfit: monthlyRevenue - totalExpenses,
        lowStockItems: 0,
        pendingOrders: 0,
        totalCustomers: 0,
        totalCostOfGoodsSold: totalCostOfGoodsSold,
        totalGrossProfit: calculatedTotalGrossProfit,
        totalNetProfit: calculatedTotalGrossProfit - totalExpenses - totalPurchasesRevenueFunded,
        periodCostOfGoodsSold: totalCostOfGoodsSold,
        periodGrossProfit: calculatedTotalGrossProfit,
        periodNetProfit: calculatedTotalGrossProfit - totalExpenses - totalPurchasesRevenueFunded,
        todayCostOfGoodsSold: todayCostOfGoodsSold,
        todayGrossProfit: calculatedTodayGrossProfit,
        todayNetProfit: calculatedTodayGrossProfit - todayExpenses - totalPurchasesRevenueFunded,
        periodExpenses: totalExpenses,
        totalPurchasesRevenueFunded: totalPurchasesRevenueFunded,
        totalPurchasesPersonalFunded: totalPurchases - totalPurchasesRevenueFunded,
        periodPurchasesRevenueFunded: totalPurchasesRevenueFunded,
        periodPurchasesPersonalFunded: totalPurchases - totalPurchasesRevenueFunded,
        totalPurchases: totalPurchases,
      );
    } catch (e) {
      print('ReportsProvider: Error calculating business metrics: $e');
      return BusinessMetrics.empty();
    }
  }

  Future<List<Map<String, dynamic>>> _calculateMonthlyTrendsFromRecords() async {
    try {
      final records = _recordsProvider!.allRecords;
      final Map<String, Map<String, double>> monthlyData = {};

      for (final record in records) {
        final monthKey = '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}';

        if (!monthlyData.containsKey(monthKey)) {
          monthlyData[monthKey] = {'sales': 0, 'expenses': 0, 'profit': 0};
        }

        if (record.type == 'sale') {
          monthlyData[monthKey]!['sales'] = (monthlyData[monthKey]!['sales'] ?? 0) + record.amount;
        } else if (record.type == 'expense' || record.type == 'purchase') {
          monthlyData[monthKey]!['expenses'] = (monthlyData[monthKey]!['expenses'] ?? 0) + record.amount;
        }
      }

      // Calculate profit for each month
      for (final monthKey in monthlyData.keys) {
        final sales = monthlyData[monthKey]!['sales'] ?? 0;
        final expenses = monthlyData[monthKey]!['expenses'] ?? 0;
        monthlyData[monthKey]!['profit'] = sales - expenses;
      }

      // Convert to list and sort by month
      final trends = monthlyData.entries.map((entry) {
        return {
          'month': entry.key,
          'sales': entry.value['sales'],
          'expenses': entry.value['expenses'],
          'profit': entry.value['profit'],
        };
      }).toList();

      trends.sort((a, b) => a['month'].toString().compareTo(b['month'].toString()));

      return trends;
    } catch (e) {
      print('ReportsProvider: Error calculating monthly trends: $e');
      return [];
    }
  }

  Future<Map<String, double>> _calculateRevenueByPeriodFromRecords(DateTime start, DateTime end) async {
    try {
      final records = _recordsProvider!.allRecords;
      final Map<String, double> revenueData = {};

      for (final record in records) {
        if (record.type == 'sale' && 
            record.date.isAfter(start.subtract(const Duration(days: 1))) &&
            record.date.isBefore(end.add(const Duration(days: 1)))) {
          final dateKey = '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}-${record.date.day.toString().padLeft(2, '0')}';
          revenueData[dateKey] = (revenueData[dateKey] ?? 0) + record.amount;
        }
      }

      return revenueData;
    } catch (e) {
      print('ReportsProvider: Error calculating revenue by period: $e');
      return {};
    }
  }

  Future<Map<String, double>> _calculatePurchasesByPeriodFromRecords(DateTime start, DateTime end) async {
    try {
      final records = _recordsProvider!.allRecords;
      final Map<String, double> purchasesData = {};

      for (final record in records) {
        if (record.type == 'purchase' && 
            record.date.isAfter(start.subtract(const Duration(days: 1))) &&
            record.date.isBefore(end.add(const Duration(days: 1)))) {
          final dateKey = '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}-${record.date.day.toString().padLeft(2, '0')}';
          purchasesData[dateKey] = (purchasesData[dateKey] ?? 0) + record.amount;
        }
      }

      return purchasesData;
    } catch (e) {
      print('ReportsProvider: Error calculating purchases by period: $e');
      return {};
    }
  }

  Future<Map<String, double>> _calculateExpensesByPeriodFromRecords(DateTime start, DateTime end) async {
    try {
      final records = _recordsProvider!.allRecords;
      final Map<String, double> expensesData = {};

      for (final record in records) {
        if (record.type == 'expense' && 
            record.date.isAfter(start.subtract(const Duration(days: 1))) &&
            record.date.isBefore(end.add(const Duration(days: 1)))) {
          final dateKey = '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}-${record.date.day.toString().padLeft(2, '0')}';
          expensesData[dateKey] = (expensesData[dateKey] ?? 0) + record.amount;
        }
      }

      return expensesData;
    } catch (e) {
      print('ReportsProvider: Error calculating expenses by period: $e');
      return {};
    }
  }

  Future<Map<String, double>> _calculateExpensesByCategoryFromRecords(String period) async {
    try {
      final records = _recordsProvider!.allRecords;
      final (startDate, endDate) = _getDateRangeForPeriod(period);
      final filteredRecords = records.where((record) => 
        (record.type == 'expense' || record.type == 'purchase') &&
        record.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
        record.date.isBefore(endDate.add(const Duration(days: 1)))
      ).toList();

      final Map<String, double> categoryExpenses = {};

      for (final record in filteredRecords) {
        final category = record.category ?? 'Nyingine';
        categoryExpenses[category] = (categoryExpenses[category] ?? 0) + record.amount;
      }

      return categoryExpenses;
    } catch (e) {
      print('ReportsProvider: Error calculating expenses by category: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> _calculateTopSellingProductsFromRecords(String period) async {
    try {
      final records = _recordsProvider!.allRecords;
      final (startDate, endDate) = _getDateRangeForPeriod(period);
      final filteredRecords = records.where((record) => 
        record.type == 'sale' &&
        record.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
        record.date.isBefore(endDate.add(const Duration(days: 1)))
      ).toList();

      final Map<String, Map<String, dynamic>> productSales = {};

      for (final record in filteredRecords) {
        final productName = record.description;
        final productId = record.inventoryItemId;

        final key = productId ?? productName;
        if (!productSales.containsKey(key)) {
          productSales[key] = {
            'id': productId,
            'name': productName,
            'revenue': 0.0,
            'quantity': 0,
          };
        }
        productSales[key]!['revenue'] = 
            (productSales[key]!['revenue'] ?? 0.0) + record.amount;
        productSales[key]!['quantity'] = 
            (productSales[key]!['quantity'] ?? 0) + 1;
      }

      // Convert to list and sort by revenue
      final sortedProducts = productSales.values.toList()
        ..sort((a, b) => (b['revenue'] ?? 0.0).compareTo(a['revenue'] ?? 0.0));

      return sortedProducts;
    } catch (e) {
      print('ReportsProvider: Error calculating top selling products: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _calculateTopPurchasesFromRecords(String period) async {
    try {
      final records = _recordsProvider!.allRecords;
      final (startDate, endDate) = _getDateRangeForPeriod(period);
      final filteredRecords = records.where((record) => 
        record.type == 'purchase' &&
        record.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
        record.date.isBefore(endDate.add(const Duration(days: 1)))
      ).toList();

      final Map<String, Map<String, dynamic>> purchaseData = {};

      for (final record in filteredRecords) {
        final productName = record.description;
        final productId = record.inventoryItemId;

        final key = productId ?? productName;
        if (!purchaseData.containsKey(key)) {
          purchaseData[key] = {
            'id': productId,
            'name': productName,
            'revenue': 0.0,
            'quantity': 0,
          };
        }
        purchaseData[key]!['revenue'] = 
            (purchaseData[key]!['revenue'] ?? 0.0) + record.amount;
        purchaseData[key]!['quantity'] = 
            (purchaseData[key]!['quantity'] ?? 0) + 1;
      }

      // Convert to list and sort by revenue
      final sortedPurchases = purchaseData.values.toList()
        ..sort((a, b) => (b['revenue'] ?? 0.0).compareTo(a['revenue'] ?? 0.0));

      return sortedPurchases;
    } catch (e) {
      print('ReportsProvider: Error calculating top purchases: $e');
      return [];
    }
  }

  Future<void> refreshReports({String selectedPeriod = 'Mwezi huu'}) async {
    await loadReports(selectedPeriod: selectedPeriod);
  }

  // Helper method to get date range for different periods
  (DateTime startDate, DateTime endDate) _getDateRangeForPeriod(String period) {
    final now = AppUtils.getEastAfricaTime();
    final today = DateTime(now.year, now.month, now.day);

    switch (period) {
      case 'Leo':
        return (today, today);
      case 'Jana':
        final yesterday = today.subtract(const Duration(days: 1));
        return (yesterday, yesterday);
      case 'Wiki hii':
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        return (weekStart, today);
      case 'Wiki iliyopita':
        final lastWeekStart = today.subtract(Duration(days: today.weekday + 6));
        final lastWeekEnd = today.subtract(Duration(days: today.weekday));
        return (lastWeekStart, lastWeekEnd);
      case 'Mwezi huu':
        final monthStart = DateTime(now.year, now.month, 1);
        return (monthStart, today);
      case 'Mwezi uliopita':
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        final lastMonthEnd = DateTime(now.year, now.month, 0);
        return (lastMonth, lastMonthEnd);
      case 'Mwaka huu':
        final yearStart = DateTime(now.year, 1, 1);
        return (yearStart, today);
      case 'Mwaka uliopita':
        final lastYearStart = DateTime(now.year - 1, 1, 1);
        final lastYearEnd = DateTime(now.year - 1, 12, 31);
        return (lastYearStart, lastYearEnd);
      case 'Muda maalum':
        if (_customStartDate != null && _customEndDate != null) {
          return (_customStartDate!, _customEndDate!);
        }
        // If no custom dates are set, default to last 30 days
        return (today.subtract(const Duration(days: 30)), today);
      default:
        return (today.subtract(const Duration(days: 30)), today);
    }
  }

  // Method to set custom date range
  void setCustomDateRange(DateTime startDate, DateTime endDate) {
    _customStartDate = startDate;
    _customEndDate = endDate;
    notifyListeners();
  }
}