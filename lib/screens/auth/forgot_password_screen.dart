import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:luvco_logo/core/theme/app_colors.dart';
import 'package:luvco_logo/core/theme/app_text_styles.dart';
import 'package:luvco_logo/providers/forgot_password_provider.dart';
import 'package:luvco_logo/widgets/luvco_button.dart';
import 'package:luvco_logo/widgets/luvco_text_field.dart';

class ForgotPasswordScreen extends ConsumerWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final state = ref.watch(forgotPasswordProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: Column(
          children: [
            // ── Header: back arrow + "Recover Password" ──
            _ForgotHeader(size: size, padding: padding),

            // ── Scrollable content ──
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.058),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: size.height * 0.038),

                    // ── Heading ──
                    Text(
                      'Forgot Password',
                      style: AppTextStyles.heading1(context),
                    ),
                    const SizedBox(height: 8),

                    // ── Subtitle ──
                    Text(
                      "Enter the email associated with your account\nand we'll send a code to reset your password",
                      style: AppTextStyles.subtitle(context),
                    ),

                    SizedBox(height: size.height * 0.034),

                    // ── Email field ──
                    LuvcoTextField(
                      label: 'Email',
                      hintText: 'Enter your email',
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (v) =>
                          ref.read(forgotEmailProvider.notifier).state = v,
                    ),

                    SizedBox(height: size.height * 0.036),

                    // ── Reset Password button ──
                    LuvcoButton(
                      label: 'Reset Password',
                      isLoading: state.isLoading,
                      isDisabled: state.isSuccess,
                      onTap: () async {
                        final email = ref.read(forgotEmailProvider);
                        await ref
                            .read(forgotPasswordProvider.notifier)
                            .resetPassword(email);

                        // Navigate to OTP screen on success
                        if (ref.read(forgotPasswordProvider).isSuccess &&
                            context.mounted) {
                          context.push(
                            '/otp-verification?email=${Uri.encodeComponent(email)}',
                          );
                        }
                      },
                    ),

                    SizedBox(height: size.height * 0.04),
                  ],
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
// Forgot Password Header
// White card, rounded bottom corners, back arrow + pink title
// ─────────────────────────────────────────────────────────────────
class _ForgotHeader extends StatelessWidget {
  final Size size;
  final EdgeInsets padding;

  const _ForgotHeader({required this.size, required this.padding});

  @override
  Widget build(BuildContext context) {
    final headerHeight = size.height * 0.085;

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
              child: Row(
                children: [
                  // ── Back arrow ──
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      Icons.chevron_left,
                      color: AppColors.vibrantPink,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 6),

                  // ── Title ──
                  Text(
                    'Recover Password',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.vibrantPink,
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
