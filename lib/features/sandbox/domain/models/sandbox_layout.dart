import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sandboxnotion/utils/constants.dart';

/// Represents the position and size of a module tile in the sandbox grid
class ModuleTile extends Equatable {
  /// The unique identifier for this tile
  final String id;
  
  /// The type of module this tile represents
  final ModuleType type;
  
  /// The position of this tile in the grid (column index)
  final int x;
  
  /// The position of this tile in the grid (row index)
  final int y;
  
  /// The width of this tile in grid cells
  final int width;
  
  /// The height of this tile in grid cells
  final int height;
  
  /// Whether this tile is visible
  final bool isVisible;
  
  /// Whether this tile is maximized (takes up the entire grid)
  final bool isMaximized;
  
  /// Custom configuration for this module (JSON serializable)
  final Map<String, dynamic>? config;

  const ModuleTile({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.isVisible = true,
    this.isMaximized = false,
    this.config,
  });

  /// Creates a copy of this tile with the given fields replaced with new values
  ModuleTile copyWith({
    String? id,
    ModuleType? type,
    int? x,
    int? y,
    int? width,
    int? height,
    bool? isVisible,
    bool? isMaximized,
    Map<String, dynamic>? config,
  }) {
    return ModuleTile(
      id: id ?? this.id,
      type: type ?? this.type,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      isVisible: isVisible ?? this.isVisible,
      isMaximized: isMaximized ?? this.isMaximized,
      config: config ?? this.config,
    );
  }

  /// Converts this tile to a map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'isVisible': isVisible,
      'isMaximized': isMaximized,
      if (config != null) 'config': config,
    };
  }

  /// Creates a tile from a Firestore map
  factory ModuleTile.fromMap(Map<String, dynamic> map) {
    return ModuleTile(
      id: map['id'] as String,
      type: _moduleTypeFromString(map['type'] as String),
      x: map['x'] as int,
      y: map['y'] as int,
      width: map['width'] as int,
      height: map['height'] as int,
      isVisible: map['isVisible'] as bool? ?? true,
      isMaximized: map['isMaximized'] as bool? ?? false,
      config: map['config'] as Map<String, dynamic>?,
    );
  }

  /// Helper method to convert a string to a ModuleType
  static ModuleType _moduleTypeFromString(String typeStr) {
    return ModuleType.values.firstWhere(
      (type) => type.toString().split('.').last == typeStr,
      orElse: () => ModuleType.notes, // Default to notes if not found
    );
  }

  /// Gets the minimum size for this module type
  Size get minSize => type.minSize;

  /// Gets the actual pixel size based on grid dimensions
  Size getSizeInPixels(double cellSize) {
    return Size(
      width * cellSize - AppConstants.sandboxTileMargin * 2,
      height * cellSize - AppConstants.sandboxTileMargin * 2,
    );
  }

  /// Gets the actual pixel position based on grid dimensions
  Offset getPositionInPixels(double cellSize) {
    return Offset(
      x * cellSize + AppConstants.sandboxTileMargin,
      y * cellSize + AppConstants.sandboxTileMargin,
    );
  }

  /// Gets the rect for this tile in the grid
  Rect getRectInGrid() {
    return Rect.fromLTWH(x.toDouble(), y.toDouble(), width.toDouble(), height.toDouble());
  }

  /// Checks if this tile overlaps with another tile
  bool overlaps(ModuleTile other) {
    final thisRect = getRectInGrid();
    final otherRect = other.getRectInGrid();
    return thisRect.overlaps(otherRect);
  }

  /// Checks if this tile is within the grid bounds
  bool isWithinBounds(int maxColumns, int maxRows) {
    return x >= 0 && y >= 0 && x + width <= maxColumns && y + height <= maxRows;
  }

  @override
  List<Object?> get props => [id, type, x, y, width, height, isVisible, isMaximized];
  
  @override
  String toString() {
    return 'ModuleTile(id: $id, type: $type, x: $x, y: $y, width: $width, height: $height, visible: $isVisible, maximized: $isMaximized)';
  }
}

/// Represents the grid configuration for the sandbox
class GridConfig extends Equatable {
  /// The number of columns in the grid
  final int columns;
  
  /// The number of rows in the grid
  final int rows;
  
  /// The spacing between grid cells in logical pixels
  final double spacing;
  
