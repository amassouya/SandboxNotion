import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sandboxnotion/utils/constants.dart';

/// Whiteboard screen that displays a drawing canvas with tools
class WhiteboardScreen extends StatefulWidget {
  /// Optional whiteboard identifier passed from the router  
  /// (e.g. `/sandbox/whiteboard/:boardId`).
  ///
  /// The parameter is currently not used inside the placeholder
  /// implementation, but accepting it here allows the router
  /// (`app_router.dart`) to instantiate the screen with an
  /// optional `boardId` without throwing a type error.
  final String? boardId;

  const WhiteboardScreen({
    Key? key,
    this.boardId,
  }) : super(key: key);

  @override
  State<WhiteboardScreen> createState() => _WhiteboardScreenState();
}

class _WhiteboardScreenState extends State<WhiteboardScreen> {
  // Currently selected tool
  DrawingTool _selectedTool = DrawingTool.pen;
  
  // Currently selected color
  Color _selectedColor = Colors.black;
  
  // Stroke width
  double _strokeWidth = 3.0;
  
  // Whether the layers panel is open
  bool _isLayersPanelOpen = false;
  
  // List of dummy layers
  final List<WhiteboardLayer> _layers = [
    WhiteboardLayer(
      id: '1',
      name: 'Background',
      isVisible: true,
      isLocked: false,
    ),
    WhiteboardLayer(
      id: '2',
      name: 'Sketch',
      isVisible: true,
      isLocked: false,
    ),
    WhiteboardLayer(
      id: '3',
      name: 'Notes',
      isVisible: true,
      isLocked: false,
    ),
  ];
  
