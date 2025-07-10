import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sandboxnotion/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:sandboxnotion/features/auth/presentation/screens/login_screen.dart';
import 'package:sandboxnotion/features/auth/presentation/screens/signup_screen.dart';
import 'package:sandboxnotion/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:sandboxnotion/features/cards/presentation/screens/cards_screen.dart';
import 'package:sandboxnotion/features/core/presentation/screens/error_screen.dart';
import 'package:sandboxnotion/features/core/presentation/screens/loading_screen.dart';
import 'package:sandboxnotion/features/core/presentation/screens/splash_screen.dart';
import 'package:sandboxnotion/features/notes/presentation/screens/notes_screen.dart';
import 'package:sandboxnotion/features/sandbox/presentation/screens/sandbox_screen.dart';
import 'package:sandboxnotion/features/settings/presentation/screens/preferences_screen.dart';
import 'package:sandboxnotion/features/settings/presentation/screens/profile_screen.dart';
import 'package:sandboxnotion/features/settings/presentation/screens/settings_screen.dart';
import 'package:sandboxnotion/features/settings/presentation/screens/subscription_screen.dart';
import 'package:sandboxnotion/features/todo/presentation/screens/todo_screen.dart';
import 'package:sandboxnotion/features/whiteboard/presentation/screens/whiteboard_screen.dart';

/// Provider for the current authentication state
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Provider for the GoRouter instance
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  
  // Create the router with redirect logic based on auth state
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: kDebugMode,
    
    // Refresh the router when auth state changes
    refreshListenable: GoRouterRefreshStream(
      FirebaseAuth.instance.authStateChanges(),
    ),
    
    // Error handler for invalid routes
    errorBuilder: (context, state) => ErrorScreen(
      error: state.error,
      location: state.matchedLocation,
    ),
    
    // Redirect logic based on authentication state
    redirect: (context, state) {
      // Handle auth state
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      
      // Auth group paths
      final isLoggingIn = state.matchedLocation.startsWith('/login');
      final isSigningUp = state.matchedLocation.startsWith('/signup');
      final isForgotPassword = state.matchedLocation.startsWith('/forgot-password');
      final isInAuthGroup = isLoggingIn || isSigningUp || isForgotPassword;
      
      // Special case for splash screen
      if (state.matchedLocation == '/') {
        return isLoggedIn ? '/sandbox' : '/login';
      }
      
      // If user is not logged in and trying to access protected route
      if (!isLoggedIn && !isInAuthGroup) {
        // Store the attempted location for later redirect
        String redirectQuery = '';
        if (state.matchedLocation != '/login') {
          redirectQuery = '?redirect=${Uri.encodeComponent(state.matchedLocation)}';
        }
        return '/login$redirectQuery';
      }
      
      // If user is logged in and trying to access auth routes
      if (isLoggedIn && isInAuthGroup) {
        // Get the redirect query parameter if it exists
        final redirectTo = state.uri.queryParameters['redirect'];
        return redirectTo != null ? redirectTo : '/sandbox';
      }
      
      // No redirect needed
      return null;
    },
    
    routes: [
      // Splash screen route
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Auth routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      
      // Main app shell route with nested routes
      ShellRoute(
        builder: (context, state, child) {
          // Check if we're in a loading state
          if (authState.isLoading) {
            return const LoadingScreen();
          }
          
          return child;
        },
        routes: [
          // Sandbox route (main app screen with modular UI)
          GoRoute(
            path: '/sandbox',
            name: 'sandbox',
            builder: (context, state) => const SandboxScreen(),
            routes: [
              // Module routes as sub-routes of the sandbox
              GoRoute(
                path: 'calendar',
                name: 'calendar',
                builder: (context, state) => const CalendarScreen(),
                routes: [
                  // Calendar detail route
                  GoRoute(
                    path: ':eventId',
                    name: 'calendar-event',
                    builder: (context, state) => CalendarScreen(
                      eventId: state.pathParameters['eventId'],
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'todo',
                name: 'todo',
                builder: (context, state) => const TodoScreen(),
                routes: [
                  // Todo list detail route
                  GoRoute(
                    path: ':listId',
                    name: 'todo-list',
                    builder: (context, state) => TodoScreen(
                      listId: state.pathParameters['listId'],
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'notes',
                name: 'notes',
                builder: (context, state) => const NotesScreen(),
                routes: [
                  // Note detail route
                  GoRoute(
                    path: ':noteId',
                    name: 'note-detail',
                    builder: (context, state) => NotesScreen(
                      noteId: state.pathParameters['noteId'],
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'whiteboard',
                name: 'whiteboard',
                builder: (context, state) => const WhiteboardScreen(),
                routes: [
                  // Whiteboard detail route
                  GoRoute(
                    path: ':boardId',
                    name: 'whiteboard-detail',
                    builder: (context, state) => WhiteboardScreen(
                      boardId: state.pathParameters['boardId'],
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'cards',
                name: 'cards',
                builder: (context, state) => const CardsScreen(),
                routes: [
                  // Flashcard deck detail route
                  GoRoute(
                    path: ':deckId',
                    name: 'card-deck',
                    builder: (context, state) => const CardsScreen(),
                  ),
                ],
              ),
            ],
          ),
          
          // Settings routes
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: 'profile',
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
              GoRoute(
                path: 'subscription',
                name: 'subscription',
                builder: (context, state) => const SubscriptionScreen(),
              ),
              GoRoute(
                path: 'preferences',
                name: 'preferences',
                builder: (context, state) => const PreferencesScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Helper class to convert a Stream to a Listenable for GoRouter
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Extension methods for GoRouter
extension GoRouterExtensions on GoRouter {
  /// Navigate to a route and remove all previous routes
  void goAndRemoveUntil(String location) {
    go(location);
    while (canPop()) {
      pop();
    }
  }
  
  /// Navigate to a named route with parameters and remove all previous routes
  void goNamedAndRemoveUntil(String name, {Map<String, String> pathParameters = const {}, Map<String, dynamic> queryParameters = const {}}) {
    goNamed(
      name,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
    );
    while (canPop()) {
      pop();
    }
  }
}