  /// The size of each grid cell in logical pixels
  final double cellSize;
  
  /// Whether the grid should snap to a fixed grid
  final bool snapToGrid;
  
  /// Whether the grid lines should be visible
  final bool showGridLines;
  
  /// The color of the grid lines
  final Color? gridLineColor;

  const GridConfig({
    required this.columns,
    required this.rows,
    this.spacing = AppConstants.sandboxGridSize,
    this.cellSize = AppConstants.sandboxMinTileSize,
    this.snapToGrid = true,
    this.showGridLines = false,
    this.gridLineColor,
  });

  /// Creates a copy of this config with the given fields replaced with new values
  GridConfig copyWith({
    int? columns,
    int? rows,
    double? spacing,
    double? cellSize,
    bool? snapToGrid,
    bool? showGridLines,
    Color? gridLineColor,
  }) {
    return GridConfig(
      columns: columns ?? this.columns,
      rows: rows ?? this.rows,
      spacing: spacing ?? this.spacing,
      cellSize: cellSize ?? this.cellSize,
      snapToGrid: snapToGrid ?? this.snapToGrid,
      showGridLines: showGridLines ?? this.showGridLines,
      gridLineColor: gridLineColor ?? this.gridLineColor,
    );
  }

  /// Converts this config to a map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'columns': columns,
      'rows': rows,
      'spacing': spacing,
      'cellSize': cellSize,
      'snapToGrid': snapToGrid,
      'showGridLines': showGridLines,
      if (gridLineColor != null) 'gridLineColor': gridLineColor!.value,
    };
  }

  /// Creates a config from a Firestore map
  factory GridConfig.fromMap(Map<String, dynamic> map) {
    return GridConfig(
      columns: map['columns'] as int,
      rows: map['rows'] as int,
      spacing: (map['spacing'] as num).toDouble(),
      cellSize: (map['cellSize'] as num).toDouble(),
      snapToGrid: map['snapToGrid'] as bool? ?? true,
      showGridLines: map['showGridLines'] as bool? ?? false,
      gridLineColor: map['gridLineColor'] != null
          ? Color(map['gridLineColor'] as int)
          : null,
    );
  }

  /// Gets the total width of the grid in logical pixels
  double get totalWidth => columns * cellSize;

  /// Gets the total height of the grid in logical pixels
  double get totalHeight => rows * cellSize;

  /// Creates a grid config for the given device type
  factory GridConfig.forDeviceType(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return const GridConfig(
          columns: 4,
          rows: 8,
          cellSize: 80,
        );
      case DeviceType.tablet:
        return const GridConfig(
          columns: 8,
          rows: 10,
          cellSize: 100,
        );
      case DeviceType.desktop:
        return const GridConfig(
          columns: 12,
          rows: 8,
          cellSize: 120,
        );
    }
  }

  @override
  List<Object?> get props => [columns, rows, spacing, cellSize, snapToGrid, showGridLines, gridLineColor];
  
  @override
  String toString() {
    return 'GridConfig(columns: $columns, rows: $rows, cellSize: $cellSize, spacing: $spacing)';
  }
}

/// Represents the complete layout of the sandbox
class SandboxLayout extends Equatable {
  /// The grid configuration
  final GridConfig gridConfig;
  
  /// The tiles in the layout
  final List<ModuleTile> tiles;
  
  /// The device type this layout is for
  final DeviceType deviceType;
  
  /// The last time this layout was updated
  final DateTime? lastUpdated;
  
  /// The user ID this layout belongs to
  final String? userId;

  const SandboxLayout({
    required this.gridConfig,
    required this.tiles,
    required this.deviceType,
    this.lastUpdated,
    this.userId,
  });

  /// Creates a copy of this layout with the given fields replaced with new values
  SandboxLayout copyWith({
    GridConfig? gridConfig,
    List<ModuleTile>? tiles,
    DeviceType? deviceType,
    DateTime? lastUpdated,
    String? userId,
  }) {
    return SandboxLayout(
      gridConfig: gridConfig ?? this.gridConfig,
      tiles: tiles ?? this.tiles,
      deviceType: deviceType ?? this.deviceType,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      userId: userId ?? this.userId,
    );
  }

