import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';

import '../../core/theme/app_colors.dart';
import '../../models/shopping_list_model.dart';
import '../../providers/shopping_list_provider.dart';
import '../../providers/shopping_list_detail_provider.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'product_detail_sheet.dart';

class SearchProductScreen extends ConsumerStatefulWidget {
  final String listId;

  const SearchProductScreen({super.key, required this.listId});

  @override
  ConsumerState<SearchProductScreen> createState() => _SearchProductScreenState();
}

class _SearchProductScreenState extends ConsumerState<SearchProductScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _isSearching = _searchController.text.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final scale = size.width / 390;
    final lists = ref.watch(shoppingListProvider);
    final listTitle = lists.firstWhere(
      (l) => l.id == widget.listId,
      orElse: () => const ShoppingListModel(id: '', title: 'Name\'s List', description: '', itemCount: 0),
    ).title;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: Column(
          children: [
            // ── Top Bar ──
            _SearchTopBar(listTitle: listTitle, scale: scale),

            // ── Search Input ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: _SearchBar(
                controller: _searchController,
                onChanged: (_) => _onSearchChanged(),
                scale: scale,
              ),
            ),

            // ── Body ──
            Expanded(
              child: !_isSearching
                  ? _RecentSearches(scale: scale)
                  : _SearchResults(scale: scale, listId: widget.listId),
            ),

            // ── Bottom Nav ──
            const LuvcoBottomNavBar(),
          ],
        ),
      ),
    );
  }
}

// ── Top Bar ──
class _SearchTopBar extends StatelessWidget {
  final String listTitle;
  final double scale;

  const _SearchTopBar({required this.listTitle, required this.scale});

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);

    return Container(
      padding: EdgeInsets.only(
        top: padding.top + 8,
        bottom: 12,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.vibrantPink,
                size: 20 * scale.clamp(0.85, 1.2),
              ),
            ),
          ),
          Expanded(
            child: Text(
              "$listTitle: Add Products",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 18 * scale.clamp(0.85, 1.2),
                fontWeight: FontWeight.w700,
                color: AppColors.vibrantPink,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 36), // Balance back button
        ],
      ),
    );
  }
}

// ── Search Bar ──
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final double scale;

  const _SearchBar({required this.controller, required this.onChanged, required this.scale});

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
          prefixIcon: Icon(Icons.search_rounded, color: AppColors.royalPurple, size: 22 * scale),
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

// ── Recent Searches ──
class _RecentSearches extends StatelessWidget {
  final double scale;

  const _RecentSearches({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return Column(
              children: [
                ListTile(
                  leading: Image.asset(
                    'assets/images/cruesli_image.png',
                    width: 24,
                    height: 24,
                    fit: BoxFit.cover,
                  ),
                  title: Text(
                    'Food Item 01',
                    style: GoogleFonts.inter(
                      fontSize: 14 * scale,
                      color: AppColors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (index < 2)
                  const Divider(height: 1, color: AppColors.clearGrey, indent: 16, endIndent: 16),
              ],
            );
          }),
        ),
      ),
    );
  }
}

// ── Search Results ──
class _SearchResults extends ConsumerWidget {
  final double scale;
  final String listId;

