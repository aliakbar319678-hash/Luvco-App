import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../models/shopping_list_model.dart';

class ShoppingListGridCard extends StatelessWidget {
  final ShoppingListModel list;
  final VoidCallback onMoreTap;

  const ShoppingListGridCard({
    super.key,
    required this.list,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final scale = size.width / 390;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image + "..." menu row ──
          Stack(
            children: [
              // Image placeholder
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
                child: Container(
                  width: double.infinity,
                  height: size.width * 0.22,
                  color: AppColors.softGrey,
                  child: list.imageUrl != null
                      ? (list.imageUrl!.startsWith('http')
                          ? Image.network(list.imageUrl!, fit: BoxFit.cover)
                          : Image.asset(list.imageUrl!, fit: BoxFit.cover))
                      : Center(
                          child: Icon(
                            Icons.image_outlined,
                            color: AppColors.neutralGrey,
                            size: 32 * scale,
                          ),
                        ),
                ),
              ),
              // "..." more button
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: onMoreTap,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.more_horiz,
                      color: AppColors.darkGrey,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Item count badge ──
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${list.itemCount} Items',
                    style: GoogleFonts.inter(
                      fontSize: 10 * scale.clamp(0.85, 1.2),
                      color: AppColors.neutralGrey,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(height: 2),

                // ── Title ──
                Text(
                  list.title,
                  style: GoogleFonts.inter(
                    fontSize: 13 * scale.clamp(0.85, 1.2),
                    fontWeight: FontWeight.w600,
                    color: AppColors.vibrantPink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),

                // ── Description ──
                Text(
                  list.description,
                  style: GoogleFonts.inter(
                    fontSize: 11 * scale.clamp(0.85, 1.2),
                    color: AppColors.darkGrey,
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
    );
  }
}
