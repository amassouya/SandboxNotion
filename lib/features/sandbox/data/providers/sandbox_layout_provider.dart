import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sandboxnotion/features/sandbox/domain/models/sandbox_layout.dart';
import 'package:sandboxnotion/services/analytics_service.dart';
import 'package:sandboxnotion/services/error_service.dart';
import 'package:sandboxnotion/utils/constants.dart';
import 'package:sandboxnotion/utils/platform_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Provider for the current device type based on screen width
final deviceTypeProvider = Provider<DeviceType>((ref) {
  // Default to mobile if we can't determine the device type
  return DeviceType.mobile;
});

/// Provider for the current device type that updates with screen size changes
final responsiveDeviceTypeProvider = Provider.family<DeviceType, BuildContext>((ref, context) {
  final width = MediaQuery.of(context).size.width;
  return PlatformUtils.getDeviceType(width);
});

/// Provider for the current user ID
final currentUserIdProvider = Provider<String?>((ref) {
  return FirebaseAuth.instance.currentUser?.uid;
});

/// Stream provider for the sandbox layout from Firestore
final sandboxLayoutStreamProvider = StreamProvider.family<SandboxLayout, DeviceType>((ref, deviceType) {
  final userId = ref.watch(currentUserIdProvider);
  
  // If no user is logged in, return a default layout
  if (userId == null) {
    return Stream.value(SandboxLayout.createDefault(deviceType: deviceType));
  }
  
  // Get the Firestore instance
  final firestore = FirebaseFirestore.instance;
  
  // Create a reference to the user's layout document
  final layoutRef = firestore
      .collection('users')
      .doc(userId)
      .collection('layouts')
      .doc(deviceType.toString().split('.').last);
  
  // Return a stream of the layout document
  return layoutRef.snapshots().map((snapshot) {
    if (snapshot.exists && snapshot.data() != null) {
      try {
        return SandboxLayout.fromMap(snapshot.data()!);
      } catch (e, stack) {
        // Log the error and return a default layout
        ErrorService.instance.reportError(
          e,
          stack,
          reason: 'Error parsing sandbox layout from Firestore',
        );
        return SandboxLayout.createDefault(deviceType: deviceType, userId: userId);
      }
    } else {
      // If the document doesn't exist, create a default layout
      final defaultLayout = SandboxLayout.createDefault(deviceType: deviceType, userId: userId);
      
      // Save the default layout to Firestore (don't await to avoid blocking)
      layoutRef.set(defaultLayout.toMap()).catchError((e, stack) {
        ErrorService.instance.reportError(
          e,
          stack,
          reason: 'Error saving default sandbox layout to Firestore',
        );
      });
      
      return defaultLayout;
    }
  });
});

/// State notifier for managing the sandbox layout
class SandboxLayoutNotifier extends StateNotifier<SandboxLayout> {
  final FirebaseFirestore _firestore;
  final String? _userId;
  final DeviceType _deviceType;
  final Reader _read;
  
  // Cache for optimistic updates
  SandboxLayout? _previousState;
  
  SandboxLayoutNotifier(
    SandboxLayout initialState,
    this._firestore,
    this._userId,
    this._deviceType,
    this._read,
  ) : super(initialState) {
    // Initialize with the provided state
    _saveLayoutToLocalStorage(initialState);
  }
  
  /// Adds a new module tile to the layout
  Future<void> addTile(ModuleType moduleType) async {
    // Generate a unique ID for the tile
    final tileId = '${moduleType.toString().split('.').last}-${const Uuid().v4()}';
    
    // Create a new tile with default position and size
    final newTile = ModuleTile(
      id: tileId,
      type: moduleType,
      x: 0,
      y: 0,
      width: _getDefaultWidthForModule(moduleType),
      height: _getDefaultHeightForModule(moduleType),
    );
    
    // Add the tile to the layout
    _updateLayoutOptimistically(
      state.addTile(newTile),
      'add_tile',
      {'module_type': moduleType.toString().split('.').last},
    );
  }
  
  /// Removes a module tile from the layout
  Future<void> removeTile(String tileId) async {
    // Get the tile type for analytics
    final tileType = state.tiles.firstWhere(
      (tile) => tile.id == tileId,
      orElse: () => ModuleTile(
        id: '',
        type: ModuleType.notes,
        x: 0,
        y: 0,
        width: 1,
        height: 1,
      ),
    ).type;
    
    // Remove the tile from the layout
    _updateLayoutOptimistically(
      state.removeTile(tileId),
      'remove_tile',
      {'module_type': tileType.toString().split('.').last},
    );
  }
  
