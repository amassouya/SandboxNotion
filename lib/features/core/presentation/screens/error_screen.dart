import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sandboxnotion/utils/constants.dart';

/// A screen that displays when a routing error occurs
class ErrorScreen extends StatelessWidget {
  /// The error that occurred during routing
  final Exception? error;
  
  /// The location that caused the error
  final String? location;
  
  /// Optional custom message to display
  final String? message;

  const ErrorScreen({
    Key? key,
    this.error,
    this.location,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode 
          ? AppConstants.darkBackground 
          : AppConstants.lightBackground,
      appBar: AppBar(
        title: const Text('Error'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Error icon
                Icon(
                  Icons.error_outline,
                  size: 80,
                  color: AppConstants.errorColor,
                ),
                
                const SizedBox(height: 24),
                
                // Error title
                Text(
                  'Oops! Something went wrong',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Error message
                Text(
                  message ?? 'We couldn\'t find the page you were looking for.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 24),
                
                // Location info (if available and in debug mode)
                if (kDebugMode && location != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode 
                          ? Colors.grey[850] 
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Debug Information:',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Location: $location',
                          style: theme.textTheme.bodyMedium,
                        ),
                        if (error != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Error: ${error.toString()}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ],
                    ),
                  ),
                
                const SizedBox(height: 32),
                
                // Back to home button
                ElevatedButton.icon(
                  onPressed: () {
                    final auth = GoRouter.of(context).routerDelegate.currentConfiguration.matches.last.matchedLocation;
                    // Navigate to a safe location based on auth state
                    if (auth.startsWith('/login') || auth.startsWith('/signup')) {
                      context.go('/login');
                    } else {
                      context.go('/sandbox');
                    }
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('Go to Safe Location'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.seedColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Back button
                if (Navigator.canPop(context))
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
