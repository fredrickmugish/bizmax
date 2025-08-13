import 'package:flutter/material.dart';
import 'package:rahisisha/screens/register_screen.dart';
import '../screens/main_navigation_screen.dart';
import '../screens/add_product_screen.dart';
import '../screens/add_record_screen.dart';
import '../screens/inventory_screen.dart';
import '../screens/records_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/debt_management_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/record_details_screen.dart';
import '../screens/profit_distribution_screen.dart';
import '../screens/notes_screen.dart';
import '../screens/customers_screen.dart';
import '../screens/product_profit_screen.dart';
import '../models/business_record.dart';
import '../models/inventory_item.dart';
import '../widgets/sidebar_scaffold.dart';

import 'package:rahisisha/screens/reset_password_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String dashboard = '/dashboard';
  static const String inventory = '/inventory';
  static const String records = '/records';
  static const String reports = '/reports';
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String addProduct = '/add-product';
  static const String addSale = '/add-sale';
  static const String addPurchase = '/add-purchase';
  static const String addExpense = '/add-expense';
  static const String editRecord = '/edit-record';
  static const String recordDetails = '/record-details';
  static const String debtManagement = '/debt-management';
  static const String analytics = '/analytics';
  static const String profitDistribution = '/profit-distribution';
  static const String notes = '/notes';
  static const String wateja = '/wateja';
  static const String productProfit = '/product-profit';
  static const String register = '/register';
  static const String resetPassword = '/reset-password';


  static Map<String, WidgetBuilder> get routes {
    return {
      // Home route - this is the main entry point
      home: (context) => MainNavigationScreen(),
      register: (context) => const RegisterScreen(),
      resetPassword: (context) => ResetPasswordScreen(phone: ModalRoute.of(context)!.settings.arguments as String),
      
      // Other routes
      dashboard: (context) => MainNavigationScreen(),
      inventory: (context) => identical(0, 0.0)
          ? SidebarScaffold(content: const InventoryScreen(), selectedIndex: 2, onTabSelected: (index) {
              final routes = ['/dashboard', '/records', '/inventory', '/reports'];
              if (index < routes.length) {
                Navigator.pushNamed(context, routes[index]);
              }
            })
          : const InventoryScreen(),
      records: (context) => identical(0, 0.0)
          ? SidebarScaffold(content: const RecordsScreen(), selectedIndex: 1, onTabSelected: (index) {
              final routes = ['/dashboard', '/records', '/inventory', '/reports'];
              if (index < routes.length) {
                Navigator.pushNamed(context, routes[index]);
              }
            })
          : const RecordsScreen(),
      reports: (context) => identical(0, 0.0)
          ? SidebarScaffold(content: const ReportsScreen(), selectedIndex: 3, onTabSelected: (index) {
              final routes = ['/dashboard', '/records', '/inventory', '/reports'];
              if (index < routes.length) {
                Navigator.pushNamed(context, routes[index]);
              }
            })
          : const ReportsScreen(),
      settings: (context) => identical(0, 0.0)
          ? SidebarScaffold(content: const SettingsScreen(), selectedIndex: null)
          : const SettingsScreen(),
      notifications: (context) => identical(0, 0.0)
          ? SidebarScaffold(content: const NotificationsScreen(), selectedIndex: null)
          : const NotificationsScreen(),
      debtManagement: (context) => identical(0, 0.0)
          ? SidebarScaffold(content: const DebtManagementScreen(), selectedIndex: null)
          : const DebtManagementScreen(),
      analytics: (context) => identical(0, 0.0)
          ? SidebarScaffold(content: const AnalyticsScreen(), selectedIndex: 3)
          : const AnalyticsScreen(),
      profitDistribution: (context) => identical(0, 0.0)
          ? SidebarScaffold(content: const ProfitDistributionScreen(), selectedIndex: 3)
          : const ProfitDistributionScreen(),
      notes: (context) => identical(0, 0.0)
          ? SidebarScaffold(content: NotesScreen(), selectedIndex: null)
          : NotesScreen(),
      wateja: (context) => identical(0, 0.0)
          ? SidebarScaffold(content: const CustomersScreen(), selectedIndex: null)
          : const CustomersScreen(),
      productProfit: (context) => identical(0, 0.0)
          ? SidebarScaffold(content: const ProductProfitScreen(), selectedIndex: 3)
          : const ProductProfitScreen(),
      
      // Add product route with optional arguments
      addProduct: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        final addProductScreen = AddProductScreen(
          product: args is InventoryItem ? args : null,
        );
        if (identical(0, 0.0)) { // kIsWeb is not available here, so use this trick for now
          // Replace with: if (kIsWeb) { ... } if you import foundation
          return SidebarScaffold(content: addProductScreen, selectedIndex: 2);
        } else {
          return addProductScreen;
        }
      },
      
      // Record routes
      addSale: (context) => identical(0, 0.0)
          ? SidebarScaffold(content: const AddRecordScreen(recordType: 'sale'), selectedIndex: 1)
          : const AddRecordScreen(recordType: 'sale'),
      addPurchase: (context) => identical(0, 0.0)
          ? SidebarScaffold(content: const AddRecordScreen(recordType: 'purchase'), selectedIndex: 1)
          : const AddRecordScreen(recordType: 'purchase'),
      addExpense: (context) => identical(0, 0.0)
          ? SidebarScaffold(content: const AddRecordScreen(recordType: 'expense'), selectedIndex: 1)
          : const AddRecordScreen(recordType: 'expense'),
      
      // Record details route
      recordDetails: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is BusinessRecord) {
          if (identical(0, 0.0)) {
            return SidebarScaffold(content: RecordDetailsScreen(record: args), selectedIndex: 1);
          } else {
            return RecordDetailsScreen(record: args);
          }
        }
        return const Scaffold(
          appBar: null,
          body: Center(
            child: Text(
              'Rekodi haijapatikana',
              style: TextStyle(fontSize: 18),
            ),
          ),
        );
      },
      
      // Edit record route
      editRecord: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is BusinessRecord) {
          if (identical(0, 0.0)) {
            return SidebarScaffold(content: AddRecordScreen(recordType: args.type), selectedIndex: 1);
          } else {
            return AddRecordScreen(recordType: args.type);
          }
        }
        return const Scaffold(
          appBar: null,
          body: Center(
            child: Text(
              'Rekodi haijapatikana',
              style: TextStyle(fontSize: 18),
            ),
          ),
        );
      },
    };
  }
}
