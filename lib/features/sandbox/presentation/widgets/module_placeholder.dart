import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sandboxnotion/utils/constants.dart';

/// A placeholder widget for modules in the sandbox grid
class ModulePlaceholder extends StatelessWidget {
  /// The type of module this placeholder represents
  final ModuleType moduleType;
  
  /// Whether this module is maximized (takes up the entire grid)
  final bool isMaximized;
  
  /// Whether this module is in a loading state
  final bool isLoading;
  
  /// Whether this module is empty (no data)
  final bool isEmpty;
  
  /// Custom content to display in the placeholder
  final Widget? customContent;

  const ModulePlaceholder({
    Key? key,
    required this.moduleType,
    this.isMaximized = false,
    this.isLoading = false,
    this.isEmpty = true,
    this.customContent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the theme
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    // Get the module color
    final moduleColor = moduleType.color;
    
    // Calculate the header height based on maximized state
    final headerHeight = isMaximized
        ? AppConstants.sandboxTileHeaderHeight * 1.5
        : AppConstants.sandboxTileHeaderHeight;
    
    return Card(
      elevation: isMaximized ? 4 : 2,
      shadowColor: moduleColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          AppConstants.sandboxTileCornerRadius,
        ),
        side: BorderSide(
          color: moduleColor.withOpacity(isDarkMode ? 0.3 : 0.2),
          width: 1,
        ),
      ),
      color: isDarkMode
          ? Colors.grey[900]
          : Colors.white,
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Module header
          Container(
            height: headerHeight,
            decoration: BoxDecoration(
              color: moduleColor.withOpacity(isDarkMode ? 0.2 : 0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(
                  AppConstants.sandboxTileCornerRadius,
                ),
                topRight: Radius.circular(
                  AppConstants.sandboxTileCornerRadius,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            child: Row(
              children: [
                // Module icon
                Icon(
                  moduleType.icon,
                  color: moduleColor,
                  size: isMaximized ? 24 : 18,
                ),
                
                const SizedBox(width: 8),
                
                // Module name
                Expanded(
                  child: Text(
                    moduleType.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: isDarkMode ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: isMaximized ? 16 : 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          // Module content
          Expanded(
            child: _buildContent(context, isDarkMode),
          ),
        ],
      ),
    );
  }

  /// Builds the content of the placeholder based on state
  Widget _buildContent(BuildContext context, bool isDarkMode) {
    // If custom content is provided, use it
    if (customContent != null) {
      return customContent!;
    }
    
    // If loading, show loading state
    if (isLoading) {
      return _buildLoadingState(context, isDarkMode);
    }
    
    // If empty, show empty state
    if (isEmpty) {
      return _buildEmptyState(context, isDarkMode);
    }
    
    // Otherwise, show placeholder content based on module type
    return _buildPlaceholderContent(context, isDarkMode);
  }

  /// Builds the loading state
  Widget _buildLoadingState(BuildContext context, bool isDarkMode) {
    return Shimmer.fromColors(
      baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shimmer rectangles to indicate loading content
            Container(
              width: double.infinity,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 200,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const Spacer(),
            // Module-specific loading indicators
            _buildModuleSpecificLoadingIndicator(context, isDarkMode),
          ],
        ),
      ),
    );
  }

  /// Builds a module-specific loading indicator
  Widget _buildModuleSpecificLoadingIndicator(BuildContext context, bool isDarkMode) {
    switch (moduleType) {
      case ModuleType.calendar:
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: 14,
          itemBuilder: (context, index) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          },
        );
      
      case ModuleType.todo:
        return Column(
          children: List.generate(
            3,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      
      case ModuleType.notes:
        return Column(
          children: List.generate(
            4,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Container(
                width: double.infinity,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        );
      
      case ModuleType.whiteboard:
        return Container(
          width: double.infinity,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      
      case ModuleType.cards:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            3,
            (index) => Container(
              width: 60,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );
    }
  }

  /// Builds the empty state
  Widget _buildEmptyState(BuildContext context, bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Module-specific empty state icon
            Icon(
              _getEmptyStateIcon(),
              size: 48,
              color: moduleType.color.withOpacity(0.5),
            ),
            
            const SizedBox(height: 16),
            
            // Empty state message
            Text(
              _getEmptyStateMessage(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Gets the icon for the empty state based on module type
  IconData _getEmptyStateIcon() {
    switch (moduleType) {
      case ModuleType.calendar:
        return Icons.event_available;
      case ModuleType.todo:
        return Icons.check_circle_outline;
      case ModuleType.notes:
        return Icons.note_add;
      case ModuleType.whiteboard:
        return Icons.edit;
      case ModuleType.cards:
        return Icons.style;
    }
  }

  /// Gets the message for the empty state based on module type
  String _getEmptyStateMessage() {
    switch (moduleType) {
      case ModuleType.calendar:
        return 'No events scheduled\nTap to add an event';
      case ModuleType.todo:
        return 'No tasks yet\nTap to add a task';
      case ModuleType.notes:
        return 'No notes yet\nTap to create a note';
      case ModuleType.whiteboard:
        return 'Empty whiteboard\nTap to start drawing';
      case ModuleType.cards:
        return 'No flashcards yet\nTap to create a deck';
    }
  }

  /// Builds placeholder content based on module type
  Widget _buildPlaceholderContent(BuildContext context, bool isDarkMode) {
    switch (moduleType) {
      case ModuleType.calendar:
        return _buildCalendarPlaceholder(context, isDarkMode);
      case ModuleType.todo:
        return _buildTodoPlaceholder(context, isDarkMode);
      case ModuleType.notes:
        return _buildNotesPlaceholder(context, isDarkMode);
      case ModuleType.whiteboard:
        return _buildWhiteboardPlaceholder(context, isDarkMode);
      case ModuleType.cards:
        return _buildCardsPlaceholder(context, isDarkMode);
    }
  }

  /// Builds a calendar placeholder
  Widget _buildCalendarPlaceholder(BuildContext context, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'July 2025',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.chevron_left,
                    size: 20,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Weekday header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
              return SizedBox(
                width: 24,
                child: Text(
                  day,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDarkMode ? Colors.white60 : Colors.black45,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 4),
          
          // Calendar grid
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: 31,
              itemBuilder: (context, index) {
                // Highlight today
                final isToday = index == 9; // July 10
                
                // Highlight days with events
                final hasEvent = [3, 12, 20, 25].contains(index);
                
                return Container(
                  decoration: BoxDecoration(
                    color: isToday
                        ? moduleType.color.withOpacity(isDarkMode ? 0.3 : 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          '${index + 1}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isToday
                                ? moduleType.color
                                : isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (hasEvent)
                        Positioned(
                          bottom: 2,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: moduleType.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Event list preview
          if (isMaximized)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.grey[850]
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Today\'s Events',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 40,
                        decoration: BoxDecoration(
                          color: moduleType.color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '10:00 AM - 11:00 AM',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isDarkMode ? Colors.white60 : Colors.black54,
                              ),
                            ),
                            Text(
                              'Team Meeting',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Builds a todo list placeholder
  Widget _buildTodoPlaceholder(BuildContext context, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // List title
          if (isMaximized)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.list,
                    color: moduleType.color,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'My Tasks',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isDarkMode ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          
          // Task items
          Expanded(
            child: ListView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildTaskItem(
                  context,
                  'Complete project proposal',
                  true,
                  isDarkMode,
                ),
                _buildTaskItem(
                  context,
                  'Review pull requests',
                  false,
                  isDarkMode,
                ),
                _buildTaskItem(
                  context,
                  'Prepare for tomorrow\'s meeting',
                  false,
                  isDarkMode,
                ),
                if (isMaximized)
                  _buildTaskItem(
                    context,
                    'Update documentation',
                    false,
                    isDarkMode,
                  ),
                if (isMaximized)
                  _buildTaskItem(
                    context,
                    'Send weekly report',
                    false,
                    isDarkMode,
                  ),
              ],
            ),
          ),
          
          // Add task button
          if (isMaximized)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    color: moduleType.color,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Add Task',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: moduleType.color,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Builds a task item for the todo list
  Widget _buildTaskItem(
    BuildContext context,
    String title,
    bool isCompleted,
    bool isDarkMode,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: isCompleted
                  ? moduleType.color
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isCompleted
                    ? moduleType.color
                    : isDarkMode
                        ? Colors.white54
                        : Colors.black45,
                width: 1.5,
              ),
            ),
            child: isCompleted
                ? const Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.white,
                  )
                : null,
          ),
          
          const SizedBox(width: 12),
          
          // Task title
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isCompleted
                    ? isDarkMode
                        ? Colors.white38
                        : Colors.black38
                    : isDarkMode
                        ? Colors.white
                        : Colors.black87,
                decoration: isCompleted
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a notes placeholder
  Widget _buildNotesPlaceholder(BuildContext context, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Note title
          Text(
            'Meeting Notes',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isDarkMode ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          // Note date
          Text(
            'July 10, 2025',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDarkMode ? Colors.white54 : Colors.black54,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Note content
          Expanded(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Discussed project timeline and milestones. Team agreed on the following action items:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Bullet points
                  ...['Update roadmap document', 'Assign tasks to team members', 'Schedule follow-up meeting']
                      .map((item) => Padding(
                            padding: const EdgeInsets.only(
                              left: 16.0,
                              bottom: 4.0,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '• ',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: moduleType.color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    item,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: isDarkMode ? Colors.white70 : Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                  
                  if (isMaximized) const SizedBox(height: 16),
                  
                  if (isMaximized)
                    Text(
                      'Next Steps:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: isDarkMode ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  
                  if (isMaximized) const SizedBox(height: 8),
                  
                  if (isMaximized)
                    Text(
                      'Review progress at the end of the week and adjust timelines if necessary. Schedule a demo with stakeholders once the first milestone is completed.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Note actions
          if (isMaximized)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.edit,
                    color: moduleType.color,
                    size: 20,
                  ),
                  onPressed: null,
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: Icon(
                    Icons.share,
                    color: moduleType.color,
                    size: 20,
                  ),
                  onPressed: null,
                  tooltip: 'Share',
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: moduleType.color,
                    size: 20,
                  ),
                  onPressed: null,
                  tooltip: 'Delete',
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// Builds a whiteboard placeholder
  Widget _buildWhiteboardPlaceholder(BuildContext context, bool isDarkMode) {
    return Stack(
      children: [
        // Canvas background
        Positioned.fill(
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        
        // Drawing elements
        Positioned.fill(
          child: CustomPaint(
            painter: _WhiteboardPlaceholderPainter(
              isDarkMode: isDarkMode,
              moduleColor: moduleType.color,
            ),
          ),
        ),
        
        // Toolbar
        if (isMaximized)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                height: 40,
                width: 240,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Icon(
                      Icons.edit,
                      color: moduleType.color,
                      size: 20,
                    ),
                    Icon(
                      Icons.format_paint,
                      color: isDarkMode ? Colors.white54 : Colors.black54,
                      size: 20,
                    ),
                    Icon(
                      Icons.text_fields,
                      color: isDarkMode ? Colors.white54 : Colors.black54,
                      size: 20,
                    ),
                    Icon(
                      Icons.shape_line,
                      color: isDarkMode ? Colors.white54 : Colors.black54,
                      size: 20,
                    ),
                    Icon(
                      Icons.undo,
                      color: isDarkMode ? Colors.white54 : Colors.black54,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Builds a cards placeholder
  Widget _buildCardsPlaceholder(BuildContext context, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Deck title
          if (isMaximized)
            Text(
              'Programming Concepts',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isDarkMode ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          
          // Deck stats
          if (isMaximized)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                children: [
                  Text(
                    '12 cards • 75% mastered',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDarkMode ? Colors.white54 : Colors.black54,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.auto_graph,
                    color: moduleType.color,
                    size: 16,
                  ),
                ],
              ),
            ),
          
          // Card preview
          Expanded(
            child: Center(
              child: isMaximized
                  ? _buildFlashcardFront(context, isDarkMode)
                  : _buildCardStack(context, isDarkMode),
            ),
          ),
          
          // Card navigation
          if (isMaximized)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                    onPressed: null,
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.flip,
                        color: moduleType.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Flip',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: moduleType.color,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.arrow_forward,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                    onPressed: null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Builds a flashcard front
  Widget _buildFlashcardFront(BuildContext context, bool isDarkMode) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
        border: Border.all(
          color: moduleType.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'What is the difference between\nconst and final in Dart?',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  /// Builds a stack of cards
  Widget _buildCardStack(BuildContext context, bool isDarkMode) {
    return Stack(
      children: [
        // Bottom card
        Positioned(
          left: 20,
          right: 20,
          top: 10,
          bottom: 10,
          child: Transform.rotate(
            angle: 0.05,
            child: Container(
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        
        // Middle card
        Positioned(
          left: 15,
          right: 15,
          top: 5,
          bottom: 5,
          child: Transform.rotate(
            angle: -0.03,
            child: Container(
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[700] : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        
        // Top card
        Positioned(
          left: 10,
          right: 10,
          top: 0,
          bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[850] : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: moduleType.color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.style,
                    color: moduleType.color,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '12 Cards',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom painter for whiteboard placeholder
class _WhiteboardPlaceholderPainter extends CustomPainter {
  final bool isDarkMode;
  final Color moduleColor;

  _WhiteboardPlaceholderPainter({
    required this.isDarkMode,
    required this.moduleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = moduleColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    // Draw a simple diagram
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.2;
    
    // Draw circle
    canvas.drawCircle(center, radius, paint);
    
    // Draw lines
    canvas.drawLine(
      Offset(center.dx - radius * 1.5, center.dy - radius * 1.5),
      Offset(center.dx - radius * 0.5, center.dy - radius * 0.5),
      paint,
    );
    
    canvas.drawLine(
      Offset(center.dx + radius * 1.5, center.dy - radius * 1.5),
      Offset(center.dx + radius * 0.5, center.dy - radius * 0.5),
      paint,
    );
    
    canvas.drawLine(
      Offset(center.dx - radius * 1.5, center.dy + radius * 1.5),
      Offset(center.dx - radius * 0.5, center.dy + radius * 0.5),
      paint,
    );
    
    canvas.drawLine(
      Offset(center.dx + radius * 1.5, center.dy + radius * 1.5),
      Offset(center.dx + radius * 0.5, center.dy + radius * 0.5),
      paint,
    );
    
    // Draw text boxes
    final textBoxPaint = Paint()
      ..color = isDarkMode ? Colors.grey[700]! : Colors.white
      ..style = PaintingStyle.fill;
    
    final textBoxStrokePaint = Paint()
      ..color = moduleColor.withOpacity(0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    // Top text box
    final topTextBox = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy - radius * 2.5),
        width: radius * 3,
        height: radius,
      ),
      Radius.circular(radius * 0.2),
    );
    
    canvas.drawRRect(topTextBox, textBoxPaint);
    canvas.drawRRect(topTextBox, textBoxStrokePaint);
    
    // Bottom text box
    final bottomTextBox = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + radius * 2.5),
        width: radius * 3,
        height: radius,
      ),
      Radius.circular(radius * 0.2),
    );
    
    canvas.drawRRect(bottomTextBox, textBoxPaint);
    canvas.drawRRect(bottomTextBox, textBoxStrokePaint);
  }

  @override
  bool shouldRepaint(_WhiteboardPlaceholderPainter oldDelegate) {
    return oldDelegate.isDarkMode != isDarkMode ||
        oldDelegate.moduleColor != moduleColor;
  }
}
