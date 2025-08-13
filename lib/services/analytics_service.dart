import '../models/business_metrics.dart';
import '../models/business_record.dart';
import '../models/inventory_item.dart';
import 'database_service.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  static AnalyticsService get instance => _instance;
  AnalyticsService._internal();

  final DatabaseService _db = DatabaseService.instance;

  Future<BusinessMetrics> calculateBusinessMetrics() async {
    try {
      print('AnalyticsService: Starting to calculate business metrics...');
      final records = await _db.getAllRecords();
      print('AnalyticsService: Retrieved ${records.length} records from database');
      
      final inventoryItems = await _db.getAllInventoryItems();
      print('AnalyticsService: Retrieved ${inventoryItems.length} inventory items from database');
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final monthStart = DateTime(now.year, now.month, 1);

      // Calculate totals
      double totalRevenue = 0;
      double totalExpenses = 0;
      double todayRevenue = 0;
      double todayExpenses = 0;
      double monthlyRevenue = 0;

      for (final record in records) {
        if (record.type == 'sale') {
          totalRevenue += record.amount;
          if (record.date.isAfter(today.subtract(const Duration(days: 1)))) {
            todayRevenue += record.amount;
          }
          if (record.date.isAfter(monthStart.subtract(const Duration(days: 1)))) {
            monthlyRevenue += record.amount;
          }
        } else if (record.type == 'expense' || record.type == 'purchase') {
          totalExpenses += record.amount;
          if (record.date.isAfter(today.subtract(const Duration(days: 1)))) {
            todayExpenses += record.amount;
          }
        }
      }

      print('AnalyticsService: Calculated - Total Revenue: $totalRevenue, Total Expenses: $totalExpenses');

      // Calculate low stock items
      final lowStockItems = inventoryItems
          .where((item) => item.quantity <= item.minStockLevel)
          .length;

      final metrics = BusinessMetrics(
        totalRevenue: totalRevenue,
        totalExpenses: totalExpenses,
        totalProfit: totalRevenue - totalExpenses,
        todayRevenue: todayRevenue,
        todayExpenses: todayExpenses,
        todayPurchases: 0.0, // TODO: Calculate today's purchases
        todayProfit: todayRevenue - todayExpenses,
        monthlyRevenue: monthlyRevenue,
        monthlyProfit: monthlyRevenue - totalExpenses,
        lowStockItems: lowStockItems,
        pendingOrders: 0, // TODO: Implement orders
        totalCustomers: _getUniqueCustomers(records),
        totalCostOfGoodsSold: 0.0, // TODO: Calculate from sales records
        totalGrossProfit: totalRevenue - 0.0, // TODO: Calculate with COGS
        totalNetProfit: (totalRevenue - 0.0) - totalExpenses, // TODO: Calculate with COGS
        periodCostOfGoodsSold: 0.0, // TODO: Calculate for current period
        periodGrossProfit: monthlyRevenue - 0.0, // TODO: Calculate with COGS
        periodNetProfit: (monthlyRevenue - 0.0) - totalExpenses, // TODO: Calculate with COGS
        todayCostOfGoodsSold: 0.0, // TODO: Calculate for today
        todayGrossProfit: todayRevenue - 0.0, // TODO: Calculate with COGS
        todayNetProfit: (todayRevenue - 0.0) - todayExpenses, // TODO: Calculate with COGS
        periodExpenses: totalExpenses, // Using total expenses as period expenses for now
        totalPurchasesRevenueFunded: 0.0, // TODO: Calculate from purchase records
        totalPurchasesPersonalFunded: 0.0, // TODO: Calculate from purchase records
        periodPurchasesRevenueFunded: 0.0, // TODO: Calculate for current period
        periodPurchasesPersonalFunded: 0.0, // TODO: Calculate for current period
      );
      
      print('AnalyticsService: Business metrics calculation completed');
      return metrics;
    } catch (e) {
      print('AnalyticsService: Error calculating business metrics: $e');
      return BusinessMetrics.empty();
    }
  }

  int _getUniqueCustomers(List<BusinessRecord> records) {
    final customers = records
        .where((r) => r.type == 'sale' && r.customerName != null)
        .map((r) => r.customerName!)
        .toSet();
    return customers.length;
  }

  Future<List<BusinessRecord>> getRecentTransactions({int limit = 10}) async {
    try {
      final records = await _db.getAllRecords();
      records.sort((a, b) => b.date.compareTo(a.date));
      return records.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, double>> getMonthlySales() async {
    try {
      final records = await _db.getAllRecords();
      final salesRecords = records.where((r) => r.type == 'sale').toList();
      
      final Map<String, double> monthlySales = {};
      
      for (final record in salesRecords) {
        final monthKey = '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}';
        monthlySales[monthKey] = (monthlySales[monthKey] ?? 0) + record.amount;
      }
      
      return monthlySales;
    } catch (e) {
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getMonthlyTrends() async {
    try {
      final records = await _db.getAllRecords();
      final Map<String, Map<String, double>> monthlyData = {};

      for (final record in records) {
        final monthKey = '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}';
        
        if (!monthlyData.containsKey(monthKey)) {
          monthlyData[monthKey] = {
            'sales': 0.0,
            'expenses': 0.0,
            'profit': 0.0,
          };
        }

        if (record.type == 'sale') {
          monthlyData[monthKey]!['sales'] = 
              (monthlyData[monthKey]!['sales'] ?? 0) + record.amount;
        } else if (record.type == 'expense' || record.type == 'purchase') {
          monthlyData[monthKey]!['expenses'] = 
              (monthlyData[monthKey]!['expenses'] ?? 0) + record.amount;
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
      return [];
    }
  }

  Future<Map<String, double>> getExpensesByCategory() async {
    try {
      final records = await _db.getAllRecords();
      final expenseRecords = records.where((r) => 
          r.type == 'expense' || r.type == 'purchase').toList();
      
      final Map<String, double> categoryExpenses = {};
      
      for (final record in expenseRecords) {
        final category = record.category ?? 'Nyingine';
        categoryExpenses[category] = (categoryExpenses[category] ?? 0) + record.amount;
      }
      
      return categoryExpenses;
    } catch (e) {
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getTopSellingProducts() async {
    try {
      final records = await _db.getAllRecords();
      final salesRecords = records.where((r) => r.type == 'sale').toList();
      
      final Map<String, Map<String, dynamic>> productSales = {};
      
      for (final record in salesRecords) {
        // This assumes the description contains product info
        // In a real app, you'd have a proper product-sales relationship
        final productName = record.description;
        
        if (!productSales.containsKey(productName)) {
          productSales[productName] = {
            'name': productName,
            'totalSales': 0.0,
            'quantity': 0,
          };
        }
        
        productSales[productName]!['totalSales'] = 
            (productSales[productName]!['totalSales'] as double) + record.amount;
        productSales[productName]!['quantity'] = 
            (productSales[productName]!['quantity'] as int) + 1;
      }
      
      final topProducts = productSales.values.toList();
      topProducts.sort((a, b) => 
          (b['totalSales'] as double).compareTo(a['totalSales'] as double));
      
      return topProducts.take(10).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, int>> getStockLevels() async {
    try {
      final items = await _db.getAllInventoryItems();
      final Map<String, int> stockLevels = {};
      
      for (final item in items) {
        if (item.quantity <= 0) {
          stockLevels['out_of_stock'] = (stockLevels['out_of_stock'] ?? 0) + 1;
        } else if (item.quantity <= item.minStockLevel) {
          stockLevels['low_stock'] = (stockLevels['low_stock'] ?? 0) + 1;
        } else {
          stockLevels['good_stock'] = (stockLevels['good_stock'] ?? 0) + 1;
        }
      }
      
      return stockLevels;
    } catch (e) {
      return {};
    }
  }

  Future<double> calculateInventoryValue() async {
    try {
      final items = await _db.getAllInventoryItems();
      double totalValue = 0;
      
      for (final item in items) {
        totalValue += item.quantity * item.sellingPrice;
      }
      
      return totalValue;
    } catch (e) {
      return 0.0;
    }
  }

  Future<List<Map<String, dynamic>>> getDailySalesData({int days = 30}) async {
    try {
      final records = await _db.getAllRecords();
      final salesRecords = records.where((r) => r.type == 'sale').toList();
      
      final Map<String, double> dailySales = {};
      final now = DateTime.now();
      
      // Initialize with zeros for the last 'days' days
      for (int i = 0; i < days; i++) {
        final date = now.subtract(Duration(days: i));
        final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        dailySales[dateKey] = 0.0;
      }
      
      // Fill with actual sales data
      for (final record in salesRecords) {
        final dateKey = '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}-${record.date.day.toString().padLeft(2, '0')}';
        if (dailySales.containsKey(dateKey)) {
          dailySales[dateKey] = (dailySales[dateKey] ?? 0) + record.amount;
        }
      }
      
      // Convert to list and sort by date
      final salesData = dailySales.entries.map((entry) {
        return {
          'date': entry.key,
          'sales': entry.value,
        };
      }).toList();
      
      salesData.sort((a, b) => a['date'].toString().compareTo(b['date'].toString()));
      
      return salesData;
    } catch (e) {
      return [];
    }
  }
}
