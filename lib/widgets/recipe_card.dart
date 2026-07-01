import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../models/recipe_model.dart';
import '../core/network/api_client.dart';

// ─────────────────────────────────────────────────────────────────
// Recipe Grid Card
// ─────────────────────────────────────────────────────────────────
class RecipeGridCard extends StatelessWidget {
  final RecipeModel recipe;
  final VoidCallback onMoreTap;
  final VoidCallback? onTap;

  const RecipeGridCard({
    super.key,
    required this.recipe,
    required this.onMoreTap,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.sizeOf(context).width / 390;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(16),
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
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1.1,
                    child: Builder(builder: (context) {
                      final url = recipe.imageUrl;
                      final resolvedUrl = ApiClient.instance.resolveImageUrl(url);
                      if (resolvedUrl.isEmpty) {
                        return Image.asset('assets/images/bread_pic.png', fit: BoxFit.cover);
                      }

                      if (resolvedUrl.startsWith('http')) {
                        return Image.network(
                          resolvedUrl, 
                          fit: BoxFit.cover, 
                          errorBuilder: (_, __, ___) => Image.asset('assets/images/bread_pic.png', fit: BoxFit.cover),
                        );
                      }
                      
                      return Image.asset(resolvedUrl, fit: BoxFit.cover);
                    }),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onMoreTap,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.more_horiz,
                        size: 16,
                        color: AppColors.darkGrey,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Info ──
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: GoogleFonts.inter(
                      fontSize: 15 * scale.clamp(0.85, 1.2),
                      fontWeight: FontWeight.w700,
                      color: AppColors.vibrantPink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    recipe.description,
                    style: GoogleFonts.inter(
                      fontSize: 12 * scale.clamp(0.85, 1.2),
                      color: AppColors.darkGrey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: recipe.dietTags
                          .map((tag) => Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: _DietTag(label: tag, scale: scale),
                              ))
                          .toList(),
                    ),
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
// Recipe List Card (horizontal)
// ─────────────────────────────────────────────────────────────────
class RecipeListCard extends StatelessWidget {
  final RecipeModel recipe;
  final VoidCallback onMoreTap;
  final VoidCallback? onTap;

  const RecipeListCard({
    super.key,
    required this.recipe,
    required this.onMoreTap,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.sizeOf(context).width / 390;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Thumbnail ──
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 80 * scale.clamp(0.85, 1.2),
                height: 80 * scale.clamp(0.85, 1.2),
                child: Builder(builder: (context) {
                  final url = recipe.imageUrl;
                  final resolvedUrl = ApiClient.instance.resolveImageUrl(url);
                  if (resolvedUrl.isEmpty) {
                    return Image.asset('assets/images/bread_pic.png', fit: BoxFit.cover);
                  }

                  if (resolvedUrl.startsWith('http')) {
                    return Image.network(
                      resolvedUrl, 
                      fit: BoxFit.cover, 
                      errorBuilder: (_, __, ___) => Image.asset('assets/images/bread_pic.png', fit: BoxFit.cover),
                    );
                  }
                  
                  return Image.asset(resolvedUrl, fit: BoxFit.cover);
                }),
              ),
            ),
            const SizedBox(width: 12),

            // ── Info ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: GoogleFonts.inter(
                      fontSize: 16 * scale.clamp(0.85, 1.2),
                      fontWeight: FontWeight.w700,
                      color: AppColors.vibrantPink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    recipe.description,
                    style: GoogleFonts.inter(
                      fontSize: 13 * scale.clamp(0.85, 1.2),
                      color: AppColors.darkGrey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: recipe.dietTags
                          .map((tag) => Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: _DietTag(label: tag, scale: scale),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),

            // ── More button ──
            GestureDetector(
              onTap: onMoreTap,
              child: const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.more_horiz,
                  color: AppColors.darkGrey,
                  size: 20,
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
// Shared diet label chip
// ─────────────────────────────────────────────────────────────────
class _DietTag extends StatelessWidget {
  final String label;
  final double scale;

  const _DietTag({required this.label, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.softGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.clearGrey),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 9 * scale.clamp(0.85, 1.2),
          fontWeight: FontWeight.w500,
          color: AppColors.darkGrey,
        ),
      ),
    );
  }
}
