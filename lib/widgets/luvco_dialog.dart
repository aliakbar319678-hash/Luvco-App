import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────
// Reusable Luvco bottom sheet for "More Actions"
// ─────────────────────────────────────────────────────────────────
class LuvcoMoreActionsSheet extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const LuvcoMoreActionsSheet({
    super.key,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.sizeOf(context).width / 390;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.clearGrey,
              borderRadius: BorderRadius.circular(100),
            ),
          ),

          _SheetAction(
            label: 'Edit Lists Title',
            icon: Icons.edit_outlined,
            iconColor: AppColors.darkGrey,
            labelColor: AppColors.black,
            scale: scale,
            onTap: () {
              Navigator.of(context).pop();
              onEdit();
            },
          ),

          _SheetAction(
            label: 'Duplicate List',
            icon: Icons.copy_outlined,
            iconColor: AppColors.darkGrey,
            labelColor: AppColors.black,
            scale: scale,
            onTap: () {
              Navigator.of(context).pop();
              onDuplicate();
            },
          ),

          _SheetAction(
            label: 'Delete List',
            icon: Icons.delete_outline_rounded,
            iconColor: AppColors.errorRed,
            labelColor: AppColors.errorRed,
            scale: scale,
            onTap: () {
              Navigator.of(context).pop();
              onDelete();
            },
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color labelColor;
  final double scale;
  final VoidCallback onTap;

  const _SheetAction({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.labelColor,
    required this.scale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 15 * scale.clamp(0.85, 1.2),
                  fontWeight: FontWeight.w500,
                  color: labelColor,
                ),
              ),
            ),
            Icon(icon, color: iconColor, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Edit List Dialog
// ─────────────────────────────────────────────────────────────────
class LuvcoEditListDialog extends StatefulWidget {
  final String initialTitle;
  final String initialDescription;
  final void Function(String title, String description) onSave;

  const LuvcoEditListDialog({
    super.key,
    required this.initialTitle,
    required this.initialDescription,
    required this.onSave,
  });

  @override
  State<LuvcoEditListDialog> createState() => _LuvcoEditListDialogState();
}

class _LuvcoEditListDialogState extends State<LuvcoEditListDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _descController = TextEditingController(text: widget.initialDescription);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final scale = size.width / 390;

    return Dialog(
      backgroundColor: AppColors.pureWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Do you want to edit the list\ninformation?',
                    style: GoogleFonts.inter(
                      fontSize: 16 * scale.clamp(0.85, 1.2),
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                      height: 1.3,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(
                    Icons.close,
                    color: AppColors.darkGrey,
                    size: 22,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── List Title ──
            Text(
              'List Title',
              style: GoogleFonts.inter(
                fontSize: 13 * scale.clamp(0.85, 1.2),
                fontWeight: FontWeight.w500,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            _DialogTextField(controller: _titleController, hint: 'List title'),

            const SizedBox(height: 16),

            // ── Description ──
            Text(
              'Description',
              style: GoogleFonts.inter(
                fontSize: 13 * scale.clamp(0.85, 1.2),
                fontWeight: FontWeight.w500,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            _DialogTextField(
              controller: _descController,
              hint: 'Short description of the shopping list.',
            ),

            const SizedBox(height: 24),

            // ── Save Changes button ──
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  widget.onSave(
                    _titleController.text.trim(),
                    _descController.text.trim(),
                  );
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.royalPurple,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: Text(
                  'Save Changes',
                  style: GoogleFonts.inter(
                    fontSize: 15 * scale.clamp(0.85, 1.2),
                    fontWeight: FontWeight.w600,
                    color: AppColors.pureWhite,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _DialogTextField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: GoogleFonts.inter(fontSize: 14, color: AppColors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.neutralGrey,
        ),
        filled: true,
        fillColor: AppColors.pureWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
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
          borderSide: const BorderSide(
            color: AppColors.royalPurple,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Delete Confirmation Dialog
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
            // ── Question ──
            Text(
              'Do you want to delete "$listName"?',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16 * scale.clamp(0.85, 1.2),
                fontWeight: FontWeight.w700,
                color: AppColors.black,
                height: 1.3,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13 * scale.clamp(0.85, 1.2),
                color: AppColors.darkGrey,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 24),

            // ── Cancel / Delete row ──
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
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
                Container(width: 1, height: 24, color: AppColors.clearGrey),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      onDelete();
                    },
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
// Duplicate Success Overlay (shown briefly after duplicate)
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
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Green checkmark icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: Color(0xFF43A047),
                size: 44,
              ),
            ),

            const SizedBox(height: 18),

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
