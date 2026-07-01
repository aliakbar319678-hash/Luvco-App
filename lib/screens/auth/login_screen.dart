import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luvco_logo/core/theme/app_colors.dart';
import 'package:luvco_logo/core/theme/app_text_styles.dart';
import 'package:luvco_logo/models/auth_model.dart';
import 'package:luvco_logo/providers/auth_provider.dart';
import 'package:luvco_logo/widgets/luvco_button.dart';
import 'package:luvco_logo/widgets/luvco_text_field.dart';
import 'package:luvco_logo/widgets/auth_header.dart';
import 'package:luvco_logo/widgets/auth_error_row.dart';

// Provider to track if the password field is being typed
final passwordTypingProvider = StateProvider<bool>((ref) => false);
// Provider to hold a debouncing timer for typing detection
final passwordTypingTimerProvider = StateProvider<Timer?>((ref) => null);

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final loginState = ref.watch(loginProvider);
    final isLoading = loginState.status == LoginStatus.loading;
    final hasError = loginState.hasError;

    // Navigate to onboarding on success
    ref.listen<LoginState>(loginProvider, (previous, next) {
      if (next.status == LoginStatus.success) {
        context.go('/onboarding');
      }
    });

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
            // ── White header card with logo ──
            const AuthHeader(
              showLogo: true,
              showBackButton: false,
            ),

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

                    // ── Password field (wrapped in Consumer to avoid rebuilding the whole screen on toggle/typing status) ──
                    Consumer(
                      builder: (context, ref, child) {
                        final obscure = ref.watch(obscurePasswordProvider);
                        final isTyping = ref.watch(passwordTypingProvider);
                        
                        return LuvcoTextField(
                          label: 'Password',
                          hintText: 'Password',
                          obscureText: obscure,
                          keyboardType: TextInputType.visiblePassword,
                          hasError: hasError,
                          onChanged: (v) {
                            ref.read(passwordProvider.notifier).state = v;
                            // start typing detection
                            ref.read(passwordTypingProvider.notifier).state = true;
                            // cancel previous timer
                            ref.read(passwordTypingTimerProvider.notifier).state?.cancel();
                            // debounce - after 800ms set typing false
                            ref.read(passwordTypingTimerProvider.notifier).state = Timer(const Duration(milliseconds: 800), () {
                              ref.read(passwordTypingProvider.notifier).state = false;
                            });
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
                                   : isTyping
                                       ? Colors.black
                                       : AppColors.neutralGrey,
                              size: 20,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 8),

                    // ── Error message row (visible only on error) ──
                    if (hasError) ...[
                      AuthErrorRow(
                        message: loginState.errorMessage ??
                            "We don't recognize the email or password",
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
        ),
      ),
    );
  }
}
