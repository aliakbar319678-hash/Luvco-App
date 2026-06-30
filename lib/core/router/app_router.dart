import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luvco_logo/screens/auth/forgot_password_screen.dart';
import 'package:luvco_logo/screens/auth/login_screen.dart';
import 'package:luvco_logo/screens/auth/new_password_screen.dart';
import 'package:luvco_logo/screens/auth/otp_verification_screen.dart';
import 'package:luvco_logo/screens/auth/password_updated_screen.dart';
import 'package:luvco_logo/screens/auth/signup_otp_screen.dart';
import 'package:luvco_logo/screens/auth/signup_screen.dart';
import 'package:luvco_logo/screens/auth/terms_and_conditions_screen.dart';
import 'package:luvco_logo/screens/auth/privacy_policy_screen.dart';
import 'package:luvco_logo/screens/recipe/new_recipe_screen.dart';
import 'package:luvco_logo/screens/recipe/recipe_detail_screen.dart';
import 'package:luvco_logo/models/recipe_detail_model.dart';
import 'package:luvco_logo/providers/recipe_detail_provider.dart';
import 'package:luvco_logo/screens/profile/food_preferences_screen.dart';
import 'package:luvco_logo/screens/splash/splash_screen.dart';
import 'package:luvco_logo/screens/onboarding/onboarding_screen.dart';
import 'package:luvco_logo/screens/onboarding/diet_preference_screen.dart';
import 'package:luvco_logo/screens/onboarding/food_allergy_screen.dart';
import 'package:luvco_logo/screens/profile/user_profile_screen.dart';
import 'package:luvco_logo/screens/shopping/new_shopping_list_screen.dart';
import 'package:luvco_logo/screens/shopping/shopping_list_detail_screen.dart';
import 'package:luvco_logo/screens/shopping/search_product_screen.dart';
import 'package:luvco_logo/screens/account/account_settings_screen.dart';
import 'package:luvco_logo/screens/favorites/favorites_screen.dart';
import 'package:luvco_logo/screens/dashboard/user_dashboard_screen.dart';
import 'package:luvco_logo/screens/dashboard/dashboard_search_product_screen.dart';
import 'package:luvco_logo/screens/scanner/search_recipe/search_recipe_screen.dart';
import 'package:luvco_logo/screens/product/product_detail_screen.dart';
import 'package:luvco_logo/screens/scanner/barcode_scanner_screen.dart';
import 'package:luvco_logo/models/product_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared transition builder — smooth fade + subtle upward slide.
// GPU-friendly: uses opacity + translate only (no clipping, no scale distortion).
// Duration is intentionally short (220ms) to feel snappy without lagging.
// ─────────────────────────────────────────────────────────────────────────────
Page<void> _fadeSlide({
  required LocalKey key,
  required Widget child,
  bool isTab = false,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: Duration(milliseconds: isTab ? 200 : 350),
    reverseTransitionDuration: Duration(milliseconds: isTab ? 150 : 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (isTab) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      }
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.fastEaseInToSlowEaseOut,
          ),
        ),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(-0.24, 0.0),
          ).animate(
            CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.fastEaseInToSlowEaseOut,
            ),
          ),
          child: child,
        ),
      );
    },
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// App Router Provider
// Using Provider (not StateNotifierProvider) — the GoRouter is immutable after
// creation and should never be rebuilt. ref.read() is used at the call site.
// ─────────────────────────────────────────────────────────────────────────────
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => _fadeSlide(
          key: state.pageKey,
          isTab: true,
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _fadeSlide(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (context, state) => _fadeSlide(
          key: state.pageKey,
          child: const ForgotPasswordScreen(),
        ),
      ),
      GoRoute(
        path: '/otp-verification',
        pageBuilder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return _fadeSlide(
            key: state.pageKey,
            child: OtpVerificationScreen(email: email),
          );
        },
      ),
      GoRoute(
        path: '/new-password',
        pageBuilder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          final code = state.uri.queryParameters['code'] ?? '';
          return _fadeSlide(
            key: state.pageKey,
            child: NewPasswordScreen(email: email, code: code),
          );
        },
      ),
      GoRoute(
        path: '/password-updated',
        pageBuilder: (context, state) => _fadeSlide(
          key: state.pageKey,
          child: const PasswordUpdatedScreen(),
        ),
      ),
      GoRoute(
        path: '/signup',
        pageBuilder: (context, state) => _fadeSlide(
          key: state.pageKey,
          child: const SignupScreen(),
        ),
      ),
      GoRoute(
        path: '/terms',
        pageBuilder: (context, state) => _fadeSlide(
          key: state.pageKey,
          child: const TermsAndConditionsScreen(),
        ),
      ),
      GoRoute(
        path: '/privacy',
        pageBuilder: (context, state) => _fadeSlide(
          key: state.pageKey,
          child: const PrivacyPolicyScreen(),
        ),
      ),
      GoRoute(
        path: '/signup-verify',
        pageBuilder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return _fadeSlide(
            key: state.pageKey,
            child: SignupOtpScreen(email: email),
          );
        },
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => _fadeSlide(
          key: state.pageKey,
          child: const OnboardingScreen(),
        ),
        routes: [
          GoRoute(
            path: 'diet',
            pageBuilder: (context, state) => _fadeSlide(
              key: state.pageKey,
              child: const DietPreferenceScreen(),
            ),
          ),
          GoRoute(
            path: 'allergy',
            pageBuilder: (context, state) => _fadeSlide(
              key: state.pageKey,
              child: const FoodAllergyScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) => _fadeSlide(
          key: state.pageKey,
          isTab: true,
          child: const UserProfileScreen(),
        ),
      ),
      GoRoute(
        path: '/new-shopping-list',
        pageBuilder: (context, state) => _fadeSlide(
          key: state.pageKey,
          child: const NewShoppingListScreen(),
        ),
      ),
      GoRoute(
        path: '/account-settings',
        pageBuilder: (context, state) => _fadeSlide(
          key: state.pageKey,
          child: const AccountSettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/shopping-list/:id',
        pageBuilder: (context, state) {
          final listId = state.pathParameters['id'] ?? '';
          return _fadeSlide(
            key: state.pageKey,
            child: ShoppingListDetailScreen(listId: listId),
          );
        },
      ),
      GoRoute(
        path: '/search-product/:id',
        pageBuilder: (context, state) {
          final listId = state.pathParameters['id'] ?? '';
          return _fadeSlide(
            key: state.pageKey,
            child: SearchProductScreen(listId: listId),
          );
        },
      ),
      GoRoute(
        path: '/favorites',
        pageBuilder: (context, state) => _fadeSlide(
          key: state.pageKey,
          child: const FavoritesScreen(),
        ),
      ),
      GoRoute(
        path: '/new-recipe',
        pageBuilder: (context, state) => _fadeSlide(
          key: state.pageKey,
          child: const NewRecipeScreen(),
        ),
      ),
      GoRoute(
        path: '/recipe-detail',
        pageBuilder: (context, state) {
          final recipe =
              state.extra as RecipeDetailModel? ?? demoRecipeDetail;
          return _fadeSlide(
            key: state.pageKey,
            child: RecipeDetailScreen(recipe: recipe),
          );
        },
      ),
      GoRoute(
        path: '/food-challenges',
        pageBuilder: (context, state) => _fadeSlide(
          key: state.pageKey,
          child: const FoodPreferencesScreen(isDiet: false),
        ),
      ),
      GoRoute(
        path: '/food-diet',
        pageBuilder: (context, state) => _fadeSlide(
          key: state.pageKey,
          child: const FoodPreferencesScreen(isDiet: true),
        ),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => _fadeSlide(
          key: state.pageKey,
          isTab: true,
          child: const UserDashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/dashboard-search',
        pageBuilder: (context, state) => _fadeSlide(
          key: state.pageKey,
          child: const DashboardSearchProductScreen(),
        ),
      ),
      GoRoute(
        path: '/search-recipe',
        pageBuilder: (context, state) => _fadeSlide(
          key: state.pageKey,
          child: const SearchRecipeScreen(),
        ),
      ),
      GoRoute(
        path: '/product-detail',
        pageBuilder: (context, state) {
          final product = state.extra is ProductModel
              ? state.extra as ProductModel
              : ProductModel.demo();
          return _fadeSlide(
            key: state.pageKey,
            child: ProductDetailScreen(product: product),
          );
        },
      ),
      GoRoute(
        path: '/barcode-scanner',
        pageBuilder: (context, state) => _fadeSlide(
          key: state.pageKey,
          child: const BarcodeScannerScreen(),
        ),
      ),
    ],
  );
});

