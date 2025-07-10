import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sandboxnotion/utils/constants.dart';

/// Todo screen that displays a task list with categories
class TodoScreen extends StatefulWidget {
  const TodoScreen({Key? key}) : super(key: key);

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> with SingleTickerProviderStateMixin {
  // Tab controller for categories
  late TabController _tabController;
  
  // Available categories
  final List<String> _categories = ['All', 'Work', 'Personal', 'Shopping', 'Ideas'];
  
  // Loading state
  bool _isLoading = false;
  
  // Dummy todo items
  final List<TodoItem> _todoItems = [
    TodoItem(
      id: '1',
      title: 'Complete project proposal',
      isCompleted: true,
      category: 'Work',
      dueDate: DateTime.now().add(const Duration(days: 1)),
    ),
    TodoItem(
      id: '2',
      title: 'Review pull requests',
      isCompleted: false,
      category: 'Work',
      dueDate: DateTime.now(),
    ),
    TodoItem(
      id: '3',
      title: 'Buy groceries',
      isCompleted: false,
      category: 'Shopping',
      dueDate: DateTime.now().add(const Duration(days: 2)),
    ),
    TodoItem(
      id: '4',
      title: 'Call mom',
      isCompleted: false,
      category: 'Personal',
      dueDate: DateTime.now().add(const Duration(days: 3)),
    ),
    TodoItem(
      id: '5',
      title: 'Prepare for meeting',
      isCompleted: false,
      category: 'Work',
      dueDate: DateTime.now(),
      priority: Priority.high,
    ),
    TodoItem(
      id: '6',
      title: 'Brainstorm app features',
      isCompleted: false,
      category: 'Ideas',
      dueDate: null,
    ),
    TodoItem(
      id: '7',
      title: 'Schedule dentist appointment',
      isCompleted: false,
      category: 'Personal',
      dueDate: DateTime.now().add(const Duration(days: 7)),
      priority: Priority.medium,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    
    // Simulate loading
    setState(() {
      _isLoading = true;
    });
    
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Get filtered todo items based on selected category
  List<TodoItem> get _filteredTodoItems {
    final selectedCategory = _categories[_tabController.index];
    if (selectedCategory == 'All') {
      return _todoItems;
    }
    return _todoItems.where((item) => item.category == selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Todo List',
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
          // Search button
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: null, // Disabled in placeholder
            tooltip: 'Search Tasks',
          ),
          
          // More options
          PopupMenuButton<String>(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'sort_date',
                child: Text('Sort by Date'),
              ),
              const PopupMenuItem(
                value: 'sort_priority',
                child: Text('Sort by Priority'),
              ),
              const PopupMenuItem(
                value: 'show_completed',
                child: Text('Show Completed'),
              ),
              const PopupMenuItem(
                value: 'hide_completed',
                child: Text('Hide Completed'),
              ),
            ],
            onSelected: (value) {
              // Would implement sorting/filtering logic in a real app
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: _categories.map((category) => Tab(text: category)).toList(),
          labelColor: AppConstants.seedColor,
          unselectedLabelColor: isDarkMode ? Colors.white70 : Colors.black54,
          indicatorColor: AppConstants.seedColor,
          dividerColor: Colors.transparent,
          onTap: (_) {
            // Force a rebuild to update the filtered list
            setState(() {});
          },
        ),
      ),
      body: Stack(
        children: [
          // Todo list content
          _isLoading
              ? _buildLoadingState(context, isDarkMode)
              : TabBarView(
                  controller: _tabController,
                  children: _categories.map((category) {
                    final items = category == 'All'
                        ? _todoItems
                        : _todoItems.where((item) => item.category == category).toList();
                    
                    return items.isEmpty
                        ? _buildEmptyState(context)
                        : ListView.builder(
                            itemCount: items.length,
                            padding: EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: isSmallScreen ? 8 : 16,
                            ),
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return _buildTodoItem(context, item);
                            },
                          );
                  }).toList(),
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
                          'Todo Module',
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
      floatingActionButton: FloatingActionButton(
        onPressed: null, // Disabled in placeholder
        backgroundColor: AppConstants.seedColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_task),
      ),
    );
  }

  // Build loading state widget
  Widget _buildLoadingState(BuildContext context, bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppConstants.seedColor,
          ),
          const SizedBox(height: 24),
          Text(
            'Loading tasks...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  // Build empty state widget
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a new task to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Build todo item widget
  Widget _buildTodoItem(BuildContext context, TodoItem item) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    // Priority color
    Color priorityColor;
    switch (item.priority) {
      case Priority.high:
        priorityColor = Colors.red;
        break;
      case Priority.medium:
        priorityColor = Colors.orange;
        break;
      case Priority.low:
        priorityColor = Colors.green;
        break;
      case Priority.none:
        priorityColor = Colors.transparent;
        break;
    }
    
    return Dismissible(
      key: Key(item.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        // Would remove the item in a real app
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task "${item.title}" dismissed'),
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () {
                // Would implement undo functionality in a real app
              },
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
        elevation: 1,
        child: ListTile(
          leading: Checkbox(
            value: item.isCompleted,
            activeColor: AppConstants.seedColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            onChanged: (value) {
              setState(() {
                item.isCompleted = value ?? false;
              });
            },
          ),
          title: Text(
            item.title,
            style: theme.textTheme.bodyLarge?.copyWith(
              decoration: item.isCompleted ? TextDecoration.lineThrough : null,
              color: item.isCompleted
                  ? isDarkMode
                      ? Colors.white38
                      : Colors.black38
                  : null,
            ),
          ),
          subtitle: item.dueDate != null
              ? Text(
                  'Due: ${_formatDate(item.dueDate!)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _isOverdue(item.dueDate!) && !item.isCompleted
                        ? Colors.red
                        : null,
                  ),
                )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Priority indicator
              if (item.priority != Priority.none)
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: priorityColor,
                    shape: BoxShape.circle,
                  ),
                ),
              
              // Category chip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.category,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
            ],
          ),
          onTap: () {
            // Would open task details in a real app
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Task details for "${item.title}"'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
        ),
      ),
    );
  }

  // Format date to readable string
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);
    
    if (dateToCheck == today) {
      return 'Today';
    } else if (dateToCheck == tomorrow) {
      return 'Tomorrow';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  // Check if a date is overdue
  bool _isOverdue(DateTime date) {
    final now = DateTime.now();
    return date.isBefore(now);
  }
}

/// Priority levels for todo items
enum Priority {
  none,
  low,
  medium,
  high,
}

/// Model class for todo items
class TodoItem {
  final String id;
  final String title;
  bool isCompleted;
  final String category;
  final DateTime? dueDate;
  final Priority priority;

  TodoItem({
    required this.id,
    required this.title,
    this.isCompleted = false,
    required this.category,
    this.dueDate,
    this.priority = Priority.none,
  });
}
