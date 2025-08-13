import 'package:flutter/foundation.dart';
import '../models/business_record.dart';
import '../models/inventory_item.dart';
import '../providers/records_provider.dart';
import '../providers/inventory_provider.dart';
import '../utils/app_utils.dart';
import 'package:hive/hive.dart';
import 'package:flutter/widgets.dart';

enum NotificationType {
  lowStock,
  sales,
  debt,
  system,
  report,
  expense,
  purchase,
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    required this.isRead,
    this.data,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }
}

class NotificationsProvider extends ChangeNotifier {
  List<NotificationItem> _notifications = [];
  RecordsProvider? _recordsProvider;
  InventoryProvider? _inventoryProvider;
  bool _isLoading = false;
  Set<String> _readNotificationIds = {};
  Set<String> _deletedNotificationIds = {};
  static const String _readBoxName = 'read_notifications';
  static const String _deletedBoxName = 'deleted_notifications';

  NotificationsProvider() {
    _loadReadIds();
    _loadDeletedIds();
  }

  List<NotificationItem> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void setProviders(RecordsProvider recordsProvider, InventoryProvider inventoryProvider) {
    _recordsProvider = recordsProvider;
    _inventoryProvider = inventoryProvider;
  }

  Future<void> _loadReadIds() async {
    final box = await Hive.openBox(_readBoxName);
    _readNotificationIds = Set<String>.from(box.get('ids', defaultValue: <String>[]));
    notifyListeners();
  }

  Future<void> _saveReadIds() async {
    final box = await Hive.openBox(_readBoxName);
    await box.put('ids', _readNotificationIds.toList());
  }

  Future<void> _loadDeletedIds() async {
    final box = await Hive.openBox(_deletedBoxName);
    _deletedNotificationIds = Set<String>.from(box.get('ids', defaultValue: <String>[]));
    notifyListeners();
  }

  Future<void> _saveDeletedIds() async {
    final box = await Hive.openBox(_deletedBoxName);
    await box.put('ids', _deletedNotificationIds.toList());
  }

  Future<void> loadNotifications(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_recordsProvider == null || _inventoryProvider == null) {
        print('NotificationsProvider: Providers not set');
        return;
      }

      await Future.wait([
        _recordsProvider!.loadRecords(),
        _inventoryProvider!.loadInventory(),
      ]);

      final oldNotifications = List<NotificationItem>.from(_notifications);

      _notifications.clear();
      await _generateLowStockNotifications();
      await _generateSalesNotifications();
      await _generateExpenseNotifications();
      await _generateDebtNotifications();
      await _generateSystemNotifications();
      await _generatePurchaseNotifications();

      // Logic to mark updated notifications as unread
      for (var newNotification in _notifications) {
        final oldNotification = oldNotifications.firstWhere(
          (n) => n.id == newNotification.id,
          orElse: () => newNotification, // Should not happen in updates
        );

        if (oldNotification.message != newNotification.message) {
          _readNotificationIds.remove(newNotification.id);
        }
      }
      await _saveReadIds();

      // Remove notifications that are in the deleted set
      _notifications = _notifications.where((n) => !_deletedNotificationIds.contains(n.id)).toList();
      // Set isRead based on persisted IDs
      _notifications = _notifications.map((n) => n.copyWith(isRead: _readNotificationIds.contains(n.id))).toList();
      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      print('NotificationsProvider: Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _generateLowStockNotifications() async {
    try {
      final items = _inventoryProvider!.items;
      final lowStockItems = items.where((item) => 
        item.currentStock <= item.minimumStock
      ).toList();

      if (lowStockItems.isNotEmpty) {
        final itemNames = lowStockItems.map((item) => item.name).join(', ');
        final itemIds = lowStockItems.map((item) => item.id).join('_');
        final today = AppUtils.getEastAfricaTime();
        // Use the most recently updated item's updatedAt as the timestamp
        final latestUpdate = lowStockItems.map((item) => item.updatedAt).fold<DateTime?>(null, (prev, curr) => prev == null || curr.isAfter(prev) ? curr : prev) ?? DateTime.now();
        _notifications.add(NotificationItem(
          id: 'low_stock_${today.year}-${today.month}-${today.day}_$itemIds',
          title: 'Hifadhi Chini',
          message: 'Bidhaa ${lowStockItems.length} zina hifadhi chini ya kiwango cha chini: $itemNames',
          type: NotificationType.lowStock,
          timestamp: latestUpdate,
          isRead: false,
          data: {'itemIds': lowStockItems.map((item) => item.id).toList()},
        ));
      }
    } catch (e) {
      print('Error generating low stock notifications: $e');
    }
  }

