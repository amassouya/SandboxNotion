import 'package:flutter/material.dart';
import 'package:sandboxnotion/utils/constants.dart';

/// The position of a drag handle on a tile
enum HandlePosition {
  topLeft,
  top,
  topRight,
  right,
  bottomRight,
  bottom,
  bottomLeft,
  left,
}

/// A widget that provides a draggable handle for resizing tiles
class DragHandle extends StatefulWidget {
  /// The position of this handle
  final HandlePosition position;
  
  /// The size of the handle
  final double size;
  
  /// The color of the handle
  final Color color;
  
  /// The color of the handle when hovered
  final Color? hoverColor;
  
  /// Whether the handle is visible
  final bool isVisible;
  
  /// Callback when the handle is dragged
  final Function(DragUpdateDetails) onDrag;
  
  /// Callback when the drag starts
  final Function(DragStartDetails)? onDragStart;
  
  /// Callback when the drag ends
  final Function(DragEndDetails)? onDragEnd;

  const DragHandle({
    Key? key,
    required this.position,
    this.size = AppConstants.sandboxTileResizeHandleSize,
    required this.color,
    this.hoverColor,
    this.isVisible = true,
    required this.onDrag,
    this.onDragStart,
    this.onDragEnd,
  }) : super(key: key);

  @override
  State<DragHandle> createState() => _DragHandleState();
}

class _DragHandleState extends State<DragHandle> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    // Get the appropriate cursor based on handle position
    final cursor = _getCursorForPosition(widget.position);
    
    // Get the appropriate alignment based on handle position
    final alignment = _getAlignmentForPosition(widget.position);
    
    // Determine if this is a corner handle
    final isCorner = _isCornerHandle(widget.position);
    
    return Align(
      alignment: alignment,
      child: MouseRegion(
        cursor: cursor,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onPanStart: widget.onDragStart,
          onPanUpdate: widget.onDrag,
          onPanEnd: widget.onDragEnd,
          child: Container(
            width: isCorner ? widget.size : (widget.position == HandlePosition.left || widget.position == HandlePosition.right) ? widget.size / 2 : widget.size,
            height: isCorner ? widget.size : (widget.position == HandlePosition.top || widget.position == HandlePosition.bottom) ? widget.size / 2 : widget.size,
            decoration: BoxDecoration(
              color: _isHovered 
                  ? (widget.hoverColor ?? widget.color.withOpacity(0.8)) 
                  : widget.color.withOpacity(0.5),
              shape: isCorner ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: !isCorner ? BorderRadius.circular(widget.size / 4) : null,
              border: Border.all(
                color: Colors.white,
                width: 1.5,
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: widget.color.withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  /// Returns the appropriate cursor for the given handle position
  MouseCursor _getCursorForPosition(HandlePosition position) {
    switch (position) {
      case HandlePosition.topLeft:
        return SystemMouseCursors.resizeUpLeft;
      case HandlePosition.top:
        return SystemMouseCursors.resizeUp;
      case HandlePosition.topRight:
        return SystemMouseCursors.resizeUpRight;
      case HandlePosition.right:
        return SystemMouseCursors.resizeRight;
      case HandlePosition.bottomRight:
        return SystemMouseCursors.resizeDownRight;
      case HandlePosition.bottom:
        return SystemMouseCursors.resizeDown;
      case HandlePosition.bottomLeft:
        return SystemMouseCursors.resizeDownLeft;
      case HandlePosition.left:
        return SystemMouseCursors.resizeLeft;
    }
  }

  /// Returns the appropriate alignment for the given handle position
  Alignment _getAlignmentForPosition(HandlePosition position) {
    switch (position) {
      case HandlePosition.topLeft:
        return Alignment.topLeft;
      case HandlePosition.top:
        return Alignment.topCenter;
      case HandlePosition.topRight:
        return Alignment.topRight;
      case HandlePosition.right:
        return Alignment.centerRight;
      case HandlePosition.bottomRight:
        return Alignment.bottomRight;
      case HandlePosition.bottom:
        return Alignment.bottomCenter;
      case HandlePosition.bottomLeft:
        return Alignment.bottomLeft;
      case HandlePosition.left:
        return Alignment.centerLeft;
    }
  }

  /// Returns whether the given position is a corner
  bool _isCornerHandle(HandlePosition position) {
    return position == HandlePosition.topLeft ||
        position == HandlePosition.topRight ||
        position == HandlePosition.bottomRight ||
        position == HandlePosition.bottomLeft;
  }
}

/// A widget that displays all resize handles around a tile
class ResizeHandles extends StatelessWidget {
  /// The color of the handles
  final Color color;
  
  /// The color of the handles when hovered
  final Color? hoverColor;
  
  /// The size of the handles
  final double handleSize;
  
  /// Whether the handles are visible
  final bool isVisible;
  
  /// Callback when a handle is dragged
  final Function(HandlePosition, DragUpdateDetails) onHandleDrag;
  
  /// Callback when a handle drag starts
  final Function(HandlePosition, DragStartDetails)? onHandleDragStart;
  
  /// Callback when a handle drag ends
  final Function(HandlePosition, DragEndDetails)? onHandleDragEnd;
  
  /// Whether to show corner handles only
  final bool cornersOnly;

  const ResizeHandles({
    Key? key,
    required this.color,
    this.hoverColor,
    this.handleSize = AppConstants.sandboxTileResizeHandleSize,
    this.isVisible = true,
    required this.onHandleDrag,
    this.onHandleDragStart,
    this.onHandleDragEnd,
    this.cornersOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<HandlePosition> positions = cornersOnly
        ? [
            HandlePosition.topLeft,
            HandlePosition.topRight,
            HandlePosition.bottomRight,
            HandlePosition.bottomLeft,
          ]
        : HandlePosition.values;

    return Stack(
      children: positions.map((position) {
        return DragHandle(
          position: position,
          size: handleSize,
          color: color,
          hoverColor: hoverColor,
          isVisible: isVisible,
          onDrag: (details) => onHandleDrag(position, details),
          onDragStart: onHandleDragStart != null
              ? (details) => onHandleDragStart!(position, details)
              : null,
          onDragEnd: onHandleDragEnd != null
              ? (details) => onHandleDragEnd!(position, details)
              : null,
        );
      }).toList(),
    );
  }
}
