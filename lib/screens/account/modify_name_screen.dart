import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/modify_name_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../widgets/bottom_nav_bar.dart';

// ─────────────────────────────────────────────────────────────────
// Modify Name Screen — frames 1.6.5 / 1.6.6 / 1.6.7
// ─────────────────────────────────────────────────────────────────
class ModifyNameScreen extends ConsumerStatefulWidget {
  const ModifyNameScreen({super.key});

  @override
  ConsumerState<ModifyNameScreen> createState() => _ModifyNameScreenState();
}

class _ModifyNameScreenState extends ConsumerState<ModifyNameScreen> {
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  final FocusNode _firstNameFocus = FocusNode();
  final FocusNode _lastNameFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final profileState = ref.read(userProfileProvider);
    final user = profileState.valueOrNull;
    if (user != null) {
      ref.read(modifyNameProvider.notifier).loadCurrentName(
        user.firstName ?? '',
        user.lastName ?? '',
      );
    }
    final state = ref.read(modifyNameProvider);
    _firstNameCtrl = TextEditingController(text: state.firstName);
    _lastNameCtrl = TextEditingController(text: state.lastName);

    // Rebuild on focus change so border color updates
    _firstNameFocus.addListener(() => setState(() {}));
    _lastNameFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(modifyNameProvider);
    final notifier = ref.read(modifyNameProvider.notifier);
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final scale = size.width / 390;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: Stack(
          children: [
            Column(
              children: [
                // ── Header ──
                _ModifyNameHeader(padding: padding, scale: scale, size: size),

                // ── Body ──
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
                          'Modify Name',
                          style: GoogleFonts.inter(
                            fontSize: 22 * scale.clamp(0.85, 1.2),
                            fontWeight: FontWeight.w700,
                            color: AppColors.black,
                          ),
                        ),

                        const SizedBox(height: 6),

                        // ── Subtitle ──
                        Text(
                          'Fill in the information to change your\naccount',
                          style: GoogleFonts.inter(
                            fontSize: 13 * scale.clamp(0.85, 1.2),
                            fontWeight: FontWeight.w400,
                            color: AppColors.darkGrey,
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ── First Name field ──
                        _NameFieldLabel(label: 'First Name', scale: scale),
                        const SizedBox(height: 8),
                        _NameInputField(
                          controller: _firstNameCtrl,
                          focusNode: _firstNameFocus,
                          hint: 'Jon',
                          scale: scale,
                          isFocused: _firstNameFocus.hasFocus,
                          onChanged: notifier.setFirstName,
                        ),

                        const SizedBox(height: 20),

                        // ── Last Name field ──
                        _NameFieldLabel(label: 'Last Name', scale: scale),
                        const SizedBox(height: 8),
                        _NameInputField(
                          controller: _lastNameCtrl,
                          focusNode: _lastNameFocus,
                          hint: 'Doe',
                          scale: scale,
                          isFocused: _lastNameFocus.hasFocus,
                          onChanged: notifier.setLastName,
                        ),

                        // ── Error message ──
                        if (state.errorMessage != null) ...[
                          const SizedBox(height: 16),
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
                        ],

                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),

                const LuvcoBottomNavBar(),
              ],
            ),

            // ── Sticky Save Changes button ──────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 106 * scale, // sits above bottom nav
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.058),
                child: _SaveChangesButton(
                  state: state,
                  scale: scale,
                  size: size,
                  onTap: () => notifier.saveChanges(),
                ),
              ),
            ),

            // ── Success overlay ──────────────────────────────────
            if (state.saveSuccess)
              _NameChangedOverlay(
                scale: scale,
                size: size,
                onDismiss: () {
                  notifier.dismissSuccess();
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Header — back arrow + "Name" title in vibrantPink
// Matches all 3 frames
// ─────────────────────────────────────────────────────────────────
class _ModifyNameHeader extends StatelessWidget {
  final EdgeInsets padding;
  final double scale;
  final Size size;

  const _ModifyNameHeader({
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
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.vibrantPink,
              size: 20 * scale.clamp(0.85, 1.2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Name',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 20 * scale.clamp(0.85, 1.2),
                fontWeight: FontWeight.w700,
                color: AppColors.vibrantPink,
              ),
            ),
          ),
          // Balance spacer
          SizedBox(width: 28 * scale.clamp(0.85, 1.2)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Field label
// ─────────────────────────────────────────────────────────────────
class _NameFieldLabel extends StatelessWidget {
  final String label;
  final double scale;

  const _NameFieldLabel({required this.label, required this.scale});

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
// Name input field
// — Default border: AppColors.inputBorder (grey)
// — Focused border: AppColors.royalPurple (purple) — matches 1.6.6
// ─────────────────────────────────────────────────────────────────
class _NameInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final double scale;
  final bool isFocused;
  final ValueChanged<String> onChanged;

  const _NameInputField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.scale,
    required this.isFocused,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final fieldHeight = (size.height * 0.062).clamp(48.0, 58.0);

    final defaultBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.inputBorder, width: 1.0),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.royalPurple, width: 1.5),
    );

    return SizedBox(
      height: fieldHeight,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        style: GoogleFonts.inter(
          fontSize: 14 * scale.clamp(0.85, 1.2),
          color: AppColors.black,
          fontWeight: FontWeight.w400,
        ),
        cursorColor: AppColors.royalPurple,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            fontSize: 14 * scale.clamp(0.85, 1.2),
            color: AppColors.neutralGrey,
            fontWeight: FontWeight.w400,
          ),
          filled: true,
          fillColor: AppColors.pureWhite,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: defaultBorder,
          enabledBorder: defaultBorder,
          focusedBorder: focusedBorder,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Save Changes button
// — Disabled (faint pink + light purple text) when firstName empty
// — Enabled (royalPurple filled + white text) when firstName filled
// Matches 1.6.5 (disabled) and 1.6.6 (enabled) exactly
// ─────────────────────────────────────────────────────────────────
class _SaveChangesButton extends StatelessWidget {
  final ModifyNameState state;
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
                  fontSize: 16 * scale.clamp(0.85, 1.3),
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
// Success overlay — frame 1.6.7
// Green circle check + "The name was changed sucessfully!"
// (typo "sucessfully" kept to match Figma exactly)
// Auto-dismiss after 2s then pop screen
// ─────────────────────────────────────────────────────────────────
class _NameChangedOverlay extends StatelessWidget {
  final double scale;
  final Size size;
  final VoidCallback onDismiss;

  const _NameChangedOverlay({
    required this.scale,
    required this.size,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    // Auto-dismiss after 2 seconds
    Future.delayed(const Duration(seconds: 2), onDismiss);

    return Positioned.fill(
      child: GestureDetector(
        onTap: onDismiss,
        child: Container(
          color: Colors.black.withValues(alpha: 0.18),
          child: Center(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: size.width * 0.14),
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
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
                    width: 66 * scale.clamp(0.85, 1.2),
                    height: 66 * scale.clamp(0.85, 1.2),
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
                      size: 38 * scale.clamp(0.85, 1.2),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Message — typo kept to match Figma ──
                  Text(
                    'The name was changed\nsucessfully!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 15 * scale.clamp(0.85, 1.2),
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                      height: 1.35,
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
