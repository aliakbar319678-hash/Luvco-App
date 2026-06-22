import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/product_api_service.dart';
import '../core/network/recipe_api_service.dart';
import '../core/network/user_api_service.dart';
import '../models/product_model.dart';
import '../models/recipe_model.dart';

// ── Recommended Products ──────────────────────────────────────────
class RecommendedProduct {
  final ProductModel product;
  final bool isSafe;
  final String sustainabilityLabel; // 'Eco-Friendly' | 'Moderate Impact'
  final bool isGreenBadge; // true = green badge, false = orange badge

  const RecommendedProduct({
    required this.product,
    required this.isSafe,
    required this.sustainabilityLabel,
    required this.isGreenBadge,
  });
}

// ── Dashboard State ───────────────────────────────────────────────
class DashboardState {
  final String username;
  final List<RecommendedProduct> recommendedProducts;
  final List<RecipeModel> recentlyViewedRecipes;
  final bool isLoading;
  final String? error;

  const DashboardState({
    required this.username,
    required this.recommendedProducts,
    required this.recentlyViewedRecipes,
    this.isLoading = false,
    this.error,
  });

  DashboardState copyWith({
    String? username,
    List<RecommendedProduct>? recommendedProducts,
    List<RecipeModel>? recentlyViewedRecipes,
    bool? isLoading,
    String? error,
  }) {
    return DashboardState(
      username: username ?? this.username,
      recommendedProducts: recommendedProducts ?? this.recommendedProducts,
      recentlyViewedRecipes: recentlyViewedRecipes ?? this.recentlyViewedRecipes,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// ── Provider (Modern Notifier Syntax) ─────────────────────────────
class DashboardNotifier extends Notifier<DashboardState> {
  @override
  DashboardState build() {
    // Schedule asynchronous loading of real data on initialization
    Future.microtask(() => loadDashboardData());
    return const DashboardState(
      username: 'User',
      recommendedProducts: [],
      recentlyViewedRecipes: [],
      isLoading: true,
    );
  }

  Future<void> loadDashboardData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 1. Fetch user profile for display name
      final user = await UserApiService.instance.getProfile();
      final displayName = user.firstName ?? 'User';

      // 2. Fetch recommended products from the API
      final recommendedRaw = await ProductApiService.instance.getRecommendedProducts();
      final recommendedList = recommendedRaw.map((item) {
        final product = ProductModel.fromJson(item as Map<String, dynamic>);
        final safetyLabel = item['safetyLabel'] as String? ?? 'Safe';
        final sustainabilityLabel = item['sustainabilityLabel'] as String? ?? 'Eco-Friendly';
        return RecommendedProduct(
          product: product,
          isSafe: safetyLabel.toLowerCase() == 'safe',
          sustainabilityLabel: sustainabilityLabel,
          isGreenBadge: sustainabilityLabel.toLowerCase() == 'eco-friendly',
        );
      }).toList();

      // 3. Fetch recently viewed recipes from the API
      final recentRecipes = await RecipeApiService.instance.getRecentlyViewedRecipes();

      state = DashboardState(
        username: displayName,
        recommendedProducts: recommendedList,
        recentlyViewedRecipes: recentRecipes,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void updateUsername(String name) {
    state = state.copyWith(username: name);
  }
}

final dashboardProvider = NotifierProvider<DashboardNotifier, DashboardState>(
  () => DashboardNotifier(),
);
