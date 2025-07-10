import 'dart:math';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reorderable_grid_view/entities/order_update_entity.dart';
import 'package:flutter_reorderable_grid_view/widgets/reorderable_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:sandboxnotion/features/sandbox/data/providers/sandbox_layout_provider.dart';
import 'package:sandboxnotion/features/sandbox/domain/models/sandbox_layout.dart';
import 'package:sandboxnotion/services/analytics_service.dart';
import 'package:sandboxnotion/utils/constants.dart';

/// A widget that displays a grid of module tiles that can be reordered and resized.
class SandboxGrid extends ConsumerStatefulWidget {
  /// Creates a sandbox grid widget.
  const SandboxGrid({Key? key}) : super(key: key);

  @override
  ConsumerState<SandboxGrid> createState() => _SandboxGridState();
}

class _SandboxGridState extends ConsumerState<SandboxGrid> with SingleTickerProviderStateMixin {
  // Animation controller for the grid
  late AnimationController _animationController;
  
  // The currently selected tile (for resizing)
  String? _selectedTileId;
  
  // The current resize operation
  _ResizeOperation? _currentResizeOperation;
  
  // The initial position and size of the tile being resized
  Rect? _initialTileRect;
  
  // Whether the grid is being edited
  bool _isEditing = false;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize the animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: AppConstants.animationNormal,
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the current device type
    final deviceType = ref.watch(responsiveDeviceTypeProvider(context));
    
    // Get the current layout
    final layout = ref.watch(currentSandboxLayoutProvider(context));
    
    // Get the layout controller
    final controller = ref.watch(sandboxLayoutControllerProvider(context));
    
    // Get visible tiles
    final visibleTiles = layout.tiles.where((tile) => tile.isVisible).toList();
    
    // Check if any tile is maximized
    final maximizedTile = visibleTiles.any((tile) => tile.isMaximized)
        ? visibleTiles.firstWhere((tile) => tile.isMaximized)
        : null;
    
    // Calculate grid dimensions
    final gridConfig = layout.gridConfig;
    final cellSize = gridConfig.cellSize;
    
    return Stack(
      children: [
        // Background grid
        if (gridConfig.showGridLines)
          _GridLines(
            columns: gridConfig.columns,
            rows: gridConfig.rows,
            cellSize: cellConfig.cellSize,
            color: gridConfig.gridLineColor ?? Colors.grey.withOpacity(0.2),
          ),
        
        // Empty state
        if (visibleTiles.isEmpty)
          _EmptyState(
            onAddModule: _showAddModuleDialog,
          ),
        
        // Grid content
        if (visibleTiles.isNotEmpty)
          maximizedTile != null
              ? _MaximizedTile(
                  tile: maximizedTile,
                  onClose: () => controller.toggleMaximized(maximizedTile.id),
                )
              : _buildReorderableGrid(visibleTiles, gridConfig, controller),
        
        // FAB for adding modules
        if (!_isEditing && visibleTiles.isNotEmpty && maximizedTile == null)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: _showAddModuleDialog,
              backgroundColor: AppConstants.seedColor,
              child: const Icon(Icons.add),
              tooltip: 'Add Module',
            ),
          ),
        
