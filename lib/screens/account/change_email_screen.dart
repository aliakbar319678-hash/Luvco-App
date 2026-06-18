import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/change_email_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'verify_new_email_screen.dart'; // ← import added

// ─────────────────────────────────────────────────────────────────
// Change Email Screen — frames 1.6.8 & 1.6.9
// ─────────────────────────────────────────────────────────────────
class ChangeEmailScreen extends ConsumerStatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  ConsumerState<ChangeEmailScreen> createState() =>
      _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends ConsumerState<ChangeEmailScreen> {
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passwordCtrl;
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController();
    _passwordCtrl = TextEditingController();
    _emailFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ChangeEmailState state = ref.watch(changeEmailProvider);
    final ChangeEmailNotifier notifier =
        ref.read(changeEmailProvider.notifier);
    final userProfileAsync = ref.watch(userProfileProvider);
    final actualEmail = userProfileAsync.maybeWhen(
      data: (user) => user.email,
      orElse: () => 'test@email.com',
    );
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final scale = size.width / 390;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColors.pageBackground,
        body: Column(
          children: [
            // ── Header ──────────────────────────────────────────
            _ChangeEmailHeader(
              padding: padding,
              scale: scale,
              size: size,
            ),

            // ── Scrollable body ──────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.058,
                  vertical: 28,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Title ──
                    Text(
                      'Change Email',
                      style: GoogleFonts.inter(
                        fontSize: 26 * scale.clamp(0.85, 1.2),
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ── Subtitle ──
                    Text(
                      'Your actual email is $actualEmail. What email do you want to replace it with?',
                      style: GoogleFonts.inter(
                        fontSize: 13 * scale.clamp(0.85, 1.2),
                        color: AppColors.darkGrey,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Email label ──
                    _FieldLabel(label: 'Email', scale: scale),
                    const SizedBox(height: 8),

                    // ── Email input ──
                    _EmailInputField(
                      controller: _emailCtrl,
                      focusNode: _emailFocus,
                      hint: 'Enter your email',
                      scale: scale,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: notifier.setEmail,
                    ),

                    const SizedBox(height: 20),

                    // ── Password section label ──
                    Text(
                      'Enter your password to continue:',
                      style: GoogleFonts.inter(
                        fontSize: 13 * scale.clamp(0.85, 1.2),
                        color: AppColors.darkGrey,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ── Password label ──
                    _FieldLabel(label: 'Password', scale: scale),
                    const SizedBox(height: 8),

                    // ── Password input ──
                    _EmailInputField(
                      controller: _passwordCtrl,
                      focusNode: _passwordFocus,
                      hint: 'Enter your password',
                      scale: scale,
                      obscureText: !state.isPasswordVisible,
                      onChanged: notifier.setPassword,
                      suffixIcon: GestureDetector(
                        onTap: notifier.togglePasswordVisibility,
                        child: Icon(
                          state.isPasswordVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.neutralGrey,
                          size: 20 * scale.clamp(0.85, 1.2),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ── Password hint row ──
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 14 * scale.clamp(0.85, 1.2),
                          color: AppColors.neutralGrey,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Use 8 or more characters with a mix of letters, numbers & symbols',
                            style: GoogleFonts.inter(
                              fontSize:
                                  11 * scale.clamp(0.85, 1.2),
                              color: AppColors.neutralGrey,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // ── Error message ──
                    if (state.errorMessage != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.errorRed,
                            size: 14 * scale.clamp(0.85, 1.2),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              state.errorMessage!,
                              style: GoogleFonts.inter(
                                fontSize: 12 * scale.clamp(0.85, 1.2),
                                color: AppColors.errorRed,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Continue button ──
                    _ContinueButton(
                      canContinue: state.canContinue,
                      isLoading: state.isLoading,
                      scale: scale,
                      size: size,
                      onTap: () async {
                        final ok =
                            await notifier.continueToVerify();
                        if (ok && context.mounted) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => VerifyNewEmailScreen(
                                email: state.email,
                              ),
                            ),
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            const LuvcoBottomNavBar(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Header — back arrow + "Email" title in vibrantPink
// Matches frames 1.6.8 & 1.6.9
// ─────────────────────────────────────────────────────────────────
class _ChangeEmailHeader extends StatelessWidget {
  final EdgeInsets padding;
  final double scale;
  final Size size;

  const _ChangeEmailHeader({
    required this.padding,
    required this.scale,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: padding.top + 12,
        bottom: 16,
        left: size.width * 0.058,
        right: size.width * 0.058,
      ),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Back arrow ──
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.vibrantPink,
              size: 20 * scale.clamp(0.85, 1.2),
            ),
          ),
          const SizedBox(width: 8),

          // ── Title centered ──
          Expanded(
            child: Text(
              'Email',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 20 * scale.clamp(0.85, 1.2),
                fontWeight: FontWeight.w700,
                color: AppColors.vibrantPink,
              ),
            ),
          ),

          // ── Balance spacer ──
          SizedBox(width: 28 * scale.clamp(0.85, 1.2)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Field label
// ─────────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String label;
  final double scale;

  const _FieldLabel({required this.label, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 14 * scale.clamp(0.85, 1.2),
        fontWeight: FontWeight.w500,
        color: AppColors.black,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Input field — email and password
// Purple border on focus, grey on idle
// ─────────────────────────────────────────────────────────────────
class _EmailInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final double scale;
  final TextInputType keyboardType;
  final bool obscureText;
  final ValueChanged<String> onChanged;
  final Widget? suffixIcon;

  const _EmailInputField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.scale,
    required this.onChanged,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final fieldHeight = (size.height * 0.062).clamp(48.0, 58.0);

    final defaultBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(
          color: AppColors.inputBorder, width: 1.0),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(
          color: AppColors.royalPurple, width: 1.5),
    );

    return SizedBox(
      height: fieldHeight,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        obscureText: obscureText,
        keyboardType: keyboardType,
        cursorColor: AppColors.royalPurple,
        style: GoogleFonts.inter(
          fontSize: 14 * scale.clamp(0.85, 1.2),
          color: AppColors.black,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            fontSize: 14 * scale.clamp(0.85, 1.2),
            color: AppColors.neutralGrey,
          ),
          filled: true,
          fillColor: AppColors.pureWhite,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
          border: defaultBorder,
          enabledBorder: defaultBorder,
          focusedBorder: focusedBorder,
          suffixIcon: suffixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: suffixIcon,
                )
              : null,
          suffixIconConstraints: const BoxConstraints(
              minWidth: 40, minHeight: 40),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Continue button
// Disabled: faint pink bg + lightRoyalPurple text
// Enabled: royalPurple bg + white text + chevron right
// ─────────────────────────────────────────────────────────────────
class _ContinueButton extends StatelessWidget {
  final bool canContinue;
  final bool isLoading;
  final double scale;
  final Size size;
  final VoidCallback onTap;

  const _ContinueButton({
    required this.canContinue,
    required this.isLoading,
    required this.scale,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final height = (size.height * 0.062).clamp(48.0, 58.0);

    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: (canContinue && !isLoading) ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canContinue
              ? AppColors.royalPurple
              : AppColors.faintPink,
          disabledBackgroundColor: AppColors.faintPink,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continue',
                    style: GoogleFonts.inter(
                      fontSize: 16 * scale.clamp(0.85, 1.3),
                      fontWeight: FontWeight.w600,
                      color: canContinue
                          ? AppColors.pureWhite
                          : AppColors.lightRoyalPurple,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: canContinue
                        ? AppColors.pureWhite
                        : AppColors.lightRoyalPurple,
                    size: 22 * scale.clamp(0.85, 1.2),
                  ),
                ],
              ),
      ),
    );
  }
}
