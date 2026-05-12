import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luvco_logo/screens/auth/forgot_password_screen.dart';
import 'package:luvco_logo/screens/auth/login_screen.dart';
import 'package:luvco_logo/screens/auth/new_password_screen.dart'; // ← NEW
import 'package:luvco_logo/screens/auth/otp_verification_screen.dart';
import 'package:luvco_logo/screens/auth/password_updated_screen.dart'; // ← NEW
import 'package:luvco_logo/screens/auth/signup_otp_screen.dart';
import 'package:luvco_logo/screens/auth/signup_screen.dart';
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

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/otp-verification',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return OtpVerificationScreen(email: email);
        },
      ),
      GoRoute(
        path: '/new-password', // ← NEW
        builder: (context, state) => const NewPasswordScreen(),
      ),
      GoRoute(
        path: '/password-updated', // ← NEW
        builder: (context, state) => const PasswordUpdatedScreen(),
      ),

      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/signup-verify',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return SignupOtpScreen(email: email);
        },
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
        routes: [
          GoRoute(
            path: 'diet',
            builder: (context, state) => const DietPreferenceScreen(),
          ),
          GoRoute(
            path: 'allergy',
            builder: (context, state) => const FoodAllergyScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const UserProfileScreen(),
      ),
      GoRoute(
        path: '/new-shopping-list',
        builder: (context, state) => const NewShoppingListScreen(),
      ),
      GoRoute(
        path: '/account-settings',
        builder: (context, state) => const AccountSettingsScreen(),
      ),
      GoRoute(
        path: '/shopping-list/:id',
        builder: (context, state) {
          final listId = state.pathParameters['id'] ?? '';
          return ShoppingListDetailScreen(listId: listId);
        },
      ),
      GoRoute(
        path: '/search-product/:id',
        builder: (context, state) {
          final listId = state.pathParameters['id'] ?? '';
          return SearchProductScreen(listId: listId);
        },
      ),
      GoRoute(
        path: '/favorites',
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: '/new-recipe',
        builder: (context, state) => const NewRecipeScreen(),
      ),
      GoRoute(
        path: '/recipe-detail',
        builder: (context, state) {
          final recipe = state.extra as RecipeDetailModel? ?? demoRecipeDetail;
          return RecipeDetailScreen(recipe: recipe);
        },
      ),
      GoRoute(
        path: '/food-challenges',
        builder: (context, state) => const FoodPreferencesScreen(isDiet: false),
      ),
      GoRoute(
        path: '/food-diet',
        builder: (context, state) => const FoodPreferencesScreen(isDiet: true),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const UserDashboardScreen(),
      ),
    ],
  );
});
