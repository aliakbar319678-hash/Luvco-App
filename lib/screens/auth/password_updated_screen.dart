import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:luvco_logo/core/theme/app_colors.dart';
import 'package:luvco_logo/widgets/luvco_button.dart';
import 'package:luvco_logo/widgets/luvco_logo.dart';

class PasswordUpdatedScreen extends ConsumerWidget {
  const PasswordUpdatedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.pureWhite,
        body: SafeArea(
          child: Container(
            color: AppColors.pageBackground,
            child: Column(
              children: [
            // ── Header: white card + logo ──
            _ConfirmationHeader(size: size, padding: padding),

            // ── Centred confirmation content ──
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.058),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Big heading ──
                    Text(
                      'Your password has\nbeen update',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Subtitle ──
                    Text(
                      'A confirmation has been send to your email',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.darkGrey,
                        height: 1.4,
                      ),
                    ),

                    SizedBox(height: size.height * 0.048),

                    // ── Ok button → back to login ──
                    LuvcoButton(label: 'Ok', onTap: () => context.go('/login')),
                  ],
                ),
              ),
            ),
          ],
        ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Header: white card with rounded bottom + logo
// ─────────────────────────────────────────────────────────────────
class _ConfirmationHeader extends StatelessWidget {
  final Size size;
  final EdgeInsets padding;

  const _ConfirmationHeader({required this.size, required this.padding});

  @override
  Widget build(BuildContext context) {
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
          SizedBox(height: 12),
          LuvcoLogo(width: size.width * 0.32, color: LuvcoLogoColor.pink),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
