import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lottie/lottie.dart';
import 'package:sandboxnotion/services/analytics_service.dart';
import 'package:sandboxnotion/utils/constants.dart';
import 'package:sandboxnotion/utils/platform_utils.dart';

/// Login screen for user authentication
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Form controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Form key for validation
  final _formKey = GlobalKey<FormState>();
  
  // Loading and error states
  bool _isLoading = false;
  String? _errorMessage;
  
  // Whether to show the password
  bool _showPassword = false;
  
  // Whether to show the email form
  bool _showEmailForm = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // App logo and title
                    _buildAppHeader(context, isDarkMode),
                    
                    const SizedBox(height: 48),
                    
                    // Error message (if any)
                    if (_errorMessage != null)
                      _buildErrorMessage(context),
                    
                    // Loading indicator or login options
                    _isLoading
                        ? _buildLoadingIndicator(context)
                        : _showEmailForm
                            ? _buildEmailForm(context, isDarkMode)
                            : _buildLoginOptions(context, isDarkMode),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the app logo and title
  Widget _buildAppHeader(BuildContext context, bool isDarkMode) {
    return Column(
      children: [
        // App logo
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.dashboard_customize,
            size: 60,
            color: AppConstants.seedColor,
          ),
        ),
        
        const SizedBox(height: 24),
        
        // App title
        Text(
          AppConstants.appName,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppConstants.seedColor,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 8),
        
        // App tagline
        Text(
          'Your modular workspace for productivity',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Builds the error message widget
  Widget _buildErrorMessage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.red.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.close,
                color: Colors.red,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the loading indicator
  Widget _buildLoadingIndicator(BuildContext context) {
    return Column(
      children: [
        // Loading animation
        Lottie.asset(
          'assets/lottie/loading.json',
          width: 200,
          height: 200,
          errorBuilder: (context, error, stackTrace) {
            // Fallback if Lottie animation is not available
            return const CircularProgressIndicator();
          },
        ),
        
        const SizedBox(height: 24),
        
        // Loading text
        Text(
          'Signing in...',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Builds the login options (Google, Email)
  Widget _buildLoginOptions(BuildContext context, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Google Sign-In button
        ElevatedButton.icon(
          onPressed: _signInWithGoogle,
          icon: Image.asset(
            'assets/images/google_logo.png',
            width: 24,
            height: 24,
            errorBuilder: (context, error, stackTrace) {
              // Fallback if Google logo is not available
              return const Icon(Icons.g_mobiledata);
            },
          ),
          label: const Text('Sign in with Google'),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDarkMode ? Colors.white : Colors.white,
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Email Sign-In button
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _showEmailForm = true;
            });
          },
          icon: const Icon(Icons.email),
          label: const Text('Sign in with Email'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.seedColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Terms of service text
        Text(
          'By signing in, you agree to our Terms of Service and Privacy Policy',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isDarkMode ? Colors.white54 : Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Builds the email login form
  Widget _buildEmailForm(BuildContext context, bool isDarkMode) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email field
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email',
              prefixIcon: const Icon(Icons.email),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Password field
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _showPassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _showPassword = !_showPassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            obscureText: !_showPassword,
            textInputAction: TextInputAction.done,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 8),
          
          // Forgot password link
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                // TODO: Implement forgot password
              },
              child: const Text('Forgot Password?'),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Sign in button
          ElevatedButton(
            onPressed: _signInWithEmail,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.seedColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Sign In'),
          ),
          
          const SizedBox(height: 16),
          
          // Register link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Don\'t have an account?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to registration screen
                  // For now, we'll just show the email form
                  setState(() {
                    _showEmailForm = true;
                  });
                },
                child: const Text('Register'),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Back button
          TextButton.icon(
            onPressed: () {
              setState(() {
                _showEmailForm = false;
                _emailController.clear();
                _passwordController.clear();
              });
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to Sign In Options'),
          ),
        ],
      ),
    );
  }

  /// Sign in with Google
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Initialize Google Sign In
      final GoogleSignIn googleSignIn = GoogleSignIn();
      
      // Start the sign-in process
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      // If user canceled the sign-in process
      if (googleUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Sign in with Firebase
      await FirebaseAuth.instance.signInWithCredential(credential);
      
      // Log the sign-in event
      AnalyticsService.instance.logLogin(method: 'google');
      
      // Navigate to the sandbox screen
      if (mounted) {
        context.go('/sandbox');
      }
    } catch (e) {
      // Handle errors
      setState(() {
        _isLoading = false;
        _errorMessage = _getAuthErrorMessage(e);
      });
      
      // Log the error
      AnalyticsService.instance.logError(
        errorType: 'auth_error',
        message: e.toString(),
      );
    }
  }

  /// Sign in with email and password
  Future<void> _signInWithEmail() async {
    // Validate the form
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Sign in with Firebase
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      // Log the sign-in event
      AnalyticsService.instance.logLogin(method: 'email');
      
      // Navigate to the sandbox screen
      if (mounted) {
        context.go('/sandbox');
      }
    } catch (e) {
      // Handle errors
      setState(() {
        _isLoading = false;
        _errorMessage = _getAuthErrorMessage(e);
      });
      
      // Log the error
      AnalyticsService.instance.logError(
        errorType: 'auth_error',
        message: e.toString(),
      );
    }
  }

  /// Get a user-friendly error message from Firebase Auth exceptions
  String _getAuthErrorMessage(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'No user found with this email address.';
        case 'wrong-password':
          return 'Invalid password. Please try again.';
        case 'invalid-email':
          return 'The email address is not valid.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'too-many-requests':
          return 'Too many sign-in attempts. Please try again later.';
        case 'operation-not-allowed':
          return 'This sign-in method is not allowed. Please contact support.';
        case 'account-exists-with-different-credential':
          return 'An account already exists with the same email address but different sign-in credentials.';
        case 'invalid-credential':
          return 'The authentication credential is invalid. Please try again.';
        case 'network-request-failed':
          return 'A network error occurred. Please check your connection and try again.';
        default:
          return 'An error occurred during sign in: ${e.message}';
      }
    }
    return 'An unexpected error occurred. Please try again.';
  }
}
