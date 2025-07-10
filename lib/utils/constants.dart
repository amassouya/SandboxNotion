import 'package:flutter/material.dart';

/// Application-wide constants
class AppConstants {
  // App information
  static const String appName = 'SandboxNotion';
  static const String appVersion = '0.1.0';
  
  // Colors and theme
  static const Color seedColor = Color(0xFF6750A4); // Primary color
  static const Color secondaryColor = Color(0xFF625B71);
  static const Color tertiaryColor = Color(0xFF7D5260);
  static const Color errorColor = Color(0xFFB3261E);
  
  // Light theme colors
  static const Color lightBackground = Color(0xFFF8F8F8);
  static const Color lightSurface = Colors.white;
  static const Color lightOnSurface = Color(0xFF1C1B1F);
  
  // Dark theme colors
  static const Color darkBackground = Color(0xFF1C1B1F);
  static const Color darkSurface = Color(0xFF2D2C31);
  static const Color darkOnSurface = Color(0xFFE6E1E5);
  
  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  static const Duration animationVerySlow = Duration(milliseconds: 800);
  
  // Sandbox grid constants
  static const double gridCellSize = 20.0; // Size of one grid cell
  static const double gridSpacing = 4.0; // Spacing between grid cells
  static const int gridColumns = 12; // Number of columns in the grid
  static const int gridRows = 10; // Number of rows in the grid
  static const double gridLineThickness = 0.5; // Thickness of grid lines
  
  // Tile constants
  static const double sandboxTileHeaderHeight = 40.0; // Height of tile header
  static const double sandboxTileCornerRadius = 8.0; // Corner radius of tiles
  static const double sandboxTileMinWidth = gridCellSize * 3; // Minimum tile width
  static const double sandboxTileMinHeight = gridCellSize * 2; // Minimum tile height
  static const double sandboxTileResizeHandleSize = 20.0; // Size of resize handles
  
  // Responsive breakpoints
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 1200.0;
}

/// Device type enum for responsive design
enum DeviceType {
  mobile,
  tablet,
  desktop,
}

/// Module types available in the sandbox
enum ModuleType {
  calendar(
    name: 'Calendar',
    icon: Icons.calendar_today,
    color: Colors.blue,
  ),
  todo(
    name: 'Todo',
    icon: Icons.check_circle_outline,
    color: Colors.green,
  ),
  notes(
    name: 'Notes',
    icon: Icons.note,
    color: Colors.amber,
  ),
  whiteboard(
    name: 'Whiteboard',
    icon: Icons.edit,
    color: Colors.purple,
  ),
  cards(
    name: 'Cards',
    icon: Icons.style,
    color: Colors.orange,
  );

  const ModuleType({
    required this.name,
    required this.icon,
    required this.color,
  });

  /// Display name of the module
  final String name;
  
  /// Icon to represent the module
  final IconData icon;
  
  /// Primary color associated with the module
  final Color color;
}

/// Extension methods for DeviceType
extension DeviceTypeExtension on DeviceType {
  /// Returns true if the device is mobile
  bool get isMobile => this == DeviceType.mobile;
  
  /// Returns true if the device is tablet
  bool get isTablet => this == DeviceType.tablet;
  
  /// Returns true if the device is desktop
  bool get isDesktop => this == DeviceType.desktop;
}

/// Extension methods for ModuleType
extension ModuleTypeExtension on ModuleType {
  /// Returns the route path for this module
  String get routePath {
    switch (this) {
      case ModuleType.calendar:
        return '/sandbox/calendar';
      case ModuleType.todo:
        return '/sandbox/todo';
      case ModuleType.notes:
        return '/sandbox/notes';
      case ModuleType.whiteboard:
        return '/sandbox/whiteboard';
      case ModuleType.cards:
        return '/sandbox/cards';
    }
  }
  
  /// Returns the default size for this module type (width, height) in grid cells
  List<int> get defaultSize {
    switch (this) {
      case ModuleType.calendar:
        return [6, 4];
      case ModuleType.todo:
        return [4, 4];
      case ModuleType.notes:
        return [4, 3];
      case ModuleType.whiteboard:
        return [6, 5];
      case ModuleType.cards:
        return [4, 3];
    }
  }
}