  // Currently selected layer
  String _selectedLayerId = '2'; // Sketch layer

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Whiteboard',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
          tooltip: 'Back to Sandbox',
        ),
        actions: [
          // Undo button
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: null, // Disabled in placeholder
            tooltip: 'Undo',
          ),
          
          // Redo button
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: null, // Disabled in placeholder
            tooltip: 'Redo',
          ),
          
          // Clear button
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: null, // Disabled in placeholder
            tooltip: 'Clear Canvas',
          ),
          
          // Export button
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: null, // Disabled in placeholder
            tooltip: 'Export',
          ),
          
          // More options
          PopupMenuButton<String>(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'grid',
                child: Text('Show Grid'),
              ),
              const PopupMenuItem(
                value: 'snap',
                child: Text('Snap to Grid'),
              ),
              const PopupMenuItem(
                value: 'background',
                child: Text('Change Background'),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Text('Share Whiteboard'),
              ),
            ],
            onSelected: (value) {
              // Would implement options in a real app
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content with canvas and tools
          Row(
            children: [
              // Layers panel (if open)
              if (_isLayersPanelOpen)
                Container(
                  width: 240,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[900] : Colors.white,
                    border: Border(
                      right: BorderSide(
                        color: isDarkMode
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.1),
                      ),
                    ),
                  ),
                  child: _buildLayersPanel(context, isDarkMode),
                ),
              
              // Canvas and tools
              Expanded(
                child: Column(
                  children: [
                    // Canvas area
                    Expanded(
                      child: _buildCanvas(context, isDarkMode),
                    ),
                    
                    // Drawing tools toolbar
                    _buildToolbar(context, isDarkMode),
                  ],
                ),
              ),
            ],
          ),
          
          // Under construction overlay
          Positioned.fill(
            child: Container(
              color: isDarkMode 
                  ? Colors.black.withOpacity(0.7) 
                  : Colors.white.withOpacity(0.7),
              child: Center(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.construction,
                          size: 64,
                          color: AppConstants.seedColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Whiteboard Module',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This feature is under construction.\nCheck back soon!',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Back to Sandbox'),
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
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      // Toggle layers panel button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _isLayersPanelOpen = !_isLayersPanelOpen;
          });
        },
        backgroundColor: AppConstants.seedColor,
        foregroundColor: Colors.white,
        child: Icon(_isLayersPanelOpen ? Icons.layers_clear : Icons.layers),
      ),
    );
  }

  // Build the canvas widget
  Widget _buildCanvas(BuildContext context, bool isDarkMode) {
    return Container(
      color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[800] : Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CustomPaint(
              painter: _WhiteboardPainter(
                isDarkMode: isDarkMode,
                showGrid: true,
              ),
              child: Container(),
            ),
          ),
        ),
      ),
    );
  }

  // Build the toolbar widget
  Widget _buildToolbar(BuildContext context, bool isDarkMode) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Drawing tools
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Pen tool
                  _buildToolButton(
                    context,
                    DrawingTool.pen,
                    Icons.edit,
                    'Pen',
                  ),
                  
                  // Highlighter tool
                  _buildToolButton(
                    context,
                    DrawingTool.highlighter,
                    Icons.brush,
                    'Highlighter',
                  ),
                  
                  // Eraser tool
                  _buildToolButton(
                    context,
                    DrawingTool.eraser,
                    Icons.auto_fix_high,
                    'Eraser',
                  ),
                  
                  // Text tool
                  _buildToolButton(
                    context,
                    DrawingTool.text,
                    Icons.text_fields,
                    'Text',
                  ),
                  
                  // Shape tool
                  _buildToolButton(
                    context,
                    DrawingTool.shape,
                    Icons.shape_line,
                    'Shape',
                  ),
                  
                  // Selection tool
                  _buildToolButton(
                    context,
                    DrawingTool.selection,
                    Icons.crop_free,
                    'Select',
                  ),
                  
                  // Hand tool (for panning)
                  _buildToolButton(
                    context,
                    DrawingTool.hand,
                    Icons.pan_tool,
                    'Pan',
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Divider
                  Container(
                    height: 36,
                    width: 1,
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.1),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Color picker
                  _buildColorPicker(context, isDarkMode),
                  
                  const SizedBox(width: 16),
                  
                  // Stroke width slider
                  Container(
                    width: 150,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Stroke Width',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDarkMode ? Colors.white54 : Colors.black54,
                          ),
                        ),
                        Slider(
                          value: _strokeWidth,
                          min: 1.0,
                          max: 10.0,
                          divisions: 9,
                          label: _strokeWidth.round().toString(),
                          onChanged: (value) {
                            setState(() {
                              _strokeWidth = value;
                            });
                          },
                          activeColor: AppConstants.seedColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build a tool button
  Widget _buildToolButton(
    BuildContext context,
    DrawingTool tool,
    IconData icon,
    String tooltip,
  ) {
    final isSelected = _selectedTool == tool;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: isSelected
              ? AppConstants.seedColor.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              setState(() {
                _selectedTool = tool;
              });
            },
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: isSelected
                    ? Border.all(
                        color: AppConstants.seedColor,
                        width: 2,
                      )
                    : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? AppConstants.seedColor
                    : isDarkMode
                        ? Colors.white70
                        : Colors.black54,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Build color picker
  Widget _buildColorPicker(BuildContext context, bool isDarkMode) {
    final colors = [
      Colors.black,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
    ];
    
    return Row(
      children: [
        Text(
          'Color:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isDarkMode ? Colors.white54 : Colors.black54,
          ),
        ),
        const SizedBox(width: 8),
        ...colors.map((color) {
          final isSelected = _selectedColor == color;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                setState(() {
                  _selectedColor = color;
                });
              },
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppConstants.seedColor
                        : isDarkMode
                            ? Colors.white70
                            : Colors.black54,
                    width: isSelected ? 2 : 1,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // Build layers panel
  Widget _buildLayersPanel(BuildContext context, bool isDarkMode) {
    return Column(
      children: [
        // Panel header
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.1),
              ),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.layers),
              const SizedBox(width: 8),
              Text(
                'Layers',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: null, // Disabled in placeholder
                tooltip: 'Add Layer',
              ),
            ],
          ),
        ),
        
        // Layers list
        Expanded(
          child: ListView.builder(
            itemCount: _layers.length,
            itemBuilder: (context, index) {
              final layer = _layers[index];
              final isSelected = layer.id == _selectedLayerId;
              
              return ListTile(
                selected: isSelected,
                selectedTileColor: AppConstants.seedColor.withOpacity(0.1),
                leading: IconButton(
                  icon: Icon(
                    layer.isVisible ? Icons.visibility : Icons.visibility_off,
                    color: layer.isVisible
                        ? isDarkMode
                            ? Colors.white70
                            : Colors.black54
                        : Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      layer.isVisible = !layer.isVisible;
                    });
                  },
                  tooltip: layer.isVisible ? 'Hide Layer' : 'Show Layer',
                ),
                title: Text(
                  layer.name,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(
                    layer.isLocked ? Icons.lock : Icons.lock_open,
                    color: layer.isLocked
                        ? Colors.red
                        : isDarkMode
                            ? Colors.white54
                            : Colors.black45,
                  ),
                  onPressed: () {
                    setState(() {
                      layer.isLocked = !layer.isLocked;
                    });
                  },
                  tooltip: layer.isLocked ? 'Unlock Layer' : 'Lock Layer',
                ),
                onTap: () {
                  setState(() {
                    _selectedLayerId = layer.id;
                  });
                },
              );
            },
          ),
        ),
        
        // Panel footer
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.1),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete'),
                onPressed: null, // Disabled in placeholder
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.arrow_upward),
                label: const Text('Move Up'),
                onPressed: null, // Disabled in placeholder
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Drawing tools available in the whiteboard
enum DrawingTool {
  pen,
  highlighter,
  eraser,
  text,
  shape,
  selection,
  hand,
}

