import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sandboxnotion/utils/constants.dart';

/// Cards screen that displays flashcard decks and study interface
class CardsScreen extends StatefulWidget {
  const CardsScreen({Key? key}) : super(key: key);

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> with SingleTickerProviderStateMixin {
  // Currently selected deck
  Deck? _selectedDeck;
  
  // Currently selected card index
  int _currentCardIndex = 0;
  
  // Whether the current card is flipped
  bool _isCardFlipped = false;
  
  // Card flip animation controller
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  
  // Whether the deck list is in grid view
  bool _isGridView = false;
  
  // Search query
  String _searchQuery = '';
  
  // Whether search is active
  bool _isSearching = false;
  
  // Dummy decks
  final List<Deck> _decks = [
    Deck(
      id: '1',
      title: 'Programming Concepts',
      description: 'Basic programming concepts and terminology',
      cardCount: 24,
      mastered: 18,
      lastStudied: DateTime.now().subtract(const Duration(days: 1)),
      category: 'Technology',
      color: Colors.blue,
    ),
    Deck(
      id: '2',
      title: 'Spanish Vocabulary',
      description: 'Common Spanish words and phrases',
      cardCount: 50,
      mastered: 15,
      lastStudied: DateTime.now().subtract(const Duration(days: 3)),
      category: 'Language',
      color: Colors.orange,
    ),
    Deck(
      id: '3',
      title: 'World Capitals',
      description: 'Countries and their capital cities',
      cardCount: 30,
      mastered: 25,
      lastStudied: DateTime.now().subtract(const Duration(hours: 5)),
      category: 'Geography',
      color: Colors.green,
    ),
    Deck(
      id: '4',
      title: 'Chemical Elements',
      description: 'Periodic table elements and properties',
      cardCount: 40,
      mastered: 10,
      lastStudied: DateTime.now().subtract(const Duration(days: 7)),
      category: 'Science',
      color: Colors.purple,
    ),
    Deck(
      id: '5',
      title: 'Historical Dates',
      description: 'Important dates in world history',
      cardCount: 35,
      mastered: 20,
      lastStudied: DateTime.now().subtract(const Duration(days: 2)),
      category: 'History',
      color: Colors.red,
    ),
  ];
  
  // Dummy cards for the selected deck
  final List<FlashCard> _programmingCards = [
    FlashCard(
      id: '1',
      front: 'What is the difference between const and final in Dart?',
      back: 'const is a compile-time constant, while final can be set only once but at runtime. const values must be known at compile time.',
      mastered: false,
      lastReviewed: DateTime.now().subtract(const Duration(days: 2)),
    ),
    FlashCard(
      id: '2',
      front: 'What is a pure function?',
      back: 'A pure function is a function that always returns the same result for the same arguments and has no side effects.',
      mastered: true,
      lastReviewed: DateTime.now().subtract(const Duration(days: 1)),
    ),
    FlashCard(
      id: '3',
      front: 'What is the difference between Stack and Queue?',
      back: 'Stack is a LIFO (Last In First Out) data structure, while Queue is a FIFO (First In First Out) data structure.',
      mastered: false,
      lastReviewed: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize flip animation controller
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _flipController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Set default selected deck
    _selectedDeck = _decks.first;
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  // Get filtered decks based on search query
  List<Deck> get _filteredDecks {
    return _decks.where((deck) {
      // Filter by search query
      final searchMatch = _searchQuery.isEmpty ||
          deck.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          deck.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          deck.category.toLowerCase().contains(_searchQuery.toLowerCase());
      
      return searchMatch;
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
          // Cards content
          _selectedDeck != null && MediaQuery.of(context).size.width > 600
              ? _buildSplitView(context, isDarkMode)
              : _buildSingleView(context, isDarkMode),
          
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
                          'Flashcards Module',
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
        child: const Icon(Icons.add),
        tooltip: 'Create New Deck',
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
            hintText: 'Search decks...',
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
          'Flashcards',
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
            tooltip: 'Search Decks',
          ),
          
          // Toggle view button
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
            tooltip: _isGridView ? 'List View' : 'Grid View',
          ),
          
          // More options
          PopupMenuButton<String>(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'sort_name',
                child: Text('Sort by Name'),
              ),
              const PopupMenuItem(
                value: 'sort_recent',
                child: Text('Sort by Recent'),
              ),
              const PopupMenuItem(
                value: 'sort_progress',
                child: Text('Sort by Progress'),
              ),
              const PopupMenuItem(
                value: 'import',
                child: Text('Import Decks'),
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

  // Build split view (deck list and card review side by side)
  Widget _buildSplitView(BuildContext context, bool isDarkMode) {
    return Row(
      children: [
        // Deck list (1/3 of screen)
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.35,
          child: _buildDeckList(context, isDarkMode),
        ),
        
        // Vertical divider
        const VerticalDivider(width: 1),
        
        // Card review (2/3 of screen)
        Expanded(
          child: _buildCardReview(context, isDarkMode),
        ),
      ],
    );
  }

  // Build single view (either deck list or card review)
  Widget _buildSingleView(BuildContext context, bool isDarkMode) {
    if (_selectedDeck != null && MediaQuery.of(context).size.width <= 600) {
      return _buildCardReview(context, isDarkMode);
    } else {
      return _buildDeckList(context, isDarkMode);
    }
  }

  // Build deck list
  Widget _buildDeckList(BuildContext context, bool isDarkMode) {
    if (_filteredDecks.isEmpty) {
      return _buildEmptyState(context);
    }
    
    return Column(
      children: [
        // Categories filter (placeholder)
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip(context, 'All', true),
                _buildCategoryChip(context, 'Technology', false),
                _buildCategoryChip(context, 'Language', false),
                _buildCategoryChip(context, 'Science', false),
                _buildCategoryChip(context, 'History', false),
                _buildCategoryChip(context, 'Geography', false),
              ],
            ),
          ),
        ),
        
        const Divider(height: 1),
        
        // Deck list
        Expanded(
          child: _isGridView
              ? GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _filteredDecks.length,
                  itemBuilder: (context, index) {
                    return _buildDeckGridItem(context, _filteredDecks[index], isDarkMode);
                  },
                )
              : ListView.builder(
                  itemCount: _filteredDecks.length,
                  itemBuilder: (context, index) {
                    return _buildDeckListItem(context, _filteredDecks[index], isDarkMode);
                  },
                ),
        ),
      ],
    );
  }

  // Build category filter chip
  Widget _buildCategoryChip(BuildContext context, String category, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(category),
        selected: isSelected,
        onSelected: (selected) {
          // Would implement category filtering in a real app
        },
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[200],
        selectedColor: AppConstants.seedColor.withOpacity(0.2),
        labelStyle: TextStyle(
          color: isSelected
              ? AppConstants.seedColor
              : Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  // Build deck list item
  Widget _buildDeckListItem(BuildContext context, Deck deck, bool isDarkMode) {
    final theme = Theme.of(context);
    final isSelected = _selectedDeck?.id == deck.id;
    
    // Calculate mastery percentage
    final masteryPercentage = deck.cardCount > 0
        ? (deck.mastered / deck.cardCount * 100).round()
        : 0;
    
    return ListTile(
      selected: isSelected,
      selectedTileColor: AppConstants.seedColor.withOpacity(0.1),
      leading: CircleAvatar(
        backgroundColor: deck.color.withOpacity(0.2),
        child: Text(
          deck.title.substring(0, 1),
          style: TextStyle(
            color: deck.color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        deck.title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${deck.cardCount} cards • ${deck.mastered} mastered',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDarkMode ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: deck.cardCount > 0 ? deck.mastered / deck.cardCount : 0,
            backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(deck.color),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$masteryPercentage%',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: deck.color,
            ),
          ),
          Text(
            _formatTimeAgo(deck.lastStudied),
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDarkMode ? Colors.white38 : Colors.black38,
              fontSize: 10,
            ),
          ),
        ],
      ),
      onTap: () {
        setState(() {
          _selectedDeck = deck;
          _currentCardIndex = 0;
          _isCardFlipped = false;
          _flipController.reset();
        });
        
        // On smaller screens, navigate to card review
        if (MediaQuery.of(context).size.width <= 600) {
          // This would navigate to the card review in a real app
        }
      },
    );
  }

  // Build deck grid item
  Widget _buildDeckGridItem(BuildContext context, Deck deck, bool isDarkMode) {
    final theme = Theme.of(context);
    
    // Calculate mastery percentage
    final masteryPercentage = deck.cardCount > 0
        ? (deck.mastered / deck.cardCount * 100).round()
        : 0;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: deck.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _selectedDeck = deck;
            _currentCardIndex = 0;
            _isCardFlipped = false;
            _flipController.reset();
          });
          
          // On smaller screens, navigate to card review
          if (MediaQuery.of(context).size.width <= 600) {
            // This would navigate to the card review in a real app
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Deck title and icon
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: deck.color.withOpacity(0.2),
                    child: Text(
                      deck.title.substring(0, 1),
                      style: TextStyle(
                        color: deck.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      deck.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Deck description
              Text(
                deck.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const Spacer(),
              
              // Progress bar
              LinearProgressIndicator(
                value: deck.cardCount > 0 ? deck.mastered / deck.cardCount : 0,
                backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(deck.color),
              ),
              
              const SizedBox(height: 8),
              
              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${deck.cardCount} cards',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDarkMode ? Colors.white54 : Colors.black54,
                    ),
                  ),
                  Text(
                    '$masteryPercentage% mastered',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: deck.color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build empty state
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.style,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No flashcard decks found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a new deck to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Build card review
  Widget _buildCardReview(BuildContext context, bool isDarkMode) {
    if (_selectedDeck == null) {
      return Center(
        child: Text(
          'Select a deck to start reviewing',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      );
    }
    
    return Column(
      children: [
        // Deck info header
        Container(
          padding: const EdgeInsets.all(16),
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
              // Back button (for mobile)
              if (MediaQuery.of(context).size.width <= 600)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      _selectedDeck = null;
                    });
                  },
                  tooltip: 'Back to Decks',
                ),
              
              // Deck title and info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedDeck!.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_selectedDeck!.cardCount} cards • ${_selectedDeck!.mastered} mastered',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Study options button
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'study',
                    child: Text('Study All'),
                  ),
                  const PopupMenuItem(
                    value: 'review',
                    child: Text('Review Difficult'),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit Deck'),
                  ),
                  const PopupMenuItem(
                    value: 'share',
                    child: Text('Share Deck'),
                  ),
                ],
                onSelected: (value) {
                  // Would implement options in a real app
                },
              ),
            ],
          ),
        ),
        
        // Progress indicators
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Mastery progress
              Expanded(
                child: _buildProgressIndicator(
                  context,
                  'Mastery',
                  _selectedDeck!.mastered,
                  _selectedDeck!.cardCount,
                  Colors.green,
                  isDarkMode,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Review progress (placeholder)
              Expanded(
                child: _buildProgressIndicator(
                  context,
                  'Due for Review',
                  5,
                  _selectedDeck!.cardCount,
                  Colors.orange,
                  isDarkMode,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // New cards progress (placeholder)
              Expanded(
                child: _buildProgressIndicator(
                  context,
                  'New Cards',
                  _selectedDeck!.cardCount - _selectedDeck!.mastered - 5,
                  _selectedDeck!.cardCount,
                  Colors.blue,
                  isDarkMode,
                ),
              ),
            ],
          ),
        ),
        
        // Flashcard review area
        Expanded(
          child: Center(
            child: _buildFlashcard(context, isDarkMode),
          ),
        ),
        
        // Card navigation
        Container(
          padding: const EdgeInsets.all(16),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous card button
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _currentCardIndex > 0
                    ? () {
                        setState(() {
                          _currentCardIndex--;
                          _isCardFlipped = false;
                          _flipController.reset();
                        });
                      }
                    : null,
                tooltip: 'Previous Card',
              ),
              
              // Card counter
              Text(
                'Card ${_currentCardIndex + 1} of ${_programmingCards.length}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              
              // Flip button
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isCardFlipped = !_isCardFlipped;
                  });
                  
                  if (_isCardFlipped) {
                    _flipController.forward();
                  } else {
                    _flipController.reverse();
                  }
                },
                icon: const Icon(Icons.flip),
                label: const Text('Flip'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.seedColor,
                  foregroundColor: Colors.white,
                ),
              ),
              
              // Next card button
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: _currentCardIndex < _programmingCards.length - 1
                    ? () {
                        setState(() {
                          _currentCardIndex++;
                          _isCardFlipped = false;
                          _flipController.reset();
                        });
                      }
                    : null,
                tooltip: 'Next Card',
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Build progress indicator
  Widget _buildProgressIndicator(
    BuildContext context,
    String label,
    int value,
    int total,
    Color color,
    bool isDarkMode,
  ) {
    final percentage = total > 0 ? (value / total * 100).round() : 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 4),
        
        // Progress bar
        LinearProgressIndicator(
          value: total > 0 ? value / total : 0,
          backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
        
        const SizedBox(height: 4),
        
        // Value and percentage
        Text(
          '$value of $total ($percentage%)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
      ],
    );
  }

  // Build flashcard
  Widget _buildFlashcard(BuildContext context, bool isDarkMode) {
    if (_programmingCards.isEmpty) {
      return const Text('No cards in this deck');
    }
    
    final card = _programmingCards[_currentCardIndex];
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _isCardFlipped = !_isCardFlipped;
        });
        
        if (_isCardFlipped) {
          _flipController.forward();
        } else {
          _flipController.reverse();
        }
      },
      child: AnimatedBuilder(
        animation: _flipAnimation,
        builder: (context, child) {
          final angle = _flipAnimation.value * 3.14159;
          final frontOpacity = angle >= 1.57 ? 0.0 : 1.0;
          final backOpacity = angle < 1.57 ? 0.0 : 1.0;
          
          return Stack(
            children: [
              // Card front
              Opacity(
                opacity: frontOpacity,
                child: Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(angle),
                  alignment: Alignment.center,
                  child: _buildCardSide(
                    context,
                    card.front,
                    isDarkMode,
                    true,
                    card.mastered,
                  ),
                ),
              ),
              
              // Card back
              Opacity(
                opacity: backOpacity,
                child: Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(angle + 3.14159),
                  alignment: Alignment.center,
                  child: _buildCardSide(
                    context,
                    card.back,
                    isDarkMode,
                    false,
                    card.mastered,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Build card side (front or back)
  Widget _buildCardSide(
    BuildContext context,
    String content,
    bool isDarkMode,
    bool isFront,
    bool isMastered,
  ) {
    final theme = Theme.of(context);
    
    return Container(
      width: 400,
      height: 300,
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
        border: Border.all(
          color: isMastered
              ? Colors.green.withOpacity(0.5)
              : AppConstants.seedColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Side indicator
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: isFront
                  ? AppConstants.seedColor.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              isFront ? 'Question' : 'Answer',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isFront ? AppConstants.seedColor : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Card content
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Text(
                  content,
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          
          // Mastery indicator
          if (!isFront)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: null, // Disabled in placeholder
                  icon: const Icon(Icons.thumb_down),
                  label: const Text('Still Learning'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.1),
                    foregroundColor: Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: null, // Disabled in placeholder
                  icon: const Icon(Icons.thumb_up),
                  label: const Text('Got It'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.withOpacity(0.1),
                    foregroundColor: Colors.green,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // Format time ago
  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }
}

/// Model class for flashcard decks
class Deck {
  final String id;
  final String title;
  final String description;
  final int cardCount;
  final int mastered;
  final DateTime lastStudied;
  final String category;
  final Color color;

  Deck({
    required this.id,
    required this.title,
    required this.description,
    required this.cardCount,
    required this.mastered,
    required this.lastStudied,
    required this.category,
    required this.color,
  });
}

/// Model class for flashcards
class FlashCard {
  final String id;
  final String front;
  final String back;
  bool mastered;
  final DateTime lastReviewed;

  FlashCard({
    required this.id,
    required this.front,
    required this.back,
    this.mastered = false,
    required this.lastReviewed,
  });
}
