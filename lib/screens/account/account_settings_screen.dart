import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/account_settings_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'change_email_screen.dart';
import 'help_support_screen.dart';
import 'modify_name_screen.dart';
import 'modify_password_screen.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/auth_api_service.dart';
import '../../core/network/user_api_service.dart';
import '../../providers/session_provider.dart';

// ─────────────────────────────────────────────────────────────────
// Account Settings Screen — frame 1.6.0 → 1.6.23
// ─────────────────────────────────────────────────────────────────
class AccountSettingsScreen extends ConsumerWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AccountSettingsState state = ref.watch(accountSettingsProvider);
    final AccountSettingsNotifier notifier = ref.read(
      accountSettingsProvider.notifier,
    );
    final userProfileAsync = ref.watch(userProfileProvider);

    final displayName = userProfileAsync.maybeWhen(
      data: (user) => '${user.firstName ?? ""} ${user.lastName ?? ""}'.trim().isEmpty
          ? 'User Name'
          : '${user.firstName} ${user.lastName}'.trim(),
      orElse: () => 'User Name',
    );

    final profilePicUrl = userProfileAsync.maybeWhen(
      data: (user) => user.profilePictureUrl,
      orElse: () => null,
    );

    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final scale = size.width / 390;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.pureWhite,
        body: SafeArea(
          child: Container(
            color: AppColors.pageBackground,
            child: Stack(
              children: [
            Column(
              children: [
                // ── Header ──
                _AccountHeader(padding: padding, scale: scale, size: size),

                // ── Scrollable content ──
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 28),

                        // ── Avatar with edit pencil ──
                        _ProfileAvatar(
                          profileImage: state.profileImage,
                          profilePicUrl: profilePicUrl,
                          scale: scale,
                          onTap: () => _showChangePhotoSheet(
                            context,
                            notifier,
                            size,
                            scale,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ── User Name ──
                        Text(
                          displayName,
                          style: GoogleFonts.inter(
                            fontSize: 18 * scale.clamp(0.85, 1.2),
                            fontWeight: FontWeight.w800,
                            color: AppColors.black,
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ── Menu items ──
                        _AccountMenuList(scale: scale, size: size),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),

                const LuvcoBottomNavBar(),
              ],
            ),

            // ── Success overlay ──────────────────────────────────
            if (state.saveSuccess)
              _ProfileChangedOverlay(
                scale: scale,
                size: size,
                onDismiss: notifier.dismissSuccess,
              ),
          ],
        ),
          ),
        ),
      ),
    );
  }

  // ── Show the "Change profile picture?" bottom sheet ─────────────
  void _showChangePhotoSheet(
    BuildContext context,
    AccountSettingsNotifier notifier,
    Size size,
    double scale,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (_) => _ChangePhotoSheet(
        onOpenCamera: () async {
          Navigator.of(context).pop();
          final file = await _pickImage(ImageSource.camera);
          if (file != null && context.mounted) {
            notifier.setPendingImage(file);
            _showImagePreviewSheet(context, notifier, file, size, scale);
          }
        },
        onOpenGallery: () async {
          Navigator.of(context).pop();
          final file = await _pickImage(ImageSource.gallery);
          if (file != null && context.mounted) {
            notifier.setPendingImage(file);
            _showImagePreviewSheet(context, notifier, file, size, scale);
          }
        },
        size: size,
        scale: scale,
      ),
    );
  }

  // ── Show image preview bottom sheet (frame 1.6.4) ───────────────
  void _showImagePreviewSheet(
    BuildContext context,
    AccountSettingsNotifier notifier,
    File image,
    Size size,
    double scale,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => _ImagePreviewSheet(
        image: image,
        scale: scale,
        size: size,
        onSave: () async {
          Navigator.of(context).pop();
          await notifier.saveProfileImage();
        },
        onCancel: () {
          Navigator.of(context).pop();
          notifier.cancelPendingImage();
        },
      ),
    );
  }

  Future<File?> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (picked == null) return null;
      return File(picked.path);
    } catch (_) {
      return null;
    }
  }
}