  /// Updates a specific tile in the layout
  SandboxLayout updateTile(String tileId, ModuleTile Function(ModuleTile) update) {
    final tileIndex = tiles.indexWhere((tile) => tile.id == tileId);
    if (tileIndex == -1) return this;
    
    final updatedTiles = List<ModuleTile>.from(tiles);
    updatedTiles[tileIndex] = update(updatedTiles[tileIndex]);
    
    return copyWith(
      tiles: updatedTiles,
      lastUpdated: DateTime.now(),
    );
  }

  /// Adds a new tile to the layout
  SandboxLayout addTile(ModuleTile tile) {
    // Check for overlaps and adjust if needed
    final adjustedTile = _findNonOverlappingPosition(tile);
    
    return copyWith(
      tiles: [...tiles, adjustedTile],
      lastUpdated: DateTime.now(),
    );
  }

  /// Removes a tile from the layout
  SandboxLayout removeTile(String tileId) {
    return copyWith(
      tiles: tiles.where((tile) => tile.id != tileId).toList(),
      lastUpdated: DateTime.now(),
    );
  }

  /// Finds a non-overlapping position for a new tile
  ModuleTile _findNonOverlappingPosition(ModuleTile tile) {
    var adjustedTile = tile;
    
    // First try to place at the requested position
    if (_isValidTilePosition(adjustedTile)) {
      return adjustedTile;
    }
    
    // Try to find a free spot in the grid
    for (int y = 0; y < gridConfig.rows - adjustedTile.height + 1; y++) {
      for (int x = 0; x < gridConfig.columns - adjustedTile.width + 1; x++) {
        final testTile = adjustedTile.copyWith(x: x, y: y);
        if (_isValidTilePosition(testTile)) {
          return testTile;
        }
      }
    }
    
    // If no free spot found, try to reduce the size
    if (adjustedTile.width > 1 || adjustedTile.height > 1) {
      adjustedTile = adjustedTile.copyWith(
        width: adjustedTile.width > 1 ? adjustedTile.width - 1 : adjustedTile.width,
        height: adjustedTile.height > 1 ? adjustedTile.height - 1 : adjustedTile.height,
      );
      return _findNonOverlappingPosition(adjustedTile);
    }
    
    // Last resort: place at 0,0 with minimum size
    return adjustedTile.copyWith(x: 0, y: 0, width: 1, height: 1);
  }

  /// Checks if a tile position is valid (within bounds and not overlapping)
  bool _isValidTilePosition(ModuleTile tile) {
    // Check if within grid bounds
    if (!tile.isWithinBounds(gridConfig.columns, gridConfig.rows)) {
      return false;
    }
    
    // Check for overlaps with other tiles
    for (final otherTile in tiles) {
      if (otherTile.id != tile.id && tile.overlaps(otherTile)) {
        return false;
      }
    }
    
    return true;
  }

  /// Validates the entire layout
  bool isValid() {
    // Check if all tiles are within bounds
    for (final tile in tiles) {
      if (!tile.isWithinBounds(gridConfig.columns, gridConfig.rows)) {
        return false;
      }
    }
    
    // Check for overlaps between tiles
    for (int i = 0; i < tiles.length; i++) {
      for (int j = i + 1; j < tiles.length; j++) {
        if (tiles[i].overlaps(tiles[j])) {
          return false;
        }
      }
    }
    
    return true;
  }

