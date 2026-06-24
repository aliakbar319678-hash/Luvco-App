import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';

import '../../core/theme/app_colors.dart';
import '../../core/network/preference_api_service.dart';
import '../../models/recipe_model.dart';
import '../../core/network/list_api_service.dart';
import '../../core/network/recipe_api_service.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/shopping_list_detail_provider.dart';
import '../../providers/shopping_list_provider.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../shopping/product_detail_sheet.dart';
import '../../models/product_model.dart';

// ── Provider to load user preferences for favorites filtering ─────────
final _favoritePrefsProvider = FutureProvider<Map<String, List<String>>>((ref) async {
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

// ── Global providers for selected filters in favorites ────────────────
final favoritesSelectedDietsProvider = StateProvider<Set<String>>((_) => {});
final favoritesSelectedAllergensProvider = StateProvider<Set<String>>((_) => {});


class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(favoritesProvider);
    final sortOption = ref.watch(favoritesSortProvider);
    final selectedDiets = ref.watch(favoritesSelectedDietsProvider);
    final selectedAllergens = ref.watch(favoritesSelectedAllergensProvider);
    final size = MediaQuery.sizeOf(context);
    final scale = size.width / 390;

    var items = state.items.toList();

    // Apply filtering based on fetched product details
    if (selectedDiets.isNotEmpty || selectedAllergens.isNotEmpty) {
      items = items.where((item) {
        final detail = state.productDetails[item.barcode];
        if (detail == null) return false;

        // Check diet tags: product must match all selected diets
        if (selectedDiets.isNotEmpty) {
          final matchesDiets = selectedDiets.every((diet) {
            final dietLower = diet.toLowerCase();
            return detail.labels.any((l) {
              final labelLower = l.toLowerCase();
              return labelLower == dietLower || 
                     labelLower == 'en:$dietLower' || 
                     labelLower.contains(dietLower);
            });
          });
          if (!matchesDiets) return false;
        }

        // Check allergen tags: product must NOT contain any selected allergens (Free of)
        if (selectedAllergens.isNotEmpty) {
          final containsAllergen = selectedAllergens.any((allergen) {
            final allergenLower = allergen.toLowerCase();
            return detail.allergens.any((a) {
              final allergenInProductLower = a.toLowerCase();
              return allergenInProductLower == allergenLower || 
                     allergenInProductLower == 'en:$allergenLower' || 
                     allergenInProductLower.contains(allergenLower);
            });
          });
          if (containsAllergen) return false;
        }

        return true;
      }).toList();
    }

    if (sortOption == FavoritesSortOption.nameAZ) {
      items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }


    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: Column(
          children: [
            _FavoritesTopBar(scale: scale),
            const SizedBox(height: 16),
            Expanded(
              child: items.isEmpty
                  ? _EmptyState(scale: scale)
                  : _ProductsList(scale: scale, items: items),
            ),
            const LuvcoBottomNavBar(),
          ],
        ),
      ),
    );
  }
}




// ── Top Bar ────────────────────────────────────────────────────────
class _FavoritesTopBar extends StatelessWidget {
  final double scale;
  const _FavoritesTopBar({required this.scale});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final barHeight = 121 * scale;
    return Container(
      height: barHeight,
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: EdgeInsets.only(top: top, left: 20 * scale, right: 20 * scale),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            behavior: HitTestBehavior.opaque,
            child: Icon(
              Icons.chevron_left_rounded,
              color: AppColors.vibrantPink,
              size: 28 * scale.clamp(0.85, 1.2),
            ),
          ),
          Expanded(
            child: Text(
              'Favorites',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 20 * scale.clamp(0.85, 1.2),
                fontWeight: FontWeight.w700,
                color: AppColors.vibrantPink,
              ),
            ),
          ),
          SizedBox(width: 28 * scale),
        ],
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final double scale;
  const _EmptyState({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SubHeader(scale: scale, itemCount: 0),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/empty_favorites_illustration.jpg',
                width: 218 * scale,
                height: 261 * scale,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(Icons.favorite_border_rounded, size: 80 * scale, color: AppColors.neutralGrey),
              ),
              const SizedBox(height: 24),
              Text(
                'It looks like the Favorites\nlist is currently empty.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 16 * scale.clamp(0.85, 1.2), fontWeight: FontWeight.w600, color: AppColors.black, height: 1.5),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32 * scale),
                child: _AddProductsButton(scale: scale),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Products List ──────────────────────────────────────────────────
class _ProductsList extends ConsumerWidget {
  final double scale;
  final List<ShoppingListItem> items;
  const _ProductsList({required this.scale, required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _SubHeader(scale: scale, itemCount: items.length),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 12),
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _FavoriteCard(item: items[i], scale: scale),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16 * scale, 8, 16 * scale, 12),
          child: _AddProductsButton(scale: scale),
        ),
      ],
    );
  }
}

