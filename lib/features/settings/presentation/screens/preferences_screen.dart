import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sandboxnotion/services/analytics_service.dart';
import 'package:sandboxnotion/utils/constants.dart';

/// A placeholder preferences screen that displays app settings options
class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({Key? key}) : super(key: key);

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  // Theme mode
  ThemeMode _themeMode = ThemeMode.system;
  
  // Notification settings
  bool _enableNotifications = true;
  bool _enableSoundEffects = true;
  
  @override
  void initState() {
    super.initState();
    
    // Log screen view
    AnalyticsService.instance.logScreenView(
      screenName: 'preferences',
      screenClass: 'PreferencesScreen',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Preferences',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
          tooltip: 'Back to Settings',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appearance section
            _buildSectionHeader('APPEARANCE', isDarkMode),
            
            // Theme mode
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.brightness_6),
                    title: const Text('Theme Mode'),
                    trailing: DropdownButton<ThemeMode>(
                      value: _themeMode,
                      underline: const SizedBox.shrink(),
                      onChanged: null, // Disabled in placeholder
                      items: const [
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text('System'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text('Light'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text('Dark'),
                        ),
                      ],
                    ),
                  ),
                  
                  const Divider(height: 1),
                  
                  // Primary color
                  ListTile(
                    leading: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppConstants.seedColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: const Text('Primary Color'),
                    subtitle: const Text('Change the app accent color'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: null, // Disabled in placeholder
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Notifications section
            _buildSectionHeader('NOTIFICATIONS', isDarkMode),
            
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Enable notifications
                  SwitchListTile(
                    title: const Text('Enable Notifications'),
                    subtitle: const Text('Receive reminders and updates'),
                    value: _enableNotifications,
                    onChanged: null, // Disabled in placeholder
                    secondary: const Icon(Icons.notifications),
                  ),
                  
                  const Divider(height: 1),
                  
                  // Sound effects
                  SwitchListTile(
                    title: const Text('Sound Effects'),
                    subtitle: const Text('Play sounds for notifications'),
                    value: _enableSoundEffects,
                    onChanged: null, // Disabled in placeholder
                    secondary: const Icon(Icons.volume_up),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Data & Storage section
            _buildSectionHeader('DATA & STORAGE', isDarkMode),
            
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Cache management
                  ListTile(
                    leading: const Icon(Icons.cleaning_services),
                    title: const Text('Clear Cache'),
                    subtitle: const Text('Free up storage space'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: null, // Disabled in placeholder
                  ),
                  
                  const Divider(height: 1),
                  
                  // Data usage
                  ListTile(
                    leading: const Icon(Icons.data_usage),
                    title: const Text('Data Usage'),
                    subtitle: const Text('Manage network data consumption'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: null, // Disabled in placeholder
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Coming soon message
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode 
                      ? Colors.grey[850] 
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppConstants.seedColor.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.construction,
                      size: 32,
                      color: AppConstants.seedColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Preferences Coming Soon',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Preferences functionality will be available in the next update.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a section header
  Widget _buildSectionHeader(String title, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          color: isDarkMode ? Colors.white54 : Colors.black54,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
