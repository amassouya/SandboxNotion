import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// A service for handling and reporting errors throughout the app
class ErrorService {
  /// Singleton instance of the ErrorService
  static final ErrorService instance = ErrorService._internal();

  /// Logger instance for local logging
  late final Logger _logger;

  /// Private constructor for singleton pattern
  ErrorService._internal() {
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: !kIsWeb,
        printEmojis: true,
        printTime: true,
      ),
      level: kDebugMode ? Level.verbose : Level.info,
    );
  }

  /// Initialize the error service
  Future<void> initialize() async {
    try {
      // Configure Crashlytics in non-debug mode
      if (!kDebugMode) {
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      } else {
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
        _logger.i('Crashlytics disabled in debug mode');
      }
      
      _logger.i('Error service initialized successfully');
    } catch (e, stack) {
      _logger.e('Failed to initialize error service', error: e, stackTrace: stack);
    }
  }

  /// Log and report a non-fatal error
  Future<void> reportError(
    dynamic error,
    StackTrace stackTrace, {
    String? reason,
    bool fatal = false,
    Map<String, dynamic>? customKeys,
  }) async {
    // Always log locally
    _logger.e(
      reason ?? 'Error occurred',
      error: error,
      stackTrace: stackTrace,
    );
    
    // Only report to Crashlytics in non-debug mode
    if (!kDebugMode) {
      try {
        // Add custom keys if provided
        if (customKeys != null) {
          for (final entry in customKeys.entries) {
            FirebaseCrashlytics.instance.setCustomKey(entry.key, entry.value.toString());
          }
        }
        
        // Report the error
        await FirebaseCrashlytics.instance.recordError(
          error,
          stackTrace,
          reason: reason,
          fatal: fatal,
        );
      } catch (e) {
        // Handle errors in the error reporting itself
        _logger.e('Failed to report error to Crashlytics', error: e);
      }
    }
  }

  /// Log and report a Flutter-specific error
  Future<void> reportFlutterError(FlutterErrorDetails details) async {
    // Always log locally
    _logger.e(
      'Flutter error: ${details.exception}',
      error: details.exception,
      stackTrace: details.stack,
    );
    
    // Only report to Crashlytics in non-debug mode
    if (!kDebugMode) {
      try {
        await FirebaseCrashlytics.instance.recordFlutterError(details);
      } catch (e) {
        // Handle errors in the error reporting itself
        _logger.e('Failed to report Flutter error to Crashlytics', error: e);
      }
    } else {
      // In debug mode, print to console
      FlutterError.dumpErrorToConsole(details);
    }
  }

  /// Set a user identifier for error reports
  Future<void> setUserIdentifier(String userId) async {
    if (!kDebugMode) {
      await FirebaseCrashlytics.instance.setUserIdentifier(userId);
    }
  }

  /// Log a message (without reporting to Crashlytics)
  void log(String message, {Level level = Level.info, dynamic error, StackTrace? stackTrace}) {
    switch (level) {
      case Level.verbose:
        _logger.v(message, error: error, stackTrace: stackTrace);
        break;
      case Level.debug:
        _logger.d(message, error: error, stackTrace: stackTrace);
        break;
      case Level.info:
        _logger.i(message, error: error, stackTrace: stackTrace);
        break;
      case Level.warning:
        _logger.w(message, error: error, stackTrace: stackTrace);
        break;
      case Level.error:
        _logger.e(message, error: error, stackTrace: stackTrace);
        break;
      case Level.wtf:
        _logger.wtf(message, error: error, stackTrace: stackTrace);
        break;
      default:
        _logger.i(message, error: error, stackTrace: stackTrace);
    }
  }
}
