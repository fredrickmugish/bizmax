import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:rahisisha/screens/login_screen.dart';
import '../services/api_service.dart';
import '../services/api_exception.dart';
import 'records_provider.dart';
import '../utils/app_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _token;
  Map<String, dynamic>? _user;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;

  AuthProvider() {
    _initializeAuthStatus();
  }

  Future<void> _saveUserProfile(Map<String, dynamic>? user) async {
    final prefs = await SharedPreferences.getInstance();
    if (user != null) {
      await prefs.setString('user_profile', jsonEncode(user));
    } else {
      await prefs.remove('user_profile');
    }
  }

  Future<Map<String, dynamic>?> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user_profile');
    if (userString != null) {
      try {
        return jsonDecode(userString) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<void> _initializeAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    await _apiService.initializeTokens();

    if (_apiService.isAuthenticated) {
      _token = _apiService.accessToken;
      _user = await _loadUserProfile();
      _isAuthenticated = _user != null;

      if (_isAuthenticated) {
        try {
          final apiResponse = await _apiService.getUserProfile();
          if (apiResponse['data'] is Map<String, dynamic>) {
            _user = apiResponse['data'] as Map<String, dynamic>;
            await _saveUserProfile(_user);
          }
        } on ApiException catch (e) {
          if (e.statusCode == 401) {
            await logout();
          }
        } catch (e) {
          // Could not refresh profile, but stay logged in with local data
        }
      }
    } else {
      _isAuthenticated = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> register({
    required String name,
    required String phone,
    required String password,
    required String passwordConfirmation,
    required String businessName,
    required String businessType,
    required String businessAddress,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.register(
        name: name,
        phone: phone,
        password: password,
        passwordConfirmation: passwordConfirmation,
        businessName: businessName,
        businessType: businessType,
        businessAddress: businessAddress,
      );
    } on ApiException { // Catch ApiException specifically
      rethrow; // Re-throw the original ApiException
    } catch (e) { // Catch any other unexpected exceptions
      // You might want to log this unexpected error
      if (kDebugMode) {
        print('Unexpected error in AuthProvider.register: $e');
      }
      rethrow; // Re-throw other exceptions as well
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login({
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.login(phone: phone, password: password);

      _token = response['data']['token']?.toString();
      if (response['data']['user'] is Map<String, dynamic>) {
        _user = response['data']['user'] as Map<String, dynamic>;
      }

      _isAuthenticated = _user != null;
      await _saveUserProfile(_user);
    } on ApiException { // Catch ApiException specifically
      rethrow; // Re-throw the original ApiException
    } catch (e) { // Catch any other unexpected exceptions
      // You might want to log this unexpected error
      if (kDebugMode) {
        print('Unexpected error in AuthProvider.login: $e');
      }
      rethrow; // Re-throw other exceptions as well
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> forgotPassword({
    required String phone,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.forgotPassword(phone: phone);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword({
    required String phone,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.resetPassword(
        phone: phone,
        token: token,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.logout();
    } catch (e) {
      // Ignore errors, just clear local data
    } finally {
      _isAuthenticated = false;
      _token = null;
      _user = null;
      await _apiService.clearTokens();
      await _saveUserProfile(null);

      final context = AppUtils.globalNavigatorKey.currentContext;
      if (context != null) {
        Provider.of<RecordsProvider>(context, listen: false).clearRecords();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
      
      _isLoading = false;
      notifyListeners();
    }
  }

  String? get currentUserRole {
    return _user?['role']?.toString();
  }

  void updateUserDisplayName(String? newName) {
    if (_user != null) {
      _user!['name'] = newName;
      notifyListeners();
    }
  }

  void updateUserPhone(String? newPhone) {
    if (_user != null) {
      _user!['phone'] = newPhone;
      notifyListeners();
    }
  }
}
