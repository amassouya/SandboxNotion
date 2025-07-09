import 'dart:io';
import 'dart:ui';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sandboxnotion/utils/constants.dart';

/// Utility class for platform-specific operations and device detection
class PlatformUtils {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static PackageInfo? _packageInfo;

  /// Initialize platform utilities
  static Future<void> init() async {
    _packageInfo = await PackageInfo.fromPlatform();
  }

  /// Returns true if the app is running on a web platform
  static bool get isWeb => kIsWeb;

  /// Returns true if the app is running on an Android device
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  /// Returns true if the app is running on an iOS device
  static bool get isIOS => !kIsWeb && Platform.isIOS;

  /// Returns true if the app is running on a macOS device
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;

  /// Returns true if the app is running on a Windows device
  static bool get isWindows => !kIsWeb && Platform.isWindows;

  /// Returns true if the app is running on a Linux device
  static bool get isLinux => !kIsWeb && Platform.isLinux;

  /// Returns true if the app is running on a desktop platform
  static bool get isDesktop => !kIsWeb && (isMacOS || isWindows || isLinux);

  /// Returns true if the app is running on a mobile platform
  static bool get isMobile => !kIsWeb && (isAndroid || isIOS);

  /// Returns true if the app is running in debug mode
  static bool get isDebug => kDebugMode;

  /// Returns true if the app is running in release mode
  static bool get isRelease => kReleaseMode;

  /// Returns true if the app is running in profile mode
  static bool get isProfile => kProfileMode;

  /// Returns the device type based on screen width
  static DeviceType getDeviceType(double width) {
    if (width < AppConstants.tabletBreakpoint) {
      return DeviceType.mobile;
    } else if (width < AppConstants.desktopBreakpoint) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  /// Returns the current device type based on the window size
  static DeviceType get currentDeviceType {
    final width = PlatformDispatcher.instance.views.first.physicalSize.width /
        PlatformDispatcher.instance.views.first.devicePixelRatio;
    return getDeviceType(width);
  }

  /// Returns the app version string
  static String get appVersion {
    if (_packageInfo != null) {
      return '${_packageInfo!.version}+${_packageInfo!.buildNumber}';
    }
    return AppConstants.appVersion;
  }

  /// Returns the app name
  static String get appName {
    if (_packageInfo != null) {
      return _packageInfo!.appName;
    }
    return AppConstants.appName;
  }

  /// Returns the app package name
  static String get packageName {
    if (_packageInfo != null) {
      return _packageInfo!.packageName;
    }
    return AppConstants.appPackageName;
  }

  /// Returns the device model name
  static Future<String> getDeviceModel() async {
    if (kIsWeb) {
      return 'Web Browser';
    } else if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      return '${info.manufacturer} ${info.model}';
    } else if (Platform.isIOS) {
      final info = await _deviceInfo.iosInfo;
      return '${info.name} (${info.systemName} ${info.systemVersion})';
    } else if (Platform.isMacOS) {
      final info = await _deviceInfo.macOsInfo;
      return '${info.computerName} (${info.osRelease})';
    } else if (Platform.isWindows) {
      final info = await _deviceInfo.windowsInfo;
      return 'Windows ${info.productName} (${info.buildNumber})';
    } else if (Platform.isLinux) {
      final info = await _deviceInfo.linuxInfo;
      return '${info.name} ${info.version}';
    }
    return 'Unknown Device';
  }

  /// Returns the OS version
  static Future<String> getOSVersion() async {
    if (kIsWeb) {
      return 'Web';
    } else if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      return 'Android ${info.version.release} (SDK ${info.version.sdkInt})';
    } else if (Platform.isIOS) {
      final info = await _deviceInfo.iosInfo;
      return '${info.systemName} ${info.systemVersion}';
    } else if (Platform.isMacOS) {
      final info = await _deviceInfo.macOsInfo;
      return 'macOS ${info.osRelease}';
    } else if (Platform.isWindows) {
      final info = await _deviceInfo.windowsInfo;
      return 'Windows ${info.buildNumber}';
    } else if (Platform.isLinux) {
      final info = await _deviceInfo.linuxInfo;
      return 'Linux ${info.version}';
    }
    return 'Unknown OS';
  }

  /// Returns the appropriate file storage path for the current platform
  static Future<String> getAppStoragePath() async {
    if (kIsWeb) {
      return '';
    } else if (Platform.isAndroid) {
      return '/data/user/0/${AppConstants.appPackageName}';
    } else if (Platform.isIOS || Platform.isMacOS) {
      return (await path_provider.getApplicationDocumentsDirectory()).path;
    } else if (Platform.isWindows) {
      return (await path_provider.getApplicationSupportDirectory()).path;
    } else if (Platform.isLinux) {
      return (await path_provider.getApplicationSupportDirectory()).path;
    }
    return '';
  }

  /// Returns the appropriate temporary directory path
  static Future<String> getTempPath() async {
    if (kIsWeb) {
      return '';
    }
    return (await path_provider.getTemporaryDirectory()).path;
  }

  /// Returns true if the device is in dark mode
  static bool isDarkMode(BuildContext context) {
    return MediaQuery.of(context).platformBrightness == Brightness.dark;
  }

  /// Returns the appropriate padding for safe areas based on platform
  static EdgeInsets getSafePadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    
    // For mobile devices, respect the safe area
    if (isMobile) {
      return mediaQuery.padding;
    }
    
    // For web and desktop, use custom padding
    if (isWeb || isDesktop) {
      return const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0);
    }
    
    // Default fallback
    return mediaQuery.padding;
  }

  /// Returns a platform-appropriate duration for animations
  static Duration getPlatformAnimationDuration() {
    if (isIOS || isMacOS) {
      return AppConstants.animationNormal;
    } else {
      return AppConstants.animationFast;
    }
  }

  /// Returns the appropriate text direction for the current locale
  static TextDirection getTextDirectionForLocale(Locale locale) {
    // RTL languages
    const rtlLanguages = ['ar', 'fa', 'he', 'ur'];
    if (rtlLanguages.contains(locale.languageCode)) {
      return TextDirection.rtl;
    }
    return TextDirection.ltr;
  }

  /// Returns true if the current platform supports biometric authentication
  static Future<bool> supportsBiometrics() async {
    if (kIsWeb) {
      return false;
    }
    
    try {
      final localAuth = LocalAuthentication();
      return await localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  /// Returns true if the device has a notch or dynamic island (iOS)
  static bool hasNotch(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.viewPadding.top > 20;
  }
}

/// Extension for platform-specific UI adjustments
extension PlatformAwareContext on BuildContext {
  /// Returns true if the device is in dark mode
  bool get isDarkMode => PlatformUtils.isDarkMode(this);
  
  /// Returns the current device type
  DeviceType get deviceType => PlatformUtils.getDeviceType(
    MediaQuery.of(this).size.width,
  );
  
  /// Returns true if the current device is a mobile phone
  bool get isMobileDevice => deviceType == DeviceType.mobile;
  
  /// Returns true if the current device is a tablet
  bool get isTabletDevice => deviceType == DeviceType.tablet;
  
  /// Returns true if the current device is a desktop
  bool get isDesktopDevice => deviceType == DeviceType.desktop;
  
  /// Returns the safe area padding
  EdgeInsets get safePadding => PlatformUtils.getSafePadding(this);
  
  /// Returns true if the device has a notch
  bool get hasNotch => PlatformUtils.hasNotch(this);
}
