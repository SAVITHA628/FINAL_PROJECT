import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/constants/app_routes.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'presentation/auth/screens/forgot_password_screen.dart';
import 'presentation/auth/screens/login_screen.dart';
import 'presentation/auth/screens/register_screen.dart';
import 'presentation/auth/screens/splash_screen.dart';
import 'presentation/common/shell/main_shell.dart';
import 'presentation/favourites/screens/favourites_screen.dart';
import 'presentation/home/screens/ai_matches_screen.dart';
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

  FlutterError.onError = (details) {
    debugPrint('Flutter error: ${details.exception}');
  };

  runZonedGuarded(() {
    runApp(
      const ProviderScope(
        child: FoundItApp(),
      ),
    );
  }, (error, stack) {
    debugPrint('Zone error: $error');
  });
}

final routerProvider = Provider<GoRouter>((ref) {
  final routerNotifier = ref.watch(routerNotifierProvider);

  // All routes that are accessible WITHOUT login
  const publicRoutes = {
    AppRoutes.splash,
    AppRoutes.login,
    AppRoutes.register,
    AppRoutes.forgotPassword,
  };

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: routerNotifier,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final isSplash = loc == AppRoutes.splash;

      // Check if this route requires authentication
      final isPublicRoute = publicRoutes.contains(loc);

      final currentUser = ref.read(currentUserProvider).valueOrNull;
      final isLoggedIn = currentUser != null;

      // Splash — let SplashScreen handle navigation itself
      if (isSplash) return null;

      // 🔒 If user is NOT logged in and tries to access any protected route → redirect to login
      if (!isLoggedIn && !isPublicRoute) return AppRoutes.login;

      // ✅ If user IS logged in and tries to access auth routes → redirect to home
      if (isLoggedIn && isPublicRoute && !isSplash) return AppRoutes.home;

      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (c, s) => const SplashScreen()),
      GoRoute(path: AppRoutes.login, builder: (c, s) => const LoginScreen()),
      GoRoute(path: AppRoutes.register, builder: (c, s) => const RegisterScreen()),
      GoRoute(path: AppRoutes.forgotPassword, builder: (c, s) => const ForgotPasswordScreen()),
      ShellRoute(
        builder: (c, s, child) => MainShell(child: child),
        routes: [
          GoRoute(path: AppRoutes.home, builder: (c, s) => const HomeScreen()),
          GoRoute(path: AppRoutes.addItem, builder: (c, s) => const AddItemScreen()),
          GoRoute(path: AppRoutes.favourites, builder: (c, s) => const FavouritesScreen()),
          GoRoute(path: AppRoutes.profile, builder: (c, s) => const ProfileScreen()),
        ],
      ),
      // 🔒 These routes are also protected — router redirect handles them
      GoRoute(path: AppRoutes.search, builder: (c, s) => const SearchScreen()),
      GoRoute(path: AppRoutes.notifications, builder: (c, s) => const NotificationsScreen()),
      GoRoute(path: AppRoutes.aiMatches, builder: (c, s) => const AiMatchesScreen()),
      GoRoute(
        path: AppRoutes.itemDetail,
        builder: (c, s) => ItemDetailScreen(itemId: s.pathParameters['itemId'] ?? ''),
      ),
      GoRoute(
        path: AppRoutes.editItem,
        builder: (c, s) => EditItemScreen(itemId: s.pathParameters['itemId'] ?? ''),
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