// ─────────────────────────────────────────────────────────────────
// Header — back arrow + "My Account" title in vibrantPink
// Matches frame 1.6.0 exactly
// ─────────────────────────────────────────────────────────────────
class _AccountHeader extends StatelessWidget {
  final EdgeInsets padding;
  final double scale;
  final Size size;

  const _AccountHeader({
    required this.padding,
    required this.scale,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: 12,
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
          // Back arrow — vibrantPink to match Figma
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
              'My Account',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 20 * scale.clamp(0.85, 1.2),
                fontWeight: FontWeight.w700,
                color: AppColors.vibrantPink,
              ),
            ),
          ),
          // Balance spacer for centering the title
          SizedBox(width: 28 * scale.clamp(0.85, 1.2)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Profile avatar circle with purple pencil edit badge
// Matches frame 1.6.0 — circle photo, bottom-right purple circle
// with white pencil icon
// ─────────────────────────────────────────────────────────────────
class _ProfileAvatar extends StatelessWidget {
  final File? profileImage;
  final String? profilePicUrl;
  final double scale;
  final VoidCallback onTap;

  const _ProfileAvatar({
    required this.profileImage,
    this.profilePicUrl,
    required this.scale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatarSize = 90.0 * scale.clamp(0.85, 1.2);
    final badgeSize = 28.0 * scale.clamp(0.85, 1.2);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: avatarSize + 4,
        height: avatarSize + 4,
        child: Stack(
          children: [
            // ── Profile picture circle ──
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.clearGrey,
                border: Border.all(color: AppColors.pureWhite, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: profileImage != null
                    ? Image.file(
                        profileImage!,
                        fit: BoxFit.cover,
                        width: avatarSize,
                        height: avatarSize,
                        cacheWidth: 200,
                        cacheHeight: 200,
                      )
                    : (profilePicUrl != null && profilePicUrl!.isNotEmpty)
                        ? Image.network(
                            profilePicUrl!,
                            fit: BoxFit.cover,
                            width: avatarSize,
                            height: avatarSize,
                            cacheWidth: 200,
                            cacheHeight: 200,
                            errorBuilder: (_, __, ___) => Image.asset(
                              'assets/images/profile_pic.png',
                              fit: BoxFit.cover,
                              width: avatarSize,
                              height: avatarSize,
                              cacheWidth: 200,
                              cacheHeight: 200,
                            ),
                          )
                        : Image.asset(
                            'assets/images/profile_pic.png',
                            fit: BoxFit.cover,
                            width: avatarSize,
                            height: avatarSize,
                            cacheWidth: 200,
                            cacheHeight: 200,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.person_rounded,
                              size: avatarSize * 0.55,
                              color: AppColors.neutralGrey,
                            ),
                          ),
              ),
            ),

            // ── Purple pencil edit badge ── (bottom-right)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  color: AppColors.royalPurple,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.pureWhite, width: 2),
                ),
                child: Icon(
                  Icons.edit_rounded,
                  color: AppColors.pureWhite,
                  size: badgeSize * 0.52,
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
// Account menu list — Name / Email / Password / Help & Support /
// Delete Account / Log Out
// Matches frame 1.6.0 exactly — white card, rows with icon + label
// + chevron right, each separated by a thin divider line
// ─────────────────────────────────────────────────────────────────
class _AccountMenuList extends ConsumerWidget {
  final double scale;
  final Size size;

  const _AccountMenuList({required this.scale, required this.size});

  static const _topItems = [
    _MenuItem(
      icon: Icons.person_outline_rounded,
      label: 'Name',
      isDestructive: false,
      showChevron: true,
    ),
    _MenuItem(
      icon: Icons.email_outlined,
      label: 'Email',
      isDestructive: false,
      showChevron: true,
    ),
    _MenuItem(
      icon: Icons.lock_outline_rounded,
      label: 'Password',
      isDestructive: false,
      showChevron: true,
    ),
    _MenuItem(
      icon: Icons.help_outline_rounded,
      label: 'Help & Support',
      isDestructive: false,
      showChevron: true,
    ),
    _MenuItem(
      icon: Icons.delete_outline_rounded,
      label: 'Delete Account',
      isDestructive: true,
      showChevron: true,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.058),
      child: Column(
        children: [
          // ── Top grouped card (Name → Delete Account) ──
          Container(
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: List.generate(_topItems.length, (i) {
                final item = _topItems[i];
                final isLast = i == _topItems.length - 1;
                return Column(
                  children: [
                    _AccountMenuRow(
                      item: item,
                      scale: scale,
                      onTap: () => _handleTap(context, ref, item.label),
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        thickness: 1,
                        indent: 16,
                        endIndent: 16,
                        color: AppColors.clearGrey.withValues(alpha: 0.6),
                      ),
                  ],
                );
              }),
            ),
          ),

          const SizedBox(height: 16),

          // ── Log Out — separate card ──
          Container(
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _AccountMenuRow(
              item: const _MenuItem(
                icon: Icons.logout_rounded,
                label: 'Log Out',
                isDestructive: false,
                showChevron: false,
              ),
              scale: scale,
              onTap: () => _handleTap(context, ref, 'Log Out'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleTap(BuildContext context, WidgetRef ref, String label) async {
    if (label == 'Name') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const ModifyNameScreen()));
    } else if (label == 'Email') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const ChangeEmailScreen()));
    } else if (label == 'Password') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const ModifyPasswordScreen()));
    } else if (label == 'Help & Support') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
    } else if (label == 'Delete Account') {
      _showDeleteAccountConfirmDialog(context, ref);
    } else if (label == 'Log Out') {
      await logoutAndClearProviders(ref);
      if (context.mounted) context.go('/login');
    }
  }

  void _showDeleteAccountConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: AppColors.pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Delete Account',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.errorRed,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to permanently delete your account? This action cannot be undone and will delete all your data.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.darkGrey,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(dialogCtx),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                  Container(width: 1, height: 20, color: AppColors.clearGrey),
                  GestureDetector(
                    onTap: () async {
                      Navigator.pop(dialogCtx);
                      try {
                        await UserApiService.instance.deleteAccount();
                        await logoutAndClearProviders(ref);
                        if (context.mounted) {
                          context.go('/login');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to delete account: $e'),
                              backgroundColor: AppColors.errorRed,
                            ),
                          );
                        }
                      }
                    },
                    child: Text(
                      'Delete',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.errorRed,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final bool isDestructive;
  final bool showChevron;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.isDestructive,
    required this.showChevron,
  });
}

