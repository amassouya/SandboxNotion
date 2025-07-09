import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/subjects.dart';
import 'package:sandboxnotion/services/analytics_service.dart';
import 'package:sandboxnotion/services/error_service.dart';
import 'package:sandboxnotion/utils/constants.dart';
import 'package:sandboxnotion/utils/platform_utils.dart';

/// Data model for notifications
class AppNotification {
  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final Map<String, dynamic>? data;
  final DateTime timestamp;
  final NotificationType type;
  final bool isRead;
  final String? actionRoute;
  
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    this.data,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.actionRoute,
  });
  
  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    String? imageUrl,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    NotificationType? type,
    bool? isRead,
    String? actionRoute,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      actionRoute: actionRoute ?? this.actionRoute,
    );
  }
  
  factory AppNotification.fromRemoteMessage(RemoteMessage message) {
    final data = message.data;
    final notification = message.notification;
    
    return AppNotification(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: notification?.title ?? 'SandboxNotion',
      body: notification?.body ?? '',
      imageUrl: notification?.android?.imageUrl ?? notification?.apple?.imageUrl,
      data: data,
      timestamp: message.sentTime ?? DateTime.now(),
      type: _getNotificationTypeFromData(data),
      actionRoute: data['route'],
    );
  }
  
  factory AppNotification.fromLocalNotification(
    int id,
    String title,
    String body,
    NotificationType type, {
    String? imageUrl,
    Map<String, dynamic>? data,
    String? actionRoute,
  }) {
    return AppNotification(
      id: id.toString(),
      title: title,
      body: body,
      imageUrl: imageUrl,
      data: data,
      timestamp: DateTime.now(),
      type: type,
      actionRoute: actionRoute,
    );
  }
  
  static NotificationType _getNotificationTypeFromData(Map<String, dynamic> data) {
    final typeString = data['type'] as String?;
    
    if (typeString != null) {
      try {
        return NotificationType.values.firstWhere(
          (e) => e.toString().split('.').last == typeString,
          orElse: () => NotificationType.general,
        );
      } catch (_) {
        return NotificationType.general;
      }
    }
    
    // Try to infer type from other data
    if (data.containsKey('event_id')) {
      return NotificationType.calendar;
    } else if (data.containsKey('task_id')) {
      return NotificationType.todo;
    } else if (data.containsKey('note_id')) {
      return NotificationType.notes;
    } else if (data.containsKey('board_id')) {
      return NotificationType.whiteboard;
    } else if (data.containsKey('card_id')) {
      return NotificationType.cards;
    } else if (data.containsKey('subscription_id')) {
      return NotificationType.subscription;
    }
    
    return NotificationType.general;
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'data': data,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'type': type.toString().split('.').last,
      'isRead': isRead,
      'actionRoute': actionRoute,
    };
  }
  
  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      imageUrl: map['imageUrl'] as String?,
      data: map['data'] as Map<String, dynamic>?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      type: NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => NotificationType.general,
      ),
      isRead: map['isRead'] as bool? ?? false,
      actionRoute: map['actionRoute'] as String?,
    );
  }
  
  String toJson() => json.encode(toMap());
  
  factory AppNotification.fromJson(String source) => 
      AppNotification.fromMap(json.decode(source) as Map<String, dynamic>);
      
  @override
  String toString() {
    return 'AppNotification(id: $id, title: $title, body: $body, type: $type, isRead: $isRead)';
  }
}

/// Types of notifications in the app
enum NotificationType {
  general,
  calendar,
  todo,
  notes,
  whiteboard,
  cards,
  subscription,
  system,
}

/// Service to handle all types of notifications: FCM, local, and in-app
class NotificationService {
  // Singleton instance
  static final NotificationService instance = NotificationService._internal();
  
  // Private constructor
  NotificationService._internal();
  
  // Firebase Messaging instance
  late final FirebaseMessaging _messaging;
  
  // Flutter Local Notifications plugin
  late final FlutterLocalNotificationsPlugin _localNotifications;
  
  // Stream controller for in-app notifications
  final _notificationStreamController = BehaviorSubject<AppNotification>();
  
