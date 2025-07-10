import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:sandboxnotion/firebase_options.dart';
import 'package:sandboxnotion/router/app_router.dart';
import 'package:go_router/go_router.dart'; // Added import for GoRouter
import 'package:sandboxnotion/services/analytics_service.dart';
import 'package:sandboxnotion/services/error_service.dart';
import 'package:sandboxnotion/services/notification_service.dart';
import 'package:sandboxnotion/utils/constants.dart';
import 'package:sandboxnotion/utils/platform_utils.dart';

// Global logger instance
final logger = Logger(
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

// Global error observer for Riverpod
class ProviderErrorObserver extends ProviderObserver {
  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    logger.e(
      'Provider error: ${provider.name ?? provider.runtimeType}',
      error: error,
      stackTrace: stackTrace,
    );
    
    // Report to Crashlytics if not in debug mode
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: 'Provider error: ${provider.name ?? provider.runtimeType}',
        fatal: false,
      );
    }
  }
}

void main() async {
  // Ensure Flutter is initialized
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  
  // Keep splash screen until app is fully loaded
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  // Load environment variables
  await dotenv.load(fileName: '.env');
  
  // Initialize error handling
  await _initializeErrorHandling();
  
  // Initialize Firebase
  await _initializeFirebase();
  
  // Initialize services
  await _initializeServices();
  
  // Remove splash screen
  FlutterNativeSplash.remove();
  
  // Run the app inside a zone to catch all errors
  runZonedGuarded(
    () => runApp(
      ProviderScope(
        observers: [ProviderErrorObserver()],
        child: const SandboxNotionApp(),
      ),
    ),
    (error, stack) {
      logger.e('Uncaught error in zone', error: error, stackTrace: stack);
      if (!kDebugMode) {
        FirebaseCrashlytics.instance.recordError(error, stack);
      }
    },
  );
}

Future<void> _initializeErrorHandling() async {
  // Custom error handling for Flutter errors
  FlutterError.onError = (FlutterErrorDetails details) {
    logger.e(
      'Flutter error: ${details.exception}',
      error: details.exception,
      stackTrace: details.stack,
    );
    
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordFlutterError(details);
    } else {
      FlutterError.dumpErrorToConsole(details);
    }
  };
  
  // Handle errors in the current Isolate
  PlatformDispatcher.instance.onError = (error, stack) {
    logger.e('Platform dispatcher error', error: error, stackTrace: stack);
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordError(error, stack);
    }
    return true;
  };
}

Future<void> _initializeFirebase() async {
  try {
    // Initialize Firebase with platform-specific options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    logger.i('Firebase initialized successfully');
    
    // Initialize App Check
    await _initializeAppCheck();
    
    // Initialize Firebase services
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    
    // Enable Crashlytics collection in non-debug mode
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
    
    // Set up Firebase Analytics
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(!kDebugMode);
    
    // Configure Firebase Storage caching
    if (!kIsWeb) {
      await FirebaseStorage.instance.setMaxDownloadRetryTime(
        const Duration(seconds: 30),
      );
      await FirebaseStorage.instance.setMaxUploadRetryTime(
        const Duration(minutes: 2),
      );
    }
    
    // Configure messaging for notifications
    if (!kIsWeb) {
      await _configureMessaging();
    }
  } catch (e, stack) {
    logger.e('Failed to initialize Firebase', error: e, stackTrace: stack);
    if (!kDebugMode) {
      await FirebaseCrashlytics.instance.recordError(e, stack);
    }
    rethrow;
  }
}

Future<void> _initializeAppCheck() async {
  try {
    // Initialize App Check with platform-specific providers
    if (kIsWeb) {
      await FirebaseAppCheck.instance.activate(
        webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
      );
    } else if (Platform.isAndroid) {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
      );
    } else if (Platform.isIOS || Platform.isMacOS) {
      await FirebaseAppCheck.instance.activate(
        appleProvider: AppleProvider.appAttest,
      );
    }
    
    logger.i('Firebase App Check initialized successfully');
  } catch (e, stack) {
    logger.e('Failed to initialize Firebase App Check', error: e, stackTrace: stack);
    // Non-fatal error, continue app initialization
  }
}

