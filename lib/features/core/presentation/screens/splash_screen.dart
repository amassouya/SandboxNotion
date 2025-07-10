import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:sandboxnotion/utils/constants.dart';

/// A splash screen that displays when the app is starting up
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  // Animation controller for fade-in effect
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: AppConstants.animationSlow,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    
    // Start animation
    _animationController.forward();
    
    // Navigate to next screen after delay
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        // The router will handle redirecting to the appropriate screen
        // based on authentication state
        context.go('/login');
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode 
          ? AppConstants.darkBackground 
          : AppConstants.lightBackground,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[850] : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 80,
                    height: 80,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback if logo image is not available
                      return Icon(
                        Icons.dashboard_customize,
                        size: 60,
                        color: AppConstants.seedColor,
                      );
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // App name
              Text(
                AppConstants.appName,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppConstants.seedColor,
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Loading indicator
              SizedBox(
                width: 40,
                height: 40,
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
            ],
          ),
        ),
      ),
    );
  }
}
