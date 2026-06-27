import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/auth_api_service.dart';
import 'user_profile_provider.dart';
import 'dashboard_provider.dart';
import 'food_settings_provider.dart';
import 'food_preferences_provider.dart';
import 'shopping_list_provider.dart';
import 'recipe_provider.dart';
import 'favorites_provider.dart';

/// Centralized logout that:
/// 1. Calls the backend logout endpoint (blacklists refresh token)
/// 2. Clears stored JWT tokens from secure storage
/// 3. Invalidates ALL user-scoped Riverpod providers so the
///    next login always fetches fresh data for the new account.
///
/// MUST be called instead of AuthApiService.instance.logout() directly.
Future<void> logoutAndClearProviders(WidgetRef ref) async {
  // 1. Backend logout + clear tokens
  await AuthApiService.instance.logout();

  // 2. Invalidate all user-data providers so they reload fresh
  //    on next login — prevents cross-account data leakage.
  ref.invalidate(userProfileProvider);
  ref.invalidate(dashboardProvider);
  ref.invalidate(foodSettingsProvider);
  ref.invalidate(foodAllergiesProvider);
  ref.invalidate(foodDietProvider);
  ref.invalidate(shoppingListProvider);
  ref.invalidate(savedRecipesProvider);
  ref.invalidate(favoritesProvider);
}