  // Stream of recent notifications
  final _recentNotifications = BehaviorSubject<List<AppNotification>>.seeded([]);
  
  // Maximum number of recent notifications to keep
  static const _maxRecentNotifications = 50;
  
  // Notification channel IDs
  static const String _channelId = 'sandboxnotion_channel';
  static const String _channelName = 'SandboxNotion Notifications';
  static const String _channelDescription = 'Notifications from SandboxNotion app';
  
  // High importance channel for urgent notifications
  static const String _highImportanceChannelId = 'sandboxnotion_high_importance_channel';
  static const String _highImportanceChannelName = 'Important Notifications';
  static const String _highImportanceChannelDescription = 'Urgent notifications from SandboxNotion app';
  
  // Flag to track if notifications are enabled
  bool _notificationsEnabled = false;
  
  // Notification permission status
  AuthorizationStatus _permissionStatus = AuthorizationStatus.notDetermined;
  
  /// Initialize the notification service
  Future<void> initialize() async {
    try {
      // Initialize Firebase Messaging
      _messaging = FirebaseMessaging.instance;
      
      // Initialize Flutter Local Notifications
      _localNotifications = FlutterLocalNotificationsPlugin();
      
      // Request permission for notifications
      await _requestPermission();
      
      // Initialize platform-specific notification settings
      await _initPlatformSpecificSettings();
      
      // Configure FCM message handling
      _configureFCM();
      
      debugPrint('Notification service initialized successfully');
    } catch (e, stack) {
      debugPrint('Error initializing notification service: $e');
      await ErrorService.instance.reportError(
        e,
        stack,
        reason: 'Failed to initialize notification service',
      );
    }
  }
  
  /// Request permission for notifications
  Future<void> _requestPermission() async {
    if (kIsWeb) {
      // Web platform has a different permission model
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      
      _permissionStatus = settings.authorizationStatus;
      _notificationsEnabled = _permissionStatus == AuthorizationStatus.authorized || 
                             _permissionStatus == AuthorizationStatus.provisional;
                             
      debugPrint('Web notification permission status: $_permissionStatus');
    } else if (Platform.isIOS || Platform.isMacOS) {
      // iOS and macOS
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: true,
        sound: true,
      );
      
      _permissionStatus = settings.authorizationStatus;
      _notificationsEnabled = _permissionStatus == AuthorizationStatus.authorized || 
                             _permissionStatus == AuthorizationStatus.provisional;
                             
      // Also request permission for local notifications
      final localResult = await _localNotifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          
      if (localResult != null) {
        _notificationsEnabled = _notificationsEnabled && localResult;
      }
      
      debugPrint('iOS notification permission status: $_permissionStatus, local: $localResult');
    } else if (Platform.isAndroid) {
      // Android doesn't need explicit permission for FCM since API level 33+
      // but we still request for local notifications
      final localResult = await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestPermission();
          
      _notificationsEnabled = localResult ?? false;
      _permissionStatus = _notificationsEnabled 
          ? AuthorizationStatus.authorized 
          : AuthorizationStatus.denied;
          
      debugPrint('Android notification permission status: $localResult');
    }
    
