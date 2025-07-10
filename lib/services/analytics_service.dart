import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:sandboxnotion/utils/constants.dart';

/// A service for tracking user analytics events throughout the app
class AnalyticsService {
  /// Singleton instance of the AnalyticsService
  static final AnalyticsService instance = AnalyticsService._internal();

  /// Firebase Analytics instance
  late final FirebaseAnalytics _analytics;

  /// Private constructor for singleton pattern
  AnalyticsService._internal() {
    _analytics = FirebaseAnalytics.instance;
    _initializeAnalytics();
  }

  /// Initialize analytics settings
  void _initializeAnalytics() {
    // Disable analytics in debug mode if needed
    if (kDebugMode) {
      // Uncomment to disable analytics in debug mode
      // _analytics.setAnalyticsCollectionEnabled(false);
    }
  }

  /// Get the analytics observer for navigation
  FirebaseAnalyticsObserver getAnalyticsObserver() {
    return FirebaseAnalyticsObserver(analytics: _analytics);
  }

  /// Log a screen view event
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
      _debugLog('Screen view: $screenName');
    } catch (e) {
      _handleError('logScreenView', e);
    }
  }

  /// Log a custom event with optional parameters
  Future<void> logCustomEvent({
    required String eventName,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: eventName,
        parameters: parameters,
      );
      _debugLog('Custom event: $eventName, params: $parameters');
    } catch (e) {
      _handleError('logCustomEvent', e);
    }
  }

  /// Log user properties for segmentation
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    try {
      await _analytics.setUserProperty(
        name: name,
        value: value,
      );
      _debugLog('User property: $name = $value');
    } catch (e) {
      _handleError('setUserProperty', e);
    }
  }

  /// Log when a user signs in
  Future<void> logLogin({String? method}) async {
    try {
      await _analytics.logLogin(loginMethod: method ?? 'email');
      _debugLog('Login event: method = $method');
    } catch (e) {
      _handleError('logLogin', e);
    }
  }

  /// Log when a user signs up
  Future<void> logSignUp({String? method}) async {
    try {
      await _analytics.logSignUp(signUpMethod: method ?? 'email');
      _debugLog('SignUp event: method = $method');
    } catch (e) {
      _handleError('logSignUp', e);
    }
  }

  /// Log when a user completes a purchase
  Future<void> logPurchase({
    required String id,
    required String productId,
    required double price,
    required String currency,
  }) async {
    try {
      await _analytics.logPurchase(
        transactionId: id,
        affiliation: 'App Store',
        currency: currency,
        value: price,
        items: [
          AnalyticsEventItem(
            itemId: productId,
            itemName: productId,
            price: price,
          ),
        ],
      );
      _debugLog('Purchase event: $productId for $price $currency');
    } catch (e) {
      _handleError('logPurchase', e);
    }
  }

  // SANDBOX-SPECIFIC ANALYTICS

  /// Log module interaction events
  Future<void> logModuleInteraction({
    required ModuleType moduleType,
    required String action,
    Map<String, dynamic>? additionalParams,
  }) async {
    try {
      final params = <String, dynamic>{
        'module_type': moduleType.name,
        'action': action,
      };

      if (additionalParams != null) {
        params.addAll(additionalParams);
      }

      await _analytics.logEvent(
        name: 'module_interaction',
        parameters: params,
      );
      _debugLog('Module interaction: ${moduleType.name}, action: $action');
    } catch (e) {
      _handleError('logModuleInteraction', e);
    }
  }

  /// Log sandbox layout changes
  Future<void> logSandboxLayoutChange({
    required int moduleCount,
    required List<ModuleType> activeModules,
  }) async {
    try {
      final moduleTypes = activeModules.map((m) => m.name).toList();
      
      await _analytics.logEvent(
        name: 'sandbox_layout_change',
        parameters: {
          'module_count': moduleCount,
          'active_modules': moduleTypes.join(','),
        },
      );
      _debugLog('Layout change: $moduleCount modules');
    } catch (e) {
      _handleError('logSandboxLayoutChange', e);
    }
  }

  /// Log AI feature usage
  Future<void> logAIFeatureUsage({
    required String featureName,
    required bool success,
    int? tokensUsed,
    int? responseTimeMs,
  }) async {
    try {
      final params = <String, dynamic>{
        'feature_name': featureName,
        'success': success,
      };

      if (tokensUsed != null) {
        params['tokens_used'] = tokensUsed;
      }

      if (responseTimeMs != null) {
        params['response_time_ms'] = responseTimeMs;
      }

      await _analytics.logEvent(
        name: 'ai_feature_usage',
        parameters: params,
      );
      _debugLog('AI feature usage: $featureName, success: $success');
    } catch (e) {
      _handleError('logAIFeatureUsage', e);
    }
  }

  /// Log subscription status change
  Future<void> logSubscriptionStatusChange({
    required bool isPremium,
    String? plan,
    String? source,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'subscription_status_change',
        parameters: {
          'is_premium': isPremium,
          'plan': plan ?? 'unknown',
          'source': source ?? 'unknown',
        },
      );
      _debugLog('Subscription change: isPremium=$isPremium, plan=$plan');
    } catch (e) {
      _handleError('logSubscriptionStatusChange', e);
    }
  }

  /// Log errors that occur in the app
  Future<void> logError({
    required String errorType,
    required String message,
    StackTrace? stackTrace,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'app_error',
        parameters: {
          'error_type': errorType,
          'message': message,
          'stack_trace': stackTrace?.toString() ?? 'unknown',
        },
      );
      _debugLog('Error logged: $errorType - $message');
    } catch (e) {
      _handleError('logError', e);
    }
  }

  /// Handle errors within the analytics service
  void _handleError(String methodName, dynamic error) {
    // Don't crash the app if analytics fails
    if (kDebugMode) {
      print('Analytics error in $methodName: $error');
    }
  }

  /// Debug log helper
  void _debugLog(String message) {
    if (kDebugMode) {
      print('Analytics: $message');
    }
  }
}
