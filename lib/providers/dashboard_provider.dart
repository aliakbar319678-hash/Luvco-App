import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  const DashboardState({
    required this.username,
    required this.recommendedProducts,
    required this.recentlyViewedRecipes,
  });
}

// ── Demo data ─────────────────────────────────────────────────────
const _demoState = DashboardState(
  username: 'Username',
  recommendedProducts: [
    RecommendedProduct(
      product: ProductModel(
        id: 'p1',
        name: 'Name of the Product',
        description: 'Other data from the product.',
        thumbnailAsset: 'assets/images/product_image.png',
        isSustainable: true,
      ),
      isSafe: true,
      sustainabilityLabel: 'Eco-Friendly',
      isGreenBadge: true,
    ),
    RecommendedProduct(
      product: ProductModel(
        id: 'p2',
        name: 'Name of the Product',
        description: 'Other data from the product.',
        thumbnailAsset: 'assets/images/product_image.png',
        isSustainable: true,
      ),
      isSafe: true,
      sustainabilityLabel: 'Moderate Impact',
      isGreenBadge: false,
    ),
  ],
  recentlyViewedRecipes: [
    RecipeModel(
      id: 'rv1',
      title: 'Name of the Recipe',
      description: 'Other data from the recipe.',
      imageUrl: 'assets/images/cake_image.png',
      dietTags: ['Gluten Free', 'Label 01', 'Label 02'],
    ),
    RecipeModel(
      id: 'rv2',
      title: 'Name of the Recipe',
      description: 'Other data from the recipe.',
      imageUrl: 'assets/images/cake_image2.png',
      dietTags: ['Gluten Free', 'Label 01', 'Label 02'],
    ),
  ],
);

// ── Provider ──────────────────────────────────────────────────────
class DashboardNotifier extends StateNotifier<DashboardState> {
  DashboardNotifier() : super(_demoState);

  void updateUsername(String name) {
    state = DashboardState(
      username: name,
      recommendedProducts: state.recommendedProducts,
      recentlyViewedRecipes: state.recentlyViewedRecipes,
    );
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>(
      (_) => DashboardNotifier(),
    );
