
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_exception.dart'; // Correctly import ApiException from its dedicated file
import '../providers/auth_provider.dart';
import 'package:flutter/foundation.dart'; // Added this import

class ErrorHandler {
  static final Map<String, String> _localizedErrorMessages = {
    'not authenticated': 'Muda umeisha. Tafadhali ingia tena.', // Session expired
    'unauthorized': 'Muda umeisha. Tafadhali ingia tena.', // Session expired
    'invalid credentials': 'Namba ya simu au Nywila sio sahihi', // Login error
    'these credentials do not match our records.': 'Namba ya simu au Nywila sio sahihi', // Common Laravel login error
    'invalid otp': 'OTP uliyoweka sio sahihi', // OTP error
    'the provided token is invalid.': 'OTP uliyoweka sio sahihi', // Common Laravel OTP error
    'phone has already been taken': 'Namba ya simu tayari imetumika',
    'the phone has already been taken.': 'Namba ya simu tayari imetumika', // Common Laravel validation error
    'the password confirmation does not match.': 'Neno la siri halifanani.', // Common Laravel validation error
    // Add more mappings as needed
  };

  static void handleError(BuildContext context, dynamic error) {
    String message = 'Hitilafu imetokea'; // Default generic message
    bool shouldLogout = false;

    if (kDebugMode) { // Add this block for debugging
      print('ErrorHandler: Received error type: ${error.runtimeType}');
      print('ErrorHandler: Received error: $error');
      if (error is ApiException) {
        print('ErrorHandler: ApiException message: ${error.message}');
        print('ErrorHandler: ApiException statusCode: ${error.statusCode}');
        print('ErrorHandler: ApiException errors: ${error.errors}');
      }
    }

    if (error is ApiException) {
      String apiMessage = error.message.toLowerCase();

      // Check for authentication error (401)
      if (error.statusCode == 401) {
        // Differentiate between invalid login and session expired
        if (apiMessage.toLowerCase() == 'invalid credentials' || apiMessage.toLowerCase() == 'these credentials do not match our records.') {
          message = _localizedErrorMessages[apiMessage.toLowerCase()] ?? error.message;
        } else { // Assume session expired for other 401s
          shouldLogout = true;
          message = _localizedErrorMessages['not authenticated'] ?? 'Kikao kimeisha. Tafadhali ingia tena.';
        }
      } else {
        // Try to get a specific error from the backend's 'errors' map first
        if (error.errors != null && error.errors!.isNotEmpty) {
          final firstError = error.errors!.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            apiMessage = firstError.first.toString().toLowerCase();
            if (kDebugMode) { // Add for debugging
              print('ErrorHandler: Extracted apiMessage from errors map: $apiMessage');
            }
          }
        }

        // Translate known messages
        message = _localizedErrorMessages[apiMessage] ?? error.message; // Use original message if no translation
      }
    } else if (error is Exception) {
      message = error.toString();
    }
    
    if (shouldLogout) {
      // Show dialog in the center of the screen
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Session Expired'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
      // Automatically logout the user
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.logout();
      return; // Don't show SnackBar for session expiration
    }
    
    // For other errors, show SnackBar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    });
  }
  
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}
