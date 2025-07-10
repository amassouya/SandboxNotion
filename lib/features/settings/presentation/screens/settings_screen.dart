import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sandboxnotion/services/analytics_service.dart';
import 'package:sandboxnotion/utils/constants.dart';
import 'package:sandboxnotion/utils/platform_utils.dart';

/// Settings screen that provides access to user profile, subscription, and preferences
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // App info
  String _appVersion = AppConstants.appVersion;
  
  @override
  void initState() {
    super.initState();
    _loadAppInfo();
    
    // Log screen view
    AnalyticsService.instance.logScreenView(
      screenName: 'settings',
      screenClass: 'SettingsScreen',
    );
  }
  
  /// Load app information
  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
      });
    } catch (e) {
      // Fallback to constant if package info fails
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    // Get current user
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
          tooltip: 'Back to Sandbox',
        ),
      ),
      body: ListView(
        children: [
          // User profile section
          _buildProfileSection(context, user, isDarkMode),
          
          const Divider(),
          
          // App settings section
          _buildSettingsSection(context, isDarkMode),
          
          const Divider(),
          
          // Account section
          _buildAccountSection(context, isDarkMode),
          
          const Divider(),
          
          // About section
          _buildAboutSection(context, isDarkMode),
          
          // App version
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Version $_appVersion',
              style: TextStyle(
                color: isDarkMode ? Colors.white38 : Colors.black38,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the profile section
  Widget _buildProfileSection(BuildContext context, User? user, bool isDarkMode) {
    return ListTile(
      leading: user?.photoURL != null
          ? CircleAvatar(
              backgroundImage: NetworkImage(user!.photoURL!),
            )
          : CircleAvatar(
              backgroundColor: AppConstants.seedColor.withOpacity(0.2),
              child: Text(
                user?.displayName?.substring(0, 1) ?? 'U',
                style: TextStyle(
                  color: AppConstants.seedColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
      title: Text(
        user?.displayName ?? 'User',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        user?.email ?? 'Not signed in',
        style: TextStyle(
          color: isDarkMode ? Colors.white54 : Colors.black54,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('/settings/profile'),
    );
  }

  /// Builds the settings section
  Widget _buildSettingsSection(BuildContext context, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
          child: Text(
            'SETTINGS',
            style: TextStyle(
              color: isDarkMode ? Colors.white54 : Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        // Appearance settings
        ListTile(
          leading: const Icon(Icons.palette),
          title: const Text('Appearance'),
          subtitle: const Text('Theme, colors, and display options'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/settings/preferences'),
        ),
        
        // Subscription settings
        ListTile(
          leading: const Icon(
            Icons.workspace_premium,
            color: Colors.amber,
          ),
          title: const Text('Subscription'),
          subtitle: const Text('Manage your subscription plan'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/settings/subscription'),
        ),
        
        // Notifications settings
        ListTile(
          leading: const Icon(Icons.notifications),
          title: const Text('Notifications'),
          subtitle: const Text('Configure notification preferences'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/settings/preferences'),
        ),
        
        // Data & storage settings
        ListTile(
          leading: const Icon(Icons.storage),
          title: const Text('Data & Storage'),
          subtitle: const Text('Manage app data and storage usage'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/settings/preferences'),
        ),
      ],
    );
  }

  /// Builds the account section
  Widget _buildAccountSection(BuildContext context, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
          child: Text(
            'ACCOUNT',
            style: TextStyle(
              color: isDarkMode ? Colors.white54 : Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        // Privacy settings
        ListTile(
          leading: const Icon(Icons.privacy_tip),
          title: const Text('Privacy'),
          subtitle: const Text('Manage your data and privacy settings'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // TODO: Implement privacy settings
          },
        ),
        
        // Sign out option
        ListTile(
          leading: const Icon(
            Icons.logout,
            color: Colors.red,
          ),
          title: const Text(
            'Sign Out',
            style: TextStyle(
              color: Colors.red,
            ),
          ),
          onTap: _signOut,
        ),
      ],
    );
  }

  /// Builds the about section
  Widget _buildAboutSection(BuildContext context, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
          child: Text(
            'ABOUT',
            style: TextStyle(
              color: isDarkMode ? Colors.white54 : Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        // Help & feedback
        ListTile(
          leading: const Icon(Icons.help_outline),
          title: const Text('Help & Feedback'),
          subtitle: const Text('Get support and share your thoughts'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // TODO: Implement help & feedback
          },
        ),
        
        // About the app
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('About SandboxNotion'),
          subtitle: const Text('Learn more about the app'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _showAboutDialog(context);
          },
        ),
      ],
    );
  }

  /// Shows the about dialog
  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: _appVersion,
      applicationIcon: Image.asset(
        'assets/images/logo.png',
        width: 50,
        height: 50,
        errorBuilder: (context, error, stackTrace) {
          // Fallback if logo image is not available
          return Icon(
            Icons.dashboard_customize,
            size: 50,
            color: AppConstants.seedColor,
          );
        },
      ),
      children: [
        const SizedBox(height: 16),
        const Text(
          'SandboxNotion is a modular productivity app that helps you organize your work and life with customizable modules.',
        ),
        const SizedBox(height: 16),
        Text('Platform: ${PlatformUtils.platformName}'),
      ],
    );
  }

  /// Signs the user out
  Future<void> _signOut() async {
    final navigator = GoRouter.of(context);
    
    // Show confirmation dialog
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    
    if (shouldSignOut == true) {
      try {
        await FirebaseAuth.instance.signOut();
        navigator.go('/login');
      } catch (e) {
        // Handle sign out error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to sign out. Please try again.'),
            ),
          );
        }
      }
    }
  }
}
