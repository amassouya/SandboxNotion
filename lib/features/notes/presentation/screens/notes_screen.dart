import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sandboxnotion/utils/constants.dart';

/// Notes screen that displays a list of notes with a rich text editor
class NotesScreen extends StatefulWidget {
  const NotesScreen({Key? key}) : super(key: key);

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  // Currently selected note
  Note? _selectedNote;
  
  // Currently selected category
  String _selectedCategory = 'All';
  
  // Available categories
  final List<String> _categories = ['All', 'Work', 'Personal', 'Ideas', 'Projects'];
  
  // Search query
  String _searchQuery = '';
  
  // Whether search is active
  bool _isSearching = false;
  
  // Dummy notes
  final List<Note> _notes = [
    Note(
      id: '1',
      title: 'Meeting Notes',
      content: 'Discussed project timeline and milestones. Team agreed on the following action items:\n\n'
          '• Update roadmap document\n'
          '• Assign tasks to team members\n'
          '• Schedule follow-up meeting\n\n'
          'Next Steps:\n'
          'Review progress at the end of the week and adjust timelines if necessary.',
      category: 'Work',
      dateCreated: DateTime.now().subtract(const Duration(days: 2)),
      dateModified: DateTime.now().subtract(const Duration(hours: 5)),
      isFavorite: true,
    ),
    Note(
      id: '2',
      title: 'App Ideas',
      content: 'Potential features for the new app:\n\n'
          '1. Dark mode support\n'
          '2. Offline capabilities\n'
          '3. Cloud synchronization\n'
          '4. Custom themes\n'
          '5. Widgets for home screen',
      category: 'Ideas',
      dateCreated: DateTime.now().subtract(const Duration(days: 5)),
      dateModified: DateTime.now().subtract(const Duration(days: 1)),
      isFavorite: false,
    ),
    Note(
      id: '3',
      title: 'Shopping List',
      content: 'Things to buy:\n\n'
          '- Milk\n'
          '- Eggs\n'
          '- Bread\n'
          '- Apples\n'
          '- Coffee',
      category: 'Personal',
      dateCreated: DateTime.now().subtract(const Duration(days: 1)),
      dateModified: DateTime.now().subtract(const Duration(hours: 12)),
      isFavorite: false,
    ),
    Note(
      id: '4',
      title: 'Project Roadmap',
      content: '# Q3 Roadmap\n\n'
          '## July\n'
          '- Complete UI redesign\n'
          '- Implement authentication flow\n\n'
          '## August\n'
          '- Add cloud sync feature\n'
          '- Optimize performance\n\n'
          '## September\n'
          '- Beta testing\n'
          '- Prepare for launch',
      category: 'Projects',
      dateCreated: DateTime.now().subtract(const Duration(days: 10)),
      dateModified: DateTime.now().subtract(const Duration(days: 3)),
      isFavorite: true,
    ),
    Note(
      id: '5',
      title: 'Book Recommendations',
      content: 'Books to read:\n\n'
          '1. "Atomic Habits" by James Clear\n'
          '2. "The Psychology of Money" by Morgan Housel\n'
          '3. "Deep Work" by Cal Newport\n'
          '4. "Designing Data-Intensive Applications" by Martin Kleppmann',
      category: 'Personal',
      dateCreated: DateTime.now().subtract(const Duration(days: 15)),
      dateModified: DateTime.now().subtract(const Duration(days: 15)),
      isFavorite: false,
    ),
  ];

  // Get filtered notes based on selected category and search query
  List<Note> get _filteredNotes {
    return _notes.where((note) {
      // Filter by category
      final categoryMatch = _selectedCategory == 'All' || note.category == _selectedCategory;
      
      // Filter by search query
      final searchMatch = _searchQuery.isEmpty ||
          note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          note.content.toLowerCase().contains(_searchQuery.toLowerCase());
      
      return categoryMatch && searchMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: _buildAppBar(context, isDarkMode),
      body: Stack(
        children: [
          // Notes content
          Row(
            children: [
              // Notes list
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    // Category selector
                    Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final isSelected = category == _selectedCategory;
                          
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(category),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedCategory = category;
                                  });
                                }
                              },
                              backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                              selectedColor: AppConstants.seedColor.withOpacity(0.2),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? AppConstants.seedColor
                                    : isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    const Divider(height: 1),
                    
                    // Notes list
                    Expanded(
                      child: _filteredNotes.isEmpty
                          ? _buildEmptyState(context)
                          : ListView.builder(
                              itemCount: _filteredNotes.length,
                              itemBuilder: (context, index) {
                                final note = _filteredNotes[index];
                                return _buildNoteItem(context, note);
                              },
                            ),
                    ),
                  ],
                ),
              ),
              
              // Vertical divider (only on larger screens)
              if (MediaQuery.of(context).size.width > 600)
                const VerticalDivider(width: 1),
              
