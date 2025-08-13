import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/main_navigation_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('AuthWrapper: build called');
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        print('AuthWrapper: isAuthenticated =  [32m${authProvider.isAuthenticated} [0m, isLoading = ${authProvider.isLoading}');
        // Don't show loading here since we handle it in AppInitializer
        if (authProvider.isAuthenticated) {
          print('AuthWrapper: Showing MainNavigationScreen');
          return MainNavigationScreen();
        } else {
          print('AuthWrapper: Showing LoginScreen');
          return const LoginScreen();
        }
      },
    );
  }
}