  /// Updates a module tile's position and size
  Future<void> updateTilePosition(
    String tileId,
    int x,
    int y,
    int width,
    int height,
  ) async {
    // Update the tile in the layout
    _updateLayoutOptimistically(
      state.updateTile(
        tileId,
        (tile) => tile.copyWith(
          x: x,
          y: y,
          width: width,
          height: height,
        ),
      ),
      'update_tile_position',
      {'tile_id': tileId},
    );
  }
  
  /// Toggles the maximized state of a module tile
  Future<void> toggleMaximized(String tileId) async {
    // Get the current maximized state
    final isCurrentlyMaximized = state.tiles.firstWhere(
      (tile) => tile.id == tileId,
      orElse: () => ModuleTile(
        id: '',
        type: ModuleType.notes,
        x: 0,
        y: 0,
        width: 1,
        height: 1,
      ),
    ).isMaximized;
    
    // Update the tile in the layout
    _updateLayoutOptimistically(
      state.updateTile(
        tileId,
        (tile) => tile.copyWith(isMaximized: !isCurrentlyMaximized),
      ),
      'toggle_maximized',
      {'tile_id': tileId, 'maximized': !isCurrentlyMaximized},
    );
  }
  
  /// Toggles the visibility of a module tile
  Future<void> toggleVisibility(String tileId) async {
    // Get the current visibility state
    final isCurrentlyVisible = state.tiles.firstWhere(
      (tile) => tile.id == tileId,
      orElse: () => ModuleTile(
        id: '',
        type: ModuleType.notes,
        x: 0,
        y: 0,
        width: 1,
        height: 1,
        isVisible: true,
      ),
    ).isVisible;
    
    // Update the tile in the layout
    _updateLayoutOptimistically(
      state.updateTile(
        tileId,
        (tile) => tile.copyWith(isVisible: !isCurrentlyVisible),
      ),
      'toggle_visibility',
      {'tile_id': tileId, 'visible': !isCurrentlyVisible},
    );
  }
  
  /// Updates the grid configuration
  Future<void> updateGridConfig(GridConfig gridConfig) async {
    // Update the layout with the new grid config
    _updateLayoutOptimistically(
      state.copyWith(gridConfig: gridConfig),
      'update_grid_config',
      {'columns': gridConfig.columns, 'rows': gridConfig.rows},
    );
  }
  
  /// Resets the layout to the default for the current device type
  Future<void> resetToDefault() async {
    // Create a default layout
    final defaultLayout = SandboxLayout.createDefault(
      deviceType: _deviceType,
      userId: _userId,
    );
    
    // Update the layout
    _updateLayoutOptimistically(
      defaultLayout,
      'reset_to_default',
      {'device_type': _deviceType.toString().split('.').last},
    );
  }
  
  /// Updates the layout optimistically and saves to Firestore
  Future<void> _updateLayoutOptimistically(
    SandboxLayout newLayout,
    String action,
    Map<String, dynamic> params,
  ) async {
    // Save the previous state for rollback
    _previousState = state;
    
    // Update the state optimistically
    state = newLayout;
    
    // Save to local storage
    _saveLayoutToLocalStorage(newLayout);
    
    // Log the action
    AnalyticsService.instance.logSandboxLayoutChange(
      moduleCount: newLayout.tiles.length,
      activeModules: newLayout.tiles.map((tile) => tile.type).toList(),
    );
    
    // If no user is logged in, don't save to Firestore
    if (_userId == null) {
      return;
    }
    
    try {
      // Save to Firestore
      await _saveLayoutToFirestore(newLayout);
    } catch (e, stack) {
      // Log the error
      ErrorService.instance.reportError(
        e,
        stack,
        reason: 'Error saving sandbox layout to Firestore',
        customKeys: {
          'action': action,
          ...params,
        },
      );
      
      // Rollback to the previous state
      if (_previousState != null) {
        state = _previousState!;
        _saveLayoutToLocalStorage(state);
      }
    }
  }
  
  /// Saves the layout to Firestore
  Future<void> _saveLayoutToFirestore(SandboxLayout layout) async {
    if (_userId == null) return;
    
    // Create a reference to the user's layout document
    final layoutRef = _firestore
        .collection('users')
        .doc(_userId)
        .collection('layouts')
        .doc(_deviceType.toString().split('.').last);
    
    // Save the layout to Firestore
    await layoutRef.set(layout.toMap());
  }
  