// ── Sub-header (Favorites + Filter) ───────────────────────────────
class _SubHeader extends StatelessWidget {
  final double scale;
  final int itemCount;
  const _SubHeader({required this.scale, required this.itemCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.fromLTRB(20 * scale, 16, 20 * scale, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Favorites', style: GoogleFonts.inter(fontSize: 20 * scale.clamp(0.85, 1.2), fontWeight: FontWeight.w700, color: AppColors.black)),
                const SizedBox(height: 2),
                Text('See your products saved as favorite', style: GoogleFonts.inter(fontSize: 13 * scale.clamp(0.85, 1.2), color: AppColors.darkGrey)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showFilterSheet(context),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Icon(Icons.tune_rounded, size: 18 * scale, color: AppColors.darkGrey),
                const SizedBox(width: 4),
                Text('Filter', style: GoogleFonts.inter(fontSize: 13 * scale, fontWeight: FontWeight.w500, color: AppColors.darkGrey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FilterSheet(),
    );
  }
}

// ── Filter Bottom Sheet ────────────────────────────────────────────────
class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet();

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  Set<String> _selectedDiets = {};
  Set<String> _selectedAllergens = {};

  @override
  void initState() {
    super.initState();
    _selectedDiets = Set<String>.from(ref.read(favoritesSelectedDietsProvider));
    _selectedAllergens = Set<String>.from(ref.read(favoritesSelectedAllergensProvider));
  }

  @override
  Widget build(BuildContext context) {
    final sort = ref.watch(favoritesSortProvider);
    final prefsAsync = ref.watch(_favoritePrefsProvider);

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.75),
      decoration: const BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.paddingOf(context).bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filter Preferences', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.black)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close_rounded, color: AppColors.black),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Sort
            Text('Sort By', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.black)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.clearGrey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<FavoritesSortOption>(
                  value: sort,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: FavoritesSortOption.mostRecent, child: Text('Most Recent')),
                    DropdownMenuItem(value: FavoritesSortOption.nameAZ, child: Text('Name A-Z')),
                  ],
                  onChanged: (v) {
                    if (v != null) ref.read(favoritesSortProvider.notifier).state = v;
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Diet Types from backend
            prefsAsync.when(
              data: (prefs) {
                final dietOptions = prefs['dietTypes'] ?? [];
                if (dietOptions.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Diet Types', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.black)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: dietOptions.map((tag) {
                        final sel = _selectedDiets.contains(tag);
                        return GestureDetector(
                          onTap: () => setState(() => sel ? _selectedDiets.remove(tag) : _selectedDiets.add(tag)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: sel ? AppColors.softLavender : AppColors.pureWhite,
                              border: Border.all(color: sel ? AppColors.royalPurple : AppColors.inputBorder),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              tag,
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                                  color: sel ? AppColors.royalPurple : AppColors.darkGrey),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.royalPurple)),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
            // Allergens from backend
            prefsAsync.when(
              data: (prefs) {
                final allergyOptions = prefs['allergyTags'] ?? [];
                if (allergyOptions.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Free Of Ingredients', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.black)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: allergyOptions.map((tag) {
                        final sel = _selectedAllergens.contains(tag);
                        return GestureDetector(
                          onTap: () => setState(() => sel ? _selectedAllergens.remove(tag) : _selectedAllergens.add(tag)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: sel ? AppColors.softLavender : AppColors.pureWhite,
                              border: Border.all(color: sel ? AppColors.royalPurple : AppColors.inputBorder),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              tag,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                                color: sel ? AppColors.royalPurple : AppColors.darkGrey,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  ref.read(favoritesSelectedDietsProvider.notifier).state = _selectedDiets;
                  ref.read(favoritesSelectedAllergensProvider.notifier).state = _selectedAllergens;
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: (_selectedDiets.isNotEmpty || _selectedAllergens.isNotEmpty)
                      ? AppColors.vibrantPink
                      : AppColors.clearGrey,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                ),
                child: Text(
                  'Show Results',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: (_selectedDiets.isNotEmpty || _selectedAllergens.isNotEmpty)
                        ? AppColors.pureWhite
                        : AppColors.darkGrey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

}

// ── Favorite Product Card ──────────────────────────────────────────
class _FavoriteCard extends ConsumerStatefulWidget {
  final ShoppingListItem item;
  final double scale;
  const _FavoriteCard({required this.item, required this.scale});

  @override
  ConsumerState<_FavoriteCard> createState() => _FavoriteCardState();
}

class _FavoriteCardState extends ConsumerState<_FavoriteCard> {
  final CustomPopupMenuController _menuController = CustomPopupMenuController();

  @override
  void dispose() {
    _menuController.dispose();
    super.dispose();
  }

  void _openDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductDetailSheet(
        item: widget.item,
        showAddButton: false,
        showFavoritesButtons: true,
        onAddToListTap: () { Navigator.pop(context); _showAddToListSheet(); },
        onAddToRecipeTap: () { Navigator.pop(context); _showAddToRecipeSheet(); },
      ),
    );
  }

  void _showAddToListSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddToListSheet(
        scale: widget.scale,
        productBarcode: widget.item.barcode ?? '',
        productName: widget.item.name,
        productImageUrl: widget.item.thumbnailAsset ?? '',
      ),
    );
  }

  void _showAddToRecipeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddToRecipeSheet(
        scale: widget.scale,
        productBarcode: widget.item.barcode ?? '',
        productName: widget.item.name,
        productImageUrl: widget.item.thumbnailAsset ?? '',
      ),
    );
  }

  void _confirmRemove() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Do you want to remove this\nproduct from favorites?', textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 16 * widget.scale, fontWeight: FontWeight.w700, color: AppColors.black)),
              const SizedBox(height: 8),
              Text('Lorem ipsum dolor sit amet,\nconsectetur adipiscing elit.', textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 13 * widget.scale, color: AppColors.darkGrey)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text('Keep Product', style: GoogleFonts.inter(fontSize: 15 * widget.scale, fontWeight: FontWeight.w600, color: const Color(0xFF2196F3))),
                  ),
                  Container(width: 1, height: 20, color: AppColors.clearGrey),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      ref.read(favoritesProvider.notifier).removeItem(widget.item.id);
                    },
                    child: Text('Yes, remove', style: GoogleFonts.inter(fontSize: 15 * widget.scale, fontWeight: FontWeight.w600, color: AppColors.vibrantPink)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 60 * widget.scale.clamp(0.85, 1.1),
                height: 60 * widget.scale.clamp(0.85, 1.1),
                color: AppColors.softGrey,
                child: widget.item.thumbnailAsset != null
                    ? (widget.item.thumbnailAsset!.startsWith('http')
                        ? Image.network(
                            widget.item.thumbnailAsset!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.image_outlined,
                              color: AppColors.neutralGrey,
                            ),
                          )
                        : Image.asset(
                            widget.item.thumbnailAsset!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.image_outlined,
                              color: AppColors.neutralGrey,
                            ),
                          ))
                    : const Icon(Icons.image_outlined, color: AppColors.neutralGrey),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: GestureDetector(
                onTap: _openDetails,
                behavior: HitTestBehavior.opaque,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.item.name, style: GoogleFonts.inter(fontSize: 14 * widget.scale, fontWeight: FontWeight.w700, color: AppColors.vibrantPink), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text(widget.item.description, style: GoogleFonts.inter(fontSize: 12 * widget.scale, color: AppColors.darkGrey), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Heart icon
            const Icon(Icons.favorite_rounded, color: AppColors.vibrantPink, size: 22),
            const SizedBox(width: 6),
            // Menu
            CustomPopupMenu(
              controller: _menuController,
              pressType: PressType.singleClick,
              barrierColor: Colors.transparent,
              showArrow: false,
              verticalMargin: -8,
              horizontalMargin: 8,
              menuBuilder: () => ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 210,
                  decoration: BoxDecoration(
                    color: AppColors.pureWhite,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 6))],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _MenuItem(label: 'See More Details', icon: Icons.remove_red_eye_outlined, onTap: () { _menuController.hideMenu(); _openDetails(); }),
                      const Divider(height: 1, color: Color(0xFFEEEEEE)),
                      _MenuItem(label: 'Add to a Shopping List', icon: Icons.shopping_bag_outlined, onTap: () { _menuController.hideMenu(); _showAddToListSheet(); }),
                      const Divider(height: 1, color: Color(0xFFEEEEEE)),
                      _MenuItem(label: 'Add to a Recipe', icon: Icons.restaurant_menu_outlined, onTap: () { _menuController.hideMenu(); _showAddToRecipeSheet(); }),
                      const Divider(height: 1, color: Color(0xFFEEEEEE)),
                      _MenuItem(label: 'Remove from favorites', icon: Icons.favorite_border_rounded, onTap: () { _menuController.hideMenu(); _confirmRemove(); }, color: AppColors.vibrantPink),
                    ],
                  ),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.more_horiz, color: AppColors.darkGrey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  const _MenuItem({required this.label, required this.icon, required this.onTap, this.color = AppColors.black});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: color))),
            const SizedBox(width: 10),
            Icon(icon, size: 20, color: color),
          ],
        ),
      ),
    );
  }
}