              // Note editor (only on larger screens)
              if (MediaQuery.of(context).size.width > 600)
                Expanded(
                  flex: 3,
                  child: _selectedNote != null
                      ? _buildNoteEditor(context, _selectedNote!)
                      : _buildNoNoteSelectedState(context),
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
                          'Notes Module',
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
        child: const Icon(Icons.note_add),
      ),
    );
  }

  // Build app bar with search functionality
  AppBar _buildAppBar(BuildContext context, bool isDarkMode) {
    if (_isSearching) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _isSearching = false;
              _searchQuery = '';
            });
          },
          tooltip: 'Back',
        ),
        title: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search notes...',
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _searchQuery = '';
              });
            },
            tooltip: 'Clear',
          ),
        ],
      );
    } else {
      return AppBar(
        title: Text(
          'Notes',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
            onPressed: () {
              setState(() {
                _isSearching = true;
              });
            },
            tooltip: 'Search Notes',
          ),
          
          // Sort options
          PopupMenuButton<String>(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'sort_modified',
                child: Text('Sort by Last Modified'),
              ),
              const PopupMenuItem(
                value: 'sort_created',
                child: Text('Sort by Created Date'),
              ),
              const PopupMenuItem(
                value: 'sort_alphabetical',
                child: Text('Sort Alphabetically'),
              ),
              const PopupMenuItem(
                value: 'favorites',
                child: Text('Show Favorites Only'),
              ),
            ],
            onSelected: (value) {
              // Would implement sorting/filtering logic in a real app
            },
          ),
        ],
      );
    }
  }

  // Build empty state widget
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_add,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No notes found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a new note to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Build no note selected state widget
  Widget _buildNoNoteSelectedState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No note selected',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a note from the list to view and edit',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Build note item widget
  Widget _buildNoteItem(BuildContext context, Note note) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    // Calculate time difference for "Last edited" text
    final now = DateTime.now();
    final difference = now.difference(note.dateModified);
    String timeAgo;
    
    if (difference.inDays > 0) {
      timeAgo = '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      timeAgo = '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      timeAgo = '${difference.inMinutes}m ago';
    } else {
      timeAgo = 'just now';
    }
    
    return ListTile(
      selected: _selectedNote?.id == note.id,
      selectedTileColor: AppConstants.seedColor.withOpacity(0.1),
      leading: Icon(
        Icons.description,
        color: note.isFavorite
            ? Colors.amber
            : isDarkMode
                ? Colors.white70
                : Colors.black54,
      ),
      title: Text(
        note.title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: _selectedNote?.id == note.id ? FontWeight.bold : FontWeight.normal,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Note preview
          Text(
            note.content.replaceAll('\n', ' '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDarkMode ? Colors.white54 : Colors.black54,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          // Last edited and category
          Row(
            children: [
              Text(
                'Edited $timeAgo',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: isDarkMode ? Colors.white38 : Colors.black38,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  note.category,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: IconButton(
        icon: Icon(
          note.isFavorite ? Icons.star : Icons.star_border,
          color: note.isFavorite ? Colors.amber : null,
        ),
        onPressed: () {
          setState(() {
            note.isFavorite = !note.isFavorite;
          });
        },
        tooltip: note.isFavorite ? 'Remove from favorites' : 'Add to favorites',
      ),
      onTap: () {
        setState(() {
          _selectedNote = note;
        });
        
        // On smaller screens, navigate to note detail
        if (MediaQuery.of(context).size.width <= 600) {
          context.push('/sandbox/notes/${note.id}');
        }
      },
    );
  }

  // Build note editor widget
  Widget _buildNoteEditor(BuildContext context, Note note) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Column(
      children: [
        // Editor toolbar
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
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
              // Note title
              Expanded(
                child: Text(
                  note.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              // Formatting tools
              IconButton(
                icon: const Icon(Icons.format_bold),
                onPressed: null, // Disabled in placeholder
                tooltip: 'Bold',
              ),
              IconButton(
                icon: const Icon(Icons.format_italic),
                onPressed: null, // Disabled in placeholder
                tooltip: 'Italic',
              ),
              IconButton(
                icon: const Icon(Icons.format_list_bulleted),
                onPressed: null, // Disabled in placeholder
                tooltip: 'Bullet List',
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: null, // Disabled in placeholder
                tooltip: 'More Options',
              ),
            ],
          ),
        ),
        
        // Editor content
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: note.content.split('\n\n').map((paragraph) {
                  if (paragraph.startsWith('#')) {
                    // Heading
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        paragraph.replaceFirst('# ', ''),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  } else if (paragraph.startsWith('##')) {
                    // Subheading
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Text(
                        paragraph.replaceFirst('## ', ''),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  } else if (paragraph.contains('•') || paragraph.contains('-')) {
                    // Bullet list
                    final items = paragraph.split('\n');
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: items.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Text(
                              item,
                              style: theme.textTheme.bodyMedium,
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  } else if (paragraph.contains('1.') || paragraph.contains('2.')) {
                    // Numbered list
                    final items = paragraph.split('\n');
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: items.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Text(
                              item,
                              style: theme.textTheme.bodyMedium,
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  } else {
                    // Regular paragraph
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        paragraph,
                        style: theme.textTheme.bodyMedium,
                      ),
                    );
                  }
                }).toList(),
              ),
            ),
          ),
        ),
        
        // Editor status bar
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
            border: Border(
              top: BorderSide(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.1),
              ),
            ),
          ),
          child: Row(
            children: [
              // Word count
              Text(
                '${note.content.split(' ').length} words',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDarkMode ? Colors.white54 : Colors.black54,
                ),
              ),
              
              const Spacer(),
              
              // Last edited
              Text(
                'Last edited: ${_formatDate(note.dateModified)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDarkMode ? Colors.white54 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Format date to readable string
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);
    
    if (dateToCheck == today) {
      return 'Today at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.month}/${date.day}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
  }
}

/// Model class for notes
class Note {
  final String id;
  final String title;
  final String content;
  final String category;
  final DateTime dateCreated;
  final DateTime dateModified;
  bool isFavorite;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.dateCreated,
    required this.dateModified,
    this.isFavorite = false,
  });
}
