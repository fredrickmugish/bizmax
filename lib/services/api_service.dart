// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // Required for kDebugMode
import 'dart:io';
import 'package:rahisisha/services/api_exception.dart'; // IMPORTANT: This is the ONLY import for ApiException

class ApiService {
  // Singleton setup
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal() {
    // Initialize tokens when the singleton instance is first created
    _initializeTokensOnStartup();
  }

  // This method will be called only once when the singleton is first built
  Future<void> _initializeTokensOnStartup() async {
    await initializeTokens(); // Calls your existing method to load from SharedPreferences
  }

  // --- IMPORTANT: VERIFY THIS BASE URL! ---
  // Use for production
 static const String baseUrl = 'https://fortex.co.tz/api';
  // Use for Android Emulator (uncomment if needed and ensure your backend is accessible)
  // static const String baseUrl = 'http://10.0.2.2:8000/api';

  String? _accessToken;
  String? _refreshToken;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  // Initialize tokens from storage (called by _initializeTokensOnStartup)
  Future<void> initializeTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
    if (kDebugMode) {
      print('ApiService initialized. Access Token: $_accessToken');
      print('ApiService initialized. Refresh Token: $_refreshToken');
    }
  }

  // Save tokens to storage and update internal state
  Future<void> _saveTokens(String accessToken, String? refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    if (refreshToken != null) {
      await prefs.setString('refresh_token', refreshToken);
    }
    _accessToken = accessToken; // Update internal state
    _refreshToken = refreshToken; // Update internal state
    if (kDebugMode) {
      print('Tokens saved. Access Token: $_accessToken, Refresh Token: $_refreshToken');
    }
  }

  // Clear tokens
  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    _accessToken = null;
    _refreshToken = null;
    if (kDebugMode) {
      print('Tokens cleared.');
    }
  }

  bool get isAuthenticated => _accessToken != null;

  // Register User
  Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    required String password,
    required String passwordConfirmation,
    required String businessName,
    required String businessType,
    required String businessAddress,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'phone': phone,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'business_name': businessName,
          'business_type': businessType,
          'business_address': businessAddress,
        }),
      );

      final data = jsonDecode(response.body);

      if (kDebugMode) {
        print('Register API Response Status: ${response.statusCode}');
        print('Register API Response Body: $data');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (data['data'] != null && data['data']['token'] != null) {
          await _saveTokens(data['data']['token'], data['data']['token']);
        }
        return data;
      } else {
        throw ApiException(
          message: data['message'] ?? 'Registration failed',
          statusCode: response.statusCode,
          errors: data['errors'],
        );
      }
    } on SocketException {
      throw ApiException(message: 'No internet connection.', statusCode: null);
    } on ApiException { // Catch ApiException specifically
      rethrow; // Re-throw the original ApiException
    } catch (e) { // Catch any other unexpected exceptions
      throw ApiException(
        message: 'Network error or unable to connect to server.',
        statusCode: null,
      );
    }
  }

  // Login User
  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'phone': phone,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (kDebugMode) {
        print('Login API Response Status: ${response.statusCode}');
        print('Login API Response Body: $data');
      }

      if (response.statusCode == 200 && data['success'] == true) {
        if (data['data'] != null && data['data']['token'] != null) {
          await _saveTokens(data['data']['token'], data['data']['token']);
        } else {
          throw ApiException(
            message: 'Login successful but token missing from response.',
            statusCode: response.statusCode,
          );
        }
        return data;
      } else {
        // Check for common incorrect credential messages from backend
        String backendMessage = data['message']?.toLowerCase() ?? '';
        throw ApiException(
          message: data['message'] ?? 'Login failed',
          statusCode: response.statusCode,
          errors: data['errors'],
        );
      }
    } on SocketException {
      throw ApiException(message: 'No internet connection.', statusCode: null);
    } catch (e) {
      throw ApiException(
        message: 'Network error or unable to connect to server.',
        statusCode: null,
      );
    }
  }

  // Forgot Password (Request Reset Token)
  Future<Map<String, dynamic>> forgotPassword({
    required String phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'phone': phone,
        }),
      );

      final data = jsonDecode(response.body);

      if (kDebugMode) {
        print('Forgot Password API Response Status: ${response.statusCode}');
        print('Forgot Password API Response Body: $data');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      } else {
        throw ApiException(
          message: data['message'] ?? 'Failed to request password reset token',
          statusCode: response.statusCode,
          errors: data['errors'],
        );
      }
    } on SocketException {
      throw ApiException(message: 'No internet connection.', statusCode: null);
    } catch (e) {
      throw ApiException(
        message: 'Network error or unable to connect to server.',
        statusCode: null,
      );
    }
  }

  // Reset Password
  Future<Map<String, dynamic>> resetPassword({
    required String phone,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'phone': phone,
          'token': token,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      final data = jsonDecode(response.body);

      if (kDebugMode) {
        print('Reset Password API Response Status: ${response.statusCode}');
        print('Reset Password API Response Body: $data');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      } else {
        throw ApiException(
          message: data['message'] ?? 'Failed to reset password',
          statusCode: response.statusCode,
          errors: data['errors'],
        );
      }
    } on SocketException {
      throw ApiException(message: 'No internet connection.', statusCode: null);
    } catch (e) {
      throw ApiException(
        message: 'Network error or unable to connect to server.',
        statusCode: null,
      );
    }
  }

  

  // Logout
  Future<void> logout() async {
    try {
      // Attempt to hit the backend logout endpoint
      // Using _makeAuthenticatedRequest to handle token
      await _makeAuthenticatedRequest('POST', '/auth/logout');
    } on ApiException catch (e) {
      if (kDebugMode) {
        print('API Exception during logout: $e');
      }
    } catch (e) {
      if (kDebugMode) {
        print('General error during logout: $e');
      }
    } finally {
      // Always clear local tokens after attempting backend logout
      await clearTokens();
    }
  }

  // Get user profile
  Future<Map<String, dynamic>> getUserProfile() async {
    return await _makeAuthenticatedRequest('GET', '/auth/me');
  }

  // Update user profile
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (phone != null) body['phone'] = phone;
    
    return await _makeAuthenticatedRequest('PUT', '/auth/profile', body: body);
  }

  // Get Inventory Items
  Future<List<Map<String, dynamic>>> getInventoryItems() async {
    final response = await _makeAuthenticatedRequest('GET', '/inventory');
    if (response['success'] == true && response['data'] is Map && response['data']['data'] is List) {
      return List<Map<String, dynamic>>.from(response['data']['data']);
    } else {
      if (kDebugMode) {
        print('No inventory items or unexpected data format: $response');
      }
      return [];
    }
  }

  // Get Inventory Item by ID
  Future<Map<String, dynamic>> getInventoryItemById(String id) async {
    final response = await _makeAuthenticatedRequest('GET', '/inventory/$id');
    if (response['success'] == true && response['data'] is Map) {
      return Map<String, dynamic>.from(response['data']);
    } else {
      throw ApiException(
        message: response['message'] ?? 'Failed to fetch inventory item by ID',
        statusCode: null,
      );
    }
  }

  // Get Business Records
  Future<List<Map<String, dynamic>>> getBusinessRecords({
    String? type,
    String? startDate,
    String? endDate,
  }) async {
    String endpoint = '/records';
    List<String> queryParams = [];
    if (type != null) queryParams.add('type=$type');
    if (startDate != null) queryParams.add('start_date=$startDate');
    if (endDate != null) queryParams.add('end_date=$endDate');
    queryParams.add('per_page=1000');
    queryParams.add('sort_by=date');
    queryParams.add('sort_order=desc');
    if (queryParams.isNotEmpty) {
      endpoint += '?${queryParams.join('&')}';
    }
    final response = await _makeAuthenticatedRequest('GET', endpoint);
    if (response['success'] == true && response['data'] != null && response['data']['data'] is List) {
      final records = List<Map<String, dynamic>>.from(response['data']['data']);
      return records;
    } else {
      if (kDebugMode) {
        print('No business records or unexpected data format: $response');
      }
      return [];
    }
  }

  // Get Business Records by Transaction ID
  Future<List<Map<String, dynamic>>> getBusinessRecordsByTransactionId(String transactionId) async {
    final response = await _makeAuthenticatedRequest('GET', '/records/by-transaction/' + transactionId);
    if (response['success'] == true && response['data'] is List) {
      return List<Map<String, dynamic>>.from(response['data']);
    } else {
      if (kDebugMode) {
        print('No business records found for transaction ID: $transactionId or unexpected data format: $response');
      }
      return [];
    }
  }

  // Get Dashboard Metrics
  Future<Map<String, dynamic>> getDashboardMetrics() async {
    final response = await _makeAuthenticatedRequest('GET', '/dashboard/metrics');
    if (response['success'] == true) {
      return response['data'];
    } else {
      throw ApiException(
        message: response['message'] ?? 'Failed to load dashboard metrics',
        statusCode: null,
      );
    }
  }

  // Get Dashboard Data (e.g., recent activities)
  Future<Map<String, dynamic>> getDashboardData() async {
    final response = await _makeAuthenticatedRequest('GET', '/dashboard');
    if (response['success'] == true && response.containsKey('data') && response['data'] is Map<String, dynamic>) {
      return response['data'];
    } else {
      throw ApiException(
        message: response['message'] ?? 'Failed to load dashboard data: Unexpected format.',
        statusCode: null,
      );
    }
  }

  // Get Sales Trends
  Future<List<Map<String, dynamic>>> getSalesTrends() async {
    final response = await _makeAuthenticatedRequest('GET', '/dashboard/sales-trends');
    if (response['success'] == true && response['data'] is List) {
      return List<Map<String, dynamic>>.from(response['data']);
    } else {
      if (kDebugMode) {
        print('No sales trends or unexpected data format: $response');
      }
      return [];
    }
  }

  // Get Top Products
  Future<List<Map<String, dynamic>>> getTopProducts() async {
    final response = await _makeAuthenticatedRequest('GET', '/dashboard/top-products');
    if (response['success'] == true && response['data'] is List) {
      return List<Map<String, dynamic>>.from(response['data']);
    } else {
      if (kDebugMode) {
        print('No top products or unexpected data format: $response');
      }
      return [];
    }
  }

  // Get Dashboard Summary
  Future<Map<String, dynamic>> getDashboardSummary() async {
    final response = await _makeAuthenticatedRequest('GET', '/dashboard/summary');
    if (response['success'] == true) {
      return response['data'];
    } else {
      throw ApiException(
        message: response['message'] ?? 'Failed to load dashboard summary',
        statusCode: null,
      );
    }
  }

  // Add Inventory Item
  Future<Map<String, dynamic>> addInventoryItem(Map<String, dynamic> item) async {
    return await _makeAuthenticatedRequest('POST', '/inventory', body: item);
  }

  // Update Inventory Item
  Future<Map<String, dynamic>> updateInventoryItem(String id, Map<String, dynamic> item) async {
    return await _makeAuthenticatedRequest('PUT', '/inventory/$id', body: item);
  }

  // Delete Inventory Item
  Future<void> deleteInventoryItem(String id) async {
    await _makeAuthenticatedRequest('DELETE', '/inventory/$id');
  }

  // Add Business Record
  Future<Map<String, dynamic>> addBusinessRecord(Map<String, dynamic> record) async {
    return await _makeAuthenticatedRequest('POST', '/records', body: record);
  }

  // Update Business Record
  Future<Map<String, dynamic>> updateBusinessRecord(String id, Map<String, dynamic> record) async {
    return await _makeAuthenticatedRequest('PUT', '/records/$id', body: record);
  }

  // Delete Business Record
  Future<void> deleteBusinessRecord(String id) async {
    await _makeAuthenticatedRequest('DELETE', '/records/$id');
  }

  // Get Notes
  Future<List<Map<String, dynamic>>> getNotes() async {
    final response = await _makeAuthenticatedRequest('GET', '/notes');
    if (response['data'] is List) {
      return List<Map<String, dynamic>>.from(response['data']);
    } else {
      if (kDebugMode) {
        print('No notes or unexpected data format: $response');
      }
      return [];
    }
  }

  // Add Note
  Future<Map<String, dynamic>> addNote(Map<String, dynamic> note) async {
    return await _makeAuthenticatedRequest('POST', '/notes', body: note);
  }

  // Update Note
  Future<Map<String, dynamic>> updateNote(String id, Map<String, dynamic> note) async {
    return await _makeAuthenticatedRequest('PUT', '/notes/$id', body: note);
  }

  // Delete Note
  Future<void> deleteNote(String id) async {
    await _makeAuthenticatedRequest('DELETE', '/notes/$id');
  }

  // Generic authenticated request method
  Future<Map<String, dynamic>> _makeAuthenticatedRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    if (_accessToken == null) {
      throw ApiException(message: 'Not authenticated. Access token is null.', statusCode: 401);
    }

    final uri = Uri.parse('$baseUrl$endpoint');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $_accessToken',
    };

    http.Response response;

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers);
          break;
        default:
          throw ApiException(message: 'Unsupported HTTP method: $method', statusCode: 400);
      }
    } catch (e) {
      throw ApiException(
        message: 'Network error or unable to connect to server: ${e.toString()}',
        statusCode: null,
      );
    }

    final data = jsonDecode(response.body);

    if (kDebugMode) {
      print('Authenticated Request - Endpoint: $endpoint, Status: ${response.statusCode}, Body: $data');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else if (response.statusCode == 401) {
      if (kDebugMode) {
        print('401 Unauthorized. Attempting token refresh...');
      }
      try {
        await _refreshAccessToken();
        
        headers['Authorization'] = 'Bearer $_accessToken';
        
        http.Response retryResponse;
        switch (method.toUpperCase()) {
          case 'GET': retryResponse = await http.get(uri, headers: headers); break;
          case 'POST': retryResponse = await http.post(uri, headers: headers, body: body != null ? jsonEncode(body) : null,); break;
          case 'PUT': retryResponse = await http.put(uri, headers: headers, body: body != null ? jsonEncode(body) : null,); break;
          case 'DELETE': retryResponse = await http.delete(uri, headers: headers); break;
          default: throw ApiException(
            message: 'Unsupported HTTP method on retry',
            statusCode: 400,
          );
        }

        final retryData = jsonDecode(retryResponse.body);
        if (kDebugMode) {
          print('Retry Request - Endpoint: $endpoint, Status: ${retryResponse.statusCode}, Body: ${retryData.toString().substring(0, retryData.toString().length > 500 ? 500 : retryData.toString().length)}');
        }

        if (retryResponse.statusCode >= 200 && retryResponse.statusCode < 300) {
          return retryData;
        } else {
          await clearTokens();
          throw ApiException(
            message: retryData['message'] ?? 'Request failed after token refresh attempt. Please login again.',
            statusCode: retryResponse.statusCode,
            errors: retryData['errors'],
          );
        }
      } on ApiException catch (e) {
        await clearTokens();
        rethrow;
      } catch (e) {
        await clearTokens();
        throw ApiException(
          message: 'Failed to refresh token or retry request: ${e.toString()}. Please login again.',
          statusCode: response.statusCode,
        );
      }
    } else {
      throw ApiException(
        message: data['message'] ?? 'Request failed',
        statusCode: response.statusCode,
        errors: data['errors'],
      );
    }
  }

  // Refresh access token
  Future<void> _refreshAccessToken() async {
    if (_refreshToken == null) {
      throw ApiException(message: 'No refresh token available. Please login again.', statusCode: 401);
    }

    final response = await http.post(
      Uri.parse('$baseUrl/auth/refresh'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    final data = jsonDecode(response.body);

    if (kDebugMode) {
      print('Refresh Token API Response Status: ${response.statusCode}');
      print('Refresh Token API Response Body: $data');
    }

    if (response.statusCode == 200 && data['success'] == true) {
      if (data['data'] != null && data['data']['token'] != null) {
         await _saveTokens(data['data']['token'], _refreshToken);
      } else {
          throw ApiException(
            message: 'Refresh successful but new token missing from response.',
            statusCode: response.statusCode,
          );
      }
    } else {
      await clearTokens();
      throw ApiException(
        message: data['message'] ?? 'Session expired. Please login again.',
        statusCode: response.statusCode,
        errors: data['errors'],
      );
    }
  }

  // Helper for generating headers
  Future<Map<String, String>> _headers() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  // --- DELETE THE FOLLOWING METHODS IF YOU ARE NOT USING THEM AND USING _makeAuthenticatedRequest INSTEAD ---
  // These are less robust as they don't handle token refresh or standardized error handling.
  // It's recommended to refactor calls using these to _makeAuthenticatedRequest.
  Future<Map<String, dynamic>> get(String endpoint) async {
    final uri = endpoint.startsWith('/') ? Uri.parse('$baseUrl$endpoint') : Uri.parse('$baseUrl/$endpoint');
    final response = await http.get(uri, headers: await _headers());
    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw ApiException(message: data['message'] ?? 'GET request failed', statusCode: response.statusCode, errors: data['errors']);
    }
  }

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    return await _makeAuthenticatedRequest('POST', endpoint, body: data);
  }

  Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data) async {
    final uri = endpoint.startsWith('/') ? Uri.parse('$baseUrl$endpoint') : Uri.parse('$baseUrl/$endpoint');
    final response = await http.put(
      uri,
      headers: await _headers(),
      body: jsonEncode(data),
    );
    final responseData = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseData;
    } else {
      throw ApiException(message: responseData['message'] ?? 'PUT request failed', statusCode: response.statusCode, errors: responseData['errors']);
    }
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    final uri = endpoint.startsWith('/') ? Uri.parse('$baseUrl$endpoint') : Uri.parse('$baseUrl/$endpoint');
    final response = await http.delete(uri, headers: await _headers());
    final responseData = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseData;
    } else {
      throw ApiException(message: responseData['message'] ?? 'DELETE request failed', statusCode: response.statusCode, errors: responseData['errors']);
    }
  }
  // --- END OF METHODS TO POTENTIALLY DELETE ---
}