class _AccountMenuRow extends StatelessWidget {
  final _MenuItem item;
  final double scale;
  final VoidCallback onTap;

  const _AccountMenuRow({
    required this.item,
    required this.scale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = item.isDestructive ? AppColors.errorRed : AppColors.black;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16 * scale.clamp(0.85, 1.1),
        ),
        child: Row(
          children: [
            // Icon
            Icon(item.icon, color: color, size: 22 * scale.clamp(0.85, 1.2)),
            const SizedBox(width: 14),
            // Label
            Expanded(
              child: Text(
                item.label,
                style: GoogleFonts.inter(
                  fontSize: 15 * scale.clamp(0.85, 1.2),
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            // Chevron
            if (item.showChevron)
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.neutralGrey,
                size: 22 * scale.clamp(0.85, 1.2),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// "Change profile picture?" bottom sheet — frame 1.6.1
// White sheet, "X" close, two rows: Open Camera / Open Gallery
// ─────────────────────────────────────────────────────────────────
class _ChangePhotoSheet extends StatelessWidget {
  final VoidCallback onOpenCamera;
  final VoidCallback onOpenGallery;
  final Size size;
  final double scale;

  const _ChangePhotoSheet({
    required this.onOpenCamera,
    required this.onOpenGallery,
    required this.size,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 24,
        right: 24,
        bottom: 24 + bottomPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ──
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.clearGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Title row + close ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Do you want to change your\nprofile picture?',
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
                child: const Icon(
                  Icons.close_rounded,
                  color: AppColors.darkGrey,
                  size: 22,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Open Camera row ──
          _SheetOptionRow(
            icon: Icons.photo_camera_outlined,
            label: 'Open Camera',
            scale: scale,
            onTap: onOpenCamera,
          ),

          const SizedBox(height: 16),

          // ── Open Gallery row ──
          _SheetOptionRow(
            icon: Icons.photo_library_outlined,
            label: 'Open Gallery',
            scale: scale,
            onTap: onOpenGallery,
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SheetOptionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final double scale;
  final VoidCallback onTap;

  const _SheetOptionRow({
    required this.icon,
    required this.label,
    required this.scale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.darkGrey,
            size: 22 * scale.clamp(0.85, 1.2),
          ),
          const SizedBox(width: 16),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 15 * scale.clamp(0.85, 1.2),
              fontWeight: FontWeight.w500,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Image preview bottom sheet — frame 1.6.4
// Shows selected photo in a large circle, "Save Changes" (purple
// filled pill) + "Cancel" (outlined pill)
// ─────────────────────────────────────────────────────────────────
class _ImagePreviewSheet extends StatefulWidget {
  final File image;
  final double scale;
  final Size size;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _ImagePreviewSheet({
    required this.image,
    required this.scale,
    required this.size,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<_ImagePreviewSheet> createState() => _ImagePreviewSheetState();
}

class _ImagePreviewSheetState extends State<_ImagePreviewSheet> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final previewSize = widget.size.width * 0.55;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: widget.size.width * 0.058,
        right: widget.size.width * 0.058,
        bottom: 24 + bottomPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ──
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.clearGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Close button top-right ──
          Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: widget.onCancel,
              child: const Icon(
                Icons.close_rounded,
                color: AppColors.darkGrey,
                size: 22,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Circular image preview ──
          Container(
            width: previewSize,
            height: previewSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.file(
                widget.image,
                fit: BoxFit.cover,
                width: previewSize,
                height: previewSize,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // ── Save Changes button ──
          SizedBox(
            width: double.infinity,
            height: (widget.size.height * 0.062).clamp(48.0, 58.0),
            child: ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : () async {
                      setState(() => _isSaving = true);
                      await Future.delayed(Duration.zero);
                      widget.onSave();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.royalPurple,
                disabledBackgroundColor: AppColors.royalPurple.withValues(
                  alpha: 0.5,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              child: _isSaving
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
                        fontSize: 16 * widget.scale.clamp(0.85, 1.3),
                        fontWeight: FontWeight.w600,
                        color: AppColors.pureWhite,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Cancel button — outlined ──
          SizedBox(
            width: double.infinity,
            height: (widget.size.height * 0.062).clamp(48.0, 58.0),
            child: OutlinedButton(
              onPressed: _isSaving ? null : widget.onCancel,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                  color: AppColors.royalPurple,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  fontSize: 16 * widget.scale.clamp(0.85, 1.3),
                  fontWeight: FontWeight.w600,
                  color: AppColors.royalPurple,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Success overlay — frame 1.6.23
// Semi-transparent page dim, white card with green circle check +
// "Your image profile has successfully changed!"
// Auto-dismiss after 2s
// ─────────────────────────────────────────────────────────────────
class _ProfileChangedOverlay extends StatelessWidget {
  final double scale;
  final Size size;
  final VoidCallback onDismiss;

  const _ProfileChangedOverlay({
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
              margin: EdgeInsets.symmetric(horizontal: size.width * 0.14),
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
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

                  Text(
                    'Your image profile has\nsuccessfully changed!',
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
