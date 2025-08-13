// lib/screens/dashboard_screen.dart

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb

import '../providers/auth_provider.dart';
import '../providers/business_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/records_provider.dart';
import '../providers/notifications_provider.dart';
import '../services/api_exception.dart'; // Ensure this is correctly imported
import '../services/api_service.dart'; // Import ApiService
import '../services/database_service.dart';
import '../models/business_metrics.dart'; // Import BusinessMetrics
import '../models/inventory_item.dart'; // Import InventoryItem
import '../models/business_record.dart'; // Import BusinessRecord
import '../utils/app_routes.dart';
// import '../widgets/business_health_indicator.dart'; // Not used in this file
import '../widgets/business_metrics_cards.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/recent_activities_list.dart';
// import '../widgets/sidebar_scaffold.dart'; // Not used directly in DashboardScreen

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Local state to manage data loading success/failure for UI feedback
  bool _hasDataLoadError = false;

  // In-memory cache for dashboard data
  static Map<String, dynamic>? _dashboardCache;
  bool _isInitialLoad = true;

  // Data holders for main metrics (initialized in initState or read from context)
  // No need for these as instance variables if you always use context.read/watch
  // BusinessProvider? _businessProvider;
  // InventoryProvider? _inventoryProvider;
  // RecordsProvider? _recordsProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // These are not needed as instance variables if you always read from context
      // _businessProvider = context.read<BusinessProvider>();
      // _inventoryProvider = context.read<InventoryProvider>();
      // _recordsProvider = context.read<RecordsProvider>();

      _loadAllData(); // No need for showLoadingIndicator as we handle loading state in build
      // Load notifications as soon as dashboard is shown
      final notificationsProvider = context.read<NotificationsProvider>();
      // Ensure providers are not null before passing to setProviders
      // This might require `RecordsProvider` and `InventoryProvider` to be fully initialized or to
      // load their data first. If they load async, handle nulls or pass future values.
      // For now, assuming they are available after initial data load in _loadAllData if needed.
      notificationsProvider.setProviders(context.read<RecordsProvider>(), context.read<InventoryProvider>());
      notificationsProvider.loadNotifications(context);
    });
  }

  /// Loads all necessary dashboard data from various providers.
  /// Includes basic error handling and updates local error state.
  Future<void> _loadAllData() async {
    if (!mounted) return;

    final businessProvider = context.read<BusinessProvider>();
    final inventoryProvider = context.read<InventoryProvider>();
    final recordsProvider = context.read<RecordsProvider>();
    final authProvider = context.read<AuthProvider>();
    final connectivityResult = await Connectivity().checkConnectivity();

    try {
      if (mounted) {
        setState(() {
          _hasDataLoadError = false;
        });
      }

      if (kIsWeb) {
        // Web: Always fetch from API
        print('DashboardScreen: Web platform. Loading data from API.');
        await _loadDataFromApi(businessProvider, inventoryProvider, recordsProvider, authProvider);
      } else {
        // Mobile: Check connectivity
        if (connectivityResult == ConnectivityResult.none) {
          // Offline mode
          print('DashboardScreen: Offline mode detected. Loading data from local database.');
          await _loadDataFromDatabase(businessProvider, inventoryProvider, recordsProvider, authProvider);
        } else {
          // Online mode
          print('DashboardScreen: Online mode detected. Loading data from API.');
          await _loadDataFromApi(businessProvider, inventoryProvider, recordsProvider, authProvider);
        }
      }
    } catch (e, stackTrace) {
      print('Error in _loadAllData: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _hasDataLoadError = true;
        });
      }
    }
  }

  Future<void> _loadDataFromDatabase(
      BusinessProvider businessProvider,
      InventoryProvider inventoryProvider,
      RecordsProvider recordsProvider,
      AuthProvider authProvider) async {
    final db = DatabaseService.instance;

    final dashboardData = await db.getDashboardData();

    // Load business metrics with safe parsing
    final businessMetrics = dashboardData['business_metrics'];
    if (businessMetrics != null && businessMetrics is Map<String, dynamic>) {
      businessProvider.setMetrics(BusinessMetrics.fromApiJson(businessMetrics));
    }

    // Load other business data safely
    businessProvider.setRecentActivities(
      _safelyParseList(dashboardData['recent_activities'])
    );
    businessProvider.setSalesTrends(
      _safelyParseList(dashboardData['sales_trends'])
    );
    businessProvider.setTopProducts(
      _safelyParseList(dashboardData['top_products'])
    );
    businessProvider.setBusinessHealth(
      _safelyParseMap(dashboardData['business_health'])
    );
    businessProvider.setQuickStats(
      _safelyParseMap(dashboardData['quick_stats'])
    );

    // Load inventory items safely
    final inventoryItems = _safelyParseList(dashboardData['inventory_items'])
        .where((item) => item != null)
        .map((item) => InventoryItem.fromJson(item))
        .toList();
    inventoryProvider.setItems(inventoryItems);

    final lowStockItems = _safelyParseList(dashboardData['low_stock_alerts'])
        .where((item) => item != null)
        .map((item) => InventoryItem.fromJson(item))
        .toList();
    inventoryProvider.setLowStockItems(lowStockItems);

    // Load recent activities safely
    final recentActivities = _safelyParseList(dashboardData['recent_activities'])
        .where((record) => record != null)
        .map((record) => BusinessRecord.fromJson(record))
        .toList();
    recordsProvider.setRecords(recentActivities);

    // Update user and business names safely
    final userName = dashboardData['user_name']?.toString();
    final businessName = dashboardData['business_name']?.toString();
    final businessAddress = dashboardData['business_address']?.toString(); // Get business address

    if (userName != null && userName.isNotEmpty) {
      authProvider.updateUserDisplayName(userName);
    }
    if (businessName != null && businessName.isNotEmpty && authProvider.user?['id'] != null) {
      businessProvider.setBusinessName(businessName, authProvider.user!['id'].toString());
    }
    if (businessAddress != null && businessAddress.isNotEmpty && authProvider.user?['id'] != null) {
      businessProvider.setBusinessAddress(businessAddress, authProvider.user!['id'].toString());
    }
  }

  Future<void> _loadDataFromApi(
      BusinessProvider businessProvider,
      InventoryProvider inventoryProvider,
      RecordsProvider recordsProvider,
      AuthProvider authProvider) async {
    try {
      if (_dashboardCache != null && _isInitialLoad) {
        _loadCachedData(businessProvider, inventoryProvider, recordsProvider, authProvider);
        if (mounted) setState(() {});
        _isInitialLoad = false;
      }

      final dashboardData = await ApiService().getDashboardSummary();
      await _loadFreshData(dashboardData, businessProvider, inventoryProvider, recordsProvider, authProvider);
      _dashboardCache = dashboardData;
      _isInitialLoad = false;
    } on ApiException catch (e) {
      print('API Exception in _loadDataFromApi: ${e.message}');
      if (mounted) {
        setState(() {
          _hasDataLoadError = true;
        });
      }
    }
  }

  void _loadCachedData(BusinessProvider businessProvider, InventoryProvider inventoryProvider, 
                      RecordsProvider recordsProvider, AuthProvider authProvider) {
    final cache = _dashboardCache!;
    
    // Load business metrics with safe parsing
    final businessMetrics = cache['business_metrics'];
    if (businessMetrics != null && businessMetrics is Map<String, dynamic>) {
      businessProvider.setMetrics(BusinessMetrics.fromApiJson(businessMetrics));
    }

    // Load other business data safely
    businessProvider.setRecentActivities(
      _safelyParseList(cache['recent_activities'])
    );
    businessProvider.setSalesTrends(
      _safelyParseList(cache['sales_trends'])
    );
    businessProvider.setTopProducts(
      _safelyParseList(cache['top_products'])
    );
    businessProvider.setBusinessHealth(
      _safelyParseMap(cache['business_health'])
    );
    businessProvider.setQuickStats(
      _safelyParseMap(cache['quick_stats'])
    );

    // Load inventory items safely
    final inventoryItems = _safelyParseList(cache['inventory_items'])
        .where((item) => item != null)
        .map((item) => InventoryItem.fromJson(item))
        .toList();
    inventoryProvider.setItems(inventoryItems);

    final lowStockItems = _safelyParseList(cache['low_stock_alerts'])
        .where((item) => item != null)
        .map((item) => InventoryItem.fromJson(item))
        .toList();
    inventoryProvider.setLowStockItems(lowStockItems);

    // Load recent activities safely
    final recentActivities = _safelyParseList(cache['recent_activities'])
        .where((record) => record != null)
        .map((record) => BusinessRecord.fromJson(record))
        .toList();
    recordsProvider.setRecords(recentActivities);

    // Update user and business names safely
    final cachedUserName = cache['user_name']?.toString();
    final cachedBusinessName = cache['business_name']?.toString();
    final cachedBusinessAddress = cache['business_address']?.toString();
    final cachedUserPhone = cache['phone']?.toString();

    if (cachedUserName != null && cachedUserName.isNotEmpty) {
      authProvider.updateUserDisplayName(cachedUserName);
    }
    if (cachedBusinessName != null && cachedBusinessName.isNotEmpty && authProvider.user?['id'] != null) {
      businessProvider.setBusinessName(cachedBusinessName, authProvider.user!['id'].toString());
    }
    if (cachedBusinessAddress != null && cachedBusinessAddress.isNotEmpty && authProvider.user?['id'] != null) {
      businessProvider.setBusinessAddress(cachedBusinessAddress, authProvider.user!['id'].toString());
    }
    if (cachedUserPhone != null && cachedUserPhone.isNotEmpty && authProvider.user?['id'] != null) {
      authProvider.updateUserPhone(cachedUserPhone);
    }
  }

  Future<void> _loadFreshData(Map<String, dynamic> dashboardData, BusinessProvider businessProvider, 
                             InventoryProvider inventoryProvider, RecordsProvider recordsProvider, 
                             AuthProvider authProvider) async {
    // Load business metrics with safe parsing
    final businessMetrics = dashboardData['business_metrics'];
    if (businessMetrics != null && businessMetrics is Map<String, dynamic>) {
      businessProvider.setMetrics(BusinessMetrics.fromApiJson(businessMetrics));
    }

    // Load other business data safely
    businessProvider.setRecentActivities(
      _safelyParseList(dashboardData['recent_activities'])
    );
    businessProvider.setSalesTrends(
      _safelyParseList(dashboardData['sales_trends'])
    );
    businessProvider.setTopProducts(
      _safelyParseList(dashboardData['top_products'])
    );
    businessProvider.setBusinessHealth(
      _safelyParseMap(dashboardData['business_health'])
    );
    businessProvider.setQuickStats(
      _safelyParseMap(dashboardData['quick_stats'])
    );

    // Load inventory items safely
    final inventoryItems = _safelyParseList(dashboardData['inventory_items'])
        .where((item) => item != null)
        .map((item) => InventoryItem.fromJson(item))
        .toList();
    inventoryProvider.setItems(inventoryItems);

    final lowStockItems = _safelyParseList(dashboardData['low_stock_alerts'])
        .where((item) => item != null)
        .map((item) => InventoryItem.fromJson(item))
        .toList();
    inventoryProvider.setLowStockItems(lowStockItems);

    // Load recent activities safely
    final recentActivities = _safelyParseList(dashboardData['recent_activities'])
        .where((record) => record != null)
        .map((record) => BusinessRecord.fromJson(record))
        .toList();
    recordsProvider.setRecords(recentActivities);

    // Update user and business names safely
    final userName = dashboardData['user_name']?.toString();
    final businessName = dashboardData['business_name']?.toString();
    final businessAddress = dashboardData['business_address']?.toString();
    final userPhone = dashboardData['phone']?.toString();

    if (userName != null && userName.isNotEmpty) {
      authProvider.updateUserDisplayName(userName);
    }
    if (businessName != null && businessName.isNotEmpty && authProvider.user?['id'] != null) {
      businessProvider.setBusinessName(businessName, authProvider.user!['id'].toString());
    }
    if (businessAddress != null && businessAddress.isNotEmpty && authProvider.user?['id'] != null) {
      businessProvider.setBusinessAddress(businessAddress, authProvider.user!['id'].toString());
    }
    if (userPhone != null && userPhone.isNotEmpty && authProvider.user?['id'] != null) {
      authProvider.updateUserPhone(userPhone);
    }
  }

  List<dynamic> _safelyParseList(dynamic value) {
    if (value is List) return value;
    return [];
  }

  Map<String, dynamic> _safelyParseMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    return {};
  }

  /// Builds the main UI for the Dashboard screen.
  @override
  Widget build(BuildContext context) {
    print('DashboardScreen: build called');
    final authProvider = context.watch<AuthProvider>();
    final businessProvider = context.watch<BusinessProvider>();
    final inventoryProvider = context.watch<InventoryProvider>();
    final recordsProvider = context.watch<RecordsProvider>();

    // Consolidate loading states
    final bool isLoadingAnyProvider = authProvider.isLoading ||
        businessProvider.isLoading ||
        inventoryProvider.isLoading ||
        recordsProvider.isLoading;

    // Determine if we should show a full loading indicator
    final bool showFullPageLoader = isLoadingAnyProvider && (_dashboardCache == null || _isInitialLoad);

    final businessName = businessProvider.businessName; // Use the watched provider

    final isLargeWeb = kIsWeb && MediaQuery.of(context).size.width >= 840;
    final isSmallWeb = kIsWeb && MediaQuery.of(context).size.width < 840;

    final bodyContent = showFullPageLoader
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadAllData,
            child: isLargeWeb
                ? _buildWebLayout(authProvider, businessName)
                : _buildMobileLayout(authProvider, businessName),
          );

    if (isLargeWeb) {
      return bodyContent;
    } else if (isSmallWeb) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
          actions: [
            Consumer<NotificationsProvider>(
              builder: (context, notificationsProvider, child) {
                final unreadCount = notificationsProvider.unreadCount;
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                      tooltip: 'Notifications',
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.notifications),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white),
              tooltip: 'Settings',
              onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
            ),
          ],
        ),
        body: bodyContent,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showQuickRecordDialog(context),
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Rekodi Haraka'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      );
    } else {
      // Mobile layout
      return Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          actions: [
            Consumer<NotificationsProvider>(
              builder: (context, notificationsProvider, child) {
                final unreadCount = notificationsProvider.unreadCount;
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                      tooltip: 'Notifications',
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.notifications),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white),
              tooltip: 'Settings',
              onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () => _showLogoutConfirmationDialog(context),
            ),
          ],
        ),
        body: bodyContent,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showQuickRecordDialog(context),
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Rekodi Haraka'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      );
    }
  }

  /// Builds the layout for web (larger screens).
  Widget _buildWebLayout(AuthProvider authProvider, String businessName) {
    // This Scaffold is typically handled by a higher-level SidebarScaffold for consistent navigation on web.
    // If you're not using SidebarScaffold, then this is fine.
    return Scaffold(
      appBar: AppBar(
        title: _buildWebHeader(authProvider, businessName),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          Consumer<NotificationsProvider>(
            builder: (context, notificationsProvider, child) {
              final unreadCount = notificationsProvider.unreadCount;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                    tooltip: 'Notifications',
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.notifications),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            tooltip: 'Settings',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
            style: IconButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _showQuickRecordDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Rekodi Haraka'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _showLogoutConfirmationDialog(context), // Use the helper function
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // if (_hasDataLoadError) // Show error card only if there's an error
            //   Card(
            //     color: Colors.red.shade50,
            //     margin: const EdgeInsets.only(bottom: 24),
            //     child: const Padding(
            //       padding: EdgeInsets.all(16),
            //       child: Row(
            //         children: [
            //           Icon(Icons.error_outline, color: Colors.red),
            //           SizedBox(width: 12),
            //           Expanded(
            //             child: Text(
            //               'Imeshindwa kupakia baadhi ya data. Vuta chini ili kujaribu tena.', // Swahili message
            //               style: TextStyle(color: Colors.red),
            //             ),
            //           ),
            //         ],
            //       ),
            //     ),
            //   ),
            _buildWelcomeSection(authProvider.user?['name'], businessName, isLoading: authProvider.isLoading),
            const SizedBox(height: 24),
            const BusinessMetricsCards(),
            const SizedBox(height: 32),
            const QuickActionsGrid(),
            const SizedBox(height: 32),
            // Defer loading of RecentActivitiesList for perceived performance
            FutureBuilder<void>(
              future: Future.delayed(const Duration(milliseconds: 100)),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                return const RecentActivitiesList();
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// Builds the layout for mobile (smaller screens).
  Widget _buildMobileLayout(AuthProvider authProvider, String businessName) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // if (_hasDataLoadError) // Show error card only if there's an error
          //   Card(
          //     color: Colors.red.shade50,
          //     margin: const EdgeInsets.only(bottom: 16),
          //     child: const Padding(
          //       padding: EdgeInsets.all(12),
          //       child: Row(
          //         children: [
          //           Icon(Icons.error_outline, color: Colors.red),
          //           SizedBox(width: 8),
          //           Expanded(
          //             child: Text(
          //               'Imeshindwa kupakia baadhi ya data. Vuta chini ili kujaribu tena.', // Swahili message
          //               style: TextStyle(color: Colors.red),
          //             ),
          //           ),
          //         ],
          //       ),
          //     ),
            //   ),
          _buildWelcomeSection(authProvider.user?['name'], businessName, isLoading: authProvider.isLoading),
          const SizedBox(height: 16),
          const BusinessMetricsCards(),
          const SizedBox(height: 20),
          const QuickActionsGrid(),
          const SizedBox(height: 20),
          const RecentActivitiesList(),
          const SizedBox(height: 100), // Extra space at bottom for FAB
        ],
      ),
    );
  }

  /// Builds the web header title.
  Widget _buildWebHeader(AuthProvider authProvider, String businessName) {
    return Text(
      'Dashboard',
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Colors.white, // Set dashboard text color to white
      ),
    );
  }

  /// Builds the welcome message card.
  Widget _buildWelcomeSection(String? userName, String businessName, {bool isLoading = false}) {
    if (isLoading) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
    }
    final hour = DateTime.now().hour;
    String greeting;

    if (hour < 12) {
      greeting = 'Habari za Asubuhi';
    } else if (hour < 17) {
      greeting = 'Habari za Mchana';
    } else {
      greeting = 'Habari za Jioni';
    }

    return Card(
      elevation: 2, // Add a subtle shadow
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Rounded corners
      color: Colors.white, // Use white background like metric cards
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting, ${userName ?? 'Mtumiaji'}!', // Default to 'Mtumiaji' if name is null
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary, // Use primary color for greeting
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Karibu kwenye $businessName',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.business_center,
              size: 48,
              color: Theme.of(context).colorScheme.secondary, // Use secondary color for icon
            ),
          ],
        ),
      ),
    );
  }

  /// Shows the quick record action dialog/bottom sheet.
  void _showQuickRecordDialog(BuildContext context) {
    // Using mobile bottom sheet behavior for all platforms for consistency
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      // Constrain the width of the bottom sheet on web for a better dialog-like appearance
      constraints: kIsWeb ? const BoxConstraints(maxWidth: 450) : null,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Draggable handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Ongeza Rekodi Haraka',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 350), // Constrain the grid width on large screens
                    child: GridView.count(
                      controller: scrollController,
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _buildQuickActionCard('Mauzo', Icons.point_of_sale, Colors.green, () async {
                          Navigator.pop(context); // Dismiss the bottom sheet
                          await Future.delayed(Duration.zero);
                          Navigator.pushNamed(context, AppRoutes.addSale);
                        }),
                        _buildQuickActionCard('Manunuzi', Icons.shopping_cart, Colors.blue, () async {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, AppRoutes.addPurchase);
                        }),
                        _buildQuickActionCard('Matumizi', Icons.money_off, Colors.red, () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, AppRoutes.addExpense);
                        }),
                        _buildQuickActionCard('Bidhaa', Icons.inventory, Colors.orange, () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, AppRoutes.addProduct);
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a single quick action card for the bottom sheet.
  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: 3, // Give more space to the icon container
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 30, // Give the icon a fixed, reasonable size
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                flex: 2, // Give less space to the text
                child: FittedBox(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows a confirmation dialog before initiating the logout process.
  Future<void> _showLogoutConfirmationDialog(BuildContext dialogContext) async {
    final bool? confirm = await showDialog<bool>(
      context: dialogContext,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Thibitisha Kuondoka'), // Swahili
          content: const Text('Una uhakika unataka kuondoka kutoka Bizmax?'), // Swahili
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false), // User tapped "No"
              child: const Text('Hapana'), // Swahili
            ),
            ElevatedButton( // Use ElevatedButton for the primary action
              onPressed: () => Navigator.of(ctx).pop(true),  // User tapped "Yes"
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Highlight logout action
                foregroundColor: Colors.white,
              ),
              child: const Text('Ndio, Ondoka'), // Swahili
            ),
          ],
        );
      },
    );

    // If user confirmed (confirm is true)
    if (confirm == true && mounted) {
      final authProvider = dialogContext.read<AuthProvider>(); // Use dialogContext to avoid errors if original context changes
      try {
        await authProvider.logout();
        // AuthWrapper in main.dart will handle navigation after state change
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(dialogContext).showSnackBar( // Use dialogContext for SnackBar
            SnackBar(
              content: Text('Kushindwa kuondoka: ${e.message}'), // Swahili
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(dialogContext).showSnackBar( // Use dialogContext for SnackBar
            SnackBar(
              content: Text('Kuna tatizo lisilotarajiwa limetokea wakati wa kuondoka: ${e.toString()}'), // Swahili
              backgroundColor: Colors.red,
            ),
          );
        }
        // Re-throw in debug mode to see stack trace
        if (kDebugMode) {
          rethrow;
        }
      }
    }
  }
}