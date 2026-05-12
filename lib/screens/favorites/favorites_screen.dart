import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/shopping_list_detail_provider.dart';
import '../../providers/shopping_list_provider.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../shopping/product_detail_sheet.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(favoritesProvider);
    final size = MediaQuery.sizeOf(context);
    final scale = size.width / 390;

    final filteredItems = _searchQuery.isEmpty
        ? state.items
        : state.items.where((i) => i.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: Column(
          children: [
            _FavoritesTopBar(scale: scale),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: _FavoriteSearchBar(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                scale: scale,
              ),
            ),
            Expanded(
              child: filteredItems.isEmpty
                  ? _EmptyState(scale: scale)
                  : _ProductsList(scale: scale, items: filteredItems),
            ),
            const LuvcoBottomNavBar(),
          ],
        ),
      ),
    );
  }
}

// ── Search Bar ─────────────────────────────────────────────────────
class _FavoriteSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final double scale;

  const _FavoriteSearchBar({
    required this.controller,
    required this.onChanged,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.royalPurple.withValues(alpha: 0.5), width: 1.5),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.inter(fontSize: 14 * scale, color: AppColors.black),
        decoration: InputDecoration(
          hintText: 'Product Name |',
          hintStyle: GoogleFonts.inter(fontSize: 14 * scale, color: AppColors.royalPurple.withValues(alpha: 0.6)),
          prefixIcon: Padding(
            padding: EdgeInsets.all(12 * scale),
            child: Image.asset('assets/icons/milk_icon.png', width: 22 * scale, height: 22 * scale),
          ),
          suffixIcon: controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    controller.clear();
                    onChanged('');
                  },
                  child: Icon(Icons.close_rounded, color: AppColors.neutralGrey, size: 20 * scale),
                )
              : const SizedBox.shrink(),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: EdgeInsets.only(top: top + 8, bottom: 14, left: 16, right: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            behavior: HitTestBehavior.opaque,
            child: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.vibrantPink, size: 20 * scale.clamp(0.85, 1.2)),
          ),
          Expanded(
            child: Text(
              'Favorites',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 20 * scale.clamp(0.85, 1.2), fontWeight: FontWeight.w700, color: AppColors.vibrantPink),
            ),
          ),
          SizedBox(width: 20 * scale),
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
                'assets/images/Empty-Cart-1--Streamline-Milano.png',
                width: 180 * scale.clamp(0.8, 1.2),
                height: 160 * scale.clamp(0.8, 1.2),
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
      color: AppColors.pureWhite,
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
          if (itemCount > 0)
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

// ── Filter Bottom Sheet ────────────────────────────────────────────
class _FilterSheet extends ConsumerWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sort = ref.watch(favoritesSortProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
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
          Text('Filter 01', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.black)),
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
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.clearGrey,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
              ),
              child: Text('Show Results', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.darkGrey)),
            ),
          ),
          const SizedBox(height: 8),
        ],
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
      builder: (_) => _AddToListSheet(scale: widget.scale),
    );
  }

  void _showAddToRecipeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddToRecipeSheet(scale: widget.scale),
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
                    ? Image.asset(widget.item.thumbnailAsset!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined, color: AppColors.neutralGrey))
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
  const _AddToListSheet({required this.scale});

  @override
  ConsumerState<_AddToListSheet> createState() => _AddToListSheetState();
}

class _AddToListSheetState extends ConsumerState<_AddToListSheet> {
  final Set<String> _selected = {'list1'};

  @override
  Widget build(BuildContext context) {
    final lists = ref.watch(shoppingListProvider);
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 24),
              Expanded(
                child: Text('Which shopping list do you want\nto add this product?', textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 16 * widget.scale, fontWeight: FontWeight.w700, color: AppColors.black)),
              ),
              GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close_rounded, color: AppColors.black, size: 24)),
            ],
          ),
          const SizedBox(height: 16),
          ...lists.asMap().entries.map((e) {
            final id = e.value.id;
            return _CheckRow(
              label: e.value.title.isEmpty ? 'Shopping List 0${e.key + 1}' : 'Shopping List 0${e.key + 1}',
              checked: _selected.contains(id),
              onChanged: (v) => setState(() => v! ? _selected.add(id) : _selected.remove(id)),
            );
          }),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.royalPurple, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50))),
              child: Text('Save On List', style: GoogleFonts.inter(fontSize: 15 * widget.scale, fontWeight: FontWeight.w600, color: AppColors.pureWhite)),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// ── Add to Recipe Sheet ───────────────────────────────────────────
class _AddToRecipeSheet extends ConsumerStatefulWidget {
  final double scale;
  const _AddToRecipeSheet({required this.scale});

  @override
  ConsumerState<_AddToRecipeSheet> createState() => _AddToRecipeSheetState();
}

class _AddToRecipeSheetState extends ConsumerState<_AddToRecipeSheet> {
  final Set<String> _selected = {'r1'};
  final _recipes = const [
    {'id': 'r1', 'name': 'Recipe 01'},
    {'id': 'r2', 'name': 'Recipe 02'},
    {'id': 'r3', 'name': 'Recipe 03'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 24),
              Expanded(
                child: Text('Which recipe do you want to add\nthis product?', textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 16 * widget.scale, fontWeight: FontWeight.w700, color: AppColors.black)),
              ),
              GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close_rounded, color: AppColors.black, size: 24)),
            ],
          ),
          const SizedBox(height: 16),
          ..._recipes.map((r) => _CheckRow(
            label: r['name']!,
            checked: _selected.contains(r['id']),
            onChanged: (v) => setState(() => v! ? _selected.add(r['id']!) : _selected.remove(r['id']!)),
          )),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.royalPurple, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50))),
              child: Text('Save On Recipe', style: GoogleFonts.inter(fontSize: 15 * widget.scale, fontWeight: FontWeight.w600, color: AppColors.pureWhite)),
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
        onPressed: () => context.go('/profile'),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.royalPurple, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50))),
        icon: Icon(Icons.add, color: AppColors.pureWhite, size: 20 * scale.clamp(0.85, 1.2)),
        label: Text('Add Products', style: GoogleFonts.inter(fontSize: 15 * scale.clamp(0.85, 1.2), fontWeight: FontWeight.w600, color: AppColors.pureWhite)),
      ),
    );
  }
}