  Future<void> _generateSalesNotifications() async {
    try {
      final today = AppUtils.getEastAfricaTime();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final todaySales = _recordsProvider!.allRecords.where((record) =>
        record.type == 'sale' &&
        record.date.isAfter(startOfDay.subtract(const Duration(days: 1))) &&
        record.date.isBefore(endOfDay.add(const Duration(days: 1)))
      ).toList();

      if (todaySales.isNotEmpty) {
        final totalSales = todaySales.fold(0.0, (sum, record) => sum + record.amount);
        final salesCount = todaySales.length;
        final latestSale = todaySales.map((record) => record.updatedAt).fold<DateTime?>(null, (prev, curr) => prev == null || curr.isAfter(prev) ? curr : prev) ?? DateTime.now();
        final notificationId = 'sales_${today.year}-${today.month}-${today.day}';

        final newNotification = NotificationItem(
          id: notificationId,
          title: 'Mauzo Leo',
          message: 'Umepata mauzo $salesCount ya TSH ${totalSales.toStringAsFixed(0)} leo',
          type: NotificationType.sales,
          timestamp: latestSale,
          isRead: false,
          data: {'totalSales': totalSales, 'salesCount': salesCount},
        );

        final existingIndex = _notifications.indexWhere((n) => n.id == notificationId);

        if (existingIndex != -1) {
          final existingNotification = _notifications[existingIndex];
          if (existingNotification.data?['totalSales'] != totalSales) {
            _readNotificationIds.remove(notificationId);
            _saveReadIds();
          }
          _notifications[existingIndex] = newNotification;
        } else {
          _notifications.add(newNotification);
        }
      }
    } catch (e) {
      print('Error generating sales notifications: $e');
    }
  }

  Future<void> _generateExpenseNotifications() async {
    try {
      final today = AppUtils.getEastAfricaTime();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      final todayExpenses = _recordsProvider!.allRecords.where((record) =>
        record.type == 'expense' &&
        record.date.isAfter(startOfDay.subtract(const Duration(days: 1))) &&
        record.date.isBefore(endOfDay.add(const Duration(days: 1)))
      ).toList();
      if (todayExpenses.isNotEmpty) {
        final totalExpenses = todayExpenses.fold(0.0, (sum, record) => sum + record.amount);
        final expenseCount = todayExpenses.length;
        final latestExpense = todayExpenses.map((record) => record.updatedAt).fold<DateTime?>(null, (prev, curr) => prev == null || curr.isAfter(prev) ? curr : prev) ?? DateTime.now();
        final notificationId = 'expense_${today.year}-${today.month}-${today.day}';

        final newNotification = NotificationItem(
          id: notificationId,
          title: 'Matumizi Leo',
          message: 'Umetumia TSH ${totalExpenses.toStringAsFixed(0)} kwenye matumizi $expenseCount leo',
          type: NotificationType.expense,
          timestamp: latestExpense,
          isRead: false,
          data: {'totalExpenses': totalExpenses, 'expenseCount': expenseCount},
        );

        final existingIndex = _notifications.indexWhere((n) => n.id == notificationId);

        if (existingIndex != -1) {
          final existingNotification = _notifications[existingIndex];
          if (existingNotification.data?['totalExpenses'] != totalExpenses) {
            _readNotificationIds.remove(notificationId);
            _saveReadIds();
          }
          _notifications[existingIndex] = newNotification;
        } else {
          _notifications.add(newNotification);
        }
      }
    } catch (e) {
      print('Error generating expense notifications: $e');
    }
  }

