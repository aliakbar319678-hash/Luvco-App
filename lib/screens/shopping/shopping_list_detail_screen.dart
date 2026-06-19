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
import '../../widgets/luvco_dialog.dart';
import 'product_detail_sheet.dart';

class ShoppingListDetailScreen extends ConsumerWidget {
  final String listId;

  const ShoppingListDetailScreen({super.key, required this.listId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lists = ref.watch(shoppingListProvider);
    final list = lists.firstWhere(
      (l) => l.id == listId,
      orElse: () => const ShoppingListModel(
        id: '',
        title: 'List Title',
        description: 'Short description of the shopping list.',
        itemCount: 0,
      ),
    );
    final detailState = ref.watch(shoppingListDetailProvider(listId));
    final items = detailState.items;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: Column(
          children: [
            // ── Top bar ──
            _DetailTopBar(list: list, listId: listId, ref: ref),

            // ── Scrollable content ──
            Expanded(
              child: items.isEmpty
                  ? _EmptyBody(list: list)
                  : _ProductsBody(list: list, items: items, listId: listId),
            ),

            // ── Bottom Nav ──
            const LuvcoBottomNavBar(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Top Bar
// ─────────────────────────────────────────────────────────────────
class _DetailTopBar extends StatelessWidget {
  final ShoppingListModel list;
  final String listId;
  final WidgetRef ref;

  const _DetailTopBar({
    required this.list,
    required this.listId,
    required this.ref,
  });

  void _handleMoreAction(BuildContext context, String action) {
    if (action == 'edit') {
      _showEditDialog(context);
    } else if (action == 'duplicate') {
      _doDuplicate(context);
    } else if (action == 'delete') {
      _showDeleteDialog(context);
    }
  }

  void _showEditDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LuvcoEditListBottomSheet(
        initialTitle: list.title,
        initialDescription: list.description,
        onSave: (title, desc) {
          ref.read(shoppingListProvider.notifier).editList(listId, title, desc);
        },
      ),
    );
  }

  void _doDuplicate(BuildContext context) {
    ref.read(shoppingListProvider.notifier).duplicateList(listId);
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        Future.delayed(const Duration(seconds: 2), () {
          if (dialogContext.mounted) {
            Navigator.of(dialogContext).pop();
          }
        });
        return const LuvcoDuplicateSuccessOverlay();
      },
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => LuvcoDeleteConfirmDialog(
        listName: list.title,
        onDelete: () {
          ref.read(shoppingListProvider.notifier).deleteList(listId);
          if (context.mounted) context.pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final scale = size.width / 375; // Figma design width

    final totalHeight = 121 * scale;

    return Container(
      width: double.infinity,
      height: totalHeight,
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SizedBox(height: padding.top),
          Expanded(
            child: Row(
              children: [
                // Back button
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

                // Title
                Expanded(
                  child: Text(
                    list.title,
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

                // More (•••) button
                _MoreMenuButton(
                  onAction: (action) => _handleMoreAction(context, action),
                  scale: scale,
                ),
              ],
            ),
          ),
          SizedBox(height: 12 * scale),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// "•••" More menu button with inline popup
// ─────────────────────────────────────────────────────────────────
class _MoreMenuButton extends StatefulWidget {
  final void Function(String action) onAction;
  final double scale;

  const _MoreMenuButton({required this.onAction, required this.scale});

  @override
  State<_MoreMenuButton> createState() => _MoreMenuButtonState();
}

class _MoreMenuButtonState extends State<_MoreMenuButton> {
  final CustomPopupMenuController _menuController = CustomPopupMenuController();

  @override
  void dispose() {
    _menuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPopupMenu(
      controller: _menuController,
      pressType: PressType.singleClick,
      barrierColor: Colors.transparent,
      showArrow: false,
      verticalMargin: 2,
      horizontalMargin: 8,
      menuBuilder: () => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _ContextMenu(
          onSelected: (action) {
            _menuController.hideMenu();
            widget.onAction(action);
          },
        ),
      ),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        child: Icon(
          Icons.more_horiz,
          color: AppColors.vibrantPink,
          size: 22 * widget.scale.clamp(0.85, 1.2),
        ),
      ),
    );
  }
}

// Context popup — matches Figma 1.2.3
class _ContextMenu extends StatelessWidget {
  final void Function(String action) onSelected;

  const _ContextMenu({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(12),
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
          _MenuRow(
            label: 'Edit Lists Title',
            icon: Icons.edit_outlined,
            iconColor: AppColors.black,
            labelColor: AppColors.black,
            onTap: () => onSelected('edit'),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
          _MenuRow(
            label: 'Duplicate List',
            icon: Icons.content_copy_outlined,
            iconColor: AppColors.black,
            labelColor: AppColors.black,
            onTap: () => onSelected('duplicate'),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
          _MenuRow(
            label: 'Delete List',
            icon: Icons.delete_outline_rounded,
            iconColor: AppColors.errorRed,
            labelColor: AppColors.errorRed,
            onTap: () => onSelected('delete'),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color labelColor;
  final VoidCallback onTap;

  const _MenuRow({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.labelColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: labelColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Icon(icon, size: 18, color: iconColor),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Empty State Body — Figma 1.2.0
// ─────────────────────────────────────────────────────────────────
class _EmptyBody extends StatelessWidget {
  final ShoppingListModel list;

  const _EmptyBody({required this.list});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final scale = size.width / 390;

    return Column(
      children: [
        // List title + description card — separate rounded card
        _ListInfoCard(list: list, scale: scale, size: size),

        // Middle: centered empty illustration + text
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Empty cart illustration — transparent background, blends with page
              Image.asset(
                'assets/images/empty_cart_illustration.png',
                width: 180 * scale.clamp(0.8, 1.2),
                height: 160 * scale.clamp(0.8, 1.2),
                fit: BoxFit.contain,
                color: null, // no tint
                errorBuilder: (_, __, ___) => Icon(
                  Icons.shopping_cart_outlined,
                  size: 80 * scale.clamp(0.8, 1.2),
                  color: AppColors.neutralGrey,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'It looks like this list is\ncurrently empty.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15 * scale.clamp(0.85, 1.2),
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),

        // Add Products button — pinned at the bottom above nav bar
        Padding(
          padding: EdgeInsets.fromLTRB(
            size.width * 0.06,
            8,
            size.width * 0.06,
            16,
          ),
          child: _AddProductsButton(scale: scale, size: size, listId: list.id),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Products Body — Figma 1.2.1 / 1.2.2
// ─────────────────────────────────────────────────────────────────
class _ProductsBody extends ConsumerWidget {
  final ShoppingListModel list;
  final List<ShoppingListItem> items;
  final String listId;

  const _ProductsBody({
    required this.list,
    required this.items,
    required this.listId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final scale = size.width / 390;

    return Column(
      children: [
        // List title + description card
        _ListInfoCard(list: list, scale: scale, size: size),

        // Product list — scrollable
        Expanded(
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.04,
              vertical: 8,
            ),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 0),
            itemBuilder: (context, index) {
              final item = items[index];
              return _ProductListItem(
                item: item,
                scale: scale,
                onToggle: () => ref
                    .read(shoppingListDetailProvider(listId).notifier)
                    .toggleItem(item.id),
                onDelete: () => ref
                    .read(shoppingListDetailProvider(listId).notifier)
                    .removeItem(item.id),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => ProductDetailSheet(item: item),
                  );
                },
              );
            },
          ),
        ),

        // Add Products button — pinned above bottom nav
        Padding(
          padding: EdgeInsets.fromLTRB(
            size.width * 0.04,
            8,
            size.width * 0.04,
            12,
          ),
          child: _AddProductsButton(scale: scale, size: size, listId: listId),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Shared: List Info Card (title + description row at top)
// ─────────────────────────────────────────────────────────────────
class _ListInfoCard extends StatelessWidget {
  final ShoppingListModel list;
  final double scale;
  final Size size;

  const _ListInfoCard({
    required this.list,
    required this.scale,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        size.width * 0.06,
        24,
        size.width * 0.06,
        8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            list.title,
            style: GoogleFonts.inter(
              fontSize: 24 * scale.clamp(0.85, 1.2),
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            list.description,
            style: GoogleFonts.inter(
              fontSize: 14 * scale.clamp(0.85, 1.2),
              fontWeight: FontWeight.w400,
              color: AppColors.darkGrey,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Product List Item Row — Figma 1.2.1 / 1.2.2
// ─────────────────────────────────────────────────────────────────
class _ProductListItem extends StatelessWidget {
  final ShoppingListItem item;
  final double scale;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _ProductListItem({
    required this.item,
    required this.scale,
    required this.onToggle,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isChecked = item.isChecked;

    return AnimatedOpacity(
      opacity: isChecked ? 0.6 : 1.0,
      duration: const Duration(milliseconds: 250),
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.03,
          vertical: 12,
        ),
        decoration: const BoxDecoration(
          color: AppColors.pureWhite,
          border: Border(
            bottom: BorderSide(color: Color(0xFFF0F0F0), width: 1),
          ),
        ),
        child: Row(
          children: [
            // ── Checkbox ──
            GestureDetector(
              onTap: onToggle,
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 26 * scale.clamp(0.85, 1.2),
                height: 26 * scale.clamp(0.85, 1.2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isChecked ? AppColors.royalPurple : Colors.transparent,
                  border: Border.all(
                    color: isChecked
                        ? AppColors.royalPurple
                        : AppColors.neutralGrey,
                    width: 2,
                  ),
                ),
                child: isChecked
                    ? Icon(
                        Icons.check,
                        color: AppColors.pureWhite,
                        size: 14 * scale.clamp(0.85, 1.2),
                      )
                    : null,
              ),
            ),

            SizedBox(width: size.width * 0.03),

            // ── Thumbnail ──
            GestureDetector(
              onTap: onTap,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 56 * scale.clamp(0.85, 1.1),
                  height: 56 * scale.clamp(0.85, 1.1),
                  color: AppColors.softGrey,
                  child: item.thumbnailAsset != null
                      ? (item.thumbnailAsset!.startsWith('http')
                          ? Image.network(
                              item.thumbnailAsset!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.image_outlined,
                                color: AppColors.neutralGrey,
                                size: 24,
                              ),
                            )
                          : Image.asset(
                              item.thumbnailAsset!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.image_outlined,
                                color: AppColors.neutralGrey,
                                size: 24,
                              ),
                            ))
                      : const Icon(
                          Icons.image_outlined,
                          color: AppColors.neutralGrey,
                          size: 24,
                        ),
                ),
              ),
            ),

            SizedBox(width: size.width * 0.03),

            // ── Name + description ──
            Expanded(
              child: GestureDetector(
                onTap: onTap,
                behavior: HitTestBehavior.opaque,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                    style: GoogleFonts.inter(
                      fontSize: 14 * scale.clamp(0.85, 1.2),
                      fontWeight: FontWeight.w700,
                      color: AppColors.vibrantPink,
                      decoration: isChecked
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationColor: AppColors.vibrantPink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.description,
                    style: GoogleFonts.inter(
                      fontSize: 12 * scale.clamp(0.85, 1.2),
                      fontWeight: FontWeight.w400,
                      color: AppColors.darkGrey,
                      height: 1.4,
                      decoration: isChecked
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationColor: AppColors.darkGrey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),

          SizedBox(width: size.width * 0.02),

            // ── Delete icon ──
            GestureDetector(
              onTap: onDelete,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.neutralGrey,
                  size: 22 * scale.clamp(0.85, 1.2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Add Products Button — matches Figma (moderate rounded, NOT pill)
// ─────────────────────────────────────────────────────────────────
class _AddProductsButton extends StatelessWidget {
  final double scale;
  final Size size;
  final String listId;

  const _AddProductsButton({required this.scale, required this.size, required this.listId});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: (size.height * 0.062).clamp(48.0, 58.0),
      child: ElevatedButton.icon(
        onPressed: () {
          context.push('/search-product/$listId');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.royalPurple,
          elevation: 0,
          // Figma uses moderate rounding — NOT a full pill shape
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: Icon(
          Icons.add,
          color: AppColors.pureWhite,
          size: 20 * scale.clamp(0.85, 1.2),
        ),
        label: Text(
          'Add Products',
          style: GoogleFonts.inter(
            fontSize: 16 * scale.clamp(0.85, 1.3),
            fontWeight: FontWeight.w600,
            color: AppColors.pureWhite,
          ),
        ),
      ),
    );
  }
}