Future<void> _configureMessaging() async {
  try {
    // Request permission for notifications
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: true,
      sound: true,
    );
    
    logger.i('Notification permission status: ${settings.authorizationStatus}');
    
    // Configure FCM
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Get FCM token
    final token = await messaging.getToken();
    logger.i('FCM Token: ${token?.substring(0, 10)}...');
  } catch (e, stack) {
    logger.e('Failed to configure messaging', error: e, stackTrace: stack);
    // Non-fatal error, continue app initialization
  }
}

// This must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.instance.handleBackgroundMessage(message);
}

Future<void> _initializeServices() async {
  // Initialize analytics service
  await AnalyticsService.instance.initialize();
  
  // Initialize error reporting service
  await ErrorService.instance.initialize();
  
  // Initialize notification service
  await NotificationService.instance.initialize();
}

class SandboxNotionApp extends ConsumerWidget {
  const SandboxNotionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the router from Riverpod
    final router = ref.watch(appRouterProvider);
    
    // Define the seed color for the app theme
    const seedColor = Color(0xFF4C7AF9); // #4C7AF9
    
    return MaterialApp.router(
      title: 'SandboxNotion',
      debugShowCheckedModeBanner: false,
      
      // Set up the router
      routerDelegate: router.routerDelegate,
      routeInformationParser: router.routeInformationParser,
      routeInformationProvider: router.routeInformationProvider,
      
      // Configure theme using Material 3
      theme: FlexThemeData.light(
        scheme: FlexScheme.custom,
        useMaterial3: true,
        primary: seedColor,
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 7,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 10,
          blendOnColors: false,
          useTextTheme: true,
          useM2StyleDividerInM3: true,
          alignedDropdown: true,
          useInputDecoratorThemeInDialogs: true,
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        fontFamily: GoogleFonts.inter().fontFamily,
      ),
      
      // Dark theme
      darkTheme: FlexThemeData.dark(
        scheme: FlexScheme.custom,
        useMaterial3: true,
        primary: seedColor,
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 13,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 20,
          useTextTheme: true,
          useM2StyleDividerInM3: true,
          alignedDropdown: true,
          useInputDecoratorThemeInDialogs: true,
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        fontFamily: GoogleFonts.inter().fontFamily,
      ),
      
      // Use system theme mode
      themeMode: ThemeMode.system,
      
      // Localization
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('de', 'DE'),
        Locale('fr', 'FR'),
        Locale('es', 'ES'),
      ],
      
      // Builder for responsive design
      builder: (context, child) {
        // Apply text scaling factor limit for accessibility
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: clampDouble(
              MediaQuery.of(context).textScaleFactor,
              0.8,
              1.4,
            ),
          ),
          child: ResponsiveLayoutBuilder(child: child!),
        );
      },
    );
  }
}

/// Responsive layout builder that adapts to different screen sizes
class ResponsiveLayoutBuilder extends StatelessWidget {
  final Widget child;

  const ResponsiveLayoutBuilder({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Get screen size
    final screenSize = MediaQuery.of(context).size;
    final width = screenSize.width;
    
    // Determine device type based on screen width
    final deviceType = PlatformUtils.getDeviceType(width);
    
    // Apply different paddings based on device type
    EdgeInsets safePadding;
    switch (deviceType) {
      case DeviceType.mobile:
        safePadding = const EdgeInsets.symmetric(horizontal: 16.0);
        break;
      case DeviceType.tablet:
        // On tablets, use percentage-based padding
        final horizontalPadding = width * 0.05; // 5% of screen width
        safePadding = EdgeInsets.symmetric(horizontal: horizontalPadding);
        break;
      case DeviceType.desktop:
        // On desktop, use fixed padding with max width
        final horizontalPadding = (width - AppConstants.maxContentWidth) / 2;
        safePadding = EdgeInsets.symmetric(
          horizontal: horizontalPadding > 0 ? horizontalPadding : 24.0,
        );
        break;
    }
    
    // Apply the padding
    return AnimatedPadding(
      padding: safePadding,
      duration: const Duration(milliseconds: 200),
      child: child,
    );
  }
}
