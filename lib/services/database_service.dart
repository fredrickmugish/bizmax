import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/business_record.dart';
import '../models/inventory_item.dart';
import '../models/note.dart';
import '../models/customer.dart';

class DatabaseService extends ChangeNotifier {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  static DatabaseService get instance => _instance;
  DatabaseService._internal();

  late Box<BusinessRecord> _recordsBox;
  late Box<InventoryItem> _inventoryBox;
  late Box<Note> _notesBox;
  late Box<Customer> _customersBox;

  Future<void> initialize() async {
    print('DatabaseService: Starting initialization...');
    _recordsBox = await Hive.openBox<BusinessRecord>('business_records');
    _inventoryBox = await Hive.openBox<InventoryItem>('inventory_items');
    _notesBox = await Hive.openBox<Note>('notes');
    _customersBox = await Hive.openBox<Customer>('customers');
    print('DatabaseService: Initialization completed - Records: ${_recordsBox.length}, Inventory: ${_inventoryBox.length}, Notes: ${_notesBox.length}, Customers: ${_customersBox.length}');
  }

  // Business Records
  Future<List<BusinessRecord>> getAllRecords() async {
    return _recordsBox.values.where((record) => record.isDeleted != true).toList();
  }

  Future<List<BusinessRecord>> getAllBusinessRecords() async {
    return getAllRecords();
  }

  Future<List<BusinessRecord>> getRecordsByType(String type) async {
    return _recordsBox.values.where((record) => record.type == type).toList();
  }

  Future<List<BusinessRecord>> getRecordsByDateRange(DateTime start, DateTime end) async {
    return _recordsBox.values.where((record) =>
      record.date.isAfter(start.subtract(const Duration(days: 1))) &&
      record.date.isBefore(end.add(const Duration(days: 1)))
    ).toList();
  }

  Future<Map<String, double>> getRevenueByPeriod(DateTime start, DateTime end) async {
    final records = await getRecordsByDateRange(start, end);
    final Map<String, double> revenueData = {};
    for (final record in records) {
      if (record.type == 'sale') {
        final dateKey = '${record.date.year}-${record.date.month}-${record.date.day}';
        revenueData[dateKey] = (revenueData[dateKey] ?? 0) + record.amount;
      }
    }
    return revenueData;
  }

  Future<BusinessRecord?> getRecordById(String id) async {
    return _recordsBox.get(id);
  }

  Future<void> insertRecord(BusinessRecord record) async {
    await _recordsBox.put(record.id, record);
    notifyListeners();
  }

  Future<void> saveBusinessRecord(BusinessRecord record) async {
    await insertRecord(record);
  }

  Future<void> insertBusinessRecord(BusinessRecord record) async {
    await insertRecord(record);
  }

  Future<void> upsertRecord(BusinessRecord record) async {
    await _recordsBox.put(record.id, record);
    notifyListeners();
  }

  Future<void> deleteRecord(String id) async {
    print('DatabaseService: Soft deleting record with ID: $id');
    final record = _recordsBox.get(id);
    if (record != null) {
      await _recordsBox.put(id, record.copyWith(isDeleted: true, isDirty: true));
      notifyListeners();
      print('DatabaseService: Record $id soft deleted.');
    }
  }

  Future<void> hardDeleteRecord(String id) async {
    print('DatabaseService: Hard deleting record with ID: $id');
    await _recordsBox.delete(id);
    notifyListeners();
    print('DatabaseService: Record $id hard deleted.');
  }

  // Inventory
  Future<List<InventoryItem>> getAllInventoryItems() async {
    return _inventoryBox.values.toList();
  }

  Future<InventoryItem?> getInventoryItemById(String id) async {
    return _inventoryBox.get(id);
  }

  Future<void> insertInventoryItem(InventoryItem item) async {
    await _inventoryBox.put(item.id, item);
    notifyListeners();
  }

  Future<void> upsertInventoryItem(InventoryItem item) async {
    await _inventoryBox.put(item.id, item);
    notifyListeners();
  }

  Future<void> updateInventoryItem(String id, InventoryItem updatedItem) async {
    await _inventoryBox.put(id, updatedItem.copyWith(
      id: id,
      updatedAt: DateTime.now(),
    ));
    notifyListeners();
  }

  Future<void> deleteInventoryItem(String id) async {
    final item = _inventoryBox.get(id);
    if (item != null) {
      await _inventoryBox.put(id, item.copyWith(isDeleted: true, isDirty: true));
      notifyListeners();
    }
  }

  Future<void> hardDeleteInventoryItem(String id) async {
    await _inventoryBox.delete(id);
    notifyListeners();
  }

  Future<void> updateStock(String itemId, int newQuantity) async {
    final item = _inventoryBox.get(itemId);
    if (item != null) {
      await _inventoryBox.put(itemId, item.copyWith(
        currentStock: newQuantity,
        updatedAt: DateTime.now(),
      ));
      notifyListeners();
    }
  }

  

  Future<bool> inventoryItemExists(String id) async {
    return _inventoryBox.containsKey(id);
  }

