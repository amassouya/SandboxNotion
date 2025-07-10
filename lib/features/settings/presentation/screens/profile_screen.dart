import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sandboxnotion/services/analytics_service.dart';
import 'package:sandboxnotion/utils/constants.dart';

/// A placeholder profile screen that displays user information
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Controllers for editing fields
  final _nameController = TextEditingController();
  
  // Loading state
  bool _isLoading = false;
  
  // Current user
  User? _user;
  
  @override
  void initState() {
    super.initState();
    
    // Get current user
    _user = FirebaseAuth.instance.currentUser;
    
    // Set initial values
    if (_user != null) {
      _nameController.text = _user!.displayName ?? 'User';
    }
    
    // Log screen view
    AnalyticsService.instance.logScreenView(
      screenName: 'profile',
      screenClass: 'ProfileScreen',
    );
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
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
      body: _isLoading
          ? _buildLoadingIndicator()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile header with photo
                  _buildProfileHeader(context, isDarkMode),
                  
                  const SizedBox(height: 24),
                  
                  // Profile information section
                  _buildProfileInfoSection(context, isDarkMode),
                  
                  const SizedBox(height: 24),
                  
                  // Account settings section
                  _buildAccountSettingsSection(context, isDarkMode),
                  
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
                            'Profile Editing Coming Soon',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Profile editing functionality will be available in the next update.',
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

  /// Builds the loading indicator
  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  /// Builds the profile header with photo
  Widget _buildProfileHeader(BuildContext context, bool isDarkMode) {
    return Center(
      child: Column(
        children: [
          // Profile photo
          Stack(
            children: [
              // Photo or placeholder
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: _user?.photoURL != null
                    ? ClipOval(
                        child: Image.network(
                          _user!.photoURL!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.person,
                              size: 60,
                              color: AppConstants.seedColor,
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: 60,
                        color: AppConstants.seedColor,
                      ),
              ),
              
              // Edit photo button
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppConstants.seedColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDarkMode ? Colors.grey[900]! : Colors.white,
                      width: 3,
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.camera_alt,
                      size: 20,
                      color: Colors.white,
                    ),
                    onPressed: null, // Disabled in placeholder
                    tooltip: 'Change Photo',
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // User name
          Text(
            _user?.displayName ?? 'User',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          // User email
          Text(
            _user?.email ?? 'email@example.com',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the profile information section
  Widget _buildProfileInfoSection(BuildContext context, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PERSONAL INFORMATION',
          style: TextStyle(
            color: isDarkMode ? Colors.white54 : Colors.black54,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Name field
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Name',
            hintText: 'Enter your name',
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabled: false, // Disabled in placeholder
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Email field (non-editable)
        TextField(
          controller: TextEditingController(text: _user?.email ?? 'email@example.com'),
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: const Icon(Icons.email),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabled: false,
            suffixIcon: const Icon(Icons.lock, size: 16),
          ),
          readOnly: true,
        ),
      ],
    );
  }

  /// Builds the account settings section
  Widget _buildAccountSettingsSection(BuildContext context, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ACCOUNT SETTINGS',
          style: TextStyle(
            color: isDarkMode ? Colors.white54 : Colors.black54,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Change password
        ListTile(
          leading: const Icon(Icons.lock_outline),
          title: const Text('Change Password'),
          trailing: const Icon(Icons.chevron_right),
          onTap: null, // Disabled in placeholder
        ),
        
        // Connected accounts
        ListTile(
          leading: const Icon(Icons.link),
          title: const Text('Connected Accounts'),
          trailing: const Icon(Icons.chevron_right),
          onTap: null, // Disabled in placeholder
        ),
        
        // Delete account
        ListTile(
          leading: const Icon(
            Icons.delete_outline,
            color: Colors.red,
          ),
          title: const Text(
            'Delete Account',
            style: TextStyle(
              color: Colors.red,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: Colors.red,
          ),
          onTap: null, // Disabled in placeholder
        ),
      ],
    );
  }
}
