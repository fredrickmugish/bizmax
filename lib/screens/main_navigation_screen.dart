import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'dashboard_screen.dart';
import 'records_screen.dart';
import 'inventory_screen.dart';
import 'reports_screen.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import '../widgets/sidebar_scaffold.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  String? _userRole; // Stores the current user's role

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure context is available and avoid issues
    // during the very first build cycle.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeUserRoleAndIndex();
    });
  }

  // Method to initialize user role and current index
  void _initializeUserRoleAndIndex() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    _userRole = _extractRole(user); // Extract the role once

    int defaultIndex = 0; // Default for salesperson or other roles

    if (_userRole == 'owner') {
      defaultIndex = 0; // Dashboard is usually the first tab for owner
    } else if (_userRole == 'salesperson') {
      defaultIndex = 0; // Inventory is usually the first tab for salesperson
    }
    // You can adjust defaultIndex based on which screen you want each role to see first.

    setState(() {
      _currentIndex = defaultIndex;
    });
  }

  // Helper method to extract role safely and directly from the 'role' field
  String? _extractRole(Map<String, dynamic>? userData) {
    if (userData == null) {
      return null;
    }
    // After Spatie removal, your API directly returns 'role' as a string in the user object.
    return userData['role'] as String?;
  }

  void _selectTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<AuthProvider>().logout();
              }
              ,
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use context.watch to react to changes in AuthProvider.user
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    // Use the role from the AuthProvider's user getter, as it's the single source of truth.
    // The build method will re-run when authProvider.user changes.
    final String? role = _extractRole(user);

    // If the role is null (e.g., not authenticated or during initial load),
    // you might want to show a loading indicator or a login screen.
    if (role == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Define screens and navigation items based on the user's role.
    final List<Widget> screens =
      (role == 'owner')
        ? [
            DashboardScreen(),
            RecordsScreen(),
            InventoryScreen(),
            ReportsScreen(),
          ]
        : [ // This is for 'salesperson' or any other non-owner role
            InventoryScreen(), // Salesperson's first tab
            RecordsScreen(),
          ];

    final List<BottomNavigationBarItem> navItems =
      (role == 'owner')
        ? [
            const BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
            const BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Rekodi'),
            const BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Bidhaa'),
            const BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Ripoti'),
          ]
        : [ // This is for 'salesperson' or any other non-owner role
            const BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Bidhaa'), // Salesperson's first tab
            const BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Rekodi'),
          ];

    // Render appropriate navigation based on platform (web vs. mobile)
    if (kIsWeb) {
      return SidebarScaffold(
        selectedIndex: _currentIndex,
        onTabSelected: _selectTab,
        content: screens[_currentIndex],
      );
    } else {
      return Scaffold(
        body: screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _selectTab,
          items: navItems,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
        ),
      );
    }
  }
}