  Future<List<InventoryItem>> getLowStockItems() async {
    return _inventoryBox.values.where((item) => item.currentStock <= item.minimumStock).toList();
  }

  Future<double> getTotalInventoryValue() async {
    return _inventoryBox.values.fold<double>(0.0, (sum, item) => sum + (item.currentStock * item.buyingPrice));
  }

  Future<void> clearAllData() async {
    await _recordsBox.clear();
    await _inventoryBox.clear();
    await _notesBox.clear();
    await _customersBox.clear();
    notifyListeners();
  }

  Future<void> clearAllRecords() async {
    await _recordsBox.clear();
    notifyListeners();
  }

  Future<void> clearAllInventoryItems() async {
    await _inventoryBox.clear();
    notifyListeners();
  }

  Future<List<BusinessRecord>> getDirtyRecords() async {
    return _recordsBox.values.where((record) => record.isDirty == true || record.isDeleted == true).toList();
  }

  Future<List<InventoryItem>> getDirtyInventoryItems() async {
    return _inventoryBox.values.where((item) => item.isDirty == true || item.isDeleted == true).toList();
  }

  // Notes
  Future<List<Note>> getAllNotes() async {
    return _notesBox.values.toList();
  }

  Future<Note?> getNoteById(String id) async {
    return _notesBox.get(id);
  }

  Future<void> upsertNote(Note note) async {
    if (note.id != null) { // If it has a server-generated ID, use it as the key
      await _notesBox.put(note.id, note);
    } else if (note.key != null) { // If it's an existing Hive object with a local key
      await _notesBox.put(note.key, note);
    } else { // New note, let Hive generate a key
      await _notesBox.add(note);
    }
    notifyListeners();
  }

  Future<void> hardDeleteNote(String id) async {
    await _notesBox.delete(id);
    notifyListeners();
  }

  Future<void> hardDeleteNoteByLocalKey(int key) async {
    await _notesBox.delete(key);
    notifyListeners();
  }

  Future<List<Note>> getDirtyNotes() async {
    return _notesBox.values.where((note) => note.isDirty || note.isDeleted).toList();
  }

  Future<void> deleteNote(String id) async {
    final note = _notesBox.get(id);
    if (note != null) {
      await _notesBox.put(id, note.copyWith(isDeleted: true, isDirty: true));
      notifyListeners();
    }
  }

  // Customers
  Future<List<Customer>> getAllCustomers() async {
    return _customersBox.values.where((customer) => customer.isDeleted != true).toList();
  }

  Future<void> upsertCustomer(Customer customer) async {
    await _customersBox.put(customer.id, customer);
    notifyListeners();
  }

  Future<void> deleteCustomer(String id) async {
    final customer = _customersBox.get(id);
    if (customer != null) {
      await _customersBox.put(id, customer.copyWith(isDeleted: true, isDirty: true));
      notifyListeners();
    }
  }

  Future<void> hardDeleteCustomer(String id) async {
    await _customersBox.delete(id);
    notifyListeners();
  }

  Future<List<Customer>> getDirtyCustomers() async {
    return _customersBox.values.where((customer) => customer.isDirty == true || customer.isDeleted == true).toList();
  }

  Future<List<BusinessRecord>> getBusinessRecordsByTransactionId(String transactionId) async {
    return _recordsBox.values.where((record) => record.transactionId == transactionId && record.isDeleted != true).toList();
  }

  Future<Map<String, int>> getInventoryStats() async {
    return {
      'total_items': _inventoryBox.length,
      'low_stock_items': _inventoryBox.values.where((item) => item.currentStock <= item.minimumStock).length,
      'out_of_stock_items': _inventoryBox.values.where((item) => item.currentStock == 0).length
    };
  }

  Future<Map<String, dynamic>> getBusinessMetrics() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monthStart = DateTime(now.year, now.month, 1);
    final periodStart = DateTime(now.year, now.month, now.day); // For simplicity, period is today

    double totalRevenue = 0;
    double totalExpenses = 0;
    double totalPurchases = 0;
    double totalCostOfGoodsSold = 0;
    double totalPurchasesRevenueFunded = 0;

    double todayRevenue = 0;
    double todayExpenses = 0;
    double todayPurchases = 0;
    double todayCostOfGoodsSold = 0;

    double periodRevenue = 0;
    double periodExpenses = 0;
    double periodPurchases = 0;
    double periodCostOfGoodsSold = 0;
    double periodPurchasesRevenueFunded = 0;

    double monthlyRevenue = 0;

