import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sandboxnotion/utils/constants.dart';

/// A service that handles Firebase Analytics events and user properties
class AnalyticsService {
  // Singleton instance
  static final AnalyticsService instance = AnalyticsService._internal();
  
  // Private constructor
  AnalyticsService._internal();
  
  // Firebase Analytics instance
  late final FirebaseAnalytics _analytics;
  
  // Flag to check if analytics is enabled
  bool _enabled = !kDebugMode;
  
  /// Initialize the analytics service
  Future<void> initialize() async {
    _analytics = FirebaseAnalytics.instance;
    
    try {
      // Set analytics collection enabled based on debug mode
      await _analytics.setAnalyticsCollectionEnabled(_enabled);
      
      // Log initialization event
      if (_enabled) {
        await logAppOpen();
      }
    } catch (e) {
      debugPrint('Error initializing analytics: $e');
    }
  }
  
  /// Enable or disable analytics collection
  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    await _analytics.setAnalyticsCollectionEnabled(enabled);
  }
  
  /// Log app open event
  Future<void> logAppOpen() async {
    if (!_enabled) return;
    
    try {
      await _analytics.logAppOpen();
    } catch (e) {
      debugPrint('Error logging app open: $e');
    }
  }
  
  /// Log screen view event
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (!_enabled) return;
    
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
    } catch (e) {
      debugPrint('Error logging screen view: $e');
    }
  }
  
  /// Log user login event
  Future<void> logLogin({
    required String method,
  }) async {
    if (!_enabled) return;
    
    try {
      await _analytics.logLogin(
        loginMethod: method,
      );
    } catch (e) {
      debugPrint('Error logging login: $e');
    }
  }
  
  /// Log user sign up event
  Future<void> logSignUp({
    required String method,
  }) async {
    if (!_enabled) return;
    
    try {
      await _analytics.logSignUp(
        signUpMethod: method,
      );
    } catch (e) {
      debugPrint('Error logging sign up: $e');
    }
  }
  
  /// Log module interaction event
  Future<void> logModuleInteraction({
    required ModuleType moduleType,
    required String action,
    Map<String, dynamic>? parameters,
  }) async {
    if (!_enabled) return;
    
    try {
      final Map<String, dynamic> eventParams = {
        'module_type': moduleType.name,
        'action': action,
      };
      
      if (parameters != null) {
        eventParams.addAll(parameters);
      }
      
      await _analytics.logEvent(
        name: 'module_interaction',
        parameters: eventParams,
      );
    } catch (e) {
      debugPrint('Error logging module interaction: $e');
    }
  }
  
  /// Log sandbox layout change event
  Future<void> logSandboxLayoutChange({
    required int moduleCount,
    required List<ModuleType> activeModules,
  }) async {
    if (!_enabled) return;
    
    try {
      final Map<String, dynamic> eventParams = {
        'module_count': moduleCount,
        'active_modules': activeModules.map((m) => m.name).toList().join(','),
      };
      
      await _analytics.logEvent(
        name: 'sandbox_layout_change',
        parameters: eventParams,
      );
    } catch (e) {
      debugPrint('Error logging sandbox layout change: $e');
    }
  }
  
  /// Log AI feature usage event
  Future<void> logAIFeatureUsage({
    required String featureType,
    required int tokenCount,
    String? moduleContext,
  }) async {
    if (!_enabled) return;
    
    try {
      final Map<String, dynamic> eventParams = {
        'feature_type': featureType,
        'token_count': tokenCount,
      };
      
      if (moduleContext != null) {
        eventParams['module_context'] = moduleContext;
      }
      
      await _analytics.logEvent(
        name: 'ai_feature_usage',
        parameters: eventParams,
      );
    } catch (e) {
      debugPrint('Error logging AI feature usage: $e');
    }
  }
  
  /// Log subscription event
  Future<void> logSubscriptionEvent({
    required String action,
    required String tier,
    String? platform,
    double? price,
    String? currency,
  }) async {
    if (!_enabled) return;
    
    try {
      final Map<String, dynamic> eventParams = {
        'action': action,
        'tier': tier,
      };
      
      if (platform != null) {
        eventParams['platform'] = platform;
      }
      
      if (price != null) {
        eventParams['price'] = price;
      }
      
      if (currency != null) {
        eventParams['currency'] = currency;
      }
      
      await _analytics.logEvent(
        name: 'subscription_event',
        parameters: eventParams,
      );
    } catch (e) {
      debugPrint('Error logging subscription event: $e');
    }
  }
  
  /// Log error event
  Future<void> logError({
    required String errorType,
    required String errorMessage,
    String? stackTrace,
  }) async {
    if (!_enabled) return;
    
    try {
      final Map<String, dynamic> eventParams = {
        'error_type': errorType,
        'error_message': errorMessage,
      };
      
      if (stackTrace != null) {
        // Limit stack trace length to avoid exceeding Firebase param size limits
        eventParams['stack_trace'] = stackTrace.length > 100 
            ? stackTrace.substring(0, 100) 
            : stackTrace;
      }
      
      await _analytics.logEvent(
        name: 'app_error',
        parameters: eventParams,
      );
    } catch (e) {
      debugPrint('Error logging error event: $e');
    }
  }
  
  /// Log search event
  Future<void> logSearch({
    required String searchTerm,
    required String searchContext,
  }) async {
    if (!_enabled) return;
    
    try {
      await _analytics.logSearch(
        searchTerm: searchTerm,
        origin: searchContext,
      );
    } catch (e) {
      debugPrint('Error logging search: $e');
    }
  }
  
  /// Log share event
  Future<void> logShare({
    required String contentType,
    required String itemId,
    required String method,
  }) async {
    if (!_enabled) return;
    
    try {
      await _analytics.logShare(
        contentType: contentType,
        itemId: itemId,
        method: method,
      );
    } catch (e) {
      debugPrint('Error logging share: $e');
    }
  }
  
  /// Set user properties
  Future<void> setUserProperties({
    String? userId,
    String? subscriptionStatus,
    String? preferredModules,
    String? themeMode,
    String? deviceType,
    int? moduleCount,
  }) async {
    if (!_enabled) return;
    
    try {
      if (userId != null) {
        await _analytics.setUserId(id: userId);
      }
      
      if (subscriptionStatus != null) {
        await _analytics.setUserProperty(
          name: 'subscription_status',
          value: subscriptionStatus,
        );
      }
      
      if (preferredModules != null) {
        await _analytics.setUserProperty(
          name: 'preferred_modules',
          value: preferredModules,
        );
      }
      
      if (themeMode != null) {
        await _analytics.setUserProperty(
          name: 'theme_mode',
          value: themeMode,
        );
      }
      
      if (deviceType != null) {
        await _analytics.setUserProperty(
          name: 'device_type',
          value: deviceType,
        );
      }
      
      if (moduleCount != null) {
        await _analytics.setUserProperty(
          name: 'module_count',
          value: moduleCount.toString(),
        );
      }
    } catch (e) {
      debugPrint('Error setting user properties: $e');
    }
  }
  
  /// Reset all analytics data
  Future<void> resetAnalyticsData() async {
    if (!_enabled) return;
    
    try {
      await _analytics.resetAnalyticsData();
    } catch (e) {
      debugPrint('Error resetting analytics data: $e');
    }
  }
  
  /// Log custom event
  Future<void> logCustomEvent({
    required String eventName,
    Map<String, dynamic>? parameters,
  }) async {
    if (!_enabled) return;
    
    try {
      await _analytics.logEvent(
        name: eventName,
        parameters: parameters,
      );
    } catch (e) {
      debugPrint('Error logging custom event: $e');
    }
  }
}
