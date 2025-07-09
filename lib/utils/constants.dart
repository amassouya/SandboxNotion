import 'package:flutter/material.dart';

/// Application-wide constants for SandboxNotion
class AppConstants {
  // App metadata
  static const String appName = 'SandboxNotion';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  static const String appPackageName = 'com.sandbox.notion';
  
  // API endpoints and configuration
  static const String openAiProxyEndpoint = 'openaiProxy';
  static const String subscriptionEndpoint = 'checkSubscription';
  static const int apiTimeoutSeconds = 30;
  static const int maxRetryAttempts = 3;
  
  // Firebase collection names
  static const String usersCollection = 'users';
  static const String notesCollection = 'notes';
  static const String todoListsCollection = 'todoLists';
  static const String todoItemsCollection = 'todoItems';
  static const String eventsCollection = 'events';
  static const String whiteboardsCollection = 'whiteboards';
  static const String cardsCollection = 'cards';
  static const String subscriptionsCollection = 'subscriptions';
  static const String userQuotasCollection = 'userQuotas';
  
  // Theme colors
  static const Color seedColor = Color(0xFF4C7AF9); // Primary brand color
  static const Color errorColor = Color(0xFFE53935);
  static const Color warningColor = Color(0xFFFFA000);
  static const Color successColor = Color(0xFF43A047);
  static const Color infoColor = Color(0xFF039BE5);
  
  // Additional theme colors
  static const Color calendarModuleColor = Color(0xFF4CAF50);
  static const Color todoModuleColor = Color(0xFFFF9800);
  static const Color notesModuleColor = Color(0xFF9C27B0);
  static const Color whiteboardModuleColor = Color(0xFF03A9F4);
  static const Color cardsModuleColor = Color(0xFFE91E63);
  
  // Dark theme specific colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkError = Color(0xFFCF6679);
  
  // Typography
  static const double fontSizeSmall = 12.0;
  static const double fontSizeBody = 14.0;
  static const double fontSizeSubheading = 16.0;
  static const double fontSizeHeading = 20.0;
  static const double fontSizeTitle = 24.0;
  static const double fontSizeLarge = 34.0;
  
  // Layout dimensions
  static const double maxContentWidth = 1200.0;
  static const double tabletBreakpoint = 768.0;
  static const double desktopBreakpoint = 1024.0;
  static const double minTouchTargetSize = 48.0;
  
  // Spacing and padding
  static const double spacingXxs = 2.0;
  static const double spacingXs = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;
  static const double spacingHuge = 64.0;
  
  // Border radius
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusMedium = 8.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusXLarge = 24.0;
  static const double borderRadiusCircular = 999.0;
  
  // Elevation
  static const double elevationLow = 1.0;
  static const double elevationMedium = 3.0;
  static const double elevationHigh = 6.0;
  static const double elevationXHigh = 12.0;
  
  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  static const Duration animationVerySlow = Duration(milliseconds: 800);
  static const Duration animationPageTransition = Duration(milliseconds: 200);
  static const Duration animationSnackbarDuration = Duration(seconds: 4);
  static const Duration animationTooltipDuration = Duration(seconds: 2);
  
  // Sandbox UI constants
  static const double sandboxGridSize = 8.0;
  static const double sandboxMinTileSize = 120.0;
  static const double sandboxTileMargin = 8.0;
  static const double sandboxTileCornerRadius = 16.0;
  static const double sandboxTileHeaderHeight = 40.0;
  static const double sandboxResizeHandleSize = 20.0;
  
  // Module minimum dimensions
  static const Size calendarMinSize = Size(300, 300);
  static const Size todoMinSize = Size(250, 300);
  static const Size notesMinSize = Size(250, 200);
  static const Size whiteboardMinSize = Size(300, 300);
  static const Size cardsMinSize = Size(250, 350);
  
  // Subscription constants
  static const String freeTierName = 'Free';
  static const String premiumTierName = 'Premium';
  static const double premiumMonthlyPrice = 9.99;
  static const double premiumYearlyPrice = 99.99;
  static const double premiumYearlySavingsPercent = 17;
  
