import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notifications_provider.dart';
import '../providers/records_provider.dart';
import '../providers/inventory_provider.dart';
import 'package:flutter/foundation.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotifications();
    });
  }

  void _initializeNotifications() {
    final notificationsProvider = context.read<NotificationsProvider>();
    final recordsProvider = context.read<RecordsProvider>();
    final inventoryProvider = context.read<InventoryProvider>();
    
    // Set providers and load notifications
    notificationsProvider.setProviders(recordsProvider, inventoryProvider);
    notificationsProvider.loadNotifications(context);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationsProvider>(
      builder: (context, provider, child) {
        final unreadCount = provider.unreadCount;

        return Scaffold(
          appBar: AppBar(
            title: Text('Arifa ($unreadCount)'),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            automaticallyImplyLeading: true,
            actions: [
              if (unreadCount > 0)
                TextButton(
                  onPressed: () => provider.markAllAsRead(),
                  child: const Text(
                    'Soma Zote',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.delete_sweep),
                onPressed: () => _clearAllNotifications(provider),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => provider.refreshNotifications(),
              ),
            ],
          ),
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : provider.notifications.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: () => provider.refreshNotifications(),
                      child: ListView.builder(
                        itemCount: provider.notifications.length,
                        itemBuilder: (context, index) {
                          final notification = provider.notifications[index];
                          return _buildNotificationTile(notification, provider);
                        },
                      ),
                    ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Hakuna arifa',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Arifa zitaonekana hapa',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(NotificationItem notification, NotificationsProvider provider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: notification.isRead ? null : Colors.blue.shade50,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getNotificationColor(notification.type),
          child: Icon(
            _getNotificationIcon(notification.type),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(notification.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'mark_read':
                provider.markAsRead(notification.id);
                break;
              case 'delete':
                provider.deleteNotification(notification.id);
                break;
            }
          },
          itemBuilder: (context) => [
            if (!notification.isRead)
              const PopupMenuItem(
                value: 'mark_read',
                child: Text('Alama kama Imesomwa'),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Futa'),
            ),
          ],
        ),
        onTap: () => _onNotificationTap(notification, provider),
      ),
    );
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.lowStock:
        return Colors.orange;
      case NotificationType.sales:
        return Colors.green;
      case NotificationType.debt:
        return Colors.red;
      case NotificationType.system:
        return Colors.blue;
      case NotificationType.report:
        return Colors.purple;
      case NotificationType.expense:
        return Colors.pink;
      case NotificationType.purchase:
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.lowStock:
        return Icons.inventory;
      case NotificationType.sales:
        return Icons.point_of_sale;
      case NotificationType.debt:
        return Icons.credit_card;
      case NotificationType.system:
        return Icons.settings;
      case NotificationType.report:
        return Icons.analytics;
      case NotificationType.expense:
        return Icons.attach_money;
      case NotificationType.purchase:
        return Icons.shopping_cart;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dakika zilizopita';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} saa zilizopita';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} siku zilizopita';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  void _clearAllNotifications(NotificationsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Futa Arifa Zote'),
        content: const Text('Je, una uhakika unataka kufuta arifa zote?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ghairi'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              provider.clearAllNotifications();
              Navigator.pop(context);
            },
            child: const Text('Futa Zote', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _onNotificationTap(NotificationItem notification, NotificationsProvider provider) {
    // Mark as read when tapped
    if (!notification.isRead) {
      provider.markAsRead(notification.id);
    }

    // Handle different notification types
    switch (notification.type) {
      case NotificationType.lowStock:
        Navigator.pushNamed(context, '/inventory');
        break;
      case NotificationType.sales:
        Navigator.pushNamed(context, '/records');
        break;
      case NotificationType.debt:
        Navigator.pushNamed(context, '/debt-management');
        break;
      case NotificationType.report:
        Navigator.pushNamed(context, '/reports');
        break;
      case NotificationType.system:
        // Show notification details
        _showNotificationDetails(notification);
        break;
      case NotificationType.expense:
        Navigator.pushNamed(context, '/records');
        break;
      case NotificationType.purchase:
        Navigator.pushNamed(context, '/records');
        break;
    }
  }

  void _showNotificationDetails(NotificationItem notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 16),
            Text(
              'Wakati: ${_formatTimestamp(notification.timestamp)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Sawa'),
          ),
        ],
      ),
    );
  }
}
