import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:luvco_logo/core/theme/app_colors.dart';

class LabelCircle extends StatelessWidget {
  final String label;
  final double scale;

  const LabelCircle({
    super.key,
    required this.label,
    required this.scale,
  });

  static (IconData, Color) _getIconAndColor(String name) {
    final lower = name.toLowerCase();

    // Placeholder fallbacks
    if (lower.contains('no allergens')) {
      return (Icons.health_and_safety_rounded, const Color(0xFF4CAF50)); // Green
    }
    if (lower.contains('none listed')) {
      return (Icons.info_outline_rounded, const Color(0xFF9E9E9E)); // Grey
    }

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
      return (Icons.check_circle_outline_rounded, const Color(0xFF009688)); // Teal Outline
    }
    if (lower.contains('fair trade') || lower.contains('fairtrade')) {
      return (Icons.handshake_rounded, const Color(0xFF00897B)); // Teal
    }
    if (lower.contains('no additives')) {
      return (Icons.verified, const Color(0xFF7B52D3)); // Purple badge
    }

    return (Icons.verified, const Color(0xFF7B52D3)); // Purple accent fallback
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
    final s = scale.clamp(0.85, 1.2);

    return SizedBox(
      width: 70 * s,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56 * s,
            height: 56 * s,
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.clearGrey, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                iconData,
                size: 26 * s,
                color: iconColor,
              ),
            ),
          ),
          SizedBox(height: 8 * s),
          Text(
            clean,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 10 * s,
              color: AppColors.black,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
