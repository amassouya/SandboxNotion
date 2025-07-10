import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:sandboxnotion/utils/constants.dart';

/// A loading screen that displays when content is being loaded
class LoadingScreen extends StatelessWidget {
  /// Optional message to display below the loading indicator
  final String? message;

  const LoadingScreen({
    Key? key,
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Loading animation
            SizedBox(
              width: 100,
              height: 100,
              child: Lottie.asset(
                'assets/lottie/loading.json',
                errorBuilder: (context, error, stackTrace) {
                  // Fallback if Lottie animation is not available
                  return CircularProgressIndicator(
                    color: AppConstants.seedColor,
                  );
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            // App name
            Text(
              AppConstants.appName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppConstants.seedColor,
              ),
            ),
            
            // Optional message
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