  /// Converts this layout to a map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'gridConfig': gridConfig.toMap(),
      'tiles': tiles.map((tile) => tile.toMap()).toList(),
      'deviceType': deviceType.toString().split('.').last,
      'lastUpdated': FieldValue.serverTimestamp(),
      if (userId != null) 'userId': userId,
    };
  }

  /// Creates a layout from a Firestore map
  factory SandboxLayout.fromMap(Map<String, dynamic> map) {
    return SandboxLayout(
      gridConfig: GridConfig.fromMap(map['gridConfig'] as Map<String, dynamic>),
      tiles: (map['tiles'] as List<dynamic>)
          .map((tileMap) => ModuleTile.fromMap(tileMap as Map<String, dynamic>))
          .toList(),
      deviceType: _deviceTypeFromString(map['deviceType'] as String),
      lastUpdated: map['lastUpdated'] != null
          ? (map['lastUpdated'] as Timestamp).toDate()
          : null,
      userId: map['userId'] as String?,
    );
  }

  /// Helper method to convert a string to a DeviceType
  static DeviceType _deviceTypeFromString(String typeStr) {
    return DeviceType.values.firstWhere(
      (type) => type.toString().split('.').last == typeStr,
      orElse: () => DeviceType.mobile, // Default to mobile if not found
    );
  }

  /// Creates a default layout for the given device type
  factory SandboxLayout.createDefault({
    required DeviceType deviceType,
    String? userId,
  }) {
    final gridConfig = GridConfig.forDeviceType(deviceType);
    
    // Create default tiles based on device type
    final List<ModuleTile> tiles;
    
    switch (deviceType) {
      case DeviceType.mobile:
        // For mobile, stack modules vertically
        tiles = [
          ModuleTile(
            id: 'calendar-${DateTime.now().millisecondsSinceEpoch}',
            type: ModuleType.calendar,
            x: 0,
            y: 0,
            width: 4,
            height: 2,
          ),
          ModuleTile(
            id: 'todo-${DateTime.now().millisecondsSinceEpoch}',
            type: ModuleType.todo,
            x: 0,
            y: 2,
            width: 4,
            height: 2,
          ),
          ModuleTile(
            id: 'notes-${DateTime.now().millisecondsSinceEpoch}',
            type: ModuleType.notes,
            x: 0,
            y: 4,
            width: 4,
            height: 2,
          ),
        ];
        break;
      
      case DeviceType.tablet:
        // For tablet, use a 2x2 grid layout
        tiles = [
          ModuleTile(
            id: 'calendar-${DateTime.now().millisecondsSinceEpoch}',
            type: ModuleType.calendar,
            x: 0,
            y: 0,
            width: 4,
            height: 3,
          ),
          ModuleTile(
            id: 'todo-${DateTime.now().millisecondsSinceEpoch}',
            type: ModuleType.todo,
            x: 4,
            y: 0,
            width: 4,
            height: 3,
          ),
          ModuleTile(
            id: 'notes-${DateTime.now().millisecondsSinceEpoch}',
            type: ModuleType.notes,
            x: 0,
            y: 3,
            width: 4,
            height: 3,
          ),
          ModuleTile(
            id: 'whiteboard-${DateTime.now().millisecondsSinceEpoch}',
            type: ModuleType.whiteboard,
            x: 4,
            y: 3,
            width: 4,
            height: 3,
          ),
        ];
        break;
      
      case DeviceType.desktop:
        // For desktop, use a more complex layout
        tiles = [
          ModuleTile(
            id: 'calendar-${DateTime.now().millisecondsSinceEpoch}',
            type: ModuleType.calendar,
            x: 0,
            y: 0,
            width: 6,
            height: 4,
          ),
          ModuleTile(
            id: 'todo-${DateTime.now().millisecondsSinceEpoch}',
            type: ModuleType.todo,
            x: 6,
            y: 0,
            width: 3,
            height: 4,
          ),
          ModuleTile(
            id: 'notes-${DateTime.now().millisecondsSinceEpoch}',
            type: ModuleType.notes,
            x: 9,
            y: 0,
            width: 3,
            height: 4,
          ),
          ModuleTile(
            id: 'whiteboard-${DateTime.now().millisecondsSinceEpoch}',
            type: ModuleType.whiteboard,
            x: 0,
            y: 4,
            width: 6,
            height: 4,
          ),
          ModuleTile(
            id: 'cards-${DateTime.now().millisecondsSinceEpoch}',
            type: ModuleType.cards,
            x: 6,
            y: 4,
            width: 6,
            height: 4,
          ),
        ];
        break;
    }
    
    return SandboxLayout(
      gridConfig: gridConfig,
      tiles: tiles,
      deviceType: deviceType,
      lastUpdated: DateTime.now(),
      userId: userId,
    );
  }

  /// Gets the Firestore document path for this layout
  String getFirestorePath() {
    if (userId == null) {
      throw ArgumentError('Cannot get Firestore path for layout without userId');
    }
    return 'users/$userId/layouts/${deviceType.toString().split('.').last}';
  }

  @override
  List<Object?> get props => [gridConfig, tiles, deviceType, lastUpdated, userId];
  
  @override
  String toString() {
    return 'SandboxLayout(deviceType: $deviceType, gridConfig: $gridConfig, tiles: ${tiles.length}, lastUpdated: $lastUpdated)';
  }
}
