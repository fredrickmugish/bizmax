import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:flutter/foundation.dart';
import '../providers/business_provider.dart';

class SidebarScaffold extends StatelessWidget {
  final Widget content;
  final int? selectedIndex;
  final Function(int)? onTabSelected;

  // appBar is now only used for the large web screen, or if explicitly passed
  const SidebarScaffold({Key? key, required this.content, this.selectedIndex, this.onTabSelected, this.appBar}) : super(key: key);

  final PreferredSizeWidget? appBar; // Kept for the large screen's appBar

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    String? role;
    if (user != null) {
      role = user['role'] ?? user['data']?['role'] ?? user['user']?['role'] ?? user['profile']?['role'];
    }
    final isOwner = role == 'owner';
    final navItems = isOwner
        ? [
            {'icon': Icons.dashboard, 'label': 'Dashboard'},
            {'icon': Icons.receipt_long, 'label': 'Rekodi'},
            {'icon': Icons.inventory, 'label': 'Bidhaa'},
            {'icon': Icons.analytics, 'label': 'Ripoti'},
          ]
        : [
            {'icon': Icons.inventory, 'label': 'Bidhaa'},
            {'icon': Icons.receipt_long, 'label': 'Rekodi'},
          ];
    final isSmallWeb = kIsWeb && MediaQuery.of(context).size.width < 840;
    final businessName = context.watch<BusinessProvider>().businessName;

    if (isSmallWeb) {
      print('SidebarScaffold: Using Drawer-only layout for small web screen, WITHOUT AppBar');
      // Small web screen: use Drawer, but no AppBar in this Scaffold
      return Scaffold(
        // NO AppBar here for small web screen.
        // The individual screens will add their own AppBars with menu icons.
        drawer: Drawer(
          child: Column(
            children: [
              const SizedBox(height: 32),
              // Only Bizmax name, centered
              Center(
                child: Text(
                  businessName,
                  style: const TextStyle( // Make it const if possible
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // User profile section (large avatar and name)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.blue.shade50,
                      // TODO: Replace with NetworkImage or AssetImage for user profile photo
                      child: const Icon(Icons.account_circle, color: Colors.blue, size: 60), // Make it const
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user != null && user['name'] != null ? user['name'] : '',
                      style: const TextStyle(color: Colors.blue, fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ...List.generate(navItems.length, (index) {
                final selected = selectedIndex == index;
                return ListTile(
                  leading: Icon(navItems[index]['icon'] as IconData, color: Colors.blue),
                  title: Text(
                    navItems[index]['label'] as String,
                    style: TextStyle(
                      color: selected ? Colors.blue : Colors.black,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: selected,
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    if (onTabSelected != null) {
                      onTabSelected!(index);
                    } else {
                      final ownerRoutes = ['/dashboard', '/records', '/inventory', '/reports'];
                      final salespersonRoutes = ['/inventory', '/records'];
                      final routes = isOwner ? ownerRoutes : salespersonRoutes;
                      if (index < routes.length) {
                        Navigator.pushNamed(context, routes[index]);
                      }
                    }
                  },
                );
              }),
              const Spacer(),
              // Only keep logout button at the end
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
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
                                },
                                child: const Text('Logout'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    icon: const Icon(Icons.logout, color: Colors.blue, size: 16),
                    label: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      backgroundColor: Colors.red.withOpacity(0.1),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        body: content, // The actual screen content goes here
      );
    }
    // Large web or not web: show permanent sidebar
    return Scaffold(
      appBar: appBar, // Use the provided appBar for large screens
      body: Row(
        children: [
          Container(
            width: 220,
            color: const Color(0xFF32363F),
            child: Column(
              children: [
                // Remove extra top spacing and logo/name header
                // Place logo and Bizmax name as the first nav item (not selectable)
                Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    child: Center(
                      child: Text(
                        businessName,
                        style: const TextStyle( // Make it const if possible
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ),
                ),
                // User profile section (larger, with name below avatar)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.white,
                        // TODO: Replace with NetworkImage or AssetImage for user profile photo
                        child: const Icon(Icons.account_circle, color: Colors.blue, size: 60), // Make it const
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user != null && user['name'] != null ? user['name'] : '',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20), // Space before nav items
                ...List.generate(navItems.length, (index) {
                  final selected = selectedIndex == index;
                  return Material(
                    color: selected ? Colors.blue : Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (onTabSelected != null) {
                          onTabSelected!(index);
                        } else {
                          // Default: map index to main routes
                          final ownerRoutes = ['/dashboard', '/records', '/inventory', '/reports'];
                          final salespersonRoutes = ['/inventory', '/records'];
                          final routes = isOwner ? ownerRoutes : salespersonRoutes;
                          if (index < routes.length) {
                            Navigator.pushNamed(context, routes[index]);
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        child: Row(
                          children: [
                            Icon(
                              navItems[index]['icon'] as IconData,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              navItems[index]['label'] as String,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const Spacer(),
                // Only keep logout button at the end
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () {
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
                                  },
                                  child: const Text('Logout'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      icon: const Icon(Icons.logout, color: Colors.white, size: 16),
                      label: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        backgroundColor: Colors.red.withOpacity(0.2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: content),
        ],
      ),
    );
  }
}