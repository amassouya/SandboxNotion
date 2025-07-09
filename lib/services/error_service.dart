import 'dart:async';
import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sandboxnotion/services/analytics_service.dart';
import 'package:sandboxnotion/utils/constants.dart';

/// A service that handles error reporting and provides user-friendly error messages
class ErrorService {
  // Singleton instance
  static final ErrorService instance = ErrorService._internal();
  
  // Private constructor
  ErrorService._internal();
  
  // Firebase Crashlytics instance
  late final FirebaseCrashlytics _crashlytics;
  
  // Flag to check if error reporting is enabled
  bool _enabled = !kDebugMode;
  
  /// Initialize the error service
  Future<void> initialize() async {
    _crashlytics = FirebaseCrashlytics.instance;
    
    try {
      // Set Crashlytics collection enabled based on debug mode
      await _crashlytics.setCrashlyticsCollectionEnabled(_enabled);
      
      // Set custom keys for better error categorization
      await _crashlytics.setCustomKey('app_version', AppConstants.appVersion);
      await _crashlytics.setCustomKey('build_number', AppConstants.appBuildNumber);
      
      debugPrint('Error service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing error service: $e');
    }
  }
  
  /// Enable or disable error reporting
  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    await _crashlytics.setCrashlyticsCollectionEnabled(enabled);
  }
  
  /// Report a non-fatal error to Crashlytics
  Future<void> reportError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
    Map<String, dynamic>? customKeys,
  }) async {
    if (!_enabled) {
      // Still log to console in debug mode
      debugPrint('ERROR: $reason - $error');
      debugPrint('STACK: ${stackTrace ?? 'No stack trace'}');
      return;
    }
    
    try {
      // Set custom keys if provided
      if (customKeys != null) {
        for (final entry in customKeys.entries) {
          await _crashlytics.setCustomKey(entry.key, entry.value.toString());
        }
      }
      
      // Set reason if provided
      if (reason != null) {
        await _crashlytics.setCustomKey('error_reason', reason);
      }
      
      // Log to analytics
      await AnalyticsService.instance.logError(
        errorType: error.runtimeType.toString(),
        errorMessage: error.toString(),
        stackTrace: stackTrace?.toString(),
      );
      
      // Report to Crashlytics
      await _crashlytics.recordError(
        error,
        stackTrace,
        reason: reason,
        fatal: fatal,
      );
    } catch (e) {
      debugPrint('Error reporting error to Crashlytics: $e');
    }
  }
  
  /// Report a custom error message to Crashlytics
  Future<void> reportMessage(
    String message, {
    String? category,
    Map<String, dynamic>? customKeys,
  }) async {
    if (!_enabled) {
      debugPrint('ERROR MESSAGE: $message');
      return;
    }
    
    try {
      // Set custom keys if provided
      if (customKeys != null) {
        for (final entry in customKeys.entries) {
          await _crashlytics.setCustomKey(entry.key, entry.value.toString());
        }
      }
      
      // Set category if provided
      if (category != null) {
        await _crashlytics.setCustomKey('error_category', category);
      }
      
      // Log to analytics
      await AnalyticsService.instance.logError(
        errorType: category ?? 'custom_message',
        errorMessage: message,
      );
      
      // Report to Crashlytics
      await _crashlytics.log(message);
    } catch (e) {
      debugPrint('Error reporting message to Crashlytics: $e');
    }
  }
  
  /// Set user identifier for error reports
  Future<void> setUserIdentifier(String userId) async {
    if (!_enabled) return;
    
    try {
      await _crashlytics.setUserIdentifier(userId);
    } catch (e) {
      debugPrint('Error setting user identifier: $e');
    }
  }
  
  /// Get a user-friendly error message based on the error type
  String getUserFriendlyMessage(dynamic error) {
    if (error is FirebaseException) {
      return _getFirebaseErrorMessage(error);
    } else if (error is SocketException || error is TimeoutException) {
      return AppConstants.networkErrorMessage;
    } else if (error is FormatException) {
      return 'Invalid format. Please check your input.';
    } else if (error is ArgumentError) {
      return 'Invalid argument. Please try again.';
    } else if (error is StateError) {
      return 'Application state error. Please restart the app.';
    } else if (error is AssertionError) {
      return 'Assertion failed. Please contact support.';
    } else if (error is TypeError) {
      return 'Type error. Please try again with valid input.';
    } else if (error is Exception) {
      return 'An unexpected error occurred: ${error.toString()}';
    } else {
      return AppConstants.defaultErrorMessage;
    }
  }
  
  /// Get a user-friendly error message for Firebase exceptions
  String _getFirebaseErrorMessage(FirebaseException error) {
    switch (error.code) {
      // Auth errors
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'This email address is already registered.';
      case 'weak-password':
        return 'Password is too weak. Please use a stronger password.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'requires-recent-login':
        return 'Please log in again before retrying this operation.';
      
      // Firestore errors
      case 'permission-denied':
        return AppConstants.permissionErrorMessage;
      case 'not-found':
        return 'The requested document was not found.';
      case 'already-exists':
        return 'A document with the same ID already exists.';
      case 'resource-exhausted':
        return AppConstants.quotaExceededMessage;
      
      // Storage errors
      case 'unauthorized':
        return 'You are not authorized to access this resource.';
      case 'object-not-found':
        return 'The requested file was not found.';
      case 'quota-exceeded':
        return 'Storage quota exceeded. Please free up space or upgrade your plan.';
      
      // Functions errors
      case 'functions/cancelled':
        return 'The operation was cancelled.';
      case 'functions/invalid-argument':
        return 'Invalid argument provided to the function.';
      case 'functions/deadline-exceeded':
        return 'The operation timed out. Please try again.';
      case 'functions/not-found':
        return 'The requested function was not found.';
      case 'functions/resource-exhausted':
        return AppConstants.quotaExceededMessage;
      
      // General errors
      case 'network-request-failed':
        return AppConstants.networkErrorMessage;
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'internal-error':
        return 'An internal error occurred. Please try again later.';
      
      default:
        return 'Firebase error: ${error.message ?? error.code}';
    }
  }
  
  /// Show a user-friendly error dialog
  Future<void> showErrorDialog(
    BuildContext context,
    dynamic error, {
    String? title,
    VoidCallback? onRetry,
  }) async {
    final errorMessage = getUserFriendlyMessage(error);
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title ?? 'Error'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(errorMessage),
              ],
            ),
          ),
          actions: <Widget>[
            if (onRetry != null)
              TextButton(
                child: const Text('Retry'),
                onPressed: () {
                  Navigator.of(context).pop();
                  onRetry();
                },
              ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  
  /// Show a user-friendly error snackbar
  void showErrorSnackBar(
    BuildContext context,
    dynamic error, {
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onRetry,
  }) {
    final errorMessage = getUserFriendlyMessage(error);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        duration: duration,
        action: onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                onPressed: onRetry,
              )
            : null,
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppConstants.errorColor,
      ),
    );
  }
  
  /// Force a test crash (only for testing Crashlytics)
  Future<void> forceCrash() async {
    if (!kDebugMode) {
      // Don't allow force crashes in release mode
      debugPrint('Force crash is only available in debug mode');
      return;
    }
    
    FirebaseCrashlytics.instance.crash();
  }
}
