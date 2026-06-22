import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme/app_colors.dart';
import '../../models/product_model.dart';
import '../../providers/barcode_scanner_provider.dart';

// ═══════════════════════════════════════════════════════════════
// Barcode Scanner Screen  (frames 2.2.0 → 2.2.5)
// ═══════════════════════════════════════════════════════════════
class BarcodeScannerScreen extends ConsumerWidget {
  const BarcodeScannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(barcodeScannerProvider);
    final notifier = ref.read(barcodeScannerProvider.notifier);
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final scale = (size.width / 390).clamp(0.85, 1.3);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ══════════════════════════════════════════
            // LAYER 1 — Full-screen camera background
            // ══════════════════════════════════════════
            Positioned.fill(
              child: _CameraFeed(
                blurred:
                    state.scanState == BarcodeScanState.cameraPermission ||
                    state.scanState == BarcodeScanState.loading ||
                    state.scanState == BarcodeScanState.cardOpen ||
                    state.scanState == BarcodeScanState.addToList ||
                    state.scanState == BarcodeScanState.addToRecipe,
                isScanning: state.scanState == BarcodeScanState.scanning,
                hasPermission: state.scanState != BarcodeScanState.cameraPermission,
              ),
            ),

            // ══════════════════════════════════════════
            // LAYER 2 — Top nav (always visible)
            // ══════════════════════════════════════════
            Positioned(
              top: padding.top + 6 * scale,
              left: 20 * scale,
              right: 20 * scale,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back chevron
                  _NavIconButton(
                    icon: Icons.chevron_left,
                    size: 30 * scale,
                    scale: scale,
                    onTap: () => context.pop(),
                  ),
                  // Close X
                  _NavIconButton(
                    icon: Icons.close,
                    size: 22 * scale,
                    scale: scale,
                    onTap: () => context.pop(),
                  ),
                ],
              ),
            ),

            // ══════════════════════════════════════════
            // LAYER 3 — State-specific overlays
            // ══════════════════════════════════════════

            // ── 2.2.0 Camera Permission ──
            if (state.scanState == BarcodeScanState.cameraPermission)
              _PermissionDialog(
                scale: scale,
                onAllow: notifier.allowCamera,
                onDeny: () => context.pop(),
              ),

            // ── 2.2.1 Scanning frame + button ──
            if (state.scanState == BarcodeScanState.scanning)
              _ScanningLayer(
                scale: scale,
                size: size,
                padding: padding,
              ),

            // ── 2.2.x Loading overlay ──
            if (state.scanState == BarcodeScanState.loading)
              _LoadingLayer(
                scale: scale,
                size: size,
                padding: padding,
              ),

            // ── 2.2.2 Not found card ──
            if (state.scanState == BarcodeScanState.notFound)
              _NotFoundLayer(
                scale: scale,
                size: size,
                padding: padding,
                onRetry: notifier.retryScanning,
              ),

            // ── 2.2.3 Product card ──
            if (state.scannedProduct != null &&
                (state.scanState == BarcodeScanState.cardOpen ||
                    state.scanState == BarcodeScanState.addToList ||
                    state.scanState == BarcodeScanState.addToRecipe))
              _ProductCardLayer(
                product: state.scannedProduct!,
                isFavorite: state.isFavorite,
                scale: scale,
                size: size,
                padding: padding,
                onClose: notifier.closeCard,
                onFavorite: notifier.toggleFavorite,
                onAddToList: notifier.openAddToList,
                onAddToRecipe: notifier.openAddToRecipe,
                onSeeMore: () {
                  // ── Capture product BEFORE closeCard() resets state ──
                  final product = state.scannedProduct!;
                  context.push('/product-detail', extra: product);
                  notifier.closeCard();
                },
              ),

            // ── 2.2.4 Add to Shopping List dialog ──
            if (state.scanState == BarcodeScanState.addToList)
              _ListCheckboxDialog(
                title: 'Which shopping list do you want\nto add this product?',
                items: state.shoppingLists,
                selected: state.selectedLists,
                buttonLabel: 'Save On List',
                scale: scale,
                padding: padding,
                onToggle: notifier.toggleList,
                onSave: notifier.saveOnList,
                onDismiss: notifier.closeDialog,
              ),

            // ── 2.2.5 Add to Recipe dialog ──
            if (state.scanState == BarcodeScanState.addToRecipe)
              _ListCheckboxDialog(
                title: 'Which recipe do you want to add\nthis product?',
                items: state.recipes,
                selected: state.selectedRecipes,
                buttonLabel: 'Save On Recipe',
                scale: scale,
                padding: padding,
                onToggle: notifier.toggleRecipe,
                onSave: notifier.saveOnRecipe,
                onDismiss: notifier.closeDialog,
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Shared nav icon button
// ─────────────────────────────────────────────────────────
class _NavIconButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final double scale;
  final VoidCallback onTap;

  const _NavIconButton({
    required this.icon,
    required this.size,
    required this.scale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 40 * scale,
        height: 40 * scale,
        child: Center(
          child: Icon(icon, color: Colors.white, size: size),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Camera Feed — warm tan gradient simulating real camera view
// ═══════════════════════════════════════════════════════════════
// ═══════════════════════════════════════════════════════════════
// Camera Feed — real-time camera using mobile_scanner
// ═══════════════════════════════════════════════════════════════
class _CameraFeed extends ConsumerStatefulWidget {
  final bool blurred;
  final bool isScanning;
  final bool hasPermission;

  const _CameraFeed({
    required this.blurred,
    required this.isScanning,
    required this.hasPermission,
  });

  @override
  ConsumerState<_CameraFeed> createState() => _CameraFeedState();
}

class _CameraFeedState extends ConsumerState<_CameraFeed> {
  late MobileScannerController controller;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(barcodeScannerProvider.notifier);

    if (!widget.hasPermission) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Opacity(
            opacity: 0.2,
            child: Image.asset(
              'assets/images/nutila.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    }

    final Widget bg = Stack(
      children: [
        // Real camera view
        MobileScanner(
          controller: controller,
          onDetect: (capture) {
            if (!widget.isScanning) return;
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              if (barcode.rawValue != null) {
                notifier.onBarcodeScanned(barcode.rawValue);
                break;
              }
            }
          },
          placeholderBuilder: (context) => Container(
            color: Colors.black,
            child: Center(
              child: Opacity(
                opacity: 0.2,
                child: Image.asset(
                  'assets/images/nutila.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),

        // Fallback UI if camera isn't active/visible
        if (!widget.isScanning)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.4),
            ),
          ),
      ],
    );

    if (!widget.blurred) return bg;

    return Stack(
      children: [
        bg,
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(color: Colors.black.withValues(alpha: 0.15)),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 2.2.0 — Camera Permission dialog (iOS style)
// ═══════════════════════════════════════════════════════════════
class _PermissionDialog extends StatelessWidget {
  final double scale;
  final VoidCallback onAllow;
  final VoidCallback onDeny;

  const _PermissionDialog({
    required this.scale,
    required this.onAllow,
    required this.onDeny,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 52 * scale),
        constraints: BoxConstraints(maxWidth: 300 * scale),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F2).withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(14 * scale),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                18 * scale,
                22 * scale,
                18 * scale,
                18 * scale,
              ),
              child: Column(
                children: [
                  Text(
                    'Luvco would like to access\nthe camera',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13 * scale,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 6 * scale),
                  Text(
                    'Lorem ipsum dolor sit amet,\nconsectetur adipiscing elit.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12 * scale,
                      fontWeight: FontWeight.w400,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 0.5, color: Colors.grey.withValues(alpha: 0.45)),
            SizedBox(
              height: 44 * scale,
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: onDeny,
                      child: Container(
                        color: Colors.transparent,
                        alignment: Alignment.center,
                        child: Text(
                          "Don't Allow",
                          style: GoogleFonts.inter(
                            fontSize: 14 * scale,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF007AFF),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(width: 0.5, color: Colors.grey.withValues(alpha: 0.45)),
                  Expanded(
                    child: GestureDetector(
                      onTap: onAllow,
                      child: Container(
                        color: Colors.transparent,
                        alignment: Alignment.center,
                        child: Text(
                          'OK',
                          style: GoogleFonts.inter(
                            fontSize: 14 * scale,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF007AFF),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 2.2.1 — Scanning overlay: dark mask + L-brackets + button
// ═══════════════════════════════════════════════════════════════
class _ScanningLayer extends StatelessWidget {
  final double scale;
  final Size size;
  final EdgeInsets padding;

  const _ScanningLayer({
    required this.scale,
    required this.size,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final frameW = 260.0 * scale;
    final frameH = 220.0 * scale;
    final cx = size.width / 2;
    final cy = size.height * 0.42;

    return Stack(
      children: [
        // Dark mask with transparent hole
        CustomPaint(
          size: Size(size.width, size.height),
          painter: _ScanMaskPainter(
            frameLeft: cx - frameW / 2,
            frameTop: cy - frameH / 2,
            frameRight: cx + frameW / 2,
            frameBottom: cy + frameH / 2,
            radius: 14.0,
          ),
        ),

        // L-bracket corners
        Positioned(
          left: cx - frameW / 2,
          top: cy - frameH / 2,
          width: frameW,
          height: frameH,
          child: CustomPaint(painter: _CornerBracketPainter(scale: scale)),
        ),

        // Scan info label (instead of button since it's real-time now)
        Positioned(
          bottom: padding.bottom + 36 * scale,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              height: 50 * scale,
              padding: EdgeInsets.symmetric(horizontal: 36 * scale),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(30 * scale),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'Scanning Real-Time...',
                  style: GoogleFonts.inter(
                    fontSize: 15 * scale,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScanMaskPainter extends CustomPainter {
  final double frameLeft, frameTop, frameRight, frameBottom, radius;

  const _ScanMaskPainter({
    required this.frameLeft,
    required this.frameTop,
    required this.frameRight,
    required this.frameBottom,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.52);
    final hole = RRect.fromRectAndRadius(
      Rect.fromLTRB(frameLeft, frameTop, frameRight, frameBottom),
      Radius.circular(radius),
    );
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(hole)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ScanMaskPainter old) =>
      old.frameLeft != frameLeft || old.frameTop != frameTop;
}

class _CornerBracketPainter extends CustomPainter {
  final double scale;
  const _CornerBracketPainter({required this.scale});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.2 * scale
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final arm = 26.0 * scale;
    final w = size.width;
    final h = size.height;

    // Top-left
    canvas.drawLine(Offset(0, arm), Offset.zero, paint);
    canvas.drawLine(Offset.zero, Offset(arm, 0), paint);
    // Top-right
    canvas.drawLine(Offset(w - arm, 0), Offset(w, 0), paint);
    canvas.drawLine(Offset(w, 0), Offset(w, arm), paint);
    // Bottom-left
    canvas.drawLine(Offset(0, h - arm), Offset(0, h), paint);
    canvas.drawLine(Offset(0, h), Offset(arm, h), paint);
    // Bottom-right
    canvas.drawLine(Offset(w - arm, h), Offset(w, h), paint);
    canvas.drawLine(Offset(w, h - arm), Offset(w, h), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ═══════════════════════════════════════════════════════════════
// 2.2.2 — Product NOT FOUND  (pixel-perfect match to Figma)
//
// Layout (top → bottom inside white card):
//   • Red/pink square icon container (64×64, radius 16)
//     └─ Custom barcode-scan-error icon drawn with CustomPaint
//        (matches the Figma icon exactly: rectangular frame +
//         broken centre scan line with gap — all in AppColors.errorRed)
//   • 18px gap
//   • "Product not found, try to\nscan again"  — Inter SemiBold 15
//
// The white card sits at vertical centre of the screen.
// Behind: dark semi-transparent scrim (opacity 0.45).
// Bottom: the "Scan A Barcode" pill is translucent white w/ white text.
// ═══════════════════════════════════════════════════════════════
class _NotFoundLayer extends StatelessWidget {
  final double scale;
  final Size size;
  final EdgeInsets padding;
  final VoidCallback onRetry;

  const _NotFoundLayer({
    required this.scale,
    required this.size,
    required this.padding,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Dark scrim ──
        Positioned.fill(
          child: Container(color: Colors.black.withValues(alpha: 0.45)),
        ),

        // ── Centre card ──
        Center(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 50 * scale),
            constraints: BoxConstraints(maxWidth: 290 * scale),
            padding: EdgeInsets.symmetric(
              horizontal: 28 * scale,
              vertical: 32 * scale,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20 * scale),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Red icon container
                Container(
                  width: 64 * scale,
                  height: 64 * scale,
                  decoration: BoxDecoration(
                    // Light pink/red background exactly as in Figma
                    color: const Color(0xFFFFEEEE),
                    borderRadius: BorderRadius.circular(16 * scale),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 36 * scale,
                      height: 36 * scale,
                      child: CustomPaint(
                        painter: _ScanErrorIconPainter(scale: scale),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 18 * scale),

                // Message text
                Text(
                  'Product not found, try to\nscan again',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 15 * scale,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Bottom pill button ──
        Positioned(
          bottom: padding.bottom + 36 * scale,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: onRetry,
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 50 * scale,
                padding: EdgeInsets.symmetric(horizontal: 36 * scale),
                decoration: BoxDecoration(
                  // Semi-transparent white — matches Figma 2.2.2 bottom button
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(30 * scale),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.55),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    'Scan A Barcode',
                    style: GoogleFonts.inter(
                      fontSize: 15 * scale,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 2.2.x — Loading overlay (shown while fetching product from API)
// ═══════════════════════════════════════════════════════════════
class _LoadingLayer extends StatelessWidget {
  final double scale;
  final Size size;
  final EdgeInsets padding;

  const _LoadingLayer({
    required this.scale,
    required this.size,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dark scrim
        Positioned.fill(
          child: Container(color: Colors.black.withValues(alpha: 0.55)),
        ),

        // Centre spinner card
        Center(
          child: Container(
            width: 140 * scale,
            padding: EdgeInsets.symmetric(
              horizontal: 24 * scale,
              vertical: 28 * scale,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20 * scale),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 40 * scale,
                  height: 40 * scale,
                  child: const CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFE91E8C),
                    ),
                  ),
                ),
                SizedBox(height: 16 * scale),
                Text(
                  'Fetching\nProduct...',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13 * scale,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A2E),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Custom painter that draws the scan-error icon exactly as
// shown in the Figma frame 2.2.2:
//   • Rounded-corner rectangular frame (like a viewfinder/barcode box)
//   • Two corner L-shapes inside (top-left, bottom-right) — mimicking
//     the standard barcode-reader bracket icon in red
//   • A horizontal scan line through the middle with a gap/break
//     in the centre (indicating "not found")
// All strokes are AppColors.errorRed (#E53935)
// ─────────────────────────────────────────────────────────────
class _ScanErrorIconPainter extends CustomPainter {
  final double scale;
  const _ScanErrorIconPainter({required this.scale});

  @override
  void paint(Canvas canvas, Size size) {
    const color = AppColors.errorRed;
    final strokeW = 2.2 * scale;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;
    final arm = w * 0.28; // length of each L arm
    final r = w * 0.10; // corner radius of the outer frame

    // ── Outer rounded rectangle frame ──
    final frameRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      Radius.circular(r),
    );
    canvas.drawRRect(frameRect, paint);

    // ── Inner L-bracket: top-left corner ──
    final innerPaint = Paint()
      ..color = color
      ..strokeWidth = strokeW * 1.4
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;

    // top-left horizontal
    canvas.drawLine(Offset(r, h * 0.18), Offset(r + arm, h * 0.18), innerPaint);
    // top-left vertical
    canvas.drawLine(Offset(r, h * 0.18), Offset(r, h * 0.18 + arm), innerPaint);

    // ── Inner L-bracket: bottom-right corner ──
    // bottom-right horizontal
    canvas.drawLine(
      Offset(w - r - arm, h * 0.82),
      Offset(w - r, h * 0.82),
      innerPaint,
    );
    // bottom-right vertical
    canvas.drawLine(
      Offset(w - r, h * 0.82 - arm),
      Offset(w - r, h * 0.82),
      innerPaint,
    );

    // ── Horizontal scan line with centre gap ──
    final scanPaint = Paint()
      ..color = color
      ..strokeWidth = strokeW * 0.9
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final midY = h * 0.5;
    final gapHalf = w * 0.10;

    // Left half of scan line
    canvas.drawLine(
      Offset(w * 0.12, midY),
      Offset(w / 2 - gapHalf, midY),
      scanPaint,
    );
    // Right half of scan line
    canvas.drawLine(
      Offset(w / 2 + gapHalf, midY),
      Offset(w * 0.88, midY),
      scanPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ═══════════════════════════════════════════════════════════════
// ═══════════════════════════════════════════════════════════════
// Helper functions for label sanitization and English filtering
// ═══════════════════════════════════════════════════════════════
List<String> _filterEnglish(List<String> all) {
  final englishOnly = all
      .where((l) => !RegExp(r'^[a-z]{2,3}:').hasMatch(l) || l.startsWith('en:'))
      .toList();
  return englishOnly.isNotEmpty ? englishOnly : all;
}

String _cleanLabel(String raw) {
  // Strip any language prefix code (e.g. "en:", "fr:", "en-us:")
  String cleaned = raw.replaceAll(RegExp(r'^[a-z]{2,3}(-[a-z]{2,3})?:'), '');
  cleaned = cleaned.replaceAll(RegExp(r'[-_]'), ' ').trim();
  if (cleaned.isEmpty) return raw;
  return cleaned
      .split(' ')
      .map((w) {
        if (w.isEmpty) return '';
        if (w.toLowerCase() == 'eu') return 'EU';
        return '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}';
      })
      .join(' ');
}

// 2.2.3 — Product card bottom sheet
// ═══════════════════════════════════════════════════════════════
class _ProductCardLayer extends StatelessWidget {
  final ProductModel product;
  final bool isFavorite;
  final double scale;
  final Size size;
  final EdgeInsets padding;
  final VoidCallback onClose;
  final VoidCallback onFavorite;
  final VoidCallback onAddToList;
  final VoidCallback onAddToRecipe;
  final VoidCallback onSeeMore;

  const _ProductCardLayer({
    required this.product,
    required this.isFavorite,
    required this.scale,
    required this.size,
    required this.padding,
    required this.onClose,
    required this.onFavorite,
    required this.onAddToList,
    required this.onAddToRecipe,
    required this.onSeeMore,
  });

  @override
  Widget build(BuildContext context) {
    final filteredLabels = _filterEnglish(product.labels);
    final filteredAllergens = _filterEnglish(product.allergens);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxHeight: size.height * 0.84),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24 * scale)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10 * scale),
            // Drag handle
            Container(
              width: 38 * scale,
              height: 4 * scale,
              decoration: BoxDecoration(
                color: AppColors.clearGrey,
                borderRadius: BorderRadius.circular(2 * scale),
              ),
            ),
            SizedBox(height: 6 * scale),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  20 * scale,
                  4 * scale,
                  20 * scale,
                  padding.bottom + 16 * scale,
                ),
                child: Column(
                  children: [
                    // Close row
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: onClose,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: EdgeInsets.all(4 * scale),
                          child: Icon(
                            Icons.close,
                            size: 22 * scale,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      product.name,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 20 * scale,
                        fontWeight: FontWeight.w800,
                        color: AppColors.vibrantPink,
                      ),
                    ),
                    SizedBox(height: 4 * scale),
                    Text(
                      product.description,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13 * scale,
                        color: AppColors.darkGrey,
                      ),
                    ),
                    SizedBox(height: 14 * scale),
                    _ImageWithBadges(
                      product: product,
                      isFavorite: isFavorite,
                      scale: scale,
                      onFavorite: onFavorite,
                    ),
                    SizedBox(height: 20 * scale),
                    if (filteredLabels.isNotEmpty) ...[
                      _SectionLabel(
                        title: 'Labels and Certifications',
                        scale: scale,
                      ),
                      SizedBox(height: 10 * scale),
                      _HexRow(labels: filteredLabels, scale: scale),
                      SizedBox(height: 20 * scale),
                    ],
                    if (filteredAllergens.isNotEmpty) ...[
                      _SectionLabel(title: 'Possible allergens', scale: scale),
                      SizedBox(height: 10 * scale),
                      _HexRow(labels: filteredAllergens, scale: scale),
                      SizedBox(height: 24 * scale),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: _OutlineIconBtn(
                            icon: Icons.shopping_basket_outlined,
                            label: 'Add To List',
                            scale: scale,
                            onTap: onAddToList,
                          ),
                        ),
                        SizedBox(width: 10 * scale),
                        Expanded(
                          child: _OutlineIconBtn(
                            icon: Icons.restaurant_menu_outlined,
                            label: 'Add To Recipe',
                            scale: scale,
                            onTap: onAddToRecipe,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10 * scale),
                    SizedBox(
                      width: double.infinity,
                      height: 50 * scale,
                      child: ElevatedButton(
                        onPressed: onSeeMore,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.royalPurple,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12 * scale),
                          ),
                        ),
                        child: Text(
                          'See More Details',
                          style: GoogleFonts.inter(
                            fontSize: 15 * scale,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10 * scale),
                    Text(
                      'Swipe up to see similar',
                      style: GoogleFonts.inter(
                        fontSize: 12 * scale,
                        color: AppColors.neutralGrey,
                      ),
                    ),
                    SizedBox(height: 8 * scale),
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

// ─────────────────────────────────────────────────────────
// Product image card with sustainability badges + heart
// ─────────────────────────────────────────────────────────
class _ImageWithBadges extends StatelessWidget {
  final ProductModel product;
  final bool isFavorite;
  final double scale;
  final VoidCallback onFavorite;

  const _ImageWithBadges({
    required this.product,
    required this.isFavorite,
    required this.scale,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Status tabs — flush at top, separate from white card ──────
        IntrinsicHeight(
          child: Row(
            children: [
              // Unsustainable (red)
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20 * scale),
                      topRight: Radius.circular(16 * scale),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: 10 * scale,
                    horizontal: 4 * scale,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.eco_outlined,
                        color: Colors.white,
                        size: 15 * scale,
                      ),
                      SizedBox(width: 5 * scale),
                      Text(
                        'Unsustainable',
                        style: GoogleFonts.inter(
                          fontSize: 12 * scale,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Safe (green)
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF43A047),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16 * scale),
                      topRight: Radius.circular(20 * scale),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: 10 * scale,
                    horizontal: 4 * scale,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.flag_outlined,
                        color: Colors.white,
                        size: 15 * scale,
                      ),
                      SizedBox(width: 5 * scale),
                      Text(
                        'Safe',
                        style: GoogleFonts.inter(
                          fontSize: 12 * scale,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 4 * scale), // Small visually balanced spacing

        // ── White image area with heart overlay (all corners rounded) ──
        Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16 * scale),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Centered product image
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  vertical: 20 * scale,
                  horizontal: 16 * scale,
                ),
                color: Colors.white,
                child: Center(
                  child: product.imageAsset != null && product.imageAsset!.isNotEmpty
                      ? (product.imageAsset!.startsWith('http')
                          ? Image.network(
                              product.imageAsset!,
                              height: 150 * scale,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.image_outlined,
                                size: 60 * scale,
                                color: AppColors.neutralGrey,
                              ),
                              loadingBuilder: (ctx, child, prog) {
                                if (prog == null) return child;
                                return SizedBox(
                                  height: 150 * scale,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.royalPurple,
                                    ),
                                  ),
                                );
                              },
                            )
                          : Image.asset(
                              product.imageAsset!,
                              height: 150 * scale,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.image_outlined,
                                size: 60 * scale,
                                color: AppColors.neutralGrey,
                              ),
                            ))
                      : Icon(
                          Icons.image_outlined,
                          size: 60 * scale,
                          color: AppColors.neutralGrey,
                        ),
                ),
              ),

              // Heart icon — top-right overlay
              Positioned(
                top: 10 * scale,
                right: 12 * scale,
                child: GestureDetector(
                  onTap: onFavorite,
                  behavior: HitTestBehavior.opaque,
                  child: Icon(
                    isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isFavorite ? AppColors.vibrantPink : AppColors.black,
                    size: 22 * scale,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────
// Section label
// ─────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String title;
  final double scale;
  const _SectionLabel({required this.title, required this.scale});

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 14 * scale,
        fontWeight: FontWeight.w700,
        color: AppColors.black,
      ),
    ),
  );
}

// ─────────────────────────────────────────────────
class _HexRow extends StatelessWidget {
  final List<String> labels;
  final double scale;
  const _HexRow({required this.labels, required this.scale});

  static (IconData, Color) _getIconAndColor(String name) {
    final lower = name.toLowerCase();
    
    // Allergens
    if (lower.contains('gluten') || lower.contains('wheat')) {
      return (Icons.grain_rounded, const Color(0xFFE5A93C)); // Amber/Orange
    }
    if (lower.contains('nut') || lower.contains('almond') || lower.contains('hazelnut') || lower.contains('pecan') || lower.contains('cashew')) {
      return (Icons.cookie_rounded, const Color(0xFF8D6E63)); // Brown
    }
    if (lower.contains('milk') || lower.contains('lactose') || lower.contains('dairy')) {
      return (Icons.water_drop_rounded, const Color(0xFF64B5F6)); // Light Blue
    }
    if (lower.contains('egg')) {
      return (Icons.egg_rounded, const Color(0xFFFFD54F)); // Yellow
    }
    if (lower.contains('soy')) {
      return (Icons.grass_rounded, const Color(0xFF81C784)); // Green
    }
    if (lower.contains('fish') || lower.contains('seafood') || lower.contains('shrimp')) {
      return (Icons.set_meal_rounded, const Color(0xFF4FC3F7)); // Blue
    }

    // Certifications & Labels
    if (lower.contains('organic') || lower.contains('bio')) {
      return (Icons.eco_rounded, const Color(0xFF4CAF50)); // Green
    }
    if (lower.contains('ecocert')) {
      return (Icons.verified_rounded, const Color(0xFF2E7D32)); // Dark Green
    }
    if (lower.contains('green dot') || lower.contains('recycl')) {
      return (Icons.recycling_rounded, const Color(0xFF388E3C)); // Green
    }
    if (lower.contains('agriculture') || lower.contains('grower')) {
      return (Icons.spa_rounded, const Color(0xFF81C784)); // Soft Green
    }
    if (lower.contains('vegan') || lower.contains('vegetarian')) {
      return (Icons.spa_rounded, const Color(0xFF4CAF50)); // Green
    }
    if (lower.contains('halal') || lower.contains('kosher')) {
      return (Icons.task_alt_rounded, const Color(0xFF009688)); // Teal
    }
    if (lower.contains('fair trade') || lower.contains('fairtrade')) {
      return (Icons.handshake_rounded, const Color(0xFF00897B)); // Teal
    }

    return (Icons.verified_rounded, const Color(0xFF7B52D3)); // Purple accent
  }

  Widget _buildLabelItem(String label) {
    final clean = _cleanLabel(label);
    final iconInfo = _getIconAndColor(clean);
    final iconData = iconInfo.$1;
    final iconColor = iconInfo.$2;

    return Padding(
      padding: EdgeInsets.only(right: 12 * scale),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50 * scale,
            height: 50 * scale,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.clearGrey, width: 1.2),
            ),
            child: Center(
              child: Icon(
                iconData,
                color: iconColor,
                size: 24 * scale,
              ),
            ),
          ),
          SizedBox(height: 5 * scale),
          SizedBox(
            width: 62 * scale,
            child: Text(
              clean,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 10 * scale,
                fontWeight: FontWeight.w500,
                color: AppColors.black,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = labels;

    final List<String> row1;
    final List<String> row2;

    if (items.length <= 4) {
      row1 = items;
      row2 = [];
    } else {
      final half = (items.length / 2).ceil();
      row1 = items.sublist(0, half);
      row2 = items.sublist(half);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: row1.map((item) => _buildLabelItem(item)).toList(),
          ),
        ),
        if (row2.isNotEmpty) ...[
          SizedBox(height: 12 * scale),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: row2.map((item) => _buildLabelItem(item)).toList(),
            ),
          ),
        ],
      ],
    );
  }
}


// ─────────────────────────────────────────────────
// Outlined icon button (Add To List / Add To Recipe)
// ─────────────────────────────────────────────────
class _OutlineIconBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final double scale;
  final VoidCallback onTap;

  const _OutlineIconBtn({
    required this.icon,
    required this.label,
    required this.scale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44 * scale,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30 * scale),
          border: Border.all(color: AppColors.royalPurple, width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16 * scale, color: AppColors.royalPurple),
            SizedBox(width: 6 * scale),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13 * scale,
                fontWeight: FontWeight.w600,
                color: AppColors.royalPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 2.2.4 & 2.2.5 — Checkbox bottom-sheet dialog
// ═══════════════════════════════════════════════════════════════
class _ListCheckboxDialog extends StatelessWidget {
  final String title;
  final List<String> items;
  final List<String> selected;
  final String buttonLabel;
  final double scale;
  final EdgeInsets padding;
  final ValueChanged<String> onToggle;
  final VoidCallback onSave;
  final VoidCallback onDismiss;

  const _ListCheckboxDialog({
    required this.title,
    required this.items,
    required this.selected,
    required this.buttonLabel,
    required this.scale,
    required this.padding,
    required this.onToggle,
    required this.onSave,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        color: Colors.transparent,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20 * scale),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                20 * scale,
                20 * scale,
                20 * scale,
                padding.bottom + 20 * scale,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 15 * scale,
                            fontWeight: FontWeight.w700,
                            color: AppColors.black,
                            height: 1.4,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: onDismiss,
                        child: Icon(
                          Icons.close,
                          size: 22 * scale,
                          color: AppColors.black,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16 * scale),

                  // Checkboxes
                  ...items.map((item) {
                    final checked = selected.contains(item);
                    return GestureDetector(
                      onTap: () => onToggle(item),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 11 * scale),
                        child: Row(
                          children: [
                            Container(
                              width: 22 * scale,
                              height: 22 * scale,
                              decoration: BoxDecoration(
                                color: checked
                                    ? AppColors.royalPurple
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(4 * scale),
                                border: Border.all(
                                  color: checked
                                      ? AppColors.royalPurple
                                      : AppColors.inputBorder,
                                  width: 1.5,
                                ),
                              ),
                              child: checked
                                  ? Icon(
                                      Icons.check,
                                      size: 14 * scale,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            SizedBox(width: 12 * scale),
                            Text(
                              item,
                              style: GoogleFonts.inter(
                                fontSize: 14 * scale,
                                fontWeight: FontWeight.w500,
                                color: AppColors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  SizedBox(height: 20 * scale),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 52 * scale,
                    child: ElevatedButton(
                      onPressed: selected.isNotEmpty ? onSave : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.royalPurple,
                        disabledBackgroundColor: AppColors.lightRoyalPurple,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30 * scale),
                        ),
                      ),
                      child: Text(
                        buttonLabel,
                        style: GoogleFonts.inter(
                          fontSize: 15 * scale,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
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

// ─────────────────────────────────────────────────
