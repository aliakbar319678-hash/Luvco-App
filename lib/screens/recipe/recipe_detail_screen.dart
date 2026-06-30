import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../models/recipe_detail_model.dart';
import '../../providers/recipe_detail_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'edit_recipe_screen.dart';
import '../../core/network/api_client.dart';
import '../../models/product_model.dart';

// ═══════════════════════════════════════════════════════════════════
//  RECIPE DETAIL SCREEN — entry point
// ═══════════════════════════════════════════════════════════════════
class RecipeDetailScreen extends ConsumerWidget {
  final RecipeDetailModel recipe;
  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final scale = size.width / 390;
    final padding = MediaQuery.paddingOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.pureWhite,
        bottomNavigationBar: const LuvcoBottomNavBar(),
        body: Stack(
          children: [
            // ── Background color ──────────────────────────────────────
            Container(color: AppColors.pageBackground),

            // ── Scrollable body — watches detail + activeTab ONLY ─────
            // Splitting into granular Consumers: tab switches don't rebuild
            // the overlays, popup toggles don't rebuild the scroll body.
            Consumer(
              builder: (context, ref, _) {
                final detail = ref.watch(recipeDetailProvider(recipe));
                final activeTab = ref.watch(recipeDetailTabProvider);

                return Stack(
                  children: [
                    // ── Scrollable Body ─────────────────────────────
                    Positioned.fill(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            SizedBox(height: 75 * scale),
                            _HeroImage(recipe: detail, scale: scale),
                            Transform.translate(
                              offset: Offset(0, -30 * scale),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: AppColors.pureWhite,
                                  borderRadius: BorderRadius.vertical(
                                    bottom: Radius.circular(40),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    const SizedBox(height: 12),
                                    _RecipeMetaSection(
                                      recipe: detail,
                                      scale: scale,
                                    ),
                                    const SizedBox(height: 8),
                                    _DietChipsSection(
                                      recipe: detail,
                                      scale: scale,
                                    ),
                                    const SizedBox(height: 16),
                                    _RecipeTabBar(
                                      activeTab: activeTab,
                                      scale: scale,
                                      onChanged: (i) =>
                                          ref
                                                  .read(
                                                    recipeDetailTabProvider
                                                        .notifier,
                                                  )
                                                  .state =
                                              i,
                                    ),
                                    _TabContent(
                                      recipe: detail,
                                      activeTab: activeTab,
                                      scale: scale,
                                      size: size,
                                    ),
                                    const SizedBox(height: 40),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Fixed Floating Header ────────────────────────
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: _CustomHeader(
                        scale: scale,
                        padding: padding,
                        onBack: () => context.pop(),
                        onMore: detail.isOwner
                            ? () =>
                                  ref
                                          .read(
                                            recipeDetailMoreActionsProvider
                                                .notifier,
                                          )
                                          .state =
                                      true
                            : null,
                      ),
                    ),
                  ],
                );
              },
            ),

            // ── More actions popup — separate Consumer ─────────────────
            // Only rebuilds when showMoreActions changes. Completely isolated
            // from the scroll body above.
            Consumer(
              builder: (context, ref, _) {
                final showMoreActions = ref.watch(
                  recipeDetailMoreActionsProvider,
                );
                if (!showMoreActions) return const SizedBox.shrink();
                final detail = ref.watch(recipeDetailProvider(recipe));
                return _MoreActionsOverlay(
                  recipe: detail,
                  scale: scale,
                  onDismiss: () =>
                      ref.read(recipeDetailMoreActionsProvider.notifier).state =
                          false,
                  onEdit: () {
                    ref.read(recipeDetailMoreActionsProvider.notifier).state =
                        false;
                    _openEditSheet(context, ref, detail, scale);
                  },
                  onDuplicate: () {
                    ref.read(recipeDetailMoreActionsProvider.notifier).state =
                        false;
                    ref
                        .read(myRecipesProvider.notifier)
                        .duplicateRecipe(detail.id);
                    ref.read(recipeDuplicatedSuccessProvider.notifier).state =
                        true;
                    Future.delayed(const Duration(seconds: 2), () {
                      if (context.mounted) {
                        ref
                                .read(recipeDuplicatedSuccessProvider.notifier)
                                .state =
                            false;
                      }
                    });
                  },
                  onDelete: () {
                    ref.read(recipeDetailMoreActionsProvider.notifier).state =
                        false;
                    ref
                        .read(myRecipesProvider.notifier)
                        .deleteRecipe(detail.id);
                    context.pop();
                  },
                );
              },
            ),

            // ── Duplicate success toast — separate Consumer ─────────────
            Consumer(
              builder: (context, ref, _) {
                final showDupSuccess = ref.watch(
                  recipeDuplicatedSuccessProvider,
                );
                if (!showDupSuccess) return const SizedBox.shrink();
                return const _DuplicateSuccessOverlay();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openEditSheet(
    BuildContext context,
    WidgetRef ref,
    RecipeDetailModel recipe,
    double scale,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditRecipeScreen(recipe: recipe.core),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  CUSTOM HEADER — flat, transparent bg, matches Figma 1.4.0
// ═══════════════════════════════════════════════════════════════════
class _CustomHeader extends StatelessWidget {
  final double scale;
  final EdgeInsets padding;
  final VoidCallback onBack;
  final VoidCallback? onMore;

  const _CustomHeader({
    required this.scale,
    required this.padding,
    required this.onBack,
    this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: padding.top + 6,
        bottom: 28 * scale,
        left: 4,
        right: 4,
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.vibrantPink,
              size: 20,
            ),
          ),

          // Title
          Expanded(
            child: Text(
              'Recipe Detail',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 18 * scale.clamp(0.85, 1.2),
                fontWeight: FontWeight.w700,
                color: AppColors.vibrantPink,
              ),
            ),
          ),

          // More (three dots) — always show slot for alignment
          if (onMore != null)
            IconButton(
              onPressed: onMore,
              icon: const Icon(
                Icons.more_horiz_rounded,
                color: AppColors.vibrantPink,
                size: 26,
              ),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  HERO IMAGE — reduced height to match Figma proportions
// ═══════════════════════════════════════════════════════════════════
class _HeroImage extends StatelessWidget {
  final RecipeDetailModel recipe;
  final double scale;

  const _HeroImage({required this.recipe, required this.scale});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 317 * scale,
      width: double.infinity,
      child: recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty
          ? (recipe.imageUrl!.startsWith('http')
                ? Image.network(
                    recipe.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/images/bread_pic.png',
                      fit: BoxFit.cover,
                    ),
                  )
                : Image.asset(
                    recipe.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/images/bread_pic.png',
                      fit: BoxFit.cover,
                    ),
                  ))
          : Image.asset('assets/images/bread_pic.png', fit: BoxFit.cover),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  RECIPE META CARD — card with dashed border, matches Figma
// ═══════════════════════════════════════════════════════════════════
class _RecipeMetaSection extends ConsumerWidget {
  final RecipeDetailModel recipe;
  final double scale;
  const _RecipeMetaSection({required this.recipe, required this.scale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 375 * scale,
      constraints: BoxConstraints(minHeight: 157 * scale),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(32 * scale),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(24 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Title + Bookmark Row ────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      style: GoogleFonts.inter(
                        fontSize: 22 * scale,
                        fontWeight: FontWeight.w700,
                        color: AppColors.vibrantPink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recipe.description.isNotEmpty
                          ? recipe.description
                          : 'Short description of the recipe.',
                      style: GoogleFonts.inter(
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.w400,
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  ref
                      .read(recipeDetailProvider(recipe).notifier)
                      .toggleBookmark();
                },
                icon: Icon(
                  recipe.isSaved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: AppColors.vibrantPink,
                  size: 28 * scale,
                ),
              ),
            ],
          ),

          SizedBox(height: 24 * scale), // Gap of 24px or flexible space
          // ── Servings + Time row (Centered) ───────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _MetaItem(
                label: 'Servings',
                value: '${recipe.servings}',
                icon: Icons.restaurant_menu_rounded,
                scale: scale,
              ),
              SizedBox(width: 50 * scale),
              _MetaItem(
                label: 'Time',
                value: '${recipe.timeMinutes} min',
                icon: Icons.access_time_rounded,
                scale: scale,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Paints a rounded-rect dashed border

class _MetaItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final double scale;

  const _MetaItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13 * scale.clamp(0.85, 1.2),
            fontWeight: FontWeight.w500,
            color: AppColors.vibrantPink,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20 * scale.clamp(0.85, 1.2),
              color: AppColors.vibrantPink,
            ),
            const SizedBox(width: 6),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 18 * scale.clamp(0.85, 1.2),
                fontWeight: FontWeight.w700,
                color: AppColors.vibrantPink,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  DIET CHIPS SECTION
// ═══════════════════════════════════════════════════════════════════
class _DietChipsSection extends StatelessWidget {
  final RecipeDetailModel recipe;
  final double scale;
  const _DietChipsSection({required this.recipe, required this.scale});

  @override
  Widget build(BuildContext context) {
    final showDiet = recipe.dietTypes.isNotEmpty;
    final showFree = recipe.freeOfIngredients.isNotEmpty;
    if (!showDiet && !showFree) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 16 * scale,
        vertical: 6 * scale,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showDiet) ...[
            _ChipRow(label: 'Diet Type', tags: recipe.dietTypes, scale: scale),
            if (showFree) const SizedBox(height: 12),
          ],
          if (showFree)
            _ChipRow(
              label: 'Free of Ingredients',
              tags: recipe.freeOfIngredients,
              scale: scale,
            ),
        ],
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  final String label;
  final List<String> tags;
  final double scale;
  const _ChipRow({
    required this.label,
    required this.tags,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();

    final List<String> row1;
    final List<String> row2;

    if (tags.length <= 4) {
      row1 = tags;
      row2 = [];
    } else {
      final half = (tags.length / 2).ceil();
      row1 = tags.sublist(0, half);
      row2 = tags.sublist(half);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 15 * scale.clamp(0.85, 1.2),
            fontWeight: FontWeight.w700,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: row1
                    .map((tag) => _OutlineChip(label: tag, scale: scale))
                    .toList(),
              ),
            ),
            if (row2.isNotEmpty) ...[
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: row2
                      .map((tag) => _OutlineChip(label: tag, scale: scale))
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _OutlineChip extends StatelessWidget {
  final String label;
  final double scale;
  const _OutlineChip({required this.label, required this.scale});

  static (IconData, Color) _getIconAndColor(String name) {
    final lower = name.toLowerCase();

    // Allergens
    if (lower.contains('gluten') || lower.contains('wheat')) {
      return (Icons.grain_rounded, const Color(0xFFE5A93C)); // Amber/Orange
    }
    if (lower.contains('nut') ||
        lower.contains('almond') ||
        lower.contains('hazelnut') ||
        lower.contains('pecan') ||
        lower.contains('cashew')) {
      return (Icons.cookie_rounded, const Color(0xFF8D6E63)); // Brown
    }
    if (lower.contains('milk') ||
        lower.contains('lactose') ||
        lower.contains('dairy')) {
      return (Icons.water_drop_rounded, const Color(0xFF64B5F6)); // Light Blue
    }
    if (lower.contains('egg')) {
      return (Icons.egg_rounded, const Color(0xFFFFD54F)); // Yellow
    }
    if (lower.contains('soy')) {
      return (Icons.grass_rounded, const Color(0xFF81C784)); // Green
    }
    if (lower.contains('fish') ||
        lower.contains('seafood') ||
        lower.contains('shrimp')) {
      return (Icons.set_meal_rounded, const Color(0xFF4FC3F7)); // Blue
    }

    // Certifications & Labels
    if (lower.contains('organic') || lower.contains('bio')) {
      return (Icons.eco_rounded, const Color(0xFF4CAF50)); // Green
    }
    if (lower.contains('ecocert')) {
      return (Icons.verified_rounded, const Color(0xFF2E7D32)); // Dark Green
    }
    if (lower.contains('green dot') || lower.contains('recycl')) {
      return (Icons.recycling_rounded, const Color(0xFF388E3C)); // Green
    }
    if (lower.contains('agriculture') || lower.contains('grower')) {
      return (Icons.spa_rounded, const Color(0xFF81C784)); // Soft Green
    }
    if (lower.contains('vegan') || lower.contains('vegetarian')) {
      return (Icons.spa_rounded, const Color(0xFF4CAF50)); // Green
    }
    if (lower.contains('halal') || lower.contains('kosher')) {
      return (Icons.task_alt_rounded, const Color(0xFF009688)); // Teal
    }
    if (lower.contains('fair trade') || lower.contains('fairtrade')) {
      return (Icons.handshake_rounded, const Color(0xFF00897B)); // Teal
    }

    return (Icons.verified_rounded, const Color(0xFF7B52D3)); // Purple accent
  }

  static String _cleanLabel(String raw) {
    String cleaned = raw.replaceAll(RegExp(r'^[a-z]{2}:'), '');
    cleaned = cleaned.replaceAll(RegExp(r'[-_]'), ' ').trim();
    if (cleaned.isEmpty) return raw;
    return cleaned
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w)
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final clean = _cleanLabel(label);
    final iconInfo = _getIconAndColor(clean);
    final iconData = iconInfo.$1;
    final iconColor = iconInfo.$2;

    return Padding(
      padding: EdgeInsets.only(right: 14 * scale),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58 * scale.clamp(0.85, 1.2),
            height: 58 * scale.clamp(0.85, 1.2),
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.clearGrey, width: 1.2),
            ),
            child: Center(
              child: Icon(
                iconData,
                color: iconColor,
                size: 26 * scale.clamp(0.85, 1.2),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 68 * scale.clamp(0.85, 1.2),
            child: Text(
              clean,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 10 * scale.clamp(0.85, 1.2),
                color: AppColors.black,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  TAB BAR — matches Figma purple pill tabs
// ═══════════════════════════════════════════════════════════════════
class _RecipeTabBar extends StatelessWidget {
  final int activeTab;
  final double scale;
  final ValueChanged<int> onChanged;

  const _RecipeTabBar({
    required this.activeTab,
    required this.scale,
    required this.onChanged,
  });

  static const _tabs = ['Ingredients', 'Instructions', 'Products'];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16 * scale),
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFF0EBF9),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final isActive = i == activeTab;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.royalPurple : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    _tabs[i],
                    style: GoogleFonts.inter(
                      fontSize: 12 * scale.clamp(0.85, 1.2),
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive
                          ? AppColors.pureWhite
                          : AppColors.neutralGrey,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  TAB CONTENT
// ═══════════════════════════════════════════════════════════════════
class _TabContent extends StatelessWidget {
  final RecipeDetailModel recipe;
  final int activeTab;
  final double scale;
  final Size size;

  const _TabContent({
    required this.recipe,
    required this.activeTab,
    required this.scale,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    switch (activeTab) {
      case 0:
        return _IngredientsTab(recipe: recipe, scale: scale);
      case 1:
        return _InstructionsTab(recipe: recipe, scale: scale);
      case 2:
        return _ProductsTab(recipe: recipe, scale: scale);
      default:
        return const SizedBox.shrink();
    }
  }
}

// ── Ingredients Tab ────────────────────────────────────────────────
class _IngredientsTab extends StatelessWidget {
  final RecipeDetailModel recipe;
  final double scale;
  const _IngredientsTab({required this.recipe, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 8),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(22 * scale),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.clearGrey.withValues(alpha: 0.5),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.soup_kitchen_outlined,
                  size: 24 * scale.clamp(0.85, 1.2),
                  color: AppColors.black,
                ),
                const SizedBox(width: 12),
                Text(
                  'Ingredients',
                  style: GoogleFonts.inter(
                    fontSize: 18 * scale.clamp(0.85, 1.2),
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              recipe.ingredients,
              style: GoogleFonts.inter(
                fontSize: 14 * scale.clamp(0.85, 1.2),
                color: AppColors.black,
                height: 2.0,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Instructions Tab ───────────────────────────────────────────────
class _InstructionsTab extends StatelessWidget {
  final RecipeDetailModel recipe;
  final double scale;
  const _InstructionsTab({required this.recipe, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16 * scale),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16 * scale),
        decoration: BoxDecoration(
          color: AppColors.softGrey,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.menu_book_outlined,
                  size: 18 * scale.clamp(0.85, 1.2),
                  color: AppColors.vibrantPink,
                ),
                const SizedBox(width: 6),
                Text(
                  'Instructions',
                  style: GoogleFonts.inter(
                    fontSize: 16 * scale.clamp(0.85, 1.2),
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              recipe.instructions,
              style: GoogleFonts.inter(
                fontSize: 13 * scale.clamp(0.85, 1.2),
                color: AppColors.darkGrey,
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Products Tab ───────────────────────────────────────────────────
class _ProductsTab extends ConsumerWidget {
  final RecipeDetailModel recipe;
  final double scale;
  const _ProductsTab({required this.recipe, required this.scale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayProducts = recipe.products;

    return Padding(
      padding: EdgeInsets.all(16 * scale),
      child: Column(
        children: [
          if (recipe.isOwner) _AddProductsButton(scale: scale),
          SizedBox(height: 12 * scale),
          if (displayProducts.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24 * scale),
              child: _ProductsEmptyState(scale: scale),
            )
          else
            ...displayProducts.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ProductCard(
                  product: p,
                  scale: scale,
                  isOwner: recipe.isOwner,
                  onDelete: recipe.isOwner
                      ? () => ref
                            .read(recipeDetailProvider(recipe).notifier)
                            .removeProduct(p.id)
                      : null,
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _AddProductsButton extends StatelessWidget {
  final double scale;
  const _AddProductsButton({required this.scale});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () => context.push('/dashboard-search'),
        icon: Icon(
          Icons.add,
          size: 18 * scale.clamp(0.85, 1.2),
          color: AppColors.royalPurple,
        ),
        label: Text(
          'Add Products',
          style: GoogleFonts.inter(
            fontSize: 14 * scale.clamp(0.85, 1.2),
            fontWeight: FontWeight.w600,
            color: AppColors.royalPurple,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.royalPurple, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: Colors.transparent,
        ),
      ),
    );
  }
}

// ignore: unused_element
class _ProductsEmptyState extends StatelessWidget {
  final double scale;
  const _ProductsEmptyState({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.shopping_bag_outlined,
          size: 64 * scale.clamp(0.85, 1.2),
          color: AppColors.clearGrey,
        ),
        SizedBox(height: 12 * scale),
        Text(
          'No products are attached\nto this recipe',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14 * scale.clamp(0.85, 1.2),
            fontWeight: FontWeight.w500,
            color: AppColors.neutralGrey,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  final RecipeProduct product;
  final double scale;
  final bool isOwner;
  final VoidCallback? onDelete;

  const _ProductCard({
    required this.product,
    required this.scale,
    required this.isOwner,
    this.onDelete,
  });

  Color get _sustainabilityColor {
    switch (product.sustainabilityLevel) {
      case 'Unsustainable':
        return const Color(0xFFEF4444);
      case 'Moderate Impact':
        return const Color(0xFFF59E0B);
      case 'Eco-Friendly':
        return const Color(0xFF22C55E);
      default:
        return AppColors.neutralGrey;
    }
  }

  Color get _safetyColor {
    switch (product.safetyLevel) {
      case 'Avoid':
        return const Color(0xFFF59E0B);
      case 'Safe':
        return const Color(0xFF22C55E);
      default:
        return AppColors.neutralGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        margin: EdgeInsets.only(bottom: 20 * scale),
        child: Stack(
          children: [
            // ── Background Tabs ──
            SizedBox(
              height: 48 * scale,
              width: double.infinity,
              child: Row(
                children: [
                  // Sustainability tab (left)
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: _sustainabilityColor,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16 * scale),
                          topRight: Radius.circular(16 * scale),
                        ),
                      ),
                      padding: EdgeInsets.only(top: 8 * scale),
                      alignment: Alignment.topCenter,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.eco_outlined,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            product.sustainabilityLevel,
                            style: GoogleFonts.inter(
                              fontSize: 13 * scale.clamp(0.85, 1.2),
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Safety tab (right)
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: _safetyColor,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16 * scale),
                          topRight: Radius.circular(16 * scale),
                        ),
                      ),
                      padding: EdgeInsets.only(top: 8 * scale),
                      alignment: Alignment.topCenter,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.flag_outlined,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            product.safetyLevel,
                            style: GoogleFonts.inter(
                              fontSize: 13 * scale.clamp(0.85, 1.2),
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
  
            // ── Product Info Area (White Foreground Card) ──
            GestureDetector(
              onTap: () {
                final productModel = ProductModel(
                  id: product.barcode ?? product.id,
                  name: product.name,
                  description: product.otherData,
                  thumbnailAsset: product.productImageUrl,
                  imageAsset: product.productImageUrl,
                  sustainabilityLabel: product.sustainabilityLevel,
                  safetyLabel: product.safetyLevel,
                  isSustainable: product.sustainabilityLevel.toLowerCase() == 'eco-friendly' ||
                      product.sustainabilityLevel.toLowerCase() == 'sustainable',
                );
                context.push('/product-detail', extra: productModel);
              },
              child: Container(
                margin: EdgeInsets.only(top: 32 * scale),
                decoration: BoxDecoration(
                  color: AppColors.pureWhite,
                  borderRadius: BorderRadius.circular(24 * scale),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(
                  vertical: 20 * scale,
                  horizontal: 16 * scale,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Product Image
                    SizedBox(
                      width: 64 * scale,
                      height: 64 * scale,
                      child: _buildProductImage(product.imageAsset, scale),
                    ),
                  SizedBox(width: 16 * scale),
                  // Text Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: GoogleFonts.inter(
                            fontSize: 14 * scale.clamp(0.85, 1.2),
                            fontWeight: FontWeight.w700,
                            color: AppColors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.otherData,
                          style: GoogleFonts.inter(
                            fontSize: 13 * scale.clamp(0.85, 1.2),
                            color: AppColors.darkGrey,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Delete Button
                  if (isOwner && onDelete != null) ...[
                    SizedBox(width: 12 * scale),
                    GestureDetector(
                      onTap: onDelete,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 24 * scale.clamp(0.85, 1.2),
                          color: AppColors.black,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  MORE ACTIONS POPUP OVERLAY
// ═══════════════════════════════════════════════════════════════════
class _MoreActionsOverlay extends StatelessWidget {
  final RecipeDetailModel recipe;
  final double scale;
  final VoidCallback onDismiss;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const _MoreActionsOverlay({
    required this.recipe,
    required this.scale,
    required this.onDismiss,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            child: Container(color: Colors.transparent),
          ),
        ),
        Positioned(
          top: MediaQuery.paddingOf(context).top + 48,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 180 * scale.clamp(0.85, 1.2),
              decoration: BoxDecoration(
                color: AppColors.pureWhite,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PopupItem(
                    label: 'Edit Recipe',
                    icon: Icons.edit_outlined,
                    color: AppColors.black,
                    scale: scale,
                    onTap: onEdit,
                  ),
                  const Divider(height: 1, color: AppColors.clearGrey),
                  _PopupItem(
                    label: 'Duplicate Recipe',
                    icon: Icons.copy_outlined,
                    color: AppColors.black,
                    scale: scale,
                    onTap: onDuplicate,
                  ),
                  const Divider(height: 1, color: AppColors.clearGrey),
                  _PopupItem(
                    label: 'Delete Recipe',
                    icon: Icons.delete_outline_rounded,
                    color: AppColors.errorRed,
                    scale: scale,
                    onTap: onDelete,
                    isDestructive: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PopupItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final double scale;
  final VoidCallback onTap;
  final bool isDestructive;

  const _PopupItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.scale,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 16 * scale,
          vertical: 13 * scale,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14 * scale.clamp(0.85, 1.2),
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            Icon(icon, size: 18 * scale.clamp(0.85, 1.2), color: color),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  DUPLICATE SUCCESS OVERLAY
// ═══════════════════════════════════════════════════════════════════
class _DuplicateSuccessOverlay extends StatelessWidget {
  const _DuplicateSuccessOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.3),
        child: Center(
          child: Container(
            width: 220,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Image.asset(
                    'assets/icons/done_icon.png',
                    width: 64,
                    height: 64,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'The recipe was\nduplicated!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Helper functions for image resolution
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

Widget _buildProductImage(String? path, double scale) {
  if (path == null || path.isEmpty) {
    return Icon(
      Icons.image_outlined,
      size: 32 * scale,
      color: AppColors.clearGrey,
    );
  }

  final resolvedPath = _resolveImageUrl(path);

  if (resolvedPath != null && (resolvedPath.startsWith('http') || resolvedPath.startsWith('https'))) {
    return Image.network(
      resolvedPath,
      fit: BoxFit.contain,
      cacheWidth: 120,
      cacheHeight: 120,
      errorBuilder: (_, __, ___) => Icon(
        Icons.image_outlined,
        size: 32 * scale,
        color: AppColors.clearGrey,
      ),
    );
  } else {
    return Image.asset(
      resolvedPath ?? path,
      fit: BoxFit.contain,
      cacheWidth: 120,
      cacheHeight: 120,
      errorBuilder: (_, __, ___) => Icon(
        Icons.image_outlined,
        size: 32 * scale,
        color: AppColors.clearGrey,
      ),
    );
  }
}
