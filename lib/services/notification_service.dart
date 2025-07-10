import 'dart:async';
import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';
import 'package:sandboxnotion/services/error_service.dart';

/// A service for handling notifications and Firebase Cloud Messaging
class NotificationService {
  /// Singleton instance of the NotificationService
  static final NotificationService instance = NotificationService._internal();

  /// Firebase Messaging instance
  late final FirebaseMessaging _messaging;
  
  /// Flutter Local Notifications plugin
  late final FlutterLocalNotificationsPlugin _localNotifications;
  
  /// Logger instance
  late final Logger _logger;
  
  /// Stream controller for notification taps
  final StreamController<RemoteMessage> _onMessageOpenedAppController = 
      StreamController<RemoteMessage>.broadcast();
  
  /// Stream of notification taps when app is opened from terminated state
  Stream<RemoteMessage> get onMessageOpenedApp => 
      _onMessageOpenedAppController.stream;
  
  /// Whether notifications are enabled
  bool _notificationsEnabled = false;

  /// Private constructor for singleton pattern
  NotificationService._internal() {
    _messaging = FirebaseMessaging.instance;
    _localNotifications = FlutterLocalNotificationsPlugin();
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 1,
        errorMethodCount: 5,
        lineLength: 120,
        colors: !kIsWeb,
        printEmojis: true,
        printTime: true,
      ),
      level: kDebugMode ? Level.verbose : Level.info,
    );
  }

  /// Initialize the notification service
  Future<void> initialize() async {
    try {
      // Skip initialization on web platform
      if (kIsWeb) {
        _logger.i('Notifications not supported on web platform');
        return;
      }
      
      // Request permission
      await _requestPermission();
      
      // Configure local notifications
      await _configureLocalNotifications();
      
      // Configure foreground notifications
      await _configureForegroundNotifications();
      
      // Handle notification that opened the app
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _logger.i('Notification opened app: ${message.messageId}');
        _onMessageOpenedAppController.add(message);
      });
      
      // Check for initial message (app opened from terminated state)
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _logger.i('App opened from terminated state by notification: ${initialMessage.messageId}');
        _onMessageOpenedAppController.add(initialMessage);
      }
      
      _logger.i('Notification service initialized successfully');
    } catch (e, stack) {
      _logger.e('Failed to initialize notification service', error: e, stackTrace: stack);
      ErrorService.instance.reportError(
        e, 
        stack, 
        reason: 'Failed to initialize notification service',
      );
    }
  }

  /// Request notification permissions
  Future<void> _requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: true,
        sound: true,
      );
      
      _notificationsEnabled = settings.authorizationStatus == AuthorizationStatus.authorized ||
                             settings.authorizationStatus == AuthorizationStatus.provisional;
      
      _logger.i('Notification permission status: ${settings.authorizationStatus}');
      
      // Configure FCM
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e, stack) {
      _logger.e('Failed to request notification permission', error: e, stackTrace: stack);
      ErrorService.instance.reportError(
        e, 
        stack, 
        reason: 'Failed to request notification permission',
      );
    }
  }

  /// Configure local notifications
  Future<void> _configureLocalNotifications() async {
    try {
      // Android initialization
      const androidInitializationSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS initialization
      final iosInitializationSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        onDidReceiveLocalNotification: (id, title, body, payload) async {
          _logger.d('Received local notification: $id, $title, $body, $payload');
        },
      );
      
      // Initialize local notifications
      final initializationSettings = InitializationSettings(
        android: androidInitializationSettings,
        iOS: iosInitializationSettings,
      );
      
      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          _logger.d('Local notification tapped: ${response.payload}');
        },
      );
      
      // Create notification channel for Android
      if (Platform.isAndroid) {
        const channel = AndroidNotificationChannel(
          'high_importance_channel',
          'High Importance Notifications',
          description: 'This channel is used for important notifications.',
          importance: Importance.high,
        );
        
        await _localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
      }
    } catch (e, stack) {
      _logger.e('Failed to configure local notifications', error: e, stackTrace: stack);
      ErrorService.instance.reportError(
        e, 
        stack, 
        reason: 'Failed to configure local notifications',
      );
    }
  }

  /// Configure foreground notifications
  Future<void> _configureForegroundNotifications() async {
    try {
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _logger.i('Received foreground message: ${message.messageId}');
        _handleForegroundMessage(message);
      });
    } catch (e, stack) {
      _logger.e('Failed to configure foreground notifications', error: e, stackTrace: stack);
      ErrorService.instance.reportError(
        e, 
        stack, 
        reason: 'Failed to configure foreground notifications',
      );
    }
  }

  /// Handle foreground message
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      // Extract notification data
      final notification = message.notification;
      final android = message.notification?.android;
      
      // Show local notification if notification data is available
      if (notification != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              channelDescription: 'This channel is used for important notifications.',
              icon: android?.smallIcon ?? '@mipmap/ic_launcher',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: message.data.toString(),
        );
      }
    } catch (e, stack) {
      _logger.e('Failed to handle foreground message', error: e, stackTrace: stack);
      ErrorService.instance.reportError(
        e, 
        stack, 
        reason: 'Failed to handle foreground message',
      );
    }
  }

  /// Handle background message
  Future<void> handleBackgroundMessage(RemoteMessage message) async {
    try {
      _logger.i('Handling background message: ${message.messageId}');
      
      // Process message data
      // Note: In background messages, we can't show UI or use plugins that interact with UI
      // We can only process data and update local storage or make network requests
      
      // Log the message data for debugging
      _logger.d('Background message data: ${message.data}');
    } catch (e, stack) {
      // Report error to Crashlytics
      if (!kDebugMode) {
        FirebaseCrashlytics.instance.recordError(
          e,
          stack,
          reason: 'Failed to handle background message',
          fatal: false,
        );
      }
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      _logger.i('Subscribed to topic: $topic');
    } catch (e, stack) {
      _logger.e('Failed to subscribe to topic: $topic', error: e, stackTrace: stack);
      ErrorService.instance.reportError(
        e, 
        stack, 
        reason: 'Failed to subscribe to topic: $topic',
      );
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      _logger.i('Unsubscribed from topic: $topic');
    } catch (e, stack) {
      _logger.e('Failed to unsubscribe from topic: $topic', error: e, stackTrace: stack);
      ErrorService.instance.reportError(
        e, 
        stack, 
        reason: 'Failed to unsubscribe from topic: $topic',
      );
    }
  }

  /// Get the FCM token
  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      _logger.i('FCM Token: ${token?.substring(0, 10)}...');
      return token;
    } catch (e, stack) {
      _logger.e('Failed to get FCM token', error: e, stackTrace: stack);
      ErrorService.instance.reportError(
        e, 
        stack, 
        reason: 'Failed to get FCM token',
      );
      return null;
    }
  }

  /// Delete the FCM token
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      _logger.i('FCM Token deleted');
    } catch (e, stack) {
      _logger.e('Failed to delete FCM token', error: e, stackTrace: stack);
      ErrorService.instance.reportError(
        e, 
        stack, 
        reason: 'Failed to delete FCM token',
      );
    }
  }

  /// Check if notifications are enabled
  bool get areNotificationsEnabled => _notificationsEnabled;

  /// Dispose resources
  void dispose() {
    _onMessageOpenedAppController.close();
  }
}
