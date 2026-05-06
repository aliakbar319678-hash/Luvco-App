import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final obscure = ref.watch(obscurePasswordProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F7), // light grey page bg
        body: Column(
          children: [
            // ── Top header card ──
            _LoginHeader(size: size, padding: padding),

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
                    Text('Log in', style: AppTextStyles.heading1(context)),

                    const SizedBox(height: 6),

                    // ── Subtitle ──
                    Text(
                      'Enter your credentials to access your account',
                      style: AppTextStyles.subtitle(context),
                    ),

                    SizedBox(height: size.height * 0.034),

                    // ── Email Field ──
                    LuvcoTextField(
                      label: 'Email',
                      hintText: 'Enter your email',
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (v) =>
                          ref.read(emailProvider.notifier).state = v,
                    ),

                    SizedBox(height: size.height * 0.022),

                    // ── Password Field ──
                    LuvcoTextField(
                      label: 'Password',
                      hintText: 'Password',
                      obscureText: obscure,
                      keyboardType: TextInputType.visiblePassword,
                      onChanged: (v) =>
                          ref.read(passwordProvider.notifier).state = v,
                      suffixIcon: GestureDetector(
                        onTap: () =>
                            ref.read(obscurePasswordProvider.notifier).state =
                                !obscure,
                        child: Icon(
                          obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.neutralGrey,
                          size: 20,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ── Forgot Password ──
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {},
                        child: Text(
                          'Forgot Password?',
                          style: AppTextStyles.link(context),
                        ),
                      ),
                    ),

                    SizedBox(height: size.height * 0.036),

                    // ── Log In Button ──
                    LuvcoButton(
                      label: 'Log In',
                      isLoading: isLoading,
                      onTap: () {
                        final email = ref.read(emailProvider);
                        final password = ref.read(passwordProvider);
                        ref
                            .read(loginProvider.notifier)
                            .login(AuthModel(email: email, password: password));
                      },
                    ),

                    SizedBox(height: size.height * 0.018),

                    // ── Sign Up Button ──
                    LuvcoButton(
                      label: 'Sign Up',
                      style: LuvcoButtonStyle.outlined,
                      onTap: () {},
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
// Login Header — white card, rounded bottom BOTH sides, soft shadow
// Matches Figma exactly: logo centered, curved bottom edge
// ─────────────────────────────────────────────────────────────────
class _LoginHeader extends StatelessWidget {
  final Size size;
  final EdgeInsets padding;

  const _LoginHeader({required this.size, required this.padding});

  @override
  Widget build(BuildContext context) {
    // Header height: status bar + logo area
    // Figma shows roughly 121px total at 375px width
    final headerHeight = size.height * 0.148;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        // ── Rounded on BOTH bottom corners (matches screenshot) ──
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        // ── Soft shadow at bottom of card ──
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status bar safe area
          SizedBox(height: padding.top),

          // Logo area
          SizedBox(
            height: headerHeight,
            child: Center(
              child: LuvcoLogo(
                width: size.width * 0.38,
                color: LuvcoLogoColor.pink,
              ),
            ),
          ),

          // Extra bottom breathing room before the curve
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