    // Get FCM token
    if (_notificationsEnabled) {
      await _getFCMToken();
    }
  }
  
  /// Initialize platform-specific notification settings
  Future<void> _initPlatformSpecificSettings() async {
    // Android initialization
    const androidInitSettings = AndroidInitializationSettings('ic_notification');
    
    // iOS initialization
    final iosInitSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
    );
    
    // Initialize settings
    final initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
      macOS: iosInitSettings,
    );
    
    // Initialize local notifications plugin
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );
    
    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }
  }
  
  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    // Default channel
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.defaultImportance,
      enableVibration: true,
      enableLights: true,
    );
    
    // High importance channel
    const androidHighImportanceChannel = AndroidNotificationChannel(
      _highImportanceChannelId,
      _highImportanceChannelName,
      description: _highImportanceChannelDescription,
      importance: Importance.high,
      enableVibration: true,
      enableLights: true,
    );
    
    // Create the channels
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
        
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidHighImportanceChannel);
  }
  
  /// Configure FCM message handling
  void _configureFCM() {
    // Handle messages when the app is in the foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle when the app is opened from a notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    
    // Set foreground notification presentation options
    _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }
  
  /// Get FCM token for this device
  Future<String?> _getFCMToken() async {
    try {
      final token = await _messaging.getToken();
      debugPrint('FCM Token: ${token?.substring(0, min(10, token?.length ?? 0))}...');
      return token;
    } catch (e, stack) {
      debugPrint('Error getting FCM token: $e');
      await ErrorService.instance.reportError(
        e,
        stack,
        reason: 'Failed to get FCM token',
      );
      return null;
    }
  }
  
  /// Handle foreground FCM messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Handling foreground message: ${message.messageId}');
    
    try {
      // Convert to app notification
      final notification = AppNotification.fromRemoteMessage(message);
      
      // Add to recent notifications
      _addToRecentNotifications(notification);
      
      // Send to stream for in-app display
      _notificationStreamController.add(notification);
      
      // Log analytics
      await AnalyticsService.instance.logCustomEvent(
        eventName: 'notification_received',
        parameters: {
          'message_id': message.messageId ?? '',
          'notification_type': notification.type.toString().split('.').last,
          'foreground': true,
        },
      );
      
      // Show local notification if there's a notification payload
      if (message.notification != null) {
        await _showLocalNotificationFromRemoteMessage(message);
      }
    } catch (e, stack) {
      debugPrint('Error handling foreground message: $e');
      await ErrorService.instance.reportError(
        e,
        stack,
        reason: 'Failed to handle foreground message',
      );
    }
  }
  
  /// Handle when app is opened from a notification
  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    debugPrint('App opened from notification: ${message.messageId}');
    
    try {
      // Convert to app notification
      final notification = AppNotification.fromRemoteMessage(message);
      
      // Add to recent notifications
      _addToRecentNotifications(notification);
      
      // Log analytics
      await AnalyticsService.instance.logCustomEvent(
        eventName: 'notification_opened',
        parameters: {
          'message_id': message.messageId ?? '',
          'notification_type': notification.type.toString().split('.').last,
        },
      );
      
      // Handle navigation based on notification data
      if (notification.actionRoute != null) {
        // Navigation will be handled by the UI layer that's listening to this stream
        _notificationStreamController.add(notification);
      }
    } catch (e, stack) {
      debugPrint('Error handling opened notification: $e');
      await ErrorService.instance.reportError(
        e,
        stack,
        reason: 'Failed to handle opened notification',
      );
    }
  }
  
  /// Handle background messages (must be implemented at top level in main.dart)
  Future<void> handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('Handling background message: ${message.messageId}');
    
    try {
      // Log analytics
      await AnalyticsService.instance.logCustomEvent(
        eventName: 'notification_received',
        parameters: {
          'message_id': message.messageId ?? '',
          'background': true,
        },
      );
    } catch (e) {
      debugPrint('Error handling background message: $e');
    }
  }
  
  /// Show a local notification from a remote message
  Future<void> _showLocalNotificationFromRemoteMessage(RemoteMessage message) async {
    if (!_notificationsEnabled) return;
    
    final notification = message.notification;
    if (notification == null) return;
    
    try {
      // Determine notification importance
      final channelId = _getChannelIdForNotificationType(
        AppNotification._getNotificationTypeFromData(message.data),
      );
      
      // Android-specific notification details
      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelId == _highImportanceChannelId
            ? _highImportanceChannelName
            : _channelName,
        channelDescription: channelId == _highImportanceChannelId
            ? _highImportanceChannelDescription
            : _channelDescription,
        importance: channelId == _highImportanceChannelId
            ? Importance.high
            : Importance.defaultImportance,
        priority: channelId == _highImportanceChannelId
            ? Priority.high
            : Priority.defaultPriority,
        icon: 'ic_notification',
        largeIcon: notification.android?.imageUrl != null
            ? ByteArrayAndroidBitmap(
                await _getBytesFromUrl(notification.android!.imageUrl!),
              )
            : null,
        styleInformation: notification.android?.imageUrl != null
            ? BigPictureStyleInformation(
                ByteArrayAndroidBitmap(
                  await _getBytesFromUrl(notification.android!.imageUrl!),
                ),
                largeIcon: ByteArrayAndroidBitmap(
                  await _getBytesFromUrl(notification.android!.imageUrl!),
                ),
              )
            : null,
        color: AppConstants.seedColor,
        colorized: true,
      );
      
      // iOS/macOS-specific notification details
      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        attachments: notification.apple?.imageUrl != null
            ? [
                DarwinNotificationAttachment(
                  notification.apple!.imageUrl!,
                )
              ]
            : null,
        categoryIdentifier: _getCategoryForNotificationType(
          AppNotification._getNotificationTypeFromData(message.data),
        ),
      );
      
      // Show the notification
      await _localNotifications.show(
        message.messageId.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
          macOS: iosDetails,
        ),
        payload: json.encode(message.data),
      );
    } catch (e, stack) {
      debugPrint('Error showing local notification: $e');
      await ErrorService.instance.reportError(
        e,
        stack,
        reason: 'Failed to show local notification',
      );
    }
  }
  
  /// Show a local notification
  Future<void> showLocalNotification({
    required String title,
    required String body,
    required NotificationType type,
    String? imageUrl,
    Map<String, dynamic>? data,
    String? actionRoute,
    bool highImportance = false,
  }) async {
    if (!_notificationsEnabled) return;
    
    try {
      // Generate a unique ID for the notification
      final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
      
      // Determine notification channel
      final channelId = highImportance
          ? _highImportanceChannelId
          : _getChannelIdForNotificationType(type);
      
      // Android-specific notification details
      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelId == _highImportanceChannelId
            ? _highImportanceChannelName
            : _channelName,
        channelDescription: channelId == _highImportanceChannelId
            ? _highImportanceChannelDescription
            : _channelDescription,
        importance: highImportance
            ? Importance.high
            : Importance.defaultImportance,
        priority: highImportance
            ? Priority.high
            : Priority.defaultPriority,
        icon: 'ic_notification',
        largeIcon: imageUrl != null
            ? ByteArrayAndroidBitmap(
                await _getBytesFromUrl(imageUrl),
              )
            : null,
        styleInformation: imageUrl != null
            ? BigPictureStyleInformation(
                ByteArrayAndroidBitmap(
                  await _getBytesFromUrl(imageUrl),
                ),
                largeIcon: ByteArrayAndroidBitmap(
                  await _getBytesFromUrl(imageUrl),
                ),
              )
            : null,
        color: AppConstants.seedColor,
        colorized: true,
      );
      
      // iOS/macOS-specific notification details
      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        attachments: imageUrl != null
            ? [
                DarwinNotificationAttachment(
                  imageUrl,
                )
              ]
            : null,
        categoryIdentifier: _getCategoryForNotificationType(type),
      );
      
      // Create notification payload
      final payload = json.encode({
        'type': type.toString().split('.').last,
        'route': actionRoute,
        ...?data,
      });
      
      // Show the notification
      await _localNotifications.show(
        id,
        title,
        body,
        NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
          macOS: iosDetails,
        ),
        payload: payload,
      );
      
      // Create app notification
      final notification = AppNotification.fromLocalNotification(
        id,
        title,
        body,
        type,
        imageUrl: imageUrl,
        data: data,
        actionRoute: actionRoute,
      );
      
      // Add to recent notifications
      _addToRecentNotifications(notification);
      
      // Log analytics
      await AnalyticsService.instance.logCustomEvent(
        eventName: 'local_notification_shown',
        parameters: {
          'notification_id': id.toString(),
          'notification_type': type.toString().split('.').last,
          'high_importance': highImportance,
        },
      );
    } catch (e, stack) {
      debugPrint('Error showing local notification: $e');
      await ErrorService.instance.reportError(
        e,
        stack,
        reason: 'Failed to show local notification',
      );
    }
  }
  
  /// Schedule a local notification for a future time
  Future<void> scheduleLocalNotification({
    required String title,
    required String body,
    required NotificationType type,
    required DateTime scheduledDate,
    String? imageUrl,
    Map<String, dynamic>? data,
    String? actionRoute,
    bool highImportance = false,
  }) async {
    if (!_notificationsEnabled) return;
    
    try {
      // Generate a unique ID for the notification
      final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
      
      // Determine notification channel
      final channelId = highImportance
          ? _highImportanceChannelId
          : _getChannelIdForNotificationType(type);
      
      // Android-specific notification details
      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelId == _highImportanceChannelId
            ? _highImportanceChannelName
            : _channelName,
        channelDescription: channelId == _highImportanceChannelId
            ? _highImportanceChannelDescription
            : _channelDescription,
        importance: highImportance
            ? Importance.high
            : Importance.defaultImportance,
        priority: highImportance
            ? Priority.high
            : Priority.defaultPriority,
        icon: 'ic_notification',
        color: AppConstants.seedColor,
        colorized: true,
      );
      
      // iOS/macOS-specific notification details
      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: _getCategoryForNotificationType(type),
      );
      
      // Create notification payload
      final payload = json.encode({
        'type': type.toString().split('.').last,
        'route': actionRoute,
        ...?data,
      });
      
      // Schedule the notification
      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        TZDateTime.from(scheduledDate, local),
        NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
          macOS: iosDetails,
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      
      // Log analytics
      await AnalyticsService.instance.logCustomEvent(
        eventName: 'notification_scheduled',
        parameters: {
          'notification_id': id.toString(),
          'notification_type': type.toString().split('.').last,
          'scheduled_time': scheduledDate.millisecondsSinceEpoch,
          'high_importance': highImportance,
        },
      );
    } catch (e, stack) {
      debugPrint('Error scheduling notification: $e');
      await ErrorService.instance.reportError(
        e,
        stack,
        reason: 'Failed to schedule notification',
      );
    }
  }
  
  /// Show an in-app notification
  void showInAppNotification(AppNotification notification) {
    // Add to recent notifications
    _addToRecentNotifications(notification);
    
    // Send to stream for in-app display
    _notificationStreamController.add(notification);
  }
  
  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }
  
  /// Cancel all pending notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }
  
  /// Get the notification stream for in-app notifications
  Stream<AppNotification> get notificationStream => _notificationStreamController.stream;
  
  /// Get the stream of recent notifications
  Stream<List<AppNotification>> get recentNotifications => _recentNotifications.stream;
  
  /// Get the current list of recent notifications
  List<AppNotification> get currentNotifications => _recentNotifications.value;
  
  /// Check if notifications are enabled
  bool get notificationsEnabled => _notificationsEnabled;
  
  /// Get the current permission status
  AuthorizationStatus get permissionStatus => _permissionStatus;
  
  /// Request notification permissions again (useful if previously denied)
  Future<bool> requestPermissionsAgain() async {
    await _requestPermission();
    return _notificationsEnabled;
  }
  
  /// Mark a notification as read
  void markAsRead(String notificationId) {
    final notifications = List<AppNotification>.from(_recentNotifications.value);
    final index = notifications.indexWhere((n) => n.id == notificationId);
    
    if (index != -1) {
      notifications[index] = notifications[index].copyWith(isRead: true);
      _recentNotifications.add(notifications);
    }
  }
  
  /// Mark all notifications as read
  void markAllAsRead() {
    final notifications = _recentNotifications.value.map(
      (n) => n.copyWith(isRead: true)
    ).toList();
    
    _recentNotifications.add(notifications);
  }
  
  /// Clear all notifications
  void clearAllNotifications() {
    _recentNotifications.add([]);
  }
  
  /// Get the appropriate channel ID for a notification type
  String _getChannelIdForNotificationType(NotificationType type) {
    switch (type) {
      case NotificationType.calendar:
      case NotificationType.todo:
        // Time-sensitive notifications get high importance
        return _highImportanceChannelId;
      default:
        return _channelId;
    }
  }
  
  /// Get the appropriate iOS notification category for a notification type
  String _getCategoryForNotificationType(NotificationType type) {
    switch (type) {
      case NotificationType.calendar:
        return 'calendar';
      case NotificationType.todo:
        return 'todo';
      case NotificationType.notes:
        return 'notes';
      case NotificationType.whiteboard:
        return 'whiteboard';
      case NotificationType.cards:
        return 'cards';
      case NotificationType.subscription:
        return 'subscription';
      case NotificationType.system:
        return 'system';
      default:
        return 'general';
    }
  }
  
  /// Add a notification to the recent notifications list
  void _addToRecentNotifications(AppNotification notification) {
    final notifications = List<AppNotification>.from(_recentNotifications.value);
    
    // Remove if already exists (to avoid duplicates)
    notifications.removeWhere((n) => n.id == notification.id);
    
    // Add the new notification at the beginning
    notifications.insert(0, notification);
    
    // Limit the number of notifications
    if (notifications.length > _maxRecentNotifications) {
      notifications.removeLast();
    }
    
    // Update the stream
    _recentNotifications.add(notifications);
  }
  
  /// Handle when a local notification is tapped
  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    debugPrint('Local notification tapped: ${response.id}');
    
    try {
      if (response.payload != null) {
        final data = json.decode(response.payload!) as Map<String, dynamic>;
        
        // Get notification type
        final typeString = data['type'] as String?;
        final type = typeString != null
            ? NotificationType.values.firstWhere(
                (e) => e.toString().split('.').last == typeString,
                orElse: () => NotificationType.general,
              )
            : NotificationType.general;
        
        // Create app notification
        final notification = AppNotification(
          id: response.id?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
          title: response.notificationResponseType == NotificationResponseType.selectedNotification
              ? 'Notification'
              : 'Action',
          body: '',
          data: data,
          timestamp: DateTime.now(),
          type: type,
          actionRoute: data['route'] as String?,
        );
        
        // Send to stream for handling
        _notificationStreamController.add(notification);
        
        // Log analytics
        AnalyticsService.instance.logCustomEvent(
          eventName: 'local_notification_opened',
          parameters: {
            'notification_id': response.id?.toString() ?? '',
            'notification_type': type.toString().split('.').last,
          },
        );
      }
    } catch (e, stack) {
      debugPrint('Error handling notification response: $e');
      ErrorService.instance.reportError(
        e,
        stack,
        reason: 'Failed to handle notification response',
      );
    }
  }
  
  /// Handle iOS local notifications (deprecated but needed for older iOS versions)
  void _onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) {
    debugPrint('iOS local notification received: $id');
    
    try {
      if (payload != null) {
        final data = json.decode(payload) as Map<String, dynamic>;
        
        // Get notification type
        final typeString = data['type'] as String?;
        final type = typeString != null
            ? NotificationType.values.firstWhere(
                (e) => e.toString().split('.').last == typeString,
                orElse: () => NotificationType.general,
              )
            : NotificationType.general;
        
        // Create app notification
        final notification = AppNotification(
          id: id.toString(),
          title: title ?? 'Notification',
          body: body ?? '',
          data: data,
          timestamp: DateTime.now(),
          type: type,
          actionRoute: data['route'] as String?,
        );
        
        // Send to stream for handling
        _notificationStreamController.add(notification);
      }
    } catch (e, stack) {
      debugPrint('Error handling iOS local notification: $e');
      ErrorService.instance.reportError(
        e,
        stack,
        reason: 'Failed to handle iOS local notification',
      );
    }
  }
  
  /// Get bytes from a URL for notification images
  Future<Uint8List> _getBytesFromUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      return response.bodyBytes;
    } catch (e) {
      debugPrint('Error getting bytes from URL: $e');
      // Return a transparent 1x1 pixel
      return Uint8List.fromList([0, 0, 0, 0]);
    }
  }
  
  /// Dispose the notification service
  void dispose() {
    _notificationStreamController.close();
    _recentNotifications.close();
  }
}

/// Extension for timezone handling
extension on DateTime {
  /// Convert to TZDateTime
  TZDateTime toTZDateTime() {
    return TZDateTime.from(this, local);
  }
}
