import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/product_model.dart';
import '../../models/recipe_model.dart';
import '../../widgets/bottom_nav_bar.dart';

class UserDashboardScreen extends ConsumerWidget {
  const UserDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);
    final size = MediaQuery.sizeOf(context);
    final scale = size.width / 390;
    final topPadding = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Column(
        children: [
          // ── Scrollable Content ──
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Greeting ──
                SliverToBoxAdapter(
                  child: _GreetingHeader(
                    username: state.username,
                    scale: scale,
                    topPadding: topPadding,
                  ),
                ),

                SliverToBoxAdapter(child: SizedBox(height: 24 * scale)),

                // ── Explore New Products Section ──
                SliverToBoxAdapter(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 16 * scale),
                    padding: EdgeInsets.symmetric(vertical: 24 * scale),
                    decoration: BoxDecoration(
                      color: AppColors.pureWhite,
                      borderRadius: BorderRadius.circular(20 * scale),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _SectionTitle(
                          icon: 'assets/icons/microscope_icon.png',
                          title: 'Explore new products',
                          scale: scale,
                          isAssetIcon: true,
                        ),
                        SizedBox(height: 16 * scale),
                        _ExploreActionCards(scale: scale),
                        SizedBox(height: 12 * scale),
                        _QuickActionCards(scale: scale, context: context),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(child: SizedBox(height: 28 * scale)),

                // ── Recommended Products ──
                SliverToBoxAdapter(
                  child: _SectionTitle(
                    icon: '💡',
                    title: 'Recommended products',
                    scale: scale,
                  ),
                ),

                SliverToBoxAdapter(child: SizedBox(height: 12 * scale)),

                SliverToBoxAdapter(
                  child: _RecommendedProductsRow(
                    products: state.recommendedProducts,
                    scale: scale,
                  ),
                ),

                SliverToBoxAdapter(child: SizedBox(height: 28 * scale)),

                // ── Recently Viewed Recipes ──
                SliverToBoxAdapter(
                  child: _SectionTitle(
                    icon: '🕐',
                    title: 'Recipes recently viewed',
                    scale: scale,
                  ),
                ),

                SliverToBoxAdapter(child: SizedBox(height: 12 * scale)),

                SliverToBoxAdapter(
                  child: _RecentRecipesRow(
                    recipes: state.recentlyViewedRecipes,
                    scale: scale,
                  ),
                ),

                SliverToBoxAdapter(child: SizedBox(height: 24 * scale)),
              ],
            ),
          ),

          // ── Bottom Navigation Bar ──
          const LuvcoBottomNavBar(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Greeting Header
// ─────────────────────────────────────────────────────────────────
class _GreetingHeader extends StatelessWidget {
  final String username;
  final double scale;
  final double topPadding;

  const _GreetingHeader({
    required this.username,
    required this.scale,
    required this.topPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: topPadding + 24 * scale,
        bottom: 32 * scale,
        left: 20 * scale,
        right: 20 * scale,
      ),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(32 * scale),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Hi, $username!',
            style: GoogleFonts.inter(
              fontSize: 22 * scale.clamp(0.85, 1.3),
              fontWeight: FontWeight.w700,
              color: AppColors.vibrantPink,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Section Title
// ─────────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String icon;
  final String title;
  final double scale;
  final bool isAssetIcon;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.scale,
    this.isAssetIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20 * scale),
      child: Row(
        children: [
          isAssetIcon
              ? Image.asset(
                  icon,
                  width: 20 * scale.clamp(0.85, 1.2),
                  height: 20 * scale.clamp(0.85, 1.2),
                  color: AppColors.black,
                )
              : Text(icon, style: TextStyle(fontSize: 16 * scale.clamp(0.85, 1.2))),
          SizedBox(width: 8 * scale),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16 * scale.clamp(0.85, 1.2),
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Explore Action Cards (Search Products + Find Recipe)
// ─────────────────────────────────────────────────────────────────
class _ExploreActionCards extends StatelessWidget {
  final double scale;

  const _ExploreActionCards({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20 * scale),
      child: Column(
        children: [
          _PurpleActionCard(
            title: 'Search New Products',
            subtitle: 'Search products by name or brand',
            scale: scale,
            onTap: () {},
          ),
          SizedBox(height: 10 * scale),
          _PurpleActionCard(
            title: 'Find New Recipe',
            subtitle: 'Search for a recipe by ingredient or diet type',
            scale: scale,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _PurpleActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double scale;
  final VoidCallback onTap;

  const _PurpleActionCard({
    required this.title,
    required this.subtitle,
    required this.scale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: 20 * scale,
          vertical: 26 * scale,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7B52D3), Color(0xFF6034B8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16 * scale),
          boxShadow: [
            BoxShadow(
              color: AppColors.royalPurple.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15 * scale.clamp(0.85, 1.2),
                      fontWeight: FontWeight.w700,
                      color: AppColors.pureWhite,
                    ),
                  ),
                  SizedBox(height: 2 * scale),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11 * scale.clamp(0.85, 1.2),
                      fontWeight: FontWeight.w400,
                      color: AppColors.pureWhite.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.search_rounded,
              color: AppColors.pureWhite,
              size: 22 * scale.clamp(0.85, 1.2),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Quick Action Cards (Scan Barcode + Create Shopping List)
// ─────────────────────────────────────────────────────────────────
class _QuickActionCards extends StatelessWidget {
  final double scale;
  final BuildContext context;

  const _QuickActionCards({required this.scale, required this.context});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20 * scale),
      child: Row(
        children: [
          Expanded(
            child: _PinkQuickCard(
              icon: Icons.qr_code_scanner_rounded,
              title: 'Scan the Barcode of a Product',
              scale: scale,
              onTap: () {},
            ),
          ),
          SizedBox(width: 10 * scale),
          Expanded(
            child: _PinkQuickCard(
              icon: Icons.shopping_bag_outlined,
              title: 'Create New Shopping List',
              scale: scale,
              onTap: () => context.push('/new-shopping-list'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinkQuickCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final double scale;
  final VoidCallback onTap;

  const _PinkQuickCard({
    required this.icon,
    required this.title,
    required this.scale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 150 * scale,
        padding: EdgeInsets.all(16 * scale),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF3D7F), Color(0xFFE8005A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16 * scale),
          boxShadow: [
            BoxShadow(
              color: AppColors.vibrantPink.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Icon(
                icon,
                color: AppColors.pureWhite,
                size: 24 * scale.clamp(0.85, 1.2),
              ),
            ),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14 * scale.clamp(0.85, 1.2),
                fontWeight: FontWeight.w700,
                color: AppColors.pureWhite,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Recommended Products Row
// ─────────────────────────────────────────────────────────────────
class _RecommendedProductsRow extends StatelessWidget {
  final List<RecommendedProduct> products;
  final double scale;

  const _RecommendedProductsRow({required this.products, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20 * scale),
      child: Row(
        children: products.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(
                right: index < products.length - 1 ? 10 * scale : 0,
              ),
              child: _RecommendedProductCard(item: item, scale: scale),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RecommendedProductCard extends StatelessWidget {
  final RecommendedProduct item;
  final double scale;

  const _RecommendedProductCard({required this.item, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Safe Badge ──
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 5 * scale),
            decoration: BoxDecoration(
              color: const Color(0xFF2DB34B),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16 * scale),
                topRight: Radius.circular(16 * scale),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.flag_rounded,
                  color: AppColors.pureWhite,
                  size: 13 * scale.clamp(0.85, 1.1),
                ),
                SizedBox(width: 4 * scale),
                Text(
                  'Safe',
                  style: GoogleFonts.inter(
                    fontSize: 11 * scale.clamp(0.85, 1.1),
                    fontWeight: FontWeight.w700,
                    color: AppColors.pureWhite,
                  ),
                ),
              ],
            ),
          ),

          // ── Sustainability Badge ──
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 5 * scale),
            decoration: BoxDecoration(
              color: item.isGreenBadge
                  ? const Color(0xFF1E9E38)
                  : const Color(0xFFF5A623),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  item.isGreenBadge
                      ? Icons.eco_rounded
                      : Icons.warning_amber_rounded,
                  color: AppColors.pureWhite,
                  size: 12 * scale.clamp(0.85, 1.1),
                ),
                SizedBox(width: 3 * scale),
                Text(
                  item.sustainabilityLabel,
                  style: GoogleFonts.inter(
                    fontSize: 10 * scale.clamp(0.85, 1.1),
                    fontWeight: FontWeight.w600,
                    color: AppColors.pureWhite,
                  ),
                ),
              ],
            ),
          ),

          // ── Product Image ──
          Padding(
            padding: EdgeInsets.fromLTRB(10 * scale, 10 * scale, 10 * scale, 0),
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8 * scale),
                    child: item.product.thumbnailAsset != null
                        ? Image.asset(
                            item.product.thumbnailAsset!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _ProductPlaceholder(scale: scale),
                          )
                        : _ProductPlaceholder(scale: scale),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.pureWhite.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.more_horiz,
                        size: 14,
                        color: AppColors.darkGrey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Product Info ──
          Padding(
            padding: EdgeInsets.fromLTRB(
              10 * scale,
              8 * scale,
              10 * scale,
              12 * scale,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: GoogleFonts.inter(
                    fontSize: 12 * scale.clamp(0.85, 1.1),
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2 * scale),
                Text(
                  item.product.description,
                  style: GoogleFonts.inter(
                    fontSize: 10 * scale.clamp(0.85, 1.1),
                    color: AppColors.darkGrey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductPlaceholder extends StatelessWidget {
  final double scale;
  const _ProductPlaceholder({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.softGrey,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: AppColors.neutralGrey,
          size: 32 * scale.clamp(0.85, 1.1),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Recently Viewed Recipes Row
// ─────────────────────────────────────────────────────────────────
class _RecentRecipesRow extends StatelessWidget {
  final List<RecipeModel> recipes;
  final double scale;

  const _RecentRecipesRow({required this.recipes, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20 * scale),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: recipes.asMap().entries.map((entry) {
          final index = entry.key;
          final recipe = entry.value;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(
                right: index < recipes.length - 1 ? 10 * scale : 0,
              ),
              child: _RecentRecipeCard(recipe: recipe, scale: scale),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RecentRecipeCard extends StatelessWidget {
  final RecipeModel recipe;
  final double scale;

  const _RecentRecipeCard({required this.recipe, required this.scale});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(16 * scale),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ──
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16 * scale),
                    topRight: Radius.circular(16 * scale),
                  ),
                  child: AspectRatio(
                    aspectRatio: 0.9,
                    child: recipe.imageUrl != null
                        ? Image.asset(
                            recipe.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.clearGrey,
                              child: Center(
                                child: Icon(
                                  Icons.restaurant_rounded,
                                  color: AppColors.neutralGrey,
                                  size: 28 * scale,
                                ),
                              ),
                            ),
                          )
                        : Container(color: AppColors.clearGrey),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: AppColors.pureWhite.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.more_horiz,
                        size: 14,
                        color: AppColors.darkGrey,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Info ──
            Padding(
              padding: EdgeInsets.fromLTRB(
                10 * scale,
                8 * scale,
                10 * scale,
                10 * scale,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: GoogleFonts.inter(
                      fontSize: 12 * scale.clamp(0.85, 1.1),
                      fontWeight: FontWeight.w700,
                      color: AppColors.vibrantPink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2 * scale),
                  Text(
                    recipe.description,
                    style: GoogleFonts.inter(
                      fontSize: 10 * scale.clamp(0.85, 1.1),
                      color: AppColors.darkGrey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6 * scale),
                  // ── Diet Tags ──
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: recipe.dietTags
                        .take(3)
                        .map((tag) => _DietTagChip(label: tag, scale: scale))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DietTagChip extends StatelessWidget {
  final String label;
  final double scale;

  const _DietTagChip({required this.label, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6 * scale, vertical: 2 * scale),
      decoration: BoxDecoration(
        color: AppColors.softGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.clearGrey, width: 0.8),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 9 * scale.clamp(0.85, 1.1),
          fontWeight: FontWeight.w500,
          color: AppColors.darkGrey,
        ),
      ),
    );
  }
}
