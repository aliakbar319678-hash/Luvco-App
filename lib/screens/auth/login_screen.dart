import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:luvco_logo/core/theme/app_colors.dart';
import 'package:luvco_logo/core/theme/app_text_styles.dart';
import 'package:luvco_logo/models/auth_model.dart';
import 'package:luvco_logo/providers/auth_provider.dart';
import 'package:luvco_logo/widgets/lucu_logo.dart';
import 'package:luvco_logo/widgets/luvco_button.dart';
import 'package:luvco_logo/widgets/luvco_text_field.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final loginState = ref.watch(loginProvider);
    final isLoading = loginState.status == LoginStatus.loading;
    final hasError = loginState.hasError;
    final obscure = ref.watch(obscurePasswordProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: Column(
          children: [
            // ── White header card with logo ──
            _LoginHeader(size: size, padding: padding),

            // ── Scrollable form content ──
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.058),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: size.height * 0.038),

                    // ── Heading ──
                    Text('Log in', style: AppTextStyles.heading1(context)),
                    const SizedBox(height: 6),

                    // ── Subtitle ──
                    Text(
                      'Enter your credentials to access your account',
                      style: AppTextStyles.subtitle(context),
                    ),

                    SizedBox(height: size.height * 0.034),

                    // ── Email field ──
                    LuvcoTextField(
                      label: 'Email',
                      hintText: 'Enter your email',
                      keyboardType: TextInputType.emailAddress,
                      hasError: hasError,
                      onChanged: (v) {
                        ref.read(emailProvider.notifier).state = v;
                        // Clear error as user starts retyping
                        if (hasError) ref.read(loginProvider.notifier).reset();
                      },
                    ),

                    SizedBox(height: size.height * 0.022),

                    // ── Password field ──
                    LuvcoTextField(
                      label: 'Password',
                      hintText: 'Password',
                      obscureText: obscure,
                      keyboardType: TextInputType.visiblePassword,
                      hasError: hasError,
                      onChanged: (v) {
                        ref.read(passwordProvider.notifier).state = v;
                        if (hasError) ref.read(loginProvider.notifier).reset();
                      },
                      suffixIcon: GestureDetector(
                        onTap: () =>
                            ref.read(obscurePasswordProvider.notifier).state =
                                !obscure,
                        child: Icon(
                          obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: hasError
                              ? AppColors.errorRed
                              : AppColors.neutralGrey,
                          size: 20,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ── Error message row (visible only on error) ──
                    if (hasError) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.errorRed,
                            size: 15,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            loginState.errorMessage ??
                                "We don't recognize the email or password",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.errorRed,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],

                    // ── Forgot Password link ──
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => context.push('/forgot-password'),
                        child: Text(
                          'Forgot Password?',
                          style: AppTextStyles.link(context),
                        ),
                      ),
                    ),

                    SizedBox(height: size.height * 0.036),

                    // ── Log In button (disabled on error state) ──
                    LuvcoButton(
                      label: 'Log In',
                      isLoading: isLoading,
                      isDisabled: hasError,
                      onTap: () {
                        final email = ref.read(emailProvider);
                        final password = ref.read(passwordProvider);
                        ref
                            .read(loginProvider.notifier)
                            .login(AuthModel(email: email, password: password));
                      },
                    ),

                    SizedBox(height: size.height * 0.018),

                    // ── Sign Up button ──
                    LuvcoButton(
                      label: 'Sign Up',
                      style: LuvcoButtonStyle.outlined,
                      onTap: () => context.push('/signup'),
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
// White header card — logo centered, rounded bottom corners
// ─────────────────────────────────────────────────────────────────
class _LoginHeader extends StatelessWidget {
  final Size size;
  final EdgeInsets padding;

  const _LoginHeader({required this.size, required this.padding});

  @override
  Widget build(BuildContext context) {
    final headerHeight = size.height * 0.148;

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
            child: Center(
              child: LuvcoLogo(
                width: size.width * 0.38,
                color: LuvcoLogoColor.pink,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