        // Edit mode FAB
        if (_isEditing)
          Positioned(
            right: 16,
            bottom: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Done button
                FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      _selectedTileId = null;
                    });
                  },
                  backgroundColor: AppConstants.successColor,
                  child: const Icon(Icons.check),
                  tooltip: 'Done',
                  heroTag: 'done-fab',
                ),
                const SizedBox(height: 8),
                // Reset layout button
                FloatingActionButton(
                  onPressed: () {
                    _showResetConfirmationDialog(controller);
                  },
                  backgroundColor: AppConstants.errorColor,
                  child: const Icon(Icons.restore),
                  tooltip: 'Reset Layout',
                  heroTag: 'reset-fab',
                ),
              ],
            ),
          ),
      ],
    );
  }
  
  /// Builds the reorderable grid view
  Widget _buildReorderableGrid(
    List<ModuleTile> tiles,
    GridConfig gridConfig,
    SandboxLayoutController controller,
  ) {
    return ReorderableBuilder(
      enableDraggable: _isEditing,
      dragChildBoxDecoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      onReorder: (List<OrderUpdateEntity> orderUpdateEntities) {
        // Handle reordering
        for (final update in orderUpdateEntities) {
          final fromTile = tiles[update.oldIndex];
          final toTile = tiles[update.newIndex];
          
          // Swap positions
          controller.updateTilePosition(
            fromTile.id,
            toTile.x,
            toTile.y,
            fromTile.width,
            fromTile.height,
          );
          
          controller.updateTilePosition(
            toTile.id,
            fromTile.x,
            fromTile.y,
            toTile.width,
            toTile.height,
          );
        }
      },
      builder: (children) {
        return SizedBox(
          width: gridConfig.totalWidth,
          height: gridConfig.totalHeight,
          child: Stack(
            children: [
              // Place each tile at its position
              ...tiles.asMap().entries.map((entry) {
                final index = entry.key;
                final tile = entry.value;
                
                // Calculate position and size
                final position = tile.getPositionInPixels(gridConfig.cellSize);
                final size = tile.getSizeInPixels(gridConfig.cellSize);
                
                return Positioned(
                  left: position.dx,
                  top: position.dy,
                  width: size.width,
                  height: size.height,
                  child: _buildTileWidget(
                    children[index],
                    tile,
                    gridConfig,
                    controller,
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
      children: tiles.map((tile) {
        return _ModuleTileContent(
          key: ValueKey(tile.id),
          tile: tile,
          isSelected: tile.id == _selectedTileId,
          onTap: () {
            if (_isEditing) {
              setState(() {
                _selectedTileId = tile.id;
              });
            }
          },
          onLongPress: () {
            if (!_isEditing) {
              setState(() {
                _isEditing = true;
                _selectedTileId = tile.id;
              });
            }
          },
          onMaximize: () => controller.toggleMaximized(tile.id),
          onClose: () => controller.removeTile(tile.id),
        );
      }).toList(),
    );
  }
  
  /// Builds a tile widget with resize handles if selected
  Widget _buildTileWidget(
    Widget child,
    ModuleTile tile,
    GridConfig gridConfig,
    SandboxLayoutController controller,
  ) {
    final isSelected = tile.id == _selectedTileId;
    
    return Stack(
      children: [
        // The tile content
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.sandboxTileCornerRadius),
            border: isSelected
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : null,
          ),
          child: child,
        ),
        
        // Resize handles (only show if selected)
        if (isSelected && _isEditing)
          ..._buildResizeHandles(tile, gridConfig, controller),
      ],
    );
  }
  
  /// Builds the resize handles for a tile
  List<Widget> _buildResizeHandles(
    ModuleTile tile,
    GridConfig gridConfig,
    SandboxLayoutController controller,
  ) {
    const handleSize = AppConstants.sandboxResizeHandleSize;
    
    return [
      // Top-left handle
      Positioned(
        left: 0,
        top: 0,
        child: _ResizeHandle(
          onPanStart: (details) {
            _startResizeOperation(
              tile,
              _ResizeOperation.topLeft,
              details.globalPosition,
              gridConfig,
            );
          },
          onPanUpdate: (details) {
            _updateResizeOperation(
              details.globalPosition,
              gridConfig,
              controller,
            );
          },
          onPanEnd: (details) {
            _endResizeOperation();
          },
          alignment: Alignment.topLeft,
        ),
      ),
      
      // Top-right handle
      Positioned(
        right: 0,
        top: 0,
        child: _ResizeHandle(
          onPanStart: (details) {
            _startResizeOperation(
              tile,
              _ResizeOperation.topRight,
              details.globalPosition,
              gridConfig,
            );
          },
          onPanUpdate: (details) {
            _updateResizeOperation(
              details.globalPosition,
              gridConfig,
              controller,
            );
          },
          onPanEnd: (details) {
            _endResizeOperation();
          },
          alignment: Alignment.topRight,
        ),
      ),
      
      // Bottom-left handle
      Positioned(
        left: 0,
        bottom: 0,
        child: _ResizeHandle(
          onPanStart: (details) {
            _startResizeOperation(
              tile,
              _ResizeOperation.bottomLeft,
              details.globalPosition,
              gridConfig,
            );
          },
          onPanUpdate: (details) {
            _updateResizeOperation(
              details.globalPosition,
              gridConfig,
              controller,
            );
          },
          onPanEnd: (details) {
            _endResizeOperation();
          },
          alignment: Alignment.bottomLeft,
        ),
      ),
      
      // Bottom-right handle
      Positioned(
        right: 0,
        bottom: 0,
        child: _ResizeHandle(
          onPanStart: (details) {
            _startResizeOperation(
              tile,
              _ResizeOperation.bottomRight,
              details.globalPosition,
              gridConfig,
            );
          },
          onPanUpdate: (details) {
            _updateResizeOperation(
              details.globalPosition,
              gridConfig,
              controller,
            );
          },
          onPanEnd: (details) {
            _endResizeOperation();
          },
          alignment: Alignment.bottomRight,
        ),
      ),
    ];
  }
  
  /// Starts a resize operation
  void _startResizeOperation(
    ModuleTile tile,
    _ResizeOperation operation,
    Offset globalPosition,
    GridConfig gridConfig,
  ) {
    // Get the RenderBox of the grid
    final RenderBox? gridBox = context.findRenderObject() as RenderBox?;
    if (gridBox == null) return;
    
    // Convert global position to local position
    final localPosition = gridBox.globalToLocal(globalPosition);
    
    // Store the initial tile rect
    _initialTileRect = Rect.fromLTWH(
      tile.x.toDouble(),
      tile.y.toDouble(),
      tile.width.toDouble(),
      tile.height.toDouble(),
    );
    
    // Store the current resize operation
    _currentResizeOperation = operation;
  }
  
  /// Updates a resize operation
  void _updateResizeOperation(
    Offset globalPosition,
    GridConfig gridConfig,
    SandboxLayoutController controller,
  ) {
    if (_initialTileRect == null || _currentResizeOperation == null || _selectedTileId == null) {
      return;
    }
    
    // Get the RenderBox of the grid
    final RenderBox? gridBox = context.findRenderObject() as RenderBox?;
    if (gridBox == null) return;
    
    // Convert global position to local position
    final localPosition = gridBox.globalToLocal(globalPosition);
    
    // Convert local position to grid coordinates
    final gridX = (localPosition.dx / gridConfig.cellSize).floor();
    final gridY = (localPosition.dy / gridConfig.cellSize).floor();
    
    // Calculate new rect based on the resize operation
    Rect newRect = _initialTileRect!;
    
    switch (_currentResizeOperation!) {
      case _ResizeOperation.topLeft:
        newRect = Rect.fromLTRB(
          min(gridX.toDouble(), _initialTileRect!.right - 1),
          min(gridY.toDouble(), _initialTileRect!.bottom - 1),
          _initialTileRect!.right,
          _initialTileRect!.bottom,
        );
        break;
      case _ResizeOperation.topRight:
        newRect = Rect.fromLTRB(
          _initialTileRect!.left,
          min(gridY.toDouble(), _initialTileRect!.bottom - 1),
          max(gridX.toDouble() + 1, _initialTileRect!.left + 1),
          _initialTileRect!.bottom,
        );
        break;
      case _ResizeOperation.bottomLeft:
        newRect = Rect.fromLTRB(
          min(gridX.toDouble(), _initialTileRect!.right - 1),
          _initialTileRect!.top,
          _initialTileRect!.right,
          max(gridY.toDouble() + 1, _initialTileRect!.top + 1),
        );
        break;
      case _ResizeOperation.bottomRight:
        newRect = Rect.fromLTRB(
          _initialTileRect!.left,
          _initialTileRect!.top,
          max(gridX.toDouble() + 1, _initialTileRect!.left + 1),
          max(gridY.toDouble() + 1, _initialTileRect!.top + 1),
        );
        break;
    }
    
    // Ensure minimum size
    newRect = Rect.fromLTRB(
      newRect.left,
      newRect.top,
      max(newRect.right, newRect.left + 1),
      max(newRect.bottom, newRect.top + 1),
    );
    
    // Ensure within grid bounds
    newRect = Rect.fromLTRB(
      max(0, min(newRect.left, gridConfig.columns - 1.0)),
      max(0, min(newRect.top, gridConfig.rows - 1.0)),
      max(1, min(newRect.right, gridConfig.columns.toDouble())),
      max(1, min(newRect.bottom, gridConfig.rows.toDouble())),
    );
    
    // Update the tile position
    controller.updateTilePosition(
      _selectedTileId!,
      newRect.left.toInt(),
      newRect.top.toInt(),
      newRect.width.toInt(),
      newRect.height.toInt(),
    );
  }
  
  /// Ends a resize operation
  void _endResizeOperation() {
    _initialTileRect = null;
    _currentResizeOperation = null;
  }
  
  /// Shows the add module dialog
  void _showAddModuleDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _AddModuleBottomSheet(
        onModuleSelected: (moduleType) {
          // Get the layout controller
          final controller = ref.read(sandboxLayoutControllerProvider(context));
          
          // Add the new tile
          controller.addTile(moduleType);
          
          // Log the event
          AnalyticsService.instance.logCustomEvent(
            eventName: 'add_module',
            parameters: {
              'module_type': moduleType.toString().split('.').last,
            },
          );
          
          // Close the dialog
          Navigator.of(context).pop();
        },
      ),
    );
  }
  
  /// Shows the reset confirmation dialog
  void _showResetConfirmationDialog(SandboxLayoutController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Layout'),
        content: const Text(
          'Are you sure you want to reset the layout to the default? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Reset the layout
              controller.resetToDefault();
              
              // Log the event
              AnalyticsService.instance.logCustomEvent(
                eventName: 'reset_layout',
              );
              
              // Close the dialog
              Navigator.of(context).pop();
              
              // Exit edit mode
              setState(() {
                _isEditing = false;
                _selectedTileId = null;
              });
            },
            child: const Text('Reset'),
            style: TextButton.styleFrom(
              foregroundColor: AppConstants.errorColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// A widget that displays grid lines
class _GridLines extends StatelessWidget {
  final int columns;
  final int rows;
  final double cellSize;
  final Color color;

  const _GridLines({
    Key? key,
    required this.columns,
    required this.rows,
    required this.cellSize,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(
        columns * cellSize,
        rows * cellSize,
      ),
      painter: _GridPainter(
        columns: columns,
        rows: rows,
        cellSize: cellSize,
        color: color,
      ),
    );
  }
}

/// A custom painter that draws grid lines
class _GridPainter extends CustomPainter {
  final int columns;
  final int rows;
  final double cellSize;
  final Color color;

  _GridPainter({
    required this.columns,
    required this.rows,
    required this.cellSize,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    // Draw vertical lines
    for (int i = 0; i <= columns; i++) {
      final x = i * cellSize;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (int i = 0; i <= rows; i++) {
      final y = i * cellSize;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

/// A widget that displays a resize handle
class _ResizeHandle extends StatelessWidget {
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;
  final Alignment alignment;

  const _ResizeHandle({
    Key? key,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.alignment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      child: Container(
        width: AppConstants.sandboxResizeHandleSize,
        height: AppConstants.sandboxResizeHandleSize,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).colorScheme.onPrimary,
            width: 2,
          ),
        ),
        child: Center(
          child: Icon(
            _getIconForAlignment(alignment),
            size: 12,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }
  
  /// Gets the appropriate icon for the alignment
  IconData _getIconForAlignment(Alignment alignment) {
    if (alignment == Alignment.topLeft) {
      return Icons.north_west;
    } else if (alignment == Alignment.topRight) {
      return Icons.north_east;
    } else if (alignment == Alignment.bottomLeft) {
      return Icons.south_west;
    } else if (alignment == Alignment.bottomRight) {
      return Icons.south_east;
    }
    return Icons.drag_indicator;
  }
}

/// A widget that displays the empty state
class _EmptyState extends StatelessWidget {
  final VoidCallback onAddModule;

  const _EmptyState({
    Key? key,
    required this.onAddModule,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Lottie animation
          Lottie.asset(
            AppConstants.emptyStateLottie,
            width: 200,
            height: 200,
            repeat: true,
          ),
          const SizedBox(height: 16),
          // Title
          Text(
            'Your Sandbox is Empty',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          // Description
          Text(
            'Add modules to create your personalized workspace',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Add button
          ElevatedButton.icon(
            onPressed: onAddModule,
            icon: const Icon(Icons.add),
            label: const Text('Add Module'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.seedColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A widget that displays a maximized tile
class _MaximizedTile extends StatelessWidget {
  final ModuleTile tile;
  final VoidCallback onClose;

  const _MaximizedTile({
    Key? key,
    required this.tile,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // The tile content
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
            child: _ModuleContent(
              tile: tile,
              isMaximized: true,
            ),
          ),
        ),
        
        // Close button
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.fullscreen_exit),
            tooltip: 'Exit Fullscreen',
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

/// A widget that displays the content of a module tile
class _ModuleTileContent extends StatelessWidget {
  final ModuleTile tile;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onMaximize;
  final VoidCallback onClose;

  const _ModuleTileContent({
    Key? key,
    required this.tile,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.onMaximize,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: AppConstants.animationFast,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppConstants.sandboxTileCornerRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.2 : 0.1),
              blurRadius: isSelected ? 8 : 4,
              offset: isSelected ? const Offset(0, 4) : const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tile header
            Container(
              height: AppConstants.sandboxTileHeaderHeight,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: tile.type.color.withOpacity(0.9),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppConstants.sandboxTileCornerRadius),
                  topRight: Radius.circular(AppConstants.sandboxTileCornerRadius),
                ),
              ),
              child: Row(
                children: [
                  // Module icon
                  Icon(
                    tile.type.icon,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  // Module name
                  Expanded(
                    child: Text(
                      tile.type.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Actions
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Maximize button
                      IconButton(
                        onPressed: onMaximize,
                        icon: const Icon(Icons.fullscreen),
                        iconSize: 16,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 24,
                          minHeight: 24,
                        ),
                        color: Colors.white,
                        tooltip: 'Maximize',
                      ),
                      // Close button (only visible when selected)
                      if (isSelected)
                        IconButton(
                          onPressed: onClose,
                          icon: const Icon(Icons.close),
                          iconSize: 16,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                          color: Colors.white,
                          tooltip: 'Remove',
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Tile content
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(AppConstants.sandboxTileCornerRadius),
                  bottomRight: Radius.circular(AppConstants.sandboxTileCornerRadius),
                ),
                child: _ModuleContent(
                  tile: tile,
                  isMaximized: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A widget that displays the content of a module
class _ModuleContent extends StatelessWidget {
  final ModuleTile tile;
  final bool isMaximized;

  const _ModuleContent({
    Key? key,
    required this.tile,
    required this.isMaximized,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Placeholder content for each module type
    // This will be replaced with actual module widgets in the future
    switch (tile.type) {
      case ModuleType.calendar:
        return Container(
          color: AppConstants.calendarModuleColor.withOpacity(0.1),
          child: const Center(
            child: Icon(
              Icons.calendar_today,
              size: 48,
              color: AppConstants.calendarModuleColor,
            ),
          ),
        );
      case ModuleType.todo:
        return Container(
          color: AppConstants.todoModuleColor.withOpacity(0.1),
          child: const Center(
            child: Icon(
              Icons.check_circle_outline,
              size: 48,
              color: AppConstants.todoModuleColor,
            ),
          ),
        );
      case ModuleType.notes:
        return Container(
          color: AppConstants.notesModuleColor.withOpacity(0.1),
          child: const Center(
            child: Icon(
              Icons.note,
              size: 48,
              color: AppConstants.notesModuleColor,
            ),
          ),
        );
      case ModuleType.whiteboard:
        return Container(
          color: AppConstants.whiteboardModuleColor.withOpacity(0.1),
          child: const Center(
            child: Icon(
              Icons.edit,
              size: 48,
              color: AppConstants.whiteboardModuleColor,
            ),
          ),
        );
      case ModuleType.cards:
        return Container(
          color: AppConstants.cardsModuleColor.withOpacity(0.1),
          child: const Center(
            child: Icon(
              Icons.style,
              size: 48,
              color: AppConstants.cardsModuleColor,
            ),
          ),
        );
    }
  }
}

/// A bottom sheet for adding a new module
class _AddModuleBottomSheet extends StatelessWidget {
  final Function(ModuleType) onModuleSelected;

  const _AddModuleBottomSheet({
    Key? key,
    required this.onModuleSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Text(
            'Add Module',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Module grid
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: ModuleType.values.map((moduleType) {
              return _ModuleOption(
                moduleType: moduleType,
                onTap: () => onModuleSelected(moduleType),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Cancel button
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

/// A widget that displays a module option
class _ModuleOption extends StatelessWidget {
  final ModuleType moduleType;
  final VoidCallback onTap;

  const _ModuleOption({
    Key? key,
    required this.moduleType,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OpenContainer(
      transitionDuration: AppConstants.animationNormal,
      openBuilder: (context, _) => Container(
        color: Theme.of(context).colorScheme.surface,
        child: Center(
          child: Text('${moduleType.name} will be added'),
        ),
      ),
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      closedColor: moduleType.color.withOpacity(0.1),
      closedBuilder: (context, openContainer) {
        return InkWell(
          onTap: () {
            onTap();
            // Don't open the container
          },
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Module icon
              Icon(
                moduleType.icon,
                size: 32,
                color: moduleType.color,
              ),
              const SizedBox(height: 8),
              // Module name
              Text(
                moduleType.name,
                style: TextStyle(
                  color: moduleType.color,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Enum for resize operations
enum _ResizeOperation {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}
