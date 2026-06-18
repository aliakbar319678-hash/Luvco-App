import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/modify_password_provider.dart';
import '../../widgets/bottom_nav_bar.dart';

// ─────────────────────────────────────────────────────────────────
// Modify Password Screen — frames 1.6.14 → 1.6.18, 1.6.24
// ─────────────────────────────────────────────────────────────────
class ModifyPasswordScreen extends ConsumerStatefulWidget {
  const ModifyPasswordScreen({super.key});

  @override
  ConsumerState<ModifyPasswordScreen> createState() =>
      _ModifyPasswordScreenState();
}

class _ModifyPasswordScreenState extends ConsumerState<ModifyPasswordScreen> {
  late final TextEditingController _currentCtrl;
  late final TextEditingController _newCtrl;
  late final TextEditingController _confirmCtrl;

  final FocusNode _currentFocus = FocusNode();
  final FocusNode _newFocus = FocusNode();
  final FocusNode _confirmFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentCtrl = TextEditingController();
    _newCtrl = TextEditingController();
    _confirmCtrl = TextEditingController();

    _currentFocus.addListener(() => setState(() {}));
    _newFocus.addListener(() => setState(() {}));
    _confirmFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    _currentFocus.dispose();
    _newFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(modifyPasswordProvider);
    final notifier = ref.read(modifyPasswordProvider.notifier);
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final scale = (size.width / 390).clamp(0.8, 1.3);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColors.pageBackground,
        body: Stack(
          children: [
            Column(
              children: [
                // ── Header ──
                _PasswordHeader(
                  padding: padding,
                  scale: scale,
                  size: size,
                ),

                // ── Scrollable body ──
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
                          'Modify Password',
                          style: GoogleFonts.inter(
                            fontSize: 22 * scale,
                            fontWeight: FontWeight.w700,
                            color: AppColors.black,
                          ),
                        ),

                        const SizedBox(height: 6),

                        // ── Subtitle ──
                        Text(
                          'Lorem ipsum dolor sit amet, consectetur\nadipiscing elit, sed do eiusmod.',
                          style: GoogleFonts.inter(
                            fontSize: 13 * scale,
                            fontWeight: FontWeight.w400,
                            color: AppColors.darkGrey,
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ── Current Password ──
                        _FieldLabel(
                          label: 'Current Password',
                          hasError: state.currentError !=
                              PasswordFieldError.none,
                          scale: scale,
                        ),
                        const SizedBox(height: 8),
                        _PasswordField(
                          controller: _currentCtrl,
                          focusNode: _currentFocus,
                          hint: 'Current Password',
                          obscureText: state.obscureCurrent,
                          hasError: state.currentError !=
                              PasswordFieldError.none,
                          isFocused: _currentFocus.hasFocus,
                          scale: scale,
                          size: size,
                          onChanged: notifier.setCurrentPassword,
                          onToggleObscure: notifier.toggleObscureCurrent,
                        ),
                        if (state.currentError ==
                            PasswordFieldError.wrongCurrent)
                          _ErrorRow(
                            message: 'Wrong password. Try again.',
                            scale: scale,
                          ),

                        const SizedBox(height: 20),

                        // ── New Password ──
                        _FieldLabel(
                          label: 'New Password',
                          hasError: state.newError != PasswordFieldError.none,
                          scale: scale,
                        ),
                        const SizedBox(height: 8),
                        _PasswordField(
                          controller: _newCtrl,
                          focusNode: _newFocus,
                          hint: 'At least 8 characters',
                          obscureText: state.obscureNew,
                          hasError: state.newError != PasswordFieldError.none,
                          isFocused: _newFocus.hasFocus,
                          scale: scale,
                          size: size,
                          onChanged: notifier.setNewPassword,
                          onToggleObscure: notifier.toggleObscureNew,
                        ),
                        if (state.newError == PasswordFieldError.weakNew)
                          _ErrorRow(
                            message:
                                'Password must include 8 or more characters with\na mix of letters, numbers & symbols',
                            scale: scale,
                          ),

                        const SizedBox(height: 20),

                        // ── Confirm Password ──
                        _FieldLabel(
                          label: 'Confirm Password',
                          hasError: state.confirmError !=
                              PasswordFieldError.none,
                          scale: scale,
                        ),
                        const SizedBox(height: 8),
                        _PasswordField(
                          controller: _confirmCtrl,
                          focusNode: _confirmFocus,
                          hint: 'At least 8 characters',
                          obscureText: state.obscureConfirm,
                          hasError: state.confirmError !=
                              PasswordFieldError.none,
                          isFocused: _confirmFocus.hasFocus,
                          scale: scale,
                          size: size,
                          onChanged: notifier.setConfirmPassword,
                          onToggleObscure: notifier.toggleObscureConfirm,
                        ),
                        if (state.confirmError == PasswordFieldError.mismatch)
                          _ErrorRow(
                            message: "Password doesn't match",
                            scale: scale,
                          ),

                        // bottom padding so button doesn't cover content
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),

                const LuvcoBottomNavBar(),
              ],
            ),

            // ── Sticky Save Changes button ──
            Positioned(
              left: 0,
              right: 0,
              bottom: 106 * scale,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.058,
                ),
                child: _SaveChangesButton(
                  state: state,
                  scale: scale,
                  size: size,
                  onTap: () => notifier.saveChanges(),
                ),
              ),
            ),

