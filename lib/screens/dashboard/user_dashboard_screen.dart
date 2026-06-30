import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_utils.dart';
import '../../providers/dashboard_provider.dart';

import '../../models/recipe_model.dart';
import '../../models/recipe_detail_model.dart';
import '../../core/network/api_client.dart';
import '../../widgets/bottom_nav_bar.dart';

class UserDashboardScreen extends ConsumerWidget {
  const UserDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(dashboardProvider.select((s) => s.isLoading));

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Column(
        children: [
          // ── Scrollable Content ──
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(dashboardProvider.notifier).loadDashboardData(),
              color: AppColors.vibrantPink,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  // ── Greeting ──
                  const SliverToBoxAdapter(
                    child: _GreetingHeader(),
                  ),

                  if (isLoading)
                    const SliverToBoxAdapter(
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.vibrantPink),
                      ),
                    ),

                  SliverToBoxAdapter(
                    child: SizedBox(height: context.s(24))),

                  // ── Explore New Products Section ──
                  SliverToBoxAdapter(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: context.s(16)),
                      padding: EdgeInsets.symmetric(vertical: context.s(24)),
                      decoration: BoxDecoration(
                        color: AppColors.pureWhite,
                        borderRadius: BorderRadius.circular(context.s(20)),
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
                          const _SectionTitle(
                            icon: 'assets/icons/microscope_icon.png',
                            title: 'Explore new products',
                            isAssetIcon: true,
                          ),
                          SizedBox(height: context.s(16)),
                          const _ExploreActionCards(),
                          SizedBox(height: context.s(12)),
                          const _QuickActionCards(),
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(child: SizedBox(height: context.s(28))),

                  // ── Recommended Products ──
                  const SliverToBoxAdapter(
                    child: _SectionTitle(
                      icon: '💡',
                      title: 'Recommended products',
                    ),
                  ),

                  SliverToBoxAdapter(child: SizedBox(height: context.s(12))),

                  const SliverToBoxAdapter(
                    child: _RecommendedProductsRow(),
                  ),

                  SliverToBoxAdapter(child: SizedBox(height: context.s(28))),

                  // ── Recently Viewed Recipes ──
                  const SliverToBoxAdapter(
                    child: _SectionTitle(
                      icon: '🕐',
                      title: 'Recipes recently viewed',
                    ),
                  ),

                  SliverToBoxAdapter(child: SizedBox(height: context.s(12))),

                  const SliverToBoxAdapter(
                    child: _RecentRecipesRow(),
                  ),

                  SliverToBoxAdapter(child: SizedBox(height: context.s(24))),
                ],
              ),
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
class _GreetingHeader extends ConsumerWidget {
  const _GreetingHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Selective watching! Only rebuilds when username changes.
    final username = ref.watch(dashboardProvider.select((s) => s.username));

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: context.topPadding + context.s(24),
        bottom: context.s(32),
        left: context.s(20),
        right: context.s(20),
      ),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(context.s(32)),
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
              fontSize: context.s(24),
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
  final bool isAssetIcon;

  const _SectionTitle({
    required this.icon,
    required this.title,
    this.isAssetIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.s(20)),
      child: Row(
        children: [
          isAssetIcon
              ? Image.asset(
                  icon,
                  width: context.s(26),
                  height: context.s(26),
                  color: AppColors.black,
                )
              : Text(icon, style: TextStyle(fontSize: context.s(24))),
          SizedBox(width: context.s(10)),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: context.s(22),
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
  const _ExploreActionCards();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.s(16)),
      child: Column(
        children: [
          _PurpleActionCard(
            title: 'Search New Products',
            subtitle: 'Search products by name or brand',
            onTap: () => context.push('/dashboard-search'),
          ),
          SizedBox(height: context.s(10)),
          _PurpleActionCard(
            title: 'Find New Recipe',
            subtitle: 'Search for a recipe by ingredient or diet type',
            onTap: () => context.push('/search-recipe'),
          ),
        ],
      ),
    );
  }
}

