import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import 'luvco_logo.dart';

class AuthHeader extends StatelessWidget {
  final String? title;
  final bool showLogo;
  final bool showBackButton;
  final Color titleColor;
  final VoidCallback? onBackTap;

  const AuthHeader({
    super.key,
    this.title,
    this.showLogo = false,
    this.showBackButton = true,
    this.titleColor = AppColors.royalPurple,
    this.onBackTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final headerHeight = showLogo ? size.height * 0.14 : size.height * 0.085;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: padding.top),
          SizedBox(
            height: headerHeight,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (showBackButton)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: onBackTap ?? () => context.pop(),
                        child: Icon(
                          Icons.chevron_left_rounded,
                          color: titleColor,
                          size: 28,
                        ),
                      ),
                    ),
                  if (showLogo)
                    Center(
                      child: LuvcoLogo(
                        width: size.width * 0.38,
                        color: LuvcoLogoColor.pink,
                      ),
                    )
                  else if (title != null)
                    Text(
                      title!,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
