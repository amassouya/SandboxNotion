import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:sandboxnotion/features/sandbox/data/providers/sandbox_layout_provider.dart';
import 'package:sandboxnotion/features/sandbox/domain/models/sandbox_layout.dart';
import 'package:sandboxnotion/features/sandbox/presentation/widgets/sandbox_grid.dart';
import 'package:sandboxnotion/services/analytics_service.dart';
import 'package:sandboxnotion/utils/constants.dart';
import 'package:sandboxnotion/utils/platform_utils.dart';

/// The main screen of the app that displays the sandbox grid
class SandboxScreen extends ConsumerStatefulWidget {
  const SandboxScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SandboxScreen> createState() => _SandboxScreenState();
}

class _SandboxScreenState extends ConsumerState<SandboxScreen> with SingleTickerProviderStateMixin {
  // Animation controller for the drawer and fab
  late AnimationController _animationController;
  
  // Whether the drawer is open
  bool _isDrawerOpen = false;
  
  // The currently selected module (if any)
  ModuleType? _selectedModule;
  
  // Whether to show the grid lines
  bool _showGridLines = false;
  
  // Whether to animate tile movements
  bool _animateTiles = true;
  
  // The user's subscription status
  bool _isPremiumUser = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: AppConstants.animationNormal,
    );
    
    // Check subscription status
    _checkSubscriptionStatus();
    
    // Log screen view
    AnalyticsService.instance.logScreenView(
      screenName: 'sandbox',
      screenClass: 'SandboxScreen',
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Checks the user's subscription status
  Future<void> _checkSubscriptionStatus() async {
    // TODO: Implement subscription status check from Firestore
    // For now, we'll just use a placeholder
    setState(() {
      _isPremiumUser = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get the device type
    final deviceType = PlatformUtils.getDeviceType(
      MediaQuery.of(context).size.width,
    );
    
    // Get the theme
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    // Get the current user
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      // App bar
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 32,
              height: 32,
              errorBuilder: (context, error, stackTrace) {
                // Fallback if logo image is not available
                return Icon(
                  Icons.dashboard_customize,
                  color: AppConstants.seedColor,
                );
              },
            ),
            const SizedBox(width: 8),
            Text(
              'SandboxNotion',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.push('/settings');
            },
            tooltip: 'Settings',
          ),
          
          // Profile button
          IconButton(
            icon: user?.photoURL != null
                ? CircleAvatar(
                    backgroundImage: NetworkImage(user!.photoURL!),
                    radius: 12,
                  )
                : const Icon(Icons.account_circle),
            onPressed: () {
              context.push('/settings/profile');
            },
            tooltip: 'Profile',
          ),
        ],
      ),
      
      // Drawer
      drawer: _buildDrawer(context, isDarkMode, deviceType),
      
      // Body
      body: Stack(
        children: [
          // Main content
          Positioned.fill(
            child: SandboxGrid(
              showGridLines: _showGridLines,
              animateTiles: _animateTiles,
              onModuleTap: _handleModuleTap,
              onModuleLongPress: _handleModuleLongPress,
              onModuleAdded: _handleModuleAdded,
              onModuleRemoved: _handleModuleRemoved,
              onLayoutChanged: _handleLayoutChanged,
            ),
          ),
          
          // Subscription banner (if not premium)
          if (!_isPremiumUser)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildSubscriptionBanner(context, isDarkMode),
            ),
        ],
      ),
      
      // Floating action button (for smaller screens)
      floatingActionButton: deviceType == DeviceType.mobile
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _isDrawerOpen = !_isDrawerOpen;
                });
                
                if (_isDrawerOpen) {
                  _animationController.forward();
                } else {
                  _animationController.reverse();
                }
              },
              backgroundColor: AppConstants.seedColor,
              child: AnimatedIcon(
                icon: AnimatedIcons.menu_close,
                progress: _animationController,
                color: Colors.white,
              ),
            )
          : null,
    );
  }

  /// Builds the drawer
  Widget _buildDrawer(BuildContext context, bool isDarkMode, DeviceType deviceType) {
    return Drawer(
      child: Column(
        children: [
          // Drawer header
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppConstants.seedColor,
              image: const DecorationImage(
                image: AssetImage('assets/images/drawer_header.jpg'),
                fit: BoxFit.cover,
                opacity: 0.7,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User avatar
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text(
                    FirebaseAuth.instance.currentUser?.displayName?.substring(0, 1) ?? 'U',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.seedColor,
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // User name
                Text(
                  FirebaseAuth.instance.currentUser?.displayName ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                // User email
                Text(
                  FirebaseAuth.instance.currentUser?.email ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Module list
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Module tiles
                ...ModuleType.values.map((type) => ListTile(
                  leading: Icon(
                    type.icon,
                    color: type.color,
                  ),
                  title: Text(type.name),
                  selected: _selectedModule == type,
                  selectedTileColor: type.color.withOpacity(0.1),
                  onTap: () {
                    // Close the drawer
                    Navigator.pop(context);
                    
                    // Set the selected module
                    setState(() {
                      _selectedModule = type;
                    });
                    
                    // Navigate to the module
                    _navigateToModule(type);
                  },
                )),
                
                const Divider(),
                
                // Settings
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/settings');
                  },
                ),
                
                // Grid options
                ExpansionTile(
                  leading: const Icon(Icons.grid_view),
                  title: const Text('Grid Options'),
                  children: [
                    // Show grid lines
                    SwitchListTile(
                      title: const Text('Show Grid Lines'),
                      value: _showGridLines,
                      onChanged: (value) {
                        setState(() {
                          _showGridLines = value;
                        });
                      },
                      secondary: const Icon(Icons.grid_3x3),
                      dense: true,
                    ),
                    
                    // Animate tiles
                    SwitchListTile(
                      title: const Text('Animate Tiles'),
                      value: _animateTiles,
                      onChanged: (value) {
                        setState(() {
                          _animateTiles = value;
                        });
                      },
                      secondary: const Icon(Icons.animation),
                      dense: true,
                    ),
                    
                    // Reset layout
                    ListTile(
                      leading: const Icon(Icons.restore),
                      title: const Text('Reset Layout'),
                      dense: true,
                      onTap: () {
                        Navigator.pop(context);
                        _showResetLayoutDialog(context);
                      },
                    ),
                  ],
                ),
                
                // Upgrade to premium
                if (!_isPremiumUser)
                  ListTile(
                    leading: const Icon(
                      Icons.workspace_premium,
                      color: Colors.amber,
                    ),
                    title: const Text('Upgrade to Premium'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/settings/subscription');
                    },
                  ),
                
                // Help & feedback
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Help & Feedback'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Implement help & feedback
                  },
                ),
                
                // Sign out
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Sign Out'),
                  onTap: () async {
                    Navigator.pop(context);
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                ),
              ],
            ),
          ),
          
          // App version
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Version ${AppConstants.appVersion}',
              style: TextStyle(
                color: isDarkMode ? Colors.white38 : Colors.black38,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the subscription banner for free users
  Widget _buildSubscriptionBanner(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.grey[900]!.withOpacity(0.9)
            : Colors.white.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, -1),
          ),
        ],
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
          // Premium icon
          const Icon(
            Icons.workspace_premium,
            color: Colors.amber,
          ),
          
          const SizedBox(width: 12),
          
          // Subscription text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Free Account',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  'Upgrade to Premium for unlimited modules and AI features',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          
          // Upgrade button
          ElevatedButton(
            onPressed: () {
              context.push('/settings/subscription');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.seedColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  /// Shows a dialog to confirm resetting the layout
  void _showResetLayoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset Layout'),
          content: const Text(
            'Are you sure you want to reset the layout to default? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _resetLayout();
              },
              child: const Text(
                'Reset',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Resets the layout to default
  void _resetLayout() {
    final deviceType = PlatformUtils.getDeviceType(
      MediaQuery.of(context).size.width,
    );
    
    final controller = ref.read(sandboxLayoutControllerProvider(context));
    controller.resetToDefault();
    
    // Log the action
    AnalyticsService.instance.logCustomEvent(
      eventName: 'sandbox_layout_reset',
      parameters: {
        'device_type': deviceType.toString().split('.').last,
      },
    );
  }

  /// Handles tapping on a module tile
  void _handleModuleTap(ModuleTile tile) {
    // Navigate to the module
    _navigateToModule(tile.type);
    
    // Log the action
    AnalyticsService.instance.logModuleInteraction(
      moduleType: tile.type,
      action: 'tap',
    );
  }

  /// Handles long-pressing on a module tile
  void _handleModuleLongPress(ModuleTile tile) {
    // Show module options
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Module title
              ListTile(
                leading: Icon(
                  tile.type.icon,
                  color: tile.type.color,
                ),
                title: Text(tile.type.name),
                subtitle: Text('ID: ${tile.id}'),
              ),
              
              const Divider(),
              
              // Open module
              ListTile(
                leading: const Icon(Icons.open_in_new),
                title: const Text('Open'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToModule(tile.type);
                },
              ),
              
              // Maximize module
              ListTile(
                leading: const Icon(Icons.fullscreen),
                title: const Text('Maximize'),
                onTap: () {
                  Navigator.pop(context);
                  final controller = ref.read(sandboxLayoutControllerProvider(context));
                  controller.toggleMaximized(tile.id);
                },
              ),
              
              // Remove module
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
                title: const Text(
                  'Remove',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  final controller = ref.read(sandboxLayoutControllerProvider(context));
                  controller.removeTile(tile.id);
                },
              ),
            ],
          ),
        );
      },
    );
    
    // Log the action
    AnalyticsService.instance.logModuleInteraction(
      moduleType: tile.type,
      action: 'long_press',
    );
  }

  /// Handles adding a module
  void _handleModuleAdded(ModuleType type) {
    // Log the action
    AnalyticsService.instance.logModuleInteraction(
      moduleType: type,
      action: 'add',
    );
  }

  /// Handles removing a module
  void _handleModuleRemoved(String tileId) {
    // Log the action
    AnalyticsService.instance.logCustomEvent(
      eventName: 'module_removed',
      parameters: {
        'tile_id': tileId,
      },
    );
  }

  /// Handles layout changes
  void _handleLayoutChanged(SandboxLayout layout) {
    // Log the action
    AnalyticsService.instance.logSandboxLayoutChange(
      moduleCount: layout.tiles.length,
      activeModules: layout.tiles.map((tile) => tile.type).toList(),
    );
  }

  /// Navigates to a module
  void _navigateToModule(ModuleType type) {
    switch (type) {
      case ModuleType.calendar:
        context.push('/sandbox/calendar');
        break;
      case ModuleType.todo:
        context.push('/sandbox/todo');
        break;
      case ModuleType.notes:
        context.push('/sandbox/notes');
        break;
      case ModuleType.whiteboard:
        context.push('/sandbox/whiteboard');
        break;
      case ModuleType.cards:
        context.push('/sandbox/cards');
        break;
    }
  }
}