class _PurpleActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PurpleActionCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: context.s(344),
        height: context.s(92),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7B52D3), Color(0xFF6034B8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(context.s(18)),
            boxShadow: [
              BoxShadow(
                color: AppColors.royalPurple.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(
            vertical: context.s(19),
            horizontal: context.s(24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: context.s(16),
                        fontWeight: FontWeight.w700,
                        color: AppColors.pureWhite,
                      ),
                    ),
                    SizedBox(height: context.s(4)),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: context.s(13),
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
                size: context.s(22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Quick Action Cards (Scan Barcode + Create Shopping List)
// ─────────────────────────────────────────────────────────────────
class _QuickActionCards extends StatelessWidget {
  const _QuickActionCards();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.s(20)),
      child: Row(
        children: [
          Expanded(
            child: _PinkQuickCard(
              icon: Icons.qr_code_scanner_rounded,
              title: 'Scan the Barcode of a Product',
              onTap: () => context.push('/barcode-scanner'),
            ),
          ),
          SizedBox(width: context.s(10)),
          Expanded(
            child: _PinkQuickCard(
              icon: Icons.shopping_bag_outlined,
              title: 'Create New Shopping List',
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
  final VoidCallback onTap;

  const _PinkQuickCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: context.s(180),
        padding: EdgeInsets.all(context.s(16)),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF3D7F), Color(0xFFE8005A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(context.s(16)),
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
                size: context.s(24),
              ),
            ),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: context.s(15),
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
class _RecommendedProductsRow extends ConsumerWidget {
  const _RecommendedProductsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Selective watch
    final products = ref.watch(dashboardProvider.select((s) => s.recommendedProducts));

    if (products.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: context.s(20)),
        child: Container(
          width: double.infinity,
          height: context.s(120),
          decoration: BoxDecoration(
            color: AppColors.pureWhite,
            borderRadius: BorderRadius.circular(context.s(16)),
          ),
          child: Center(
            child: Text(
              'No recommended products found.',
              style: GoogleFonts.inter(
                fontSize: context.s(14),
                color: AppColors.neutralGrey,
              ),
            ),
          ),
        ),
      );
    }

    return RepaintBoundary(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: context.s(20)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: products.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Container(
                width: context.s(164),
                margin: EdgeInsets.only(
                  right: index < products.length - 1 ? context.s(12) : 0,
                ),
                child: _RecommendedProductCard(item: item),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _RecommendedProductCard extends StatelessWidget {
  final RecommendedProduct item;

  const _RecommendedProductCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/product-detail', extra: item.product),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(context.s(16)),
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
              padding: EdgeInsets.symmetric(vertical: context.s(8)),
              decoration: BoxDecoration(
                color: item.isSafe ? const Color(0xFF2DB34B) : const Color(0xFFE8005A),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(context.s(16)),
                  topRight: Radius.circular(context.s(16)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item.isSafe ? Icons.flag_rounded : Icons.warning_rounded,
                    color: AppColors.pureWhite,
                    size: context.s(13),
                  ),
                  SizedBox(width: context.s(4)),
                  Text(
                    item.isSafe ? 'Safe' : 'Avoid',
                    style: GoogleFonts.inter(
                      fontSize: context.s(14),
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
              padding: EdgeInsets.symmetric(vertical: context.s(8)),
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
                    size: context.s(12),
                  ),
                  SizedBox(width: context.s(3)),
                  Text(
                    item.sustainabilityLabel,
                    style: GoogleFonts.inter(
                      fontSize: context.s(13),
                      fontWeight: FontWeight.w600,
                      color: AppColors.pureWhite,
                    ),
                  ),
                ],
              ),
            ),

            // ── Product Image ──
            Stack(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(context.s(20), context.s(16), context.s(20), context.s(12)),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(context.s(8)),
                      child: _buildProductImage(item.product.thumbnailAsset, context),
                    ),
                  ),
                ),
                Positioned(
                  top: context.s(12),
                  right: context.s(12),
                  child: GestureDetector(
                    onTap: () {},
                    child: Icon(
                      Icons.more_horiz,
                      size: context.s(24),
                      color: AppColors.black,
                    ),
                  ),
                ),
              ],
            ),

            // ── Product Info ──
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.s(16),
                context.s(4),
                context.s(16),
                context.s(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: GoogleFonts.inter(
                      fontSize: context.s(16),
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: context.s(6)),
                  Text(
                    item.product.description,
                    style: GoogleFonts.inter(
                      fontSize: context.s(14),
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
      ),
    );
  }
}

class _ProductPlaceholder extends StatelessWidget {
  const _ProductPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.softGrey,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: AppColors.neutralGrey,
          size: context.s(32),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Recently Viewed Recipes Row
// ─────────────────────────────────────────────────────────────────
class _RecentRecipesRow extends ConsumerWidget {
  const _RecentRecipesRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Selective watch — only rebuilds when recentlyViewedRecipes changes
    final recipes = ref.watch(
      dashboardProvider.select((s) => s.recentlyViewedRecipes),
    );

    if (recipes.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: context.s(20)),
        child: Container(
          width: double.infinity,
          height: context.s(120),
          decoration: BoxDecoration(
            color: AppColors.pureWhite,
            borderRadius: BorderRadius.circular(context.s(16)),
          ),
          child: Center(
            child: Text(
              'No recently viewed recipes.',
              style: GoogleFonts.inter(
                fontSize: context.s(14),
                color: AppColors.neutralGrey,
              ),
            ),
          ),
        ),
      );
    }

    // Fixed height replaces IntrinsicHeight.
    // IntrinsicHeight triggers a 2-pass layout (O(2N) instead of O(N)).
    // Recipe cards have a predictable structure so a clamped height is safe.
    return RepaintBoundary(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: context.s(20)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: recipes.asMap().entries.map((entry) {
              final index = entry.key;
              final recipe = entry.value;
              return Container(
                width: context.s(164),
                margin: EdgeInsets.only(
                  right: index < recipes.length - 1 ? context.s(12) : 0,
                ),
                child: _RecentRecipeCard(recipe: recipe),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _RecentRecipeCard extends StatelessWidget {
  final RecipeModel recipe;

  const _RecentRecipeCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/recipe-detail', extra: RecipeDetailModel(core: recipe)),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(context.s(16)),
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
                    topLeft: Radius.circular(context.s(16)),
                    topRight: Radius.circular(context.s(16)),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: _buildRecipeImage(recipe.imageUrl, context),
                  ),
                ),
                Positioned(
                  top: context.s(12),
                  right: context.s(12),
                  child: GestureDetector(
                    onTap: () {},
                    child: Icon(
                      Icons.more_horiz,
                      size: context.s(24),
                      color: AppColors.pureWhite,
                    ),
                  ),
                ),
              ],
            ),

            // ── Info ──
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.s(16),
                context.s(12),
                context.s(16),
                context.s(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: GoogleFonts.inter(
                      fontSize: context.s(16),
                      fontWeight: FontWeight.w700,
                      color: AppColors.vibrantPink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: context.s(6)),
                  Text(
                    recipe.description,
                    style: GoogleFonts.inter(
                      fontSize: context.s(14),
                      color: AppColors.darkGrey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: context.s(12)),
                  // ── Diet Tags ──
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: recipe.dietTags
                        .take(3)
                        .map((tag) => _DietTagChip(label: tag))
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

  const _DietTagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.s(10), vertical: context.s(4)),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkGrey.withValues(alpha: 0.5), width: 0.8),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: context.s(11),
          fontWeight: FontWeight.w500,
          color: AppColors.darkGrey,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Image Resolving Helpers
// ─────────────────────────────────────────────────────────────────
String? _resolveImageUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return url;
  }
  if (url.startsWith('assets/')) {
    return url;
  }
  final baseUrl = ApiClient.instance.dio.options.baseUrl;
  final rootUrl = baseUrl.endsWith('/api/v1')
      ? baseUrl.substring(0, baseUrl.length - 7)
      : baseUrl;
  final path = url.startsWith('/') ? url : '/$url';
  return '$rootUrl$path';
}

Widget _buildProductImage(String? path, BuildContext context) {
  if (path == null || path.isEmpty) {
    return const _ProductPlaceholder();
  }

  final resolvedPath = _resolveImageUrl(path);

  if (resolvedPath != null && (resolvedPath.startsWith('http') || resolvedPath.startsWith('https'))) {
    return Image.network(
      resolvedPath,
      fit: BoxFit.cover,
      cacheWidth: 200,
      cacheHeight: 200,
      errorBuilder: (_, __, ___) => const _ProductPlaceholder(),
    );
  } else {
    return Image.asset(
      resolvedPath ?? path,
      fit: BoxFit.cover,
      cacheWidth: 200,
      cacheHeight: 200,
      errorBuilder: (_, __, ___) => const _ProductPlaceholder(),
    );
  }
}

Widget _buildRecipeImage(String? path, BuildContext context) {
  if (path == null || path.isEmpty) {
    return Container(
      color: AppColors.clearGrey,
      child: Center(
        child: Icon(
          Icons.restaurant_rounded,
          color: AppColors.neutralGrey,
          size: context.s(28),
        ),
      ),
    );
  }

  final resolvedPath = _resolveImageUrl(path);

  if (resolvedPath != null && (resolvedPath.startsWith('http') || resolvedPath.startsWith('https'))) {
    return Image.network(
      resolvedPath,
      fit: BoxFit.cover,
      cacheWidth: 400,
      cacheHeight: 400,
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.clearGrey,
        child: Center(
          child: Icon(
            Icons.restaurant_rounded,
            color: AppColors.neutralGrey,
            size: context.s(28),
          ),
        ),
      ),
    );
  } else {
    return Image.asset(
      resolvedPath ?? path,
      fit: BoxFit.cover,
      cacheWidth: 400,
      cacheHeight: 400,
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.clearGrey,
        child: Center(
          child: Icon(
            Icons.restaurant_rounded,
            color: AppColors.neutralGrey,
            size: context.s(28),
          ),
        ),
      ),
    );
  }
}