    for (final record in _recordsBox.values) {
      // Total calculations
      if (record.type == 'sale') {
        totalRevenue += record.amount;
        totalCostOfGoodsSold += record.costOfGoodsSold ?? 0;
      } else if (record.type == 'expense') {
        totalExpenses += record.amount;
      } else if (record.type == 'purchase') {
        totalPurchases += record.amount;
        if (record.fundingSource == 'revenue') {
          totalPurchasesRevenueFunded += record.amount;
        }
      }

      // Today's calculations
      if (record.date.year == today.year && record.date.month == today.month && record.date.day == today.day) {
        if (record.type == 'sale') {
          todayRevenue += record.amount;
          todayCostOfGoodsSold += record.costOfGoodsSold ?? 0;
        } else if (record.type == 'expense') {
          todayExpenses += record.amount;
        } else if (record.type == 'purchase') {
          todayPurchases += record.amount;
        }
      }

      // Monthly calculations
      if (record.date.year == monthStart.year && record.date.month == monthStart.month) {
        if (record.type == 'sale') {
          monthlyRevenue += record.amount;
        }
      }

      // Period calculations (for simplicity, using today as period)
      if (record.date.year == periodStart.year && record.date.month == periodStart.month && record.date.day == periodStart.day) {
        if (record.type == 'sale') {
          periodRevenue += record.amount;
          periodCostOfGoodsSold += record.costOfGoodsSold ?? 0;
        } else if (record.type == 'expense') {
          periodExpenses += record.amount;
        } else if (record.type == 'purchase') {
          periodPurchases += record.amount;
          if (record.fundingSource == 'revenue') {
            periodPurchasesRevenueFunded += record.amount;
          }
        }
      }
    }

    final totalProducts = _inventoryBox.length;
    final lowStockItems = _inventoryBox.values.where((item) => item.currentStock <= item.minimumStock).length;
    final outOfStockItems = _inventoryBox.values.where((item) => item.currentStock == 0).length;
    final totalStockValue = _inventoryBox.values.fold<double>(0.0, (sum, item) => sum + (item.currentStock * item.buyingPrice));

    return {
      'total_revenue': totalRevenue,
      'total_expenses': totalExpenses,
      'total_profit': totalRevenue - totalExpenses, // Simple profit
      'total_cost_of_goods_sold': totalCostOfGoodsSold,
      'total_gross_profit': totalRevenue - totalCostOfGoodsSold,
      'total_net_profit': totalRevenue - totalCostOfGoodsSold - totalExpenses,
      'total_purchases_revenue_funded': totalPurchasesRevenueFunded,
      'total_purchases_personal_funded': totalPurchases - totalPurchasesRevenueFunded,
      'total_purchases': totalPurchases,

      'today_revenue': todayRevenue,
      'today_expenses': todayExpenses,
      'today_profit': todayRevenue - todayExpenses,
      'today_cost_of_goods_sold': todayCostOfGoodsSold,
      'today_gross_profit': todayRevenue - todayCostOfGoodsSold,
      'today_net_profit': todayRevenue - todayCostOfGoodsSold - todayExpenses,
      'today_purchases': todayPurchases,

      'monthly_revenue': monthlyRevenue,
      'monthly_profit': monthlyRevenue - totalExpenses, // Simple monthly profit

      'period_revenue': periodRevenue,
      'period_expenses': periodExpenses,
      'period_profit': periodRevenue - periodExpenses,
      'period_cost_of_goods_sold': periodCostOfGoodsSold,
      'period_gross_profit': periodRevenue - periodCostOfGoodsSold,
      'period_net_profit': periodRevenue - periodCostOfGoodsSold - periodExpenses,
      'period_purchases_revenue_funded': periodPurchasesRevenueFunded,
      'period_purchases_personal_funded': periodPurchases - periodPurchasesRevenueFunded,
      'period_purchases': periodPurchases,

      'total_products': totalProducts,
      'low_stock_items': lowStockItems,
      'out_of_stock_items': outOfStockItems,
      'total_stock_value': totalStockValue,

      // Placeholder for business health (can be calculated based on metrics)
      'business_health': {
        'score': 70,
        'status': 'good',
        'status_text': 'Biashara Ina Afya Nzuri',
      },
      // Placeholder for sales trends (can be derived from records)
      'sales_trends': [], // This would typically be a list of daily/monthly sales
      // Placeholder for quick stats (can be derived from metrics)
      'quick_stats': {
        'total_customers': 0, // Needs customer data
        'total_debt': 0, // Needs debt data
      },
    };
  }

  Future<Map<String, dynamic>> getDashboardData() async {
    final businessMetrics = await getBusinessMetrics();
    final recentActivities = await getAllRecords();
    final topProducts = await getTopSellingProducts();
    final lowStockItems = await getLowStockItems();

    return {
      'business_metrics': businessMetrics,
      'recent_activities': recentActivities.map((e) => e.toJson()).toList(),
      'top_products': topProducts,
      'low_stock_alerts': lowStockItems.map((e) => e.toJson()).toList(),
    };
  }

  Future<List<Map<String, dynamic>>> getTopSellingProducts() async {
    final Map<String, Map<String, dynamic>> productSales = {};
    
    for (final record in _recordsBox.values) {
      if (record.type == 'sale') {
        // Use description as product name for now
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
    }
    
    // Convert to list and sort by revenue
    final sortedProducts = productSales.values.toList()
      ..sort((a, b) => (b['revenue'] ?? 0.0).compareTo(a['revenue'] ?? 0.0));
    
    return sortedProducts;
  }
}
