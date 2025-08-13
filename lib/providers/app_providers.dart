import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _userEmail;
  String? _userName;
  String? _businessName;
  String? _businessType;
  String? _phone;
  String? _error;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get userEmail => _userEmail;
  String? get userName => _userName;
  String? get businessName => _businessName;
  String? get businessType => _businessType;
  String? get phone => _phone;
  String? get error => _error;

  // Initialize authentication state
  Future<void> initializeAuth() async {
    try {
      await _apiService.initializeTokens();
      _isAuthenticated = _apiService.isAuthenticated;
      
      if (_isAuthenticated) {
        // Try to fetch user profile
        try {
          final response = await _apiService.getUserProfile();
          if (response['success']) {
            _setUserData(response['data']);
          }
        } catch (e) {
          // If we can't fetch profile, clear authentication
          _isAuthenticated = false;
          await _apiService.clearTokens();
        }
      }
    } catch (e) {
      _isAuthenticated = false;
    }
    // Don't call notifyListeners here since this is called during initialization
  }

  // Register
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String businessName,
    required String businessType,
    String? phone,
    String? businessAddress,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: password,
        businessName: businessName,
        businessType: businessType,
        phone: phone,
        businessAddress: businessAddress,
      );

      if (response['success']) {
        _isAuthenticated = true;
        _setUserData(response['data']['user']);
      } else {
        throw ApiException(response['message'] ?? 'Registration failed', null);
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login
  Future<void> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.login(
        email: email,
        password: password,
      );

      if (response['success']) {
        _isAuthenticated = true;
        _setUserData(response['data']['user']);
      } else {
        throw ApiException(response['message'] ?? 'Login failed', null);
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.logout();
    } catch (e) {
    } finally {
      _isAuthenticated = false;
      _clearUserData();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update Profile
  Future<void> updateProfile({
    String? name,
    String? phone,
    String? businessName,
    String? businessType,
    String? businessAddress,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.updateProfile(
        name: name,
        phone: phone,
        businessName: businessName,
        businessType: businessType,
        businessAddress: businessAddress,
      );

      if (response['success']) {
        _setUserData(response['data']);
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Change Password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        newPasswordConfirmation: confirmPassword,
      );
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _setUserData(Map<String, dynamic> userData) {
    _userEmail = userData['email'];
    _userName = userData['name'];
    _businessName = userData['business_name'];
    _businessType = userData['business_type'];
    _phone = userData['phone'];
  }

  void _clearUserData() {
    _userEmail = null;
    _userName = null;
    _businessName = null;
    _businessType = null;
    _phone = null;
    _error = null;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

// Make sure ApiException is defined
class ApiException implements Exception {
  final String message;
  final Map<String, dynamic>? errors;

  ApiException(this.message, this.errors);

  @override
  String toString() => message;
}
