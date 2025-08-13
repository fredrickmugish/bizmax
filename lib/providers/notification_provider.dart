import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class NotificationProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Map<String, dynamic>> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load notifications
  Future<void> loadNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // For now, use mock data since API might not be ready
      await _loadMockNotifications();
      
      // Uncomment when API is ready:
      // final response = await _apiService.getNotifications();
      // _notifications = List<Map<String, dynamic>>.from(response['data']['data'] ?? []);
      // _unreadCount = await _apiService.getUnreadNotificationsCount();
      
    } catch (e) {
      _error = e.toString();
      print('Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load mock notifications for demo
  Future<void> _loadMockNotifications() async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate API delay
    
    _notifications = [
      {
        'id': '1',
        'title': 'Hifadhi Chini',
        'message': 'Bidhaa 3 zina hifadhi chini ya kiwango cha chini',
        'type': 'low_stock',
        'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        'read_at': null,
      },
      {
        'id': '2',
        'title': 'Mauzo Leo',
        'message': 'Umepata mauzo ya TSH 150,000 leo',
        'type': 'sales',
        'created_at': DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
        'read_at': null,
      },
      {
        'id': '3',
        'title': 'Backup Imekamilika',
        'message': 'Data zako zimehifadhiwa kikamilifu',
        'type': 'system',
        'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'read_at': DateTime.now().subtract(const Duration(hours: 12)).toIso8601String(),
      },
    ];
    
    _unreadCount = _notifications.where((n) => n['read_at'] == null).length;
  }

  // Mark notification as read
  Future<void> markAsRead(String id) async {
    try {
      // For now, update locally
      final index = _notifications.indexWhere((n) => n['id'] == id);
      if (index != -1 && _notifications[index]['read_at'] == null) {
        _notifications[index]['read_at'] = DateTime.now().toIso8601String();
        _unreadCount = (_unreadCount - 1).clamp(0, _unreadCount);
        notifyListeners();
      }
      
      // Uncomment when API is ready:
      // await _apiService.markNotificationAsRead(int.parse(id));
      
    } catch (e) {
      _error = e.toString();
      print('Error marking notification as read: $e');
    }
  }

  // Mark all as read
  Future<void> markAllAsRead() async {
    try {
      for (var notification in _notifications) {
        if (notification['read_at'] == null) {
          notification['read_at'] = DateTime.now().toIso8601String();
        }
      }
      _unreadCount = 0;
      notifyListeners();
      
      // Uncomment when API is ready:
      // await _apiService.markAllNotificationsAsRead();
      
    } catch (e) {
      _error = e.toString();
      print('Error marking all notifications as read: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String id) async {
    try {
      final wasUnread = _notifications.firstWhere((n) => n['id'] == id)['read_at'] == null;
      _notifications.removeWhere((n) => n['id'] == id);
      if (wasUnread) {
        _unreadCount = (_unreadCount - 1).clamp(0, _unreadCount);
      }
      notifyListeners();
      
      // Uncomment when API is ready:
      // await _apiService.deleteNotification(int.parse(id));
      
    } catch (e) {
      _error = e.toString();
      print('Error deleting notification: $e');
    }
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      _notifications.clear();
      _unreadCount = 0;
      notifyListeners();
      
      // Uncomment when API is ready:
      // await _apiService.clearAllNotifications();
      
    } catch (e) {
      _error = e.toString();
      print('Error clearing notifications: $e');
    }
  }

  // Generate low stock notifications (mock for now)
  Future<void> generateLowStockNotifications() async {
    try {
      // This would normally call the API
      // For now, just add a mock notification
      final newNotification = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': 'Hifadhi Chini',
        'message': 'Bidhaa mpya ina hifadhi chini ya kiwango cha chini',
        'type': 'low_stock',
        'created_at': DateTime.now().toIso8601String(),
        'read_at': null,
      };
      
      _notifications.insert(0, newNotification);
      _unreadCount++;
      notifyListeners();
      
      // Uncomment when API is ready:
      // await _apiService.generateLowStockNotifications();
      // await loadNotifications(); // Refresh notifications
      
    } catch (e) {
      _error = e.toString();
      print('Error generating low stock notifications: $e');
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