/// Model class for whiteboard layers
class WhiteboardLayer {
  final String id;
  final String name;
  bool isVisible;
  bool isLocked;

  WhiteboardLayer({
    required this.id,
    required this.name,
    this.isVisible = true,
    this.isLocked = false,
  });
}

/// Custom painter for the whiteboard
class _WhiteboardPainter extends CustomPainter {
  final bool isDarkMode;
  final bool showGrid;

  _WhiteboardPainter({
    required this.isDarkMode,
    this.showGrid = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw grid if enabled
    if (showGrid) {
      final gridPaint = Paint()
        ..color = isDarkMode
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.1)
        ..strokeWidth = 0.5;
      
      // Draw horizontal grid lines
      for (var i = 0; i < size.height; i += 20) {
        canvas.drawLine(
          Offset(0, i.toDouble()),
          Offset(size.width, i.toDouble()),
          gridPaint,
        );
      }
      
      // Draw vertical grid lines
      for (var i = 0; i < size.width; i += 20) {
        canvas.drawLine(
          Offset(i.toDouble(), 0),
          Offset(i.toDouble(), size.height),
          gridPaint,
        );
      }
    }
    
    // Draw a sample path for demonstration
    final paint = Paint()
      ..color = AppConstants.seedColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    
    final path = Path();
    path.moveTo(size.width * 0.2, size.height * 0.3);
    path.quadraticBezierTo(
      size.width * 0.5, size.height * 0.1,
      size.width * 0.8, size.height * 0.3,
    );
    path.quadraticBezierTo(
      size.width * 0.9, size.height * 0.5,
      size.width * 0.7, size.height * 0.7,
    );
    path.quadraticBezierTo(
      size.width * 0.5, size.height * 0.9,
      size.width * 0.3, size.height * 0.7,
    );
    path.quadraticBezierTo(
      size.width * 0.1, size.height * 0.5,
      size.width * 0.2, size.height * 0.3,
    );
    
    canvas.drawPath(path, paint);
    
    // Draw a sample shape
    final rectPaint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    final rect = Rect.fromLTWH(
      size.width * 0.6, size.height * 0.1,
      size.width * 0.3, size.height * 0.15,
    );
    
    canvas.drawRect(rect, rectPaint);
    
    // Draw a sample text placeholder
    final textPaint = Paint()
      ..color = isDarkMode ? Colors.white70 : Colors.black87;
    
    final textRect = Rect.fromLTWH(
      size.width * 0.1, size.height * 0.8,
      size.width * 0.3, size.height * 0.1,
    );
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(textRect, const Radius.circular(4)),
      Paint()
        ..color = isDarkMode
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.05),
    );
    
    // Draw selection handles
    final handlePaint = Paint()
      ..color = AppConstants.seedColor
      ..style = PaintingStyle.fill;
    
    final handleStrokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    final handleSize = 12.0;
    
    // Top-left handle
    canvas.drawCircle(
      Offset(rect.left, rect.top),
      handleSize / 2,
      handlePaint,
    );
    canvas.drawCircle(
      Offset(rect.left, rect.top),
      handleSize / 2,
      handleStrokePaint,
    );
    
    // Top-right handle
    canvas.drawCircle(
      Offset(rect.right, rect.top),
      handleSize / 2,
      handlePaint,
    );
    canvas.drawCircle(
      Offset(rect.right, rect.top),
      handleSize / 2,
      handleStrokePaint,
    );
    
    // Bottom-left handle
    canvas.drawCircle(
      Offset(rect.left, rect.bottom),
      handleSize / 2,
      handlePaint,
    );
    canvas.drawCircle(
      Offset(rect.left, rect.bottom),
      handleSize / 2,
      handleStrokePaint,
    );
    
    // Bottom-right handle
    canvas.drawCircle(
      Offset(rect.right, rect.bottom),
      handleSize / 2,
      handlePaint,
    );
    canvas.drawCircle(
      Offset(rect.right, rect.bottom),
      handleSize / 2,
      handleStrokePaint,
    );
  }

  @override
  bool shouldRepaint(_WhiteboardPainter oldDelegate) {
    return oldDelegate.isDarkMode != isDarkMode ||
        oldDelegate.showGrid != showGrid;
  }
}