  // OpenAI API constants
  static const int maxTextPromptLength = 4000;
  static const int maxCompletionTokens = 1000;
  static const double defaultTemperature = 0.7;
  static const int maxImageSize = 4 * 1024 * 1024; // 4MB
  static const int maxAudioSize = 25 * 1024 * 1024; // 25MB
  
  // Cache durations
  static const Duration defaultCacheDuration = Duration(days: 7);
  static const Duration userProfileCacheDuration = Duration(hours: 24);
  static const Duration imagesCacheDuration = Duration(days: 14);
  
  // Error messages
  static const String defaultErrorMessage = 'Something went wrong. Please try again.';
  static const String networkErrorMessage = 'Network connection error. Please check your internet connection.';
  static const String authErrorMessage = 'Authentication error. Please sign in again.';
  static const String permissionErrorMessage = 'You don\'t have permission to perform this action.';
  static const String quotaExceededMessage = 'You\'ve reached your monthly quota. Upgrade to Premium for higher limits.';
  
  // Assets paths
  static const String lottiePath = 'assets/lottie';
  static const String imagesPath = 'assets/images';
  static const String iconsPath = 'assets/icons';
  static const String emptyStateLottie = '$lottiePath/empty_state.json';
  static const String loadingLottie = '$lottiePath/loading.json';
  static const String successLottie = '$lottiePath/success.json';
  static const String errorLottie = '$lottiePath/error.json';
  
  // Shared preferences keys
  static const String prefKeyThemeMode = 'theme_mode';
  static const String prefKeyOnboardingComplete = 'onboarding_complete';
  static const String prefKeyLastSyncTime = 'last_sync_time';
  static const String prefKeyUserSettings = 'user_settings';
  static const String prefKeySandboxLayout = 'sandbox_layout';
}

/// Device type enum for responsive design
enum DeviceType {
  mobile,
  tablet,
  desktop,
}

/// Module type enum for the sandbox UI
enum ModuleType {
  calendar,
  todo,
  notes,
  whiteboard,
  cards,
}

/// Authentication providers supported by the app
enum AuthProvider {
  email,
  google,
  apple,
  anonymous,
}

/// Subscription tiers
enum SubscriptionTier {
  free,
  premium,
}

/// Payment platforms
enum PaymentPlatform {
  googlePlay,
  appStore,
  web,
}

/// Extensions for enums
extension ModuleTypeExtension on ModuleType {
  String get name {
    switch (this) {
      case ModuleType.calendar:
        return 'Calendar';
      case ModuleType.todo:
        return 'To-Do';
      case ModuleType.notes:
        return 'Notes';
      case ModuleType.whiteboard:
        return 'Whiteboard';
      case ModuleType.cards:
        return 'Cards';
    }
  }
  
  Color get color {
    switch (this) {
      case ModuleType.calendar:
        return AppConstants.calendarModuleColor;
      case ModuleType.todo:
        return AppConstants.todoModuleColor;
      case ModuleType.notes:
        return AppConstants.notesModuleColor;
      case ModuleType.whiteboard:
        return AppConstants.whiteboardModuleColor;
      case ModuleType.cards:
        return AppConstants.cardsModuleColor;
    }
  }
  
  IconData get icon {
    switch (this) {
      case ModuleType.calendar:
        return Icons.calendar_today;
      case ModuleType.todo:
        return Icons.check_circle_outline;
      case ModuleType.notes:
        return Icons.note;
      case ModuleType.whiteboard:
        return Icons.edit;
      case ModuleType.cards:
        return Icons.style;
    }
  }
  
  Size get minSize {
    switch (this) {
      case ModuleType.calendar:
        return AppConstants.calendarMinSize;
      case ModuleType.todo:
        return AppConstants.todoMinSize;
      case ModuleType.notes:
        return AppConstants.notesMinSize;
      case ModuleType.whiteboard:
        return AppConstants.whiteboardMinSize;
      case ModuleType.cards:
        return AppConstants.cardsMinSize;
    }
  }
}
