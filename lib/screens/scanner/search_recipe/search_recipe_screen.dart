import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/preference_api_service.dart';
import '../../../models/recipe_model.dart';
import '../../../models/recipe_detail_model.dart';
import '../../../providers/search_recipe_provider.dart';
import '../../../widgets/bottom_nav_bar.dart';

// ── Provider to load user preferences for filters ─────────────────
final _recipeFilterPrefsProvider = FutureProvider<Map<String, List<String>>>((ref) async {
  try {
    final prefs = await PreferenceApiService.instance.getPreferences();
    final dietTypes = ((prefs['dietTypes'] as List?) ?? []).map((e) => e.toString()).toList();
    final allergyTags = ((prefs['allergyTags'] as List?) ?? []).map((e) => e.toString()).toList();
    final customDiets = ((prefs['customDiets'] as List?) ?? [])
        .map((e) => (e as Map<String, dynamic>)['name']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
    final customAllergies = ((prefs['customAllergies'] as List?) ?? [])
        .map((e) => (e as Map<String, dynamic>)['name']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
    return {
      'dietTypes': [...dietTypes, ...customDiets],
      'allergyTags': [...allergyTags, ...customAllergies],
    };
  } catch (_) {
    return {'dietTypes': [], 'allergyTags': []};
  }
});


// ═══════════════════════════════════════════════════════════════
// Search Recipe Screen  (frames 2.0.8 → 2.0.12)
// ═══════════════════════════════════════════════════════════════
class SearchRecipeScreen extends ConsumerStatefulWidget {
  const SearchRecipeScreen({super.key});

  @override
  ConsumerState<SearchRecipeScreen> createState() => _SearchRecipeScreenState();
}

class _SearchRecipeScreenState extends ConsumerState<SearchRecipeScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bottomNavIndexProvider.notifier).state = 1;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchRecipeProvider);
    final notifier = ref.read(searchRecipeProvider.notifier);
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final scale = (size.width / 390).clamp(0.85, 1.3);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColors.pageBackground,
        body: Stack(
          children: [
            Column(
              children: [
                // ── Header ──
                _SearchHeader(
                  padding: padding,
                  scale: scale,
                  size: size,
                  controller: _searchController,
                  focusNode: _focusNode,
                  query: state.query,
                  onChanged: notifier.onSearchChanged,
                  onClear: () {
                    _searchController.clear();
                    notifier.clearSearch();
                  },
                  onFilterTap: () =>
                      _showFilterSheet(context, ref, scale, size),
                ),

                _ResultsHeader(
                  scale: scale,
                  onFilterTap: () => _showFilterSheet(context, ref, scale, size),
                ),

                // ── Body ──
                Expanded(
                  child: state.isFetching
                      ? const Center(child: CircularProgressIndicator(color: AppColors.royalPurple))
                      : state.isSearching
                          ? _ResultsList(
                              results: state.results,
                              scale: scale,
                              size: size,
                              onItemTap: notifier.openQuickView,
                              onMoreTap: (recipeId) {
                                final recipe = state.results.firstWhere((r) => r.id == recipeId);
                                final detail = _recipeToDetail(recipe);
                                context.push('/recipe-detail', extra: detail);
                              },
                            )
                          : SingleChildScrollView(
                              padding: EdgeInsets.only(
                                bottom: padding.bottom + 100,
                              ),
                              child: _EmptyState(scale: scale),
                            ),
                ),
              ],
            ),

            // ── Bottom Nav ──
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: LuvcoBottomNavBar(),
            ),

            // ── Quick View Modal ──
            if (state.selectedRecipe != null)
              _QuickViewModal(
                recipe: state.selectedRecipe!,
                scale: scale,
                size: size,
                onClose: notifier.closeQuickView,
                onSave: () => notifier.toggleSave(state.selectedRecipe!.id),
                onSeeMore: () {
                  notifier.closeQuickView();
                  final detail = _recipeToDetail(state.selectedRecipe!);
                  context.push('/recipe-detail', extra: detail);
                },
              ),
          ],
        ),
      ),
    );
  }

  RecipeDetailModel _recipeToDetail(RecipeModel r) => RecipeDetailModel(
    core: r,
    ingredientsList: const [],
    instructionsList: const [],
    products: const [],
    isOwner: false,
  );

  void _showFilterSheet(
    BuildContext context,
    WidgetRef ref,
    double scale,
    Size size,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(scale: scale, size: size, ref: ref),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Header with search bar
// ═══════════════════════════════════════════════════════════════
class _SearchHeader extends StatelessWidget {
  final EdgeInsets padding;
  final double scale;
  final Size size;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onFilterTap;

  const _SearchHeader({
    required this.padding,
    required this.scale,
    required this.size,
    required this.controller,
    required this.focusNode,
    required this.query,
    required this.onChanged,
    required this.onClear,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header Title Box (121px height) ──────────────────────
        Container(
          width: double.infinity,
          height: 121 * scale + padding.top,
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
          padding: EdgeInsets.only(top: padding.top),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16 * scale),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Icon(
                        Icons.chevron_left,
                        size: 28 * scale,
                        color: AppColors.vibrantPink,
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Search Recipe',
                          style: GoogleFonts.inter(
                            fontSize: 18 * scale,
                            fontWeight: FontWeight.w700,
                            color: AppColors.vibrantPink,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 28 * scale),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Search Bar Section (Figma top: 153px) ────────────────
        // (121 + 32 = 153 gap)
        SizedBox(height: 32 * scale),

        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16 * scale),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 50 * scale,
                  decoration: BoxDecoration(
                    color: AppColors.pureWhite,
                    borderRadius: BorderRadius.circular(18 * scale),
                    border: Border.all(
                      color: query.isNotEmpty
                          ? AppColors.royalPurple
                          : AppColors.inputBorder,
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 14 * scale),
                      Icon(
                        Icons.search,
                        size: 20 * scale,
                        color: query.isNotEmpty
                            ? AppColors.royalPurple
                            : AppColors.neutralGrey,
                      ),
                      SizedBox(width: 10 * scale),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          style: GoogleFonts.inter(
                            fontSize: 14 * scale,
                            color: AppColors.black,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search for a Recipe',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 14 * scale,
                              color: AppColors.neutralGrey,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: onChanged,
                        ),
                      ),
                      if (query.isNotEmpty) ...[
                        GestureDetector(
                          onTap: onClear,
                          child: Icon(
                            Icons.close,
                            size: 18 * scale,
                            color: AppColors.neutralGrey,
                          ),
                        ),
                        SizedBox(width: 12 * scale),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12 * scale),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Empty State  (frame 2.0.8)
// ═══════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  final double scale;
  const _EmptyState({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 60 * scale),
        // Illustration
        SizedBox(
          width: 200 * scale,
          height: 200 * scale,
          child: Image.asset(
            'assets/images/search_image.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.restaurant_menu_outlined,
              size: 100 * scale,
              color: AppColors.clearGrey,
            ),
          ),
        ),
        SizedBox(height: 24 * scale),
        Text(
          'Search for a recipe by\ningredient or diet type',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 18 * scale,
            fontWeight: FontWeight.w700,
            color: AppColors.black,
            height: 1.3,
          ),
        ),
        SizedBox(height: 60 * scale),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Results List  (frame 2.0.9)
// ═══════════════════════════════════════════════════════════════
class _ResultsList extends StatelessWidget {
  final List<RecipeModel> results;
  final double scale;
  final Size size;
  final ValueChanged<RecipeModel> onItemTap;
  final ValueChanged<String> onMoreTap;

  const _ResultsList({
    required this.results,
    required this.scale,
    required this.size,
    required this.onItemTap,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Scrollable cards ─────────────────────────────────────
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(
              16 * scale,
              4 * scale,
              16 * scale,
              100 * scale,
            ),
            itemCount: results.length,
            separatorBuilder: (_, __) => SizedBox(height: 10 * scale),
            itemBuilder: (_, i) => _RecipeCard(
              recipe: results[i],
              scale: scale,
              onTap: () => onItemTap(results[i]),
              onSeeMore: () => onMoreTap(results[i].id),
              onSave: () {}, // This will be handled in screen via notifier
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  final double scale;
  final VoidCallback onFilterTap;

  const _ResultsHeader({
    required this.scale,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.pageBackground,
      padding: EdgeInsets.fromLTRB(20 * scale, 12 * scale, 20 * scale, 10 * scale),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Results',
            style: GoogleFonts.inter(
              fontSize: 16 * scale,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          GestureDetector(
            onTap: onFilterTap,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Icon(
                  Icons.tune,
                  size: 18 * scale,
                  color: AppColors.black,
                ),
                SizedBox(width: 4 * scale),
                Text(
                  'Filter',
                  style: GoogleFonts.inter(
                    fontSize: 13 * scale,
                    fontWeight: FontWeight.w500,
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Recipe Card  (reused in results list)
// ═══════════════════════════════════════════════════════════════
class _RecipeCard extends ConsumerWidget {
  final RecipeModel recipe;
  final double scale;
  final VoidCallback onTap;
  final VoidCallback onSeeMore;
  final VoidCallback onSave;

  const _RecipeCard({
    required this.recipe,
    required this.scale,
    required this.onTap,
    required this.onSeeMore,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(12 * scale),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(8 * scale),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8 * scale),
              child: SizedBox(
                width: 80 * scale,
                height: 80 * scale,
                child: recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty
                    ? (recipe.imageUrl!.startsWith('http')
                        ? Image.network(
                            recipe.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Image.asset('assets/images/bread_pic.png', fit: BoxFit.cover),
                          )
                        : Image.asset(
                            recipe.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Image.asset('assets/images/bread_pic.png', fit: BoxFit.cover),
                          ))
                    : Image.asset('assets/images/bread_pic.png', fit: BoxFit.cover),
              ),
            ),
            SizedBox(width: 10 * scale),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          recipe.title,
                          style: GoogleFonts.inter(
                            fontSize: 14 * scale,
                            fontWeight: FontWeight.w700,
                            color: AppColors.vibrantPink,
                          ),
                        ),
                      ),
                      Theme(
                        data: Theme.of(context).copyWith(
                          hoverColor: Colors.transparent,
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                        ),
                        child: PopupMenuButton<int>(
                          icon: Icon(
                            Icons.more_horiz,
                            size: 20 * scale,
                            color: AppColors.darkGrey,
                          ),
                          offset: const Offset(0, 30),
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12 * scale),
                          ),
                          color: AppColors.pureWhite,
                          onSelected: (val) {
                            if (val == 0) onSeeMore();
                            if (val == 1) {
                              ref
                                  .read(searchRecipeProvider.notifier)
                                  .toggleSave(recipe.id);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem<int>(
                              value: 0,
                              height: 48 * scale,
                              child: _PopupItemRow(
                                label: 'See More Details',
                                icon: Icons.remove_red_eye_outlined,
                                scale: scale,
                              ),
                            ),
                            const PopupMenuDivider(height: 1),
                            PopupMenuItem<int>(
                              value: 1,
                              height: 48 * scale,
                              child: _PopupItemRow(
                                label: recipe.isSaved ? 'Unsave Recipe' : 'Save Recipe',
                                icon: recipe.isSaved ? Icons.bookmark : Icons.bookmark_border,
                                scale: scale,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2 * scale),
                  if (recipe.ownerName.isNotEmpty)
                    Text(
                      'by ${recipe.ownerName}',
                      style: GoogleFonts.inter(
                        fontSize: 12 * scale,
                        color: AppColors.darkGrey,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else if (recipe.description.isNotEmpty)
                    Text(
                      recipe.description,
                      style: GoogleFonts.inter(
                        fontSize: 12 * scale,
                        color: AppColors.darkGrey,
                      ),
                    ),
                  SizedBox(height: 6 * scale),
                  Wrap(
                    spacing: 6 * scale,
                    runSpacing: 4 * scale,
                    children: recipe.dietTags.take(3).map((tag) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8 * scale,
                          vertical: 3 * scale,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.inputBorder),
                          borderRadius: BorderRadius.circular(20 * scale),
                        ),
                        child: Text(
                          tag,
                          style: GoogleFonts.inter(
                            fontSize: 11 * scale,
                            color: AppColors.darkGrey,
                          ),
                        ),
                      );
                    }).toList(),
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

// ═══════════════════════════════════════════════════════════════
// Quick View Modal — fixed: centered title, 310×221 card, clean labels
// ═══════════════════════════════════════════════════════════════
class _QuickViewModal extends StatelessWidget {
  final RecipeModel recipe;
  final double scale;
  final Size size;
  final VoidCallback onClose;
  final VoidCallback onSave;
  final VoidCallback onSeeMore;

  const _QuickViewModal({
    required this.recipe,
    required this.scale,
    required this.size,
    required this.onClose,
    required this.onSave,
    required this.onSeeMore,
  });

  // Strips any trailing numbers/spaces from tag label
  // e.g. "Label 01" → "Label", "Gluten Free" → "Gluten Free"
  String _cleanLabel(String raw) {
    // Remove trailing space+digits pattern like " 01", " 02", " 1" etc.
    return raw.replaceAll(RegExp(r'\s+\d+$'), '').trim();
  }

  @override
  Widget build(BuildContext context) {
    // 310px card width at 390px base → proportional to screen
    final cardWidth = 310.0 * scale;
    final cardHeight = 221.0 * scale;
    final cardRadius = 18.0 * scale;

    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.45),
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () {},
          child: Container(
            // modal itself is slightly wider than card to give padding
            margin: EdgeInsets.symmetric(
              horizontal: 20 * scale,
              vertical: 36 * scale,
            ),
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
              borderRadius: BorderRadius.circular(24 * scale),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24 * scale),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Close button ──────────────────────────────
                    Padding(
                      padding: EdgeInsets.only(
                        top: 14 * scale,
                        right: 14 * scale,
                      ),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: onClose,
                          child: Icon(
                            Icons.close_rounded,
                            size: 22 * scale,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                    ),

                    // ── Title & Description — CENTERED ────────────
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        16 * scale,
                        2 * scale,
                        16 * scale,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            recipe.title,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 20 * scale,
                              fontWeight: FontWeight.w700,
                              color: AppColors.vibrantPink,
                            ),
                          ),
                          SizedBox(height: 3 * scale),
                          Text(
                            recipe.description,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 13 * scale,
                              fontWeight: FontWeight.w400,
                              color: AppColors.darkGrey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 16 * scale),

                    // ── 310 × 221 rounded card (image + meta) ─────
                    Center(
                      child: Container(
                        width: cardWidth,
                        height: cardHeight,
                        decoration: BoxDecoration(
                          color: AppColors.pureWhite,
                          borderRadius: BorderRadius.circular(cardRadius),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(cardRadius),
                          child: Column(
                            children: [
                              // ── Recipe image (top ~145 / 221 of card) ──
                              Expanded(
                                flex: 145,
                                child: SizedBox(
                                  width: double.infinity,
                                  child: recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty
                                      ? (recipe.imageUrl!.startsWith('http')
                                          ? Image.network(
                                              recipe.imageUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(
                                                color: AppColors.softGrey,
                                                child: Icon(
                                                  Icons.image_outlined,
                                                  color: AppColors.clearGrey,
                                                  size: 36 * scale,
                                                ),
                                              ),
                                            )
                                          : Image.asset(
                                              recipe.imageUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(
                                                color: AppColors.softGrey,
                                                child: Icon(
                                                  Icons.image_outlined,
                                                  color: AppColors.clearGrey,
                                                  size: 36 * scale,
                                                ),
                                              ),
                                            ))
                                      : Container(
                                          color: AppColors.softGrey,
                                          child: Icon(
                                            Icons.image_outlined,
                                            color: AppColors.clearGrey,
                                            size: 36 * scale,
                                          ),
                                        ),
                                ),
                              ),

                              // ── Servings & Time (bottom ~76 / 221) ──
                              Expanded(
                                flex: 76,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _MetaItem(
                                      label: 'Servings',
                                      icon: Icons.restaurant_rounded,
                                      value: '${recipe.servings}',
                                      scale: scale,
                                    ),
                                    SizedBox(width: 44 * scale),
                                    _MetaItem(
                                      label: 'Time',
                                      icon: Icons.access_time_rounded,
                                      value: '${recipe.timeOfPreparation} min',
                                      scale: scale,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 16 * scale),

                    // ── Diet Types ────────────────────────────────
                    _QuickTagSection(
                      title: 'Diet Types',
                      tags: recipe.dietTags.isNotEmpty
                          ? recipe.dietTags.map(_cleanLabel).toList()
                          : ['Vegan', 'Organic', 'Bio', 'Vegetarian'],
                      scale: scale,
                    ),

                    SizedBox(height: 12 * scale),

                    // ── Free of Ingredients ───────────────────────
                    _QuickTagSection(
                      title: 'Free of Ingredients',
                      tags: recipe.freeOfIngredients.isNotEmpty
                          ? recipe.freeOfIngredients.map(_cleanLabel).toList()
                          : ['Gluten Free', 'Wheat Free', 'Nut Free', 'Dairy Free'],
                      scale: scale,
                    ),

                    SizedBox(height: 22 * scale),

                    // ── Save Recipe Button ────────────────────────
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16 * scale),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50 * scale,
                        child: ElevatedButton.icon(
                          onPressed: onSave,
                          icon: Icon(
                            recipe.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                            size: 20 * scale,
                            color: AppColors.pureWhite,
                          ),
                          label: Text(
                            recipe.isSaved ? 'Unsave Recipe' : 'Save Recipe',
                            style: GoogleFonts.inter(
                              fontSize: 15 * scale,
                              fontWeight: FontWeight.w700,
                              color: AppColors.pureWhite,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.royalPurple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 10 * scale),

                    // ── See More Details Button ───────────────────
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16 * scale),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50 * scale,
                        child: OutlinedButton(
                          onPressed: onSeeMore,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppColors.royalPurple,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          child: Text(
                            'See More Details',
                            style: GoogleFonts.inter(
                              fontSize: 15 * scale,
                              fontWeight: FontWeight.w700,
                              color: AppColors.royalPurple,
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 12 * scale),

                    // ── Swipe hint — centered ─────────────────────
                    Center(
                      child: Text(
                        'Swipe up to see similar',
                        style: GoogleFonts.inter(
                          fontSize: 12 * scale,
                          color: AppColors.neutralGrey,
                        ),
                      ),
                    ),

                    SizedBox(height: 14 * scale),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Quick tag section ─────────────────────────────────────────────
class _QuickTagSection extends StatelessWidget {
  final String title;
  final List<String> tags;
  final double scale;

  const _QuickTagSection({
    required this.title,
    required this.tags,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15 * scale,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          SizedBox(height: 10 * scale),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: tags
                .map((tag) => _QuickPillTag(label: tag, scale: scale))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ── Single pill tag — circle + label below ────────────────────────
class _QuickPillTag extends StatelessWidget {
  final String label;
  final double scale;

  const _QuickPillTag({required this.label, required this.scale});

  static (IconData, Color) _getIconAndColor(String name) {
    final lower = name.toLowerCase();
    
    // Allergens
    if (lower.contains('gluten') || lower.contains('wheat')) {
      return (Icons.grain_rounded, const Color(0xFFE5A93C)); // Amber/Orange
    }
    if (lower.contains('nut') || lower.contains('almond') || lower.contains('hazelnut') || lower.contains('pecan') || lower.contains('cashew')) {
      return (Icons.cookie_rounded, const Color(0xFF8D6E63)); // Brown
    }
    if (lower.contains('milk') || lower.contains('lactose') || lower.contains('dairy')) {
      return (Icons.water_drop_rounded, const Color(0xFF64B5F6)); // Light Blue
    }
    if (lower.contains('egg')) {
      return (Icons.egg_rounded, const Color(0xFFFFD54F)); // Yellow
    }
    if (lower.contains('soy')) {
      return (Icons.grass_rounded, const Color(0xFF81C784)); // Green
    }
    if (lower.contains('fish') || lower.contains('seafood') || lower.contains('shrimp')) {
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
    final circleSize = 52.0 * scale.clamp(0.85, 1.2);

    return SizedBox(
      width: circleSize,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: circleSize,
            height: circleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.pureWhite,
              border: Border.all(color: AppColors.clearGrey, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                iconData,
                size: 20 * scale.clamp(0.85, 1.2),
                color: iconColor,
              ),
            ),
          ),
          SizedBox(height: 5 * scale.clamp(0.85, 1.2)),
          Text(
            clean,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11 * scale.clamp(0.85, 1.2),
              fontWeight: FontWeight.w500,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick view tag section (Diet Types / Free of Ingredients) ──────
// // Small circles in a row of 4 — exactly like Figma screenshot
// class _QuickTagSection extends StatelessWidget {
//   final String title;
//   final List<String> tags;
//   final double scale;

//   const _QuickTagSection({
//     required this.title,
//     required this.tags,
//     required this.scale,
//   });

//   @override
//   Widget build(BuildContext context) {
//     // Always show exactly 4 slots
//     final displayTags = List.generate(
//       4,
//       (i) => i < tags.length ? tags[i] : 'Label',
//     );

//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: 16 * scale),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: GoogleFonts.inter(
//               fontSize: 15 * scale,
//               fontWeight: FontWeight.w700,
//               color: AppColors.black,
//             ),
//           ),
//           SizedBox(height: 10 * scale),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: displayTags
//                 .map((tag) => _QuickPillTag(label: tag, scale: scale))
//                 .toList(),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ── Single pill tag — small circle with icon + label below ─────────
// class _QuickPillTag extends StatelessWidget {
//   final String label;
//   final double scale;

//   const _QuickPillTag({required this.label, required this.scale});

//   @override
//   Widget build(BuildContext context) {
//     final circleSize = 54.0 * scale;

//     return SizedBox(
//       width: circleSize,
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             width: circleSize,
//             height: circleSize,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               color: AppColors.pureWhite,
//               border: Border.all(color: AppColors.clearGrey, width: 1.2),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withValues(alpha: 0.04),
//                   blurRadius: 4,
//                   offset: const Offset(0, 1),
//                 ),
//               ],
//             ),
//             child: Center(
//               child: Icon(
//                 Icons.hexagon_outlined,
//                 size: 22 * scale,
//                 color: AppColors.black,
//               ),
//             ),
//           ),
//           SizedBox(height: 4 * scale),
//           Text(
//             label,
//             textAlign: TextAlign.center,
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//             style: GoogleFonts.inter(
//               fontSize: 11 * scale,
//               fontWeight: FontWeight.w500,
//               color: AppColors.black,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// ═══════════════════════════════════════════════════════════════
// More Actions Popup
// ═══════════════════════════════════════════════════════════════
// ── Internal helper for the popup menu items ──────────────────────
class _PopupItemRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final double scale;

  const _PopupItemRow({
    required this.label,
    required this.icon,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14 * scale,
              fontWeight: FontWeight.w500,
              color: AppColors.black,
            ),
          ),
        ),
        Icon(icon, size: 18 * scale, color: AppColors.darkGrey),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Filter Bottom Sheet
// ═══════════════════════════════════════════════════════════════
class _FilterSheet extends ConsumerStatefulWidget {
  final double scale;
  final Size size;
  final WidgetRef ref;

  const _FilterSheet({
    required this.scale,
    required this.size,
    required this.ref,
  });

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late SearchRecipeFilter _localFilter;

  static const _sortOptions = ['Most Recent', 'Oldest', 'A-Z', 'Z-A'];

  @override
  void initState() {
    super.initState();
    _localFilter = widget.ref.read(searchRecipeProvider).filter;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;

    final bool isDirty =
        _localFilter.filter2Tags.isNotEmpty ||
        _localFilter.filter3Tags.isNotEmpty ||
        _localFilter.sortBy != 'Most Recent';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20 * s)),
      ),
      padding: EdgeInsets.fromLTRB(
        16 * s,
        16 * s,
        16 * s,
        MediaQuery.paddingOf(context).bottom + 16 * s,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle + Close
          Row(
            children: [
              Expanded(
                child: Text(
                  'Filter Preferences',
                  style: GoogleFonts.inter(
                    fontSize: 17 * s,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Icon(Icons.close, size: 22 * s, color: AppColors.black),
              ),
            ],
          ),

          SizedBox(height: 18 * s),

          // Sort dropdown
          Text(
            'Sort By',
            style: GoogleFonts.inter(
              fontSize: 13 * s,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          SizedBox(height: 6 * s),
          _SortDropdown(
            value: _localFilter.sortBy,
            options: _sortOptions,
            scale: s,
            onChanged: (v) =>
                setState(() => _localFilter = _localFilter.copyWith(sortBy: v)),
          ),

          SizedBox(height: 16 * s),

          // Diet Types — from backend preferences
          Consumer(
            builder: (ctx, ref, _) {
              final prefsAsync = ref.watch(_recipeFilterPrefsProvider);
              return prefsAsync.when(
                data: (prefs) {
                  final dietOptions = prefs['dietTypes'] ?? [];
                  if (dietOptions.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Diet Types',
                        style: GoogleFonts.inter(
                          fontSize: 13 * s,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),
                      SizedBox(height: 8 * s),
                      _TagChips(
                        options: dietOptions,
                        selected: _localFilter.filter2Tags,
                        scale: s,
                        onToggle: (tag) {
                          final list = List<String>.from(_localFilter.filter2Tags);
                          list.contains(tag) ? list.remove(tag) : list.add(tag);
                          setState(() => _localFilter = _localFilter.copyWith(filter2Tags: list));
                        },
                      ),
                      SizedBox(height: 16 * s),
                    ],
                  );
                },
                loading: () => Padding(
                  padding: EdgeInsets.only(bottom: 16 * s),
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.royalPurple)),
                ),
                error: (_, __) => const SizedBox.shrink(),
              );
            },
          ),

          // Allergen Filters — from backend preferences
          Consumer(
            builder: (ctx, ref, _) {
              final prefsAsync = ref.watch(_recipeFilterPrefsProvider);
              return prefsAsync.when(
                data: (prefs) {
                  final allergyOptions = prefs['allergyTags'] ?? [];
                  if (allergyOptions.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Free Of Ingredients',
                        style: GoogleFonts.inter(
                          fontSize: 13 * s,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),
                      SizedBox(height: 8 * s),
                      _TagChips(
                        options: allergyOptions,
                        selected: _localFilter.filter3Tags,
                        scale: s,
                        onToggle: (tag) {
                          final list = List<String>.from(_localFilter.filter3Tags);
                          list.contains(tag) ? list.remove(tag) : list.add(tag);
                          setState(() => _localFilter = _localFilter.copyWith(filter3Tags: list));
                        },
                      ),
                      SizedBox(height: 16 * s),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              );
            },
          ),

          SizedBox(height: 24 * s),

          // Show Results button
          SizedBox(
            width: double.infinity,
            height: 50 * s,
            child: ElevatedButton(
              onPressed: () {
                widget.ref
                    .read(searchRecipeProvider.notifier)
                    .updateFilter(_localFilter);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDirty
                    ? AppColors.vibrantPink
                    : AppColors.softLavender,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12 * s),
                ),
              ),
              child: Text(
                'Show Results',
                style: GoogleFonts.inter(
                  fontSize: 15 * s,
                  fontWeight: FontWeight.w600,
                  color: isDirty ? AppColors.pureWhite : AppColors.neutralGrey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  final String value;
  final List<String> options;
  final double scale;
  final ValueChanged<String> onChanged;

  const _SortDropdown({
    required this.value,
    required this.options,
    required this.scale,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48 * scale,
      padding: EdgeInsets.symmetric(horizontal: 14 * scale),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.inputBorder),
        borderRadius: BorderRadius.circular(10 * scale),
        color: AppColors.pureWhite,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: 20 * scale,
            color: AppColors.darkGrey,
          ),
          style: GoogleFonts.inter(
            fontSize: 14 * scale,
            color: AppColors.black,
          ),
          items: options
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: (v) => v != null ? onChanged(v) : null,
        ),
      ),
    );
  }
}

class _TagChips extends StatelessWidget {
  final List<String> options;
  final List<String> selected;
  final double scale;
  final ValueChanged<String> onToggle;

  const _TagChips({
    required this.options,
    required this.selected,
    required this.scale,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8 * scale,
      runSpacing: 8 * scale,
      children: options.map((tag) {
        final isSelected = selected.contains(tag);
        return GestureDetector(
          onTap: () => onToggle(tag),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 14 * scale,
              vertical: 7 * scale,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.softLavender : AppColors.pureWhite,
              border: Border.all(
                color: isSelected
                    ? AppColors.royalPurple
                    : AppColors.inputBorder,
              ),
              borderRadius: BorderRadius.circular(20 * scale),
            ),
            child: Text(
              tag,
              style: GoogleFonts.inter(
                fontSize: 13 * scale,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.royalPurple : AppColors.darkGrey,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Reusable sub-widgets
// ═══════════════════════════════════════════════════════════════
class _MetaItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final double scale;

  const _MetaItem({
    required this.label,
    required this.icon,
    required this.value,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13 * scale,
            fontWeight: FontWeight.w500,
            color: AppColors.vibrantPink,
          ),
        ),
        SizedBox(height: 6 * scale),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20 * scale, color: AppColors.vibrantPink),
            SizedBox(width: 6 * scale),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 18 * scale,
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

