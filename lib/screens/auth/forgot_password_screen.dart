import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luvco_logo/core/theme/app_colors.dart';
import 'package:luvco_logo/core/theme/app_text_styles.dart';
import 'package:luvco_logo/providers/forgot_password_provider.dart';
import 'package:luvco_logo/widgets/luvco_button.dart';
import 'package:luvco_logo/widgets/luvco_text_field.dart';
import 'package:luvco_logo/widgets/auth_header.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  @override
  void initState() {
    super.initState();
    // Reset the state when entering the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(forgotPasswordProvider.notifier).reset();
      ref.read(forgotEmailProvider.notifier).state = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final state = ref.watch(forgotPasswordProvider);

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
            // ── Header: back arrow + "Recover Password" ──
            const AuthHeader(
              title: 'Recover Password',
              titleColor: AppColors.vibrantPink,
            ),

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
                      onChanged: (v) {
                        ref.read(forgotEmailProvider.notifier).state = v;
                        // If we were in success state, reset so button becomes enabled again
                        if (ref.read(forgotPasswordProvider).isSuccess) {
                          ref.read(forgotPasswordProvider.notifier).reset();
                        }
                      },
                    ),

                    SizedBox(height: size.height * 0.036),

                    // ── Reset Password button ──
                    Consumer(
                      builder: (context, ref, child) {
                        final email = ref.watch(forgotEmailProvider);
                        final isDisabled = email.isEmpty || state.isSuccess;

                        return LuvcoButton(
                          label: 'Reset Password',
                          isLoading: state.isLoading,
                          isDisabled: isDisabled,
                          disabledBackgroundColor: AppColors.pureWhite,
                          disabledTextColor: AppColors.neutralGrey,
                          onTap: () async {
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
                        );
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
        ),
      ),
    );
  }
}