  /// Saves the layout to local storage
  Future<void> _saveLayoutToLocalStorage(SandboxLayout layout) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'sandbox_layout_${_deviceType.toString().split('.').last}';
      
      // Convert the layout to a JSON string
      final layoutJson = layout.toMap();
      
      // Remove the userId to avoid storing it locally
      layoutJson.remove('userId');
      
      // Save to shared preferences
      await prefs.setString(key, layoutJson.toString());
    } catch (e, stack) {
      // Log the error
      ErrorService.instance.reportError(
        e,
        stack,
        reason: 'Error saving sandbox layout to local storage',
      );
    }
  }
  
  /// Gets the default width for a module type
  int _getDefaultWidthForModule(ModuleType type) {
    switch (type) {
      case ModuleType.calendar:
        return _deviceType == DeviceType.mobile ? 4 : 3;
      case ModuleType.todo:
        return _deviceType == DeviceType.mobile ? 4 : 2;
      case ModuleType.notes:
        return _deviceType == DeviceType.mobile ? 4 : 2;
      case ModuleType.whiteboard:
        return _deviceType == DeviceType.mobile ? 4 : 3;
      case ModuleType.cards:
        return _deviceType == DeviceType.mobile ? 4 : 2;
    }
  }
  
  /// Gets the default height for a module type
  int _getDefaultHeightForModule(ModuleType type) {
    switch (type) {
      case ModuleType.calendar:
        return 3;
      case ModuleType.todo:
        return 2;
      case ModuleType.notes:
        return 2;
      case ModuleType.whiteboard:
        return 3;
      case ModuleType.cards:
        return 2;
    }
  }
}

/// Provider for the sandbox layout notifier
final sandboxLayoutNotifierProvider = StateNotifierProvider.family<
    SandboxLayoutNotifier,
    SandboxLayout,
    DeviceType
>((ref, deviceType) {
  final userId = ref.watch(currentUserIdProvider);
  final firestore = FirebaseFirestore.instance;
  
  // Get the initial state from the stream provider
  final layoutAsyncValue = ref.watch(sandboxLayoutStreamProvider(deviceType));
  
  // Use the data if available, otherwise create a default layout
  final initialLayout = layoutAsyncValue.maybeWhen(
    data: (layout) => layout,
    orElse: () => SandboxLayout.createDefault(deviceType: deviceType, userId: userId),
  );
  
  return SandboxLayoutNotifier(
    initialLayout,
    firestore,
    userId,
    deviceType,
    ref.read,
  );
});

/// Provider for the current sandbox layout
final currentSandboxLayoutProvider = Provider.family<SandboxLayout, BuildContext>((ref, context) {
  final deviceType = ref.watch(responsiveDeviceTypeProvider(context));
  return ref.watch(sandboxLayoutNotifierProvider(deviceType));
});

/// Provider for the sandbox layout controller
final sandboxLayoutControllerProvider = Provider.family<SandboxLayoutController, BuildContext>((ref, context) {
  final deviceType = ref.watch(responsiveDeviceTypeProvider(context));
  final notifier = ref.watch(sandboxLayoutNotifierProvider(deviceType).notifier);
  
  return SandboxLayoutController(notifier);
});

/// Controller class for sandbox layout operations
class SandboxLayoutController {
  final SandboxLayoutNotifier _notifier;
  
  SandboxLayoutController(this._notifier);
  
  /// Adds a new module tile to the layout
  Future<void> addTile(ModuleType moduleType) => _notifier.addTile(moduleType);
  
  /// Removes a module tile from the layout
  Future<void> removeTile(String tileId) => _notifier.removeTile(tileId);
  
  /// Updates a module tile's position and size
  Future<void> updateTilePosition(
    String tileId,
    int x,
    int y,
    int width,
    int height,
  ) => _notifier.updateTilePosition(tileId, x, y, width, height);
  
  /// Toggles the maximized state of a module tile
  Future<void> toggleMaximized(String tileId) => _notifier.toggleMaximized(tileId);
  
  /// Toggles the visibility of a module tile
  Future<void> toggleVisibility(String tileId) => _notifier.toggleVisibility(tileId);
  
  /// Updates the grid configuration
  Future<void> updateGridConfig(GridConfig gridConfig) => _notifier.updateGridConfig(gridConfig);
  
  /// Resets the layout to the default for the current device type
  Future<void> resetToDefault() => _notifier.resetToDefault();
}
