import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:sandboxnotion/utils/constants.dart';

/// Utilities for platform-specific and responsive design functionality
class PlatformUtils {
  /// Returns the current device type based on screen width
  static DeviceType getDeviceType(double width) {
    if (width <= AppConstants.mobileBreakpoint) {
      return DeviceType.mobile;
    } else if (width <= AppConstants.tabletBreakpoint) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  /// Returns true if the app is running on a mobile device
  static bool isMobileDevice(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return getDeviceType(width) == DeviceType.mobile;
  }

  /// Returns true if the app is running on a tablet device
  static bool isTabletDevice(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return getDeviceType(width) == DeviceType.tablet;
  }

  /// Returns true if the app is running on a desktop device
  static bool isDesktopDevice(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return getDeviceType(width) == DeviceType.desktop;
  }

  /// Returns true if the app is running on iOS
  static bool get isIOS {
    return !kIsWeb && Platform.isIOS;
  }

  /// Returns true if the app is running on Android
  static bool get isAndroid {
    return !kIsWeb && Platform.isAndroid;
  }

  /// Returns true if the app is running on macOS
  static bool get isMacOS {
    return !kIsWeb && Platform.isMacOS;
  }

  /// Returns true if the app is running on Windows
  static bool get isWindows {
    return !kIsWeb && Platform.isWindows;
  }

  /// Returns true if the app is running on Linux
  static bool get isLinux {
    return !kIsWeb && Platform.isLinux;
  }

  /// Returns true if the app is running on Web
  static bool get isWeb {
    return kIsWeb;
  }

  /// Returns true if the app is running on a mobile platform (iOS or Android)
  static bool get isMobilePlatform {
    return !kIsWeb && (Platform.isIOS || Platform.isAndroid);
  }

  /// Returns true if the app is running on a desktop platform (macOS, Windows, Linux)
  static bool get isDesktopPlatform {
    return !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);
  }

  /// Returns the current platform as a string
  static String get platformName {
    if (kIsWeb) {
      return 'Web';
    } else if (Platform.isIOS) {
      return 'iOS';
    } else if (Platform.isAndroid) {
      return 'Android';
    } else if (Platform.isMacOS) {
      return 'macOS';
    } else if (Platform.isWindows) {
      return 'Windows';
    } else if (Platform.isLinux) {
      return 'Linux';
    } else {
      return 'Unknown';
    }
  }

  /// Returns true if the device is in landscape orientation
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Returns true if the device is in portrait orientation
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  /// Returns the safe area padding for the current device
  static EdgeInsets safeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// Returns the safe area insets for the current device
  static EdgeInsets safeAreaInsets(BuildContext context) {
    return MediaQuery.of(context).viewInsets;
  }

  /// Returns a responsive value based on screen size
  /// [mobile] - Value for mobile screens
  /// [tablet] - Value for tablet screens
  /// [desktop] - Value for desktop screens
  static T responsiveValue<T>({
    required BuildContext context,
    required T mobile,
    required T tablet,
    required T desktop,
  }) {
    final deviceType = getDeviceType(MediaQuery.of(context).size.width);
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet;
      case DeviceType.desktop:
        return desktop;
    }
  }

  /// Returns a responsive padding based on screen size
  static EdgeInsets responsivePadding(BuildContext context) {
    return responsiveValue<EdgeInsets>(
      context: context,
      mobile: const EdgeInsets.all(8.0),
      tablet: const EdgeInsets.all(16.0),
      desktop: const EdgeInsets.all(24.0),
    );
  }

  /// Returns a responsive font size based on screen size
  static double responsiveFontSize(
    BuildContext context, {
    required double baseFontSize,
    double? mobileMultiplier,
    double? tabletMultiplier,
    double? desktopMultiplier,
  }) {
    final deviceType = getDeviceType(MediaQuery.of(context).size.width);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return baseFontSize * (mobileMultiplier ?? 0.8);
      case DeviceType.tablet:
        return baseFontSize * (tabletMultiplier ?? 1.0);
      case DeviceType.desktop:
        return baseFontSize * (desktopMultiplier ?? 1.2);
    }
  }

  /// Returns a responsive width constraint based on screen size
  static BoxConstraints responsiveWidthConstraints(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    return responsiveValue<BoxConstraints>(
      context: context,
      mobile: BoxConstraints(maxWidth: width * 0.95),
      tablet: BoxConstraints(maxWidth: width * 0.85),
      desktop: BoxConstraints(maxWidth: width * 0.75),
    );
  }

  /// Returns a responsive height based on screen size as a percentage of screen height
  static double responsiveHeight(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.height * percentage;
  }

  /// Returns a responsive width based on screen size as a percentage of screen width
  static double responsiveWidth(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.width * percentage;
  }
}