// ── Add to Shopping List Sheet ────────────────────────────────────
class _AddToListSheet extends ConsumerStatefulWidget {
  final double scale;
  final String productBarcode;
  final String productName;
  final String productImageUrl;

  const _AddToListSheet({
    required this.scale,
    required this.productBarcode,
    required this.productName,
    required this.productImageUrl,
  });

  @override
  ConsumerState<_AddToListSheet> createState() => _AddToListSheetState();
}

class _AddToListSheetState extends ConsumerState<_AddToListSheet> {
  final Set<String> _selected = {};
  bool _isSaving = false;

  Future<void> _onSave() async {
    if (_selected.isEmpty) return;
    setState(() => _isSaving = true);
    int successCount = 0;
    for (final listId in _selected) {
      try {
        await ListApiService.instance.addItem(
          listId,
          barcode: widget.productBarcode,
          productName: widget.productName,
          productImageUrl: widget.productImageUrl,
          quantity: 1,
        );
        successCount++;
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.pop(context);
    if (successCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successCount == 1
              ? 'Product added to shopping list!'
              : 'Product added to $successCount lists!'),
          backgroundColor: AppColors.royalPurple,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lists = ref.watch(shoppingListProvider);
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close_rounded, color: AppColors.black, size: 24)),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child: lists.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('No shopping lists found. Create one first.'),
                  )
                : ListView(
                    shrinkWrap: true,
                    children: lists.map((list) {
                      return _CheckRow(
                        label: list.title,
                        checked: _selected.contains(list.id),
                        onChanged: (v) => setState(() => v! ? _selected.add(list.id) : _selected.remove(list.id)),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSaving || _selected.isEmpty ? null : _onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.royalPurple,
                disabledBackgroundColor: AppColors.royalPurple.withValues(alpha: 0.4),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
              ),
              child: Text(
                _isSaving ? 'Saving...' : 'Save On List',
                style: GoogleFonts.inter(fontSize: 15 * widget.scale, fontWeight: FontWeight.w600, color: AppColors.pureWhite),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// ── Add to Recipe Sheet ─────────────────────────────────────────────────
class _AddToRecipeSheet extends ConsumerStatefulWidget {
  final double scale;
  final String productBarcode;
  final String productName;
  final String productImageUrl;

  const _AddToRecipeSheet({
    required this.scale,
    required this.productBarcode,
    required this.productName,
    required this.productImageUrl,
  });

  @override
  ConsumerState<_AddToRecipeSheet> createState() => _AddToRecipeSheetState();
}

class _AddToRecipeSheetState extends ConsumerState<_AddToRecipeSheet> {
  final Set<String> _selected = {};
  List<RecipeModel> _recipes = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    try {
      final recipes = await RecipeApiService.instance.getRecipes('my-recipes');
      if (mounted) setState(() { _recipes = recipes; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onSave() async {
    if (_selected.isEmpty) return;
    setState(() => _isSaving = true);
    int successCount = 0;
    for (final recipeId in _selected) {
      try {
        await RecipeApiService.instance.addLinkedProduct(recipeId, {
          'barcode': widget.productBarcode,
          'productName': widget.productName,
          'productImageUrl': widget.productImageUrl,
          'quantity': 1,
          'position': 1,
        });
        successCount++;
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.pop(context);
    if (successCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successCount == 1
              ? 'Product added to recipe!'
              : 'Product added to $successCount recipes!'),
          backgroundColor: AppColors.royalPurple,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close_rounded, color: AppColors.black, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.royalPurple))
                : _recipes.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('No recipes found. Create one first.'),
                      )
                    : ListView(
                        shrinkWrap: true,
                        children: _recipes.map((recipe) {
                          return _CheckRow(
                            label: recipe.title,
                            checked: _selected.contains(recipe.id),
                            onChanged: (v) => setState(() => v! ? _selected.add(recipe.id) : _selected.remove(recipe.id)),
                          );
                        }).toList(),
                      ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSaving || _selected.isEmpty ? null : _onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.royalPurple,
                disabledBackgroundColor: AppColors.royalPurple.withValues(alpha: 0.4),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
              ),
              child: Text(
                _isSaving ? 'Saving...' : 'Save On Recipe',
                style: GoogleFonts.inter(fontSize: 15 * widget.scale, fontWeight: FontWeight.w600, color: AppColors.pureWhite),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// ── Reusable Check Row ─────────────────────────────────────────────
class _CheckRow extends StatelessWidget {
  final String label;
  final bool checked;
  final ValueChanged<bool?> onChanged;
  const _CheckRow({required this.label, required this.checked, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Checkbox(
            value: checked,
            onChanged: onChanged,
            activeColor: AppColors.royalPurple,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          Text(label, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.black)),
        ],
      ),
    );
  }
}

// ── Add Products Button ────────────────────────────────────────────
class _AddProductsButton extends StatelessWidget {
  final double scale;
  const _AddProductsButton({required this.scale});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52 * scale.clamp(0.85, 1.2),
      child: ElevatedButton.icon(
        onPressed: () => context.push('/dashboard-search'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.royalPurple,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(Icons.add, color: AppColors.pureWhite, size: 20 * scale.clamp(0.85, 1.2)),
        label: Text('Add Products', style: GoogleFonts.inter(fontSize: 15 * scale.clamp(0.85, 1.2), fontWeight: FontWeight.w600, color: AppColors.pureWhite)),
      ),
    );
  }
}
