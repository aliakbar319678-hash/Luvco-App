import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/luvco_button.dart';
import '../../widgets/onboarding_progress_bar.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final scale = size.width / 390;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.pureWhite,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.058),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: size.height * 0.022),

                // ── Progress bar — step 1 of 3 active ──
                const OnboardingProgressBar(totalSteps: 3, currentStep: 1),

                SizedBox(height: size.height * 0.048),

                // ── Heading ──
                Text(
                  'Welcome to Luvco!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 24 * scale.clamp(0.85, 1.3),
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                    height: 1.2,
                  ),
                ),

                SizedBox(height: size.height * 0.014),

                // ── Subtitle ──
                Text(
                  'Dictum sed blandit venenatis consequat cras volutpat sit risus purus. Egestas nibh est rhoncus sodales.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14 * scale.clamp(0.85, 1.3),
                    fontWeight: FontWeight.w400,
                    color: AppColors.darkGrey,
                    height: 1.5,
                  ),
                ),

                SizedBox(height: size.height * 0.04),

                // ── Illustration ──
                Expanded(
                  child: Center(child: _OnboardingIllustration(size: size)),
                ),

                SizedBox(height: size.height * 0.04),

                // ── Next button ──
                LuvcoButton(
                  label: 'Next',
                  onTap: () => context.push('/onboarding/diet'),
                ),

                SizedBox(height: size.height * 0.018),

                // ── Skip button ──
                LuvcoButton(
                  label: 'Skip',
                  style: LuvcoButtonStyle.outlined,
                  onTap: () => context.go('/profile'),
                ),

                SizedBox(height: size.height * 0.04),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Illustration placeholder — person thinking with laptop & icons
// Replace with your actual SVG/image asset
// ─────────────────────────────────────────────────────────────────
class _OnboardingIllustration extends StatelessWidget {
  final Size size;
  const _OnboardingIllustration({required this.size});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/onboard_image.png',
      width: size.width * 0.8,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Container(
        width: size.width * 0.72,
        height: size.width * 0.72,
        decoration: BoxDecoration(
          color: AppColors.softGrey,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.image_not_supported_outlined),
      ),
    );
  }
}