  const _SearchResults({required this.scale, required this.listId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mockResults = [
      _ProductResultData(
        item: const ShoppingListItem(
          id: 's1',
          name: 'Name of the Product',
          description: 'Other data from the product.',
          thumbnailAsset: 'assets/images/product_image.png',
        ),
        badge1Label: 'Unsustainable',
        badge1Color: const Color(0xFFE53935),
        badge1Icon: Icons.eco_outlined,
        badge2Label: 'Avoid',
        badge2Color: const Color(0xFFFFB300),
        badge2Icon: Icons.flag_outlined,
      ),
      _ProductResultData(
        item: const ShoppingListItem(
          id: 's2',
          name: 'Name of the Product',
          description: 'Other data from the product.',
          thumbnailAsset: 'assets/images/product_image.png',
        ),
        badge1Label: 'Moderate Impact',
        badge1Color: const Color(0xFFFFB300),
        badge1Icon: Icons.eco_outlined,
        badge2Label: 'Safe',
        badge2Color: const Color(0xFF43A047),
        badge2Icon: Icons.flag_outlined,
      ),
      _ProductResultData(
        item: const ShoppingListItem(
          id: 's3',
          name: 'Name of the Product',
          description: 'Other data from the product.',
          thumbnailAsset: 'assets/images/product_image.png',
        ),
        badge1Label: 'Eco-Friendly',
        badge1Color: const Color(0xFF43A047),
        badge1Icon: Icons.eco_outlined,
        badge2Label: 'Safe',
        badge2Color: const Color(0xFF43A047),
        badge2Icon: Icons.flag_outlined,
      ),
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
              Row(
                children: [
                  Icon(Icons.tune_rounded, size: 18 * scale, color: AppColors.darkGrey),
                  const SizedBox(width: 4),
                  Text(
                    'Filter',
                    style: GoogleFonts.inter(
                      fontSize: 13 * scale,
                      fontWeight: FontWeight.w500,
                      color: AppColors.darkGrey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            physics: const BouncingScrollPhysics(),
            itemCount: mockResults.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _ProductSearchCard(
                data: mockResults[index],
                scale: scale,
                listId: listId,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProductResultData {
  final ShoppingListItem item;
  final String badge1Label;
  final Color badge1Color;
  final IconData badge1Icon;
  final String badge2Label;
  final Color badge2Color;
  final IconData badge2Icon;

  _ProductResultData({
    required this.item,
    required this.badge1Label,
    required this.badge1Color,
    required this.badge1Icon,
    required this.badge2Label,
    required this.badge2Color,
    required this.badge2Icon,
  });
}

class _ProductSearchCard extends ConsumerStatefulWidget {
  final _ProductResultData data;
  final double scale;
  final String listId;

  const _ProductSearchCard({
    required this.data,
    required this.scale,
    required this.listId,
  });

  @override
  ConsumerState<_ProductSearchCard> createState() => _ProductSearchCardState();
}

class _ProductSearchCardState extends ConsumerState<_ProductSearchCard> {
  final CustomPopupMenuController _menuController = CustomPopupMenuController();

  @override
  void dispose() {
    _menuController.dispose();
    super.dispose();
  }

  void _showAddSuccess() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (_) => Dialog(
        backgroundColor: AppColors.pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF43A047), width: 3),
                ),
                child: const Icon(Icons.check_rounded, color: Color(0xFF43A047), size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                'Product added to the list!',
                style: GoogleFonts.inter(
                  fontSize: 16 * widget.scale,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _showConflictDialog() {
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
              Text(
                'This products is already\nadded to shopping list',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16 * widget.scale,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Do you want to still add it?',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13 * widget.scale,
                  fontWeight: FontWeight.w500,
                  color: AppColors.darkGrey,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _doAddProduct();
                    },
                    child: Text(
                      'Yes, Add It',
                      style: GoogleFonts.inter(
                        fontSize: 15 * widget.scale,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  Container(width: 1, height: 20, color: AppColors.clearGrey),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      'Don\'t Add',
                      style: GoogleFonts.inter(
                        fontSize: 15 * widget.scale,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFE53935),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _doAddProduct() {
    ref.read(shoppingListDetailProvider(widget.listId).notifier).addItem(widget.data.item);
    _showAddSuccess();
  }

  void _handleAddProduct() {
    final currentItems = ref.read(shoppingListDetailProvider(widget.listId)).items;
    final exists = currentItems.any((i) => i.name == widget.data.item.name);
    if (exists) {
      _showConflictDialog();
    } else {
      _doAddProduct();
    }
  }

  void _openDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductDetailSheet(
        item: widget.data.item,
        showAddButton: true,
        onAddTap: () {
          Navigator.pop(context);
          _handleAddProduct();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Badges ──
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: widget.data.badge1Color,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(widget.data.badge1Icon, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        widget.data.badge1Label,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12 * widget.scale,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: widget.data.badge2Color,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(widget.data.badge2Icon, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        widget.data.badge2Label,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12 * widget.scale,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Content ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Image
                Container(
                  width: 60 * widget.scale,
                  height: 60 * widget.scale,
                  decoration: BoxDecoration(
                    color: AppColors.softGrey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: widget.data.item.thumbnailAsset != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            widget.data.item.thumbnailAsset!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.image, color: AppColors.neutralGrey),
                          ),
                        )
                      : const Icon(Icons.image, color: AppColors.neutralGrey),
                ),
                const SizedBox(width: 16),
                
                // Texts
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.data.item.name,
                        style: GoogleFonts.inter(
                          fontSize: 14 * widget.scale,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.data.item.description,
                        style: GoogleFonts.inter(
                          fontSize: 12 * widget.scale,
                          color: AppColors.darkGrey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 8),

                // Menu
                CustomPopupMenu(
                  controller: _menuController,
                  pressType: PressType.singleClick,
                  barrierColor: Colors.transparent,
                  showArrow: false,
                  verticalMargin: -10,
                  horizontalMargin: 10,
                  menuBuilder: () => ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 220,
                      decoration: BoxDecoration(
                        color: AppColors.pureWhite,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 6)),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _MenuOption(
                            label: 'See More Details',
                            icon: Icons.remove_red_eye_outlined,
                            onTap: () {
                              _menuController.hideMenu();
                              _openDetails();
                            },
                          ),
                          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                          _MenuOption(
                            label: 'Add to this shopping list',
                            icon: Icons.shopping_bag_outlined,
                            onTap: () {
                              _menuController.hideMenu();
                              _handleAddProduct();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.more_horiz, color: AppColors.darkGrey),
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

class _MenuOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _MenuOption({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.black,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Icon(icon, size: 20, color: AppColors.black),
          ],
        ),
      ),
    );
  }
}
