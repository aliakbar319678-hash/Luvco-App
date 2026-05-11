import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────
// Edit List Dialog — matches Figma 1.4 & 1.5
// ─────────────────────────────────────────────────────────────────
class LuvcoEditListBottomSheet extends StatefulWidget {
  final String initialTitle;
  final String initialDescription;
  final void Function(String title, String description) onSave;

  const LuvcoEditListBottomSheet({
    super.key,
    required this.initialTitle,
    required this.initialDescription,
    required this.onSave,
  });

  @override
  State<LuvcoEditListBottomSheet> createState() => _LuvcoEditListBottomSheetState();
}

class _LuvcoEditListBottomSheetState extends State<LuvcoEditListBottomSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  bool _hasTitle = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _descController = TextEditingController(text: widget.initialDescription);
    _hasTitle = widget.initialTitle.trim().isNotEmpty;
    _titleController.addListener(_onTitleChanged);
  }

  void _onTitleChanged() {
    final hasText = _titleController.text.trim().isNotEmpty;
    if (hasText != _hasTitle) {
      setState(() => _hasTitle = hasText);
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTitleChanged);
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final scale = size.width / 390;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: 20 + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Do you want to edit the list\ninformation?',
                  style: GoogleFonts.inter(
                    fontSize: 16 * scale.clamp(0.85, 1.2),
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                    height: 1.35,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.close, color: AppColors.black, size: 22),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── List Title label + field ──
          Text(
            'List Title',
            style: GoogleFonts.inter(
              fontSize: 13 * scale.clamp(0.85, 1.2),
              fontWeight: FontWeight.w700, // Make it bolder
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 8),
          _LuvcoTextField(
            controller: _titleController,
            hint: 'My weekend shopping list',
          ),

          const SizedBox(height: 14),

          // ── Description label + field ──
          Text(
            'Description',
            style: GoogleFonts.inter(
              fontSize: 13 * scale.clamp(0.85, 1.2),
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 8),
          _LuvcoTextField(
            controller: _descController,
            hint: 'Short description of the shopping list.',
          ),

          const SizedBox(height: 24),

          // ── Save Changes button ──
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: _hasTitle
                  ? const Color(0xFFFFF0F5) // light pink background
                  : const Color(0xFFFFF0F5).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(50),
                onTap: _hasTitle
                    ? () {
                        widget.onSave(
                          _titleController.text.trim(),
                          _descController.text.trim(),
                        );
                        Navigator.of(context).pop();
                      }
                    : null,
                child: Center(
                  child: Text(
                    'Save Changes',
                    style: GoogleFonts.inter(
                      fontSize: 15 * scale.clamp(0.85, 1.2),
                      fontWeight: FontWeight.w600,
                      color: _hasTitle
                          ? const Color(0xFFA39A9A) // slightly dark grayish pink
                          : const Color(0xFFA39A9A).withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────
// Delete Confirmation Dialog — matches Figma 1.7
// ─────────────────────────────────────────────────────────────────
class LuvcoDeleteConfirmDialog extends StatelessWidget {
  final String listName;
  final VoidCallback onDelete;

  const LuvcoDeleteConfirmDialog({
    super.key,
    required this.listName,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final scale = size.width / 390;

    return Dialog(
      backgroundColor: AppColors.pureWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Question
            Text(
              'Do you want to delete "$listName"?',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16 * scale.clamp(0.85, 1.2),
                fontWeight: FontWeight.w700,
                color: AppColors.black,
                height: 1.35,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'Lorem ipsum dolor sit amet,\nconsectetur adipiscing elit.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13 * scale.clamp(0.85, 1.2),
                color: AppColors.darkGrey,
                height: 1.45,
              ),
            ),

            const SizedBox(height: 24),

            // Cancel / Delete row
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontSize: 15 * scale.clamp(0.85, 1.2),
                          fontWeight: FontWeight.w600,
                          color: AppColors.vibrantPink,
                        ),
                      ),
                    ),
                  ),
                ),
                Container(width: 1, height: 22, color: AppColors.clearGrey),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      onDelete();
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: Text(
                        'Delete',
                        style: GoogleFonts.inter(
                          fontSize: 15 * scale.clamp(0.85, 1.2),
                          fontWeight: FontWeight.w600,
                          color: AppColors.vibrantPink,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Duplicate Success Overlay — matches Figma 1.6
// ─────────────────────────────────────────────────────────────────
class LuvcoDuplicateSuccessOverlay extends StatelessWidget {
  const LuvcoDuplicateSuccessOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.sizeOf(context).width / 390;

    return Dialog(
      backgroundColor: AppColors.pureWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Double-check icon — green, matches Figma
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.playlist_add_check_rounded,
                color: Color(0xFF43A047),
                size: 44,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'This list was duplicated!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16 * scale.clamp(0.85, 1.2),
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Shared text field for dialogs
// ─────────────────────────────────────────────────────────────────
class _LuvcoTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _LuvcoTextField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: GoogleFonts.inter(fontSize: 14, color: AppColors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.neutralGrey),
        filled: true,
        fillColor: AppColors.pureWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.royalPurple, width: 1.5),
        ),
      ),
    );
  }
}
