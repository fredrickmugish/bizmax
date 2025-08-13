import 'package:flutter/foundation.dart';
import '../models/business_metrics.dart';
import '../services/api_service.dart';
import 'package:hive/hive.dart';
import 'package:flutter/material.dart';


class BusinessProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  BusinessMetrics _metrics = BusinessMetrics.empty();
  bool _isLoading = false;
  List<dynamic> _recentActivities = [];
  List<dynamic> _salesTrends = [];
  List<dynamic> _topProducts = [];

  // --- REINSTATE THESE PROPERTIES ---
  Map<String, dynamic> _businessHealth = {};
  Map<String, dynamic> _quickStats = {};
  // ----------------------------------


  // Business info
  String _businessName = 'Bizmax';
  String _businessType = 'Duka la Jumla';
  String _businessAddress = 'P.O.BOX 4115 DODOMA'; // New field
  static const String _settingsBoxName = 'business_settings';


  BusinessProvider() {
    _loadBusinessSettings();
  }


  // Getters
  BusinessMetrics get metrics => _metrics;
  bool get isLoading => _isLoading;
  List<dynamic> get recentActivities => _recentActivities;
  List<dynamic> get salesTrends => _salesTrends;
  List<dynamic> get topProducts => _topProducts;

  // --- REINSTATE THESE GETTERS ---
  Map<String, dynamic> get businessHealth => _businessHealth;
  Map<String, dynamic> get quickStats => _quickStats;
  // ----------------------------------


  // Delegate getters to metrics object (these are fine)
  double get totalRevenue => _metrics.totalRevenue;
  double get totalExpenses => _metrics.totalExpenses;
  double get totalProfit => _metrics.totalProfit;
  double get todayRevenue => _metrics.todayRevenue;
  double get todayExpenses => _metrics.todayExpenses;
  double get todayProfit => _metrics.todayProfit;
  double get monthlyRevenue => _metrics.monthlyRevenue;
  double get monthlyProfit => _metrics.monthlyProfit;
  int get lowStockItems => _metrics.lowStockItems;
  int get pendingOrders => _metrics.pendingOrders;
  int get totalCustomers => _metrics.totalCustomers;


  String get businessName => _businessName;
  String get businessType => _businessType;
  String get businessAddress => _businessAddress; // New getter


  void setMetrics(BusinessMetrics metrics) {
    _metrics = metrics;
    notifyListeners();
  }

  void setRecentActivities(List<dynamic> activities) {
    _recentActivities = activities;
    notifyListeners();
  }

  void setSalesTrends(List<dynamic> trends) {
    _salesTrends = trends;
    notifyListeners();
  }

  void setTopProducts(List<dynamic> products) {
    _topProducts = products;
    notifyListeners();
  }

  // --- REINSTATE THESE SETTERS ---
  void setBusinessHealth(Map<String, dynamic> health) {
    _businessHealth = health;
    notifyListeners();
  }

  void setQuickStats(Map<String, dynamic> stats) {
    _quickStats = stats;
    notifyListeners();
  }
  // ----------------------------------


  Future<void> _loadBusinessSettings([String? businessId]) async {
    if (businessId == null) {
      if (kDebugMode) {
        print('BusinessProvider: _loadBusinessSettings called with null businessId. Skipping settings load.');
      }
      return;
    }

    final box = await Hive.openBox(_settingsBoxName);
    _businessName = box.get('businessName_$businessId', defaultValue: 'Bizmax');
    _businessType = box.get('businessType_$businessId', defaultValue: 'Duka la Jumla');
    _businessAddress = box.get('businessAddress_$businessId', defaultValue: 'P.O.BOX 4115 DODOMA'); // Load address
    notifyListeners();
  }


  Future<void> setBusinessName(String name, String businessId) async {
    _businessName = name;
    final box = await Hive.openBox(_settingsBoxName);
    await box.put('businessName_$businessId', name);
    notifyListeners();
  }


  Future<void> setBusinessType(String type, String businessId) async {
    _businessType = type;
    final box = await Hive.openBox(_settingsBoxName);
    await box.put('businessType_$businessId', type);
    notifyListeners();
  }

  Future<void> setBusinessAddress(String address, String businessId) async {
    _businessAddress = address;
    final box = await Hive.openBox(_settingsBoxName);
    await box.put('businessAddress_$businessId', address);
    notifyListeners();
  }


  // Load all business data
  Future<void> loadBusinessData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final metricsData = await _apiService.getDashboardMetrics();
      _metrics = BusinessMetrics.fromApiJson(metricsData);

      final dashboardData = await _apiService.getDashboardData();
      _recentActivities = dashboardData['recent_activities'] is List
          ? dashboardData['recent_activities'] as List
          : [];

      final salesTrendsData = await _apiService.getSalesTrends();
      _salesTrends = salesTrendsData is List
          ? salesTrendsData as List
          : [];

      final topProductsData = await _apiService.getTopProducts();
      _topProducts = topProductsData is List
          ? topProductsData as List
          : [];

      // --- POPULATE THESE PROPERTIES FROM API RESPONSE ---
      _businessHealth = dashboardData['business_health'] is Map<String, dynamic>
          ? dashboardData['business_health'] as Map<String, dynamic>
          : {};
      _quickStats = dashboardData['quick_stats'] is Map<String, dynamic>
          ? dashboardData['quick_stats'] as Map<String, dynamic>
          : {};
      // ----------------------------------------------------

      if (kDebugMode) {
        print('BusinessProvider: Successfully loaded all business data.');
      }

    } catch (e) {
      if (kDebugMode) {
        print('BusinessProvider: Error loading business data: $e');
      }
      _metrics = BusinessMetrics.empty();
      _recentActivities = [];
      _salesTrends = [];
      _topProducts = [];
      // --- RESET THESE PROPERTIES ON ERROR ---
      _businessHealth = {};
      _quickStats = {};
      // ---------------------------------------

      rethrow;

    } finally {
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) {
        print('BusinessProvider: loadBusinessData completed. _isLoading: $_isLoading');
      }
    }
  }


  Future<void> refreshData() async {
    await loadBusinessData();
  }


  void loadForBusiness(String? businessId) {
    _loadBusinessSettings(businessId);
  }
}