            // ── Success overlay (frame 1.6.24) ──
            if (state.saveSuccess)
              _PasswordChangedOverlay(
                scale: scale,
                size: size,
                onDismiss: () {
                  if (context.mounted) {
                    notifier.dismissSuccess();
                    Navigator.of(context).pop();
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Header — back arrow + "Password" title in vibrantPink
// ─────────────────────────────────────────────────────────────────
class _PasswordHeader extends StatelessWidget {
  final EdgeInsets padding;
  final double scale;
  final Size size;

  const _PasswordHeader({
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
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            behavior: HitTestBehavior.opaque,
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.vibrantPink,
              size: 20 * scale,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Password',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 20 * scale,
                fontWeight: FontWeight.w700,
                color: AppColors.vibrantPink,
              ),
            ),
          ),
          // Balance spacer so title is truly centered
          SizedBox(width: 28 * scale),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Field label — normal black, turns red on error (frames 1.6.16–18)
// ─────────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String label;
  final bool hasError;
  final double scale;

  const _FieldLabel({
    required this.label,
    required this.hasError,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 14 * scale,
        fontWeight: FontWeight.w500,
        color: hasError ? AppColors.errorRed : AppColors.black,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Password input field
// — Default border: AppColors.inputBorder
// — Focused border: AppColors.royalPurple
// — Error border:   AppColors.errorRed + red background tint
// Matches frames 1.6.14, 1.6.15, 1.6.16, 1.6.17, 1.6.18
// ─────────────────────────────────────────────────────────────────
class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final bool obscureText;
  final bool hasError;
  final bool isFocused;
  final double scale;
  final Size size;
  final ValueChanged<String> onChanged;
  final VoidCallback onToggleObscure;

  const _PasswordField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.obscureText,
    required this.hasError,
    required this.isFocused,
    required this.scale,
    required this.size,
    required this.onChanged,
    required this.onToggleObscure,
  });

  @override
  Widget build(BuildContext context) {
    final fieldHeight = (size.height * 0.062).clamp(48.0, 58.0);

    // Border colors
    final borderColor = hasError
        ? AppColors.errorRed
        : isFocused
            ? AppColors.royalPurple
            : AppColors.inputBorder;
    final borderWidth = (hasError || isFocused) ? 1.5 : 1.0;

    final activeBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: borderColor, width: borderWidth),
    );

    // Fill: slight red tint on error to match Figma 1.6.16/1.6.17/1.6.18
    final fillColor = hasError
        ? const Color(0xFFFFF0F0)
        : AppColors.pureWhite;

    return SizedBox(
      height: fieldHeight,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        onChanged: onChanged,
        style: GoogleFonts.inter(
          fontSize: 14 * scale,
          color: AppColors.black,
          fontWeight: FontWeight.w400,
          letterSpacing: obscureText ? 2.0 : 0,
        ),
        cursorColor: AppColors.royalPurple,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            fontSize: 14 * scale,
            color: AppColors.neutralGrey,
            fontWeight: FontWeight.w400,
          ),
          filled: true,
          fillColor: fillColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: activeBorder,
          enabledBorder: activeBorder,
          focusedBorder: activeBorder,
          // Eye icon suffix
          suffixIcon: GestureDetector(
            onTap: onToggleObscure,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Icon(
                obscureText
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20 * scale,
                color: hasError
                    ? AppColors.errorRed
                    : AppColors.neutralGrey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Error row — warning icon + red message text
// Matches frames 1.6.16, 1.6.17, 1.6.18
// ─────────────────────────────────────────────────────────────────
class _ErrorRow extends StatelessWidget {
  final String message;
  final double scale;

  const _ErrorRow({required this.message, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: AppColors.errorRed,
            size: 15 * scale,
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 12 * scale,
                color: AppColors.errorRed,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Save Changes button
// — Disabled: faintPink bg + lightRoyalPurple text (frame 1.6.14)
// — Enabled:  royalPurple bg + white text (frame 1.6.15)
// ─────────────────────────────────────────────────────────────────
class _SaveChangesButton extends StatelessWidget {
  final ModifyPasswordState state;
  final double scale;
  final Size size;
  final VoidCallback onTap;

  const _SaveChangesButton({
    required this.state,
    required this.scale,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = state.canSave && !state.isSaving;

    return SizedBox(
      width: double.infinity,
      height: (size.height * 0.062).clamp(48.0, 58.0),
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled
              ? AppColors.royalPurple
              : AppColors.faintPink,
          disabledBackgroundColor: AppColors.faintPink,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
        child: state.isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                'Save Changes',
                style: GoogleFonts.inter(
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.w600,
                  color: enabled
                      ? AppColors.pureWhite
                      : AppColors.lightRoyalPurple,
                ),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Success overlay — frame 1.6.24
// Green circle check + title + subtitle
// Auto-dismiss after 2s then pop
// ─────────────────────────────────────────────────────────────────
class _PasswordChangedOverlay extends StatelessWidget {
  final double scale;
  final Size size;
  final VoidCallback onDismiss;

  const _PasswordChangedOverlay({
    required this.scale,
    required this.size,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) onDismiss();
    });

    return Positioned.fill(
      child: GestureDetector(
        onTap: onDismiss,
        child: Container(
          color: Colors.black.withValues(alpha: 0.18),
          child: Center(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: size.width * 0.12),
              padding: const EdgeInsets.symmetric(
                vertical: 32,
                horizontal: 24,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 24,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Green circle checkmark ──
                  Container(
                    width: 66 * scale,
                    height: 66 * scale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF43A047),
                        width: 2.5,
                      ),
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: const Color(0xFF43A047),
                      size: 38 * scale,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Title ──
                  Text(
                    'Your password has been\nchanged successfully!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 15 * scale,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                      height: 1.35,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ── Subtitle ──
                  Text(
                    'Ornare magna lectus id viverra\ndolor rhoncus nascetur',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12 * scale,
                      fontWeight: FontWeight.w400,
                      color: AppColors.neutralGrey,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}