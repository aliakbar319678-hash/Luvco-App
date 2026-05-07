import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../models/shopping_list_model.dart';

class ShoppingListListCard extends StatelessWidget {
  final ShoppingListModel list;
  final VoidCallback onMoreTap;

  const ShoppingListListCard({
    super.key,
    required this.list,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final scale = size.width / 390;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // ── Thumbnail ──
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 60,
                height: 60,
                color: AppColors.softGrey,
                child: list.imageUrl != null
                    ? (list.imageUrl!.startsWith('http')
                        ? Image.network(list.imageUrl!, fit: BoxFit.cover)
                        : Image.asset(list.imageUrl!, fit: BoxFit.cover))
                    : Icon(
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
                children: [
                  // Item count + "..." row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          list.title,
                          style: GoogleFonts.inter(
                            fontSize: 13 * scale.clamp(0.85, 1.2),
                            fontWeight: FontWeight.w600,
                            color: AppColors.vibrantPink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${list.itemCount} Items',
                        style: GoogleFonts.inter(
                          fontSize: 10 * scale.clamp(0.85, 1.2),
                          color: AppColors.neutralGrey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Text(
                    list.description,
                    style: GoogleFonts.inter(
                      fontSize: 11 * scale.clamp(0.85, 1.2),
                      color: AppColors.darkGrey,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // ── More button ──
            GestureDetector(
              onTap: onMoreTap,
              child: Icon(
                Icons.more_horiz,
                color: AppColors.darkGrey,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
