import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_routes.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'presentation/auth/screens/forgot_password_screen.dart';
import 'presentation/auth/screens/login_screen.dart';
import 'presentation/auth/screens/register_screen.dart';
import 'presentation/auth/screens/splash_screen.dart';
import 'presentation/common/shell/main_shell.dart';
import 'presentation/favourites/screens/favourites_screen.dart';
import 'presentation/home/screens/home_screen.dart';
import 'presentation/items/screens/add_item_screen.dart';
import 'presentation/items/screens/edit_item_screen.dart';
import 'presentation/items/screens/item_detail_screen.dart';
import 'presentation/notifications/screens/notifications_screen.dart';
import 'presentation/profile/screens/profile_screen.dart';
import 'presentation/search/screens/search_screen.dart';
import 'providers/app_providers.dart';
import 'providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool isFirebaseInitialized = false;
  try {
    if (DefaultFirebaseOptions.android.apiKey != 'YOUR_ANDROID_API_KEY') {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      isFirebaseInitialized = true;
    }
  } catch (e) {
    debugPrint('Firebase initialization warning: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        isFirebaseInitializedProvider.overrideWithValue(isFirebaseInitialized),
      ],
      child: const FoundItApp(),
    ),
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final isFirebase = ref.watch(isFirebaseInitializedProvider);
  final authStateAsync = ref.watch(authStateStreamProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: isFirebase
        ? GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges())
        : null,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final isSplash = loc == AppRoutes.splash;
      final isAuthRoute = loc == AppRoutes.login ||
          loc == AppRoutes.register ||
          loc == AppRoutes.forgotPassword;

      final firebaseUser = isFirebase ? FirebaseAuth.instance.currentUser : null;
      final isLoggedIn = firebaseUser != null || authStateAsync.valueOrNull != null;

      if (isSplash) return null;

      // 🔒 Route Protection: Redirect unauthenticated requests to /login
      if (!isLoggedIn && !isAuthRoute) {
        return AppRoutes.login;
      }

      // 🔓 Redirect authenticated users away from /login or /register to /home
      if (isLoggedIn && isAuthRoute) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.addItem,
            builder: (context, state) => const AddItemScreen(),
          ),
          GoRoute(
            path: AppRoutes.favourites,
            builder: (context, state) => const FavouritesScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.search,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.itemDetail,
        builder: (context, state) {
          final itemId = state.pathParameters['itemId'] ?? '';
          return ItemDetailScreen(itemId: itemId);
        },
      ),
      GoRoute(
        path: AppRoutes.editItem,
        builder: (context, state) {
          final itemId = state.pathParameters['itemId'] ?? '';
          return EditItemScreen(itemId: itemId);
        },
      ),
    ],
  );
});

class FoundItApp extends ConsumerWidget {
  const FoundItApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
