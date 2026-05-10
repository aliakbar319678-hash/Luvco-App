import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../models/shopping_list_model.dart';

class ShoppingListListCard extends StatefulWidget {
  final ShoppingListModel list;
  final void Function(String action) onAction;

  const ShoppingListListCard({
    super.key,
    required this.list,
    required this.onAction,
  });

  @override
  State<ShoppingListListCard> createState() => _ShoppingListListCardState();
}

class _ShoppingListListCardState extends State<ShoppingListListCard> {
  final CustomPopupMenuController _menuController = CustomPopupMenuController();

  @override
  void dispose() {
    _menuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final scale = size.width / 390;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Thumbnail ──
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 64,
                height: 64,
                color: AppColors.softGrey,
                child: widget.list.imageUrl != null
                    ? (widget.list.imageUrl!.startsWith('http')
                        ? Image.network(widget.list.imageUrl!, fit: BoxFit.cover)
                        : Image.asset(widget.list.imageUrl!, fit: BoxFit.cover))
                    : const Icon(
                        Icons.image_outlined,
                        color: AppColors.neutralGrey,
                        size: 28,
                      ),
              ),
            ),

            const SizedBox(width: 12),

            // ── Content ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Row 1: Title + item-count + "..." ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          widget.list.title,
                          style: GoogleFonts.inter(
                            fontSize: 14 * scale.clamp(0.85, 1.2),
                            fontWeight: FontWeight.w700,
                            color: AppColors.vibrantPink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.list.itemCount} items',
                        style: GoogleFonts.inter(
                          fontSize: 10 * scale.clamp(0.85, 1.2),
                          color: AppColors.royalPurple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      // ── CustomPopupMenu "..." button ──
                      CustomPopupMenu(
                        controller: _menuController,
                        pressType: PressType.singleClick,
                        barrierColor: Colors.transparent,
                        showArrow: false,
                        verticalMargin: 2,
                        horizontalMargin: 8,
                        menuBuilder: () => _LuvcoContextMenu(
                          onSelected: (action) {
                            _menuController.hideMenu();
                            widget.onAction(action);
                          },
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          child: Icon(
                            Icons.more_horiz,
                            color: AppColors.darkGrey,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // ── Row 2: Description ──
                  Text(
                    widget.list.description,
                    style: GoogleFonts.inter(
                      fontSize: 12 * scale.clamp(0.85, 1.2),
                      color: AppColors.darkGrey.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w400,
                      height: 1.4,
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

// ─────────────────────────────────────────────────────────────────
// Shared Luvco Context Menu — matches Figma 1.3 exactly
// White card, rounded, 3 items with icons on the right side
// ─────────────────────────────────────────────────────────────────
class _LuvcoContextMenu extends StatelessWidget {
  final void Function(String action) onSelected;

  const _LuvcoContextMenu({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