  Future<void> _generatePurchaseNotifications() async {
    try {
      final today = AppUtils.getEastAfricaTime();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      final todayPurchases = _recordsProvider!.allRecords.where((record) =>
        record.type == 'purchase' &&
        record.date.isAfter(startOfDay.subtract(const Duration(days: 1))) &&
        record.date.isBefore(endOfDay.add(const Duration(days: 1)))
      ).toList();
      if (todayPurchases.isNotEmpty) {
        final totalPurchases = todayPurchases.fold(0.0, (sum, record) => sum + record.amount);
        final purchaseCount = todayPurchases.length;
        final latestPurchase = todayPurchases.map((record) => record.updatedAt).fold<DateTime?>(null, (prev, curr) => prev == null || curr.isAfter(prev) ? curr : prev) ?? DateTime.now();
        final notificationId = 'purchase_${today.year}-${today.month}-${today.day}';

        final newNotification = NotificationItem(
          id: notificationId,
          title: 'Manunuzi Leo',
          message: 'Umenunua bidhaa $purchaseCount za TSH ${totalPurchases.toStringAsFixed(0)} leo',
          type: NotificationType.purchase,
          timestamp: latestPurchase,
          isRead: false,
          data: {'totalPurchases': totalPurchases, 'purchaseCount': purchaseCount},
        );

        final existingIndex = _notifications.indexWhere((n) => n.id == notificationId);

        if (existingIndex != -1) {
          final existingNotification = _notifications[existingIndex];
          if (existingNotification.data?['totalPurchases'] != totalPurchases) {
            _readNotificationIds.remove(notificationId);
            _saveReadIds();
          }
          _notifications[existingIndex] = newNotification;
        } else {
          _notifications.add(newNotification);
        }
      }
    } catch (e) {
      print('Error generating purchase notifications: $e');
    }
  }

  Future<void> _generateDebtNotifications() async {
    try {
      final today = AppUtils.getEastAfricaTime();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      final todayDebts = _recordsProvider!.allRecords.where((record) =>
        record.type == 'sale' &&
        record.isCredit &&
        record.date.isAfter(startOfDay.subtract(const Duration(days: 1))) &&
        record.date.isBefore(endOfDay.add(const Duration(days: 1)))
      ).toList();
      if (todayDebts.isNotEmpty) {
        final debtCount = todayDebts.length;
        final latestDebt = todayDebts.map((record) => record.updatedAt).fold<DateTime?>(null, (prev, curr) => prev == null || curr.isAfter(prev) ? curr : prev) ?? DateTime.now();
        final notificationId = 'debt_${today.year}-${today.month}-${today.day}';

        final existingIndex = _notifications.indexWhere((n) => n.id == notificationId);

        final newNotification = NotificationItem(
          id: notificationId,
          title: 'Madeni Mapya Leo',
          message: 'Kuna madeni $debtCount mapya leo',
          type: NotificationType.debt,
          timestamp: latestDebt,
          isRead: false,
          data: {'debtCount': debtCount},
        );

        if (existingIndex != -1) {
          _notifications[existingIndex] = newNotification;
        } else {
          _notifications.add(newNotification);
        }
      }
    } catch (e) {
      print('Error generating debt notifications: $e');
    }
  }

  Future<void> _generateSystemNotifications() async {
    try {
      final now = AppUtils.getEastAfricaTime();
      final isFriday = now.weekday == 5; // Friday
      final isEvening = now.hour >= 18; // After 6 PM
      final stableTimestamp = DateTime(now.year, now.month, now.day, 18, 0, 0);

      if (isFriday && isEvening) {
        _notifications.add(NotificationItem(
          id: 'weekly_report_${now.year}-${now.month}-${now.day}',
          title: 'Ripoti ya Wiki',
          message: 'Ripoti ya wiki hii iko tayari kwa ajili ya mapitio',
          type: NotificationType.report,
          timestamp: stableTimestamp,
          isRead: false,
        ));
      }

      // Check if it's time for monthly backup reminder
      final isMonthEnd = now.day >= 28;
      if (isMonthEnd && isEvening) {
        _notifications.add(NotificationItem(
          id: 'backup_reminder_${now.year}-${now.month}',
          title: 'Kumbusho la Backup',
          message: 'Fikiria kufanya backup ya data zako mwishoni mwa mwezi',
          type: NotificationType.system,
          timestamp: stableTimestamp,
          isRead: false,
        ));
      }
    } catch (e) {
      print('Error generating system notifications: $e');
    }
  }

  void markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _readNotificationIds.add(id);
      await _saveReadIds();
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  void markAllAsRead() async {
    _readNotificationIds.addAll(_notifications.map((n) => n.id));
    await _saveReadIds();
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
  }

  void deleteNotification(String id) async {
    _deletedNotificationIds.add(id);
    await _saveDeletedIds();
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void clearAllNotifications() async {
    _deletedNotificationIds.addAll(_notifications.map((n) => n.id));
    await _saveDeletedIds();
    _notifications.clear();
    notifyListeners();
  }

  Future<void> refreshNotifications() async {
    // await loadNotifications(); // Comment out or remove the following line if context is not available:
  }
} 