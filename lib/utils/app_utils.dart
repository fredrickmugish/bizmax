import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'app_constants.dart';

class AppUtils {
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = 
      GlobalKey<ScaffoldMessengerState>();

  static final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

  static final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();

  static String formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'sw_TZ',
      symbol: 'TSH ',
      decimalDigits: 0,
    ).format(amount);
  }

  // Date formatting
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String formatTime(DateTime time) {
    return DateFormat(AppConstants.timeFormat).format(time);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} siku zilizopita';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saa zilizopita';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika zilizopita';
    } else {
      return 'Sasa hivi';
    }
  }

  // Number formatting
  static String formatNumber(double number) {
    final formatter = NumberFormat('#,##0.##', 'sw_TZ');
    return formatter.format(number);
  }

  static String formatPercentage(double percentage) {
    return '${(percentage * 100).toStringAsFixed(1)}%';
  }

  // Validation
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static bool isValidPhoneNumber(String phone) {
    return RegExp(r'^(\+255|0)[67]\d{8}$').hasMatch(phone);
  }

  static bool isValidAmount(String amount) {
    final parsed = double.tryParse(amount);
    return parsed != null && parsed > 0 && parsed <= AppConstants.maxAmount;
  }

  // Snackbar helpers
  static void showSuccessSnackBar(String message) {
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showErrorSnackBar(String message) {
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void showInfoSnackBar(String message) {
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // New method for showing data operation success messages
  static Future<void> showDataOperationSnackBar(bool isOnline) async {
    final message = isOnline
        ? 'Data zimetumwa kwenye server kikamilifu'
        : 'Data zimehifadhiwa kwenye simu yako kikamilifu';
    showSuccessSnackBar(message);
  }

  // Color helpers
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  static Color getCategoryColor(String category) {
    final hash = category.hashCode;
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    return colors[hash.abs() % colors.length];
  }

  // File helpers
  static String getFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Business logic helpers
  static double calculateProfit(double revenue, double expenses) {
    return revenue - expenses;
  }

  static double calculateProfitMargin(double profit, double revenue) {
    if (revenue == 0) return 0;
    return profit / revenue;
  }

  static String getBusinessHealthStatus(double profitMargin, int lowStockItems) {
    if (profitMargin >= AppConstants.profitMarginThreshold && lowStockItems == 0) {
      return 'Nzuri';
    } else if (profitMargin >= 0 && lowStockItems <= 5) {
      return 'Wastani';
    } else {
      return 'Inahitaji Uangalifu';
    }
  }

  // Dialog helpers
  static Future<bool?> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Thibitisha',
    String cancelText = 'Ghairi',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  static void showLoadingDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(
              child: Text(message ?? 'Inapakia...'),
            ),
          ],
        ),
      ),
    );
  }

  // Generate unique ID
  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // Text helpers
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  static String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  // Date range helpers
  static DateTimeRange getCurrentWeek() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return DateTimeRange(start: startOfWeek, end: endOfWeek);
  }

  static DateTimeRange getCurrentMonth() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    return DateTimeRange(start: startOfMonth, end: endOfMonth);
  }

  static DateTimeRange getCurrentYear() {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final endOfYear = DateTime(now.year, 12, 31);
    return DateTimeRange(start: startOfYear, end: endOfYear);
  }

  // Get East Africa timezone (UTC+3)
  static DateTime getEastAfricaTime() {
    // Get current UTC time and convert to East Africa timezone (UTC+3)
    final utcNow = DateTime.now().toUtc();
    return utcNow.add(const Duration(hours: 3));
  }

  // Convert UTC time to East Africa time
  static DateTime toEastAfricaTime(DateTime utcTime) {
    // Convert UTC to East Africa time (UTC+3)
    return utcTime.toUtc().add(const Duration(hours: 3));
  }

  // Get current local time (assuming system is set to East Africa timezone)
  static DateTime getCurrentLocalTime() {
    return DateTime.now();
  }

  // Get start of day in East Africa timezone
  static DateTime getStartOfDayEastAfrica() {
    final eastAfricaTime = getEastAfricaTime();
    return DateTime(eastAfricaTime.year, eastAfricaTime.month, eastAfricaTime.day);
  }

  // Get end of day in East Africa timezone
  static DateTime getEndOfDayEastAfrica() {
    final startOfDay = getStartOfDayEastAfrica();
    return startOfDay.add(const Duration(days: 1));
  }

  // Format date for API (YYYY-MM-DD)
  static String formatDateForApi(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // Format date in East Africa timezone
  static String formatDateEastAfrica(DateTime date) {
    final eastAfricaDate = toEastAfricaTime(date);
    return DateFormat('dd/MM/yyyy').format(eastAfricaDate);
  }

  // Format date and time in East Africa timezone
  static String formatDateTimeEastAfrica(DateTime dateTime) {
    final eastAfricaDateTime = toEastAfricaTime(dateTime);
    return DateFormat('dd-MM-yyyy hh:mm a').format(eastAfricaDateTime);
  }
}
