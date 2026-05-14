import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

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
            // ── Full screen camera background ──
            _CameraBackground(scale: scale),

            // ── Top navigation icons (back + close) ──
            _TopNavIcons(
              scale: scale,
              onBack: () => context.pop(),
              onClose: () => context.pop(),
            ),

            // ── State-specific overlays ──
            if (state.scanState == BarcodeScanState.cameraPermission)
              _CameraPermissionDialog(
                scale: scale,
                size: size,
                onAllow: notifier.allowCamera,
                onDeny: () => context.pop(),
              ),

            if (state.scanState == BarcodeScanState.scanning)
              _ScanOverlay(
                scale: scale,
                size: size,
                onScanTap: notifier.simulateScan,
                onNotFoundTap: notifier.simulateNotFound,
              ),

            if (state.scanState == BarcodeScanState.notFound)
              _NotFoundCard(
                scale: scale,
                size: size,
                onRetry: notifier.retryScanning,
              ),

            if (state.scanState == BarcodeScanState.cardOpen ||
                state.scanState == BarcodeScanState.addToList ||
                state.scanState == BarcodeScanState.addToRecipe)
              _ProductCardOverlay(
                product: state.scannedProduct ?? _demoScannedProduct,
                isFavorite: state.isFavorite,
                scale: scale,
                size: size,
                onClose: notifier.closeCard,
                onToggleFavorite: notifier.toggleFavorite,
                onAddToList: notifier.openAddToList,
                onAddToRecipe: notifier.openAddToRecipe,
                onSeeMoreDetails: () {
                  notifier.closeCard();
                  context.push(
                    '/product-detail',
                    extra: state.scannedProduct ?? _demoScannedProduct,
                  );
                },
              ),

            // ── Add To Shopping List Dialog ──
            if (state.scanState == BarcodeScanState.addToList)
              _CheckboxDialog(
                title: 'Which shopping list do you want\nto add this product?',
                items: state.shoppingLists,
                selected: state.selectedLists,
                buttonLabel: 'Save On List',
                scale: scale,
                size: size,
                onToggle: notifier.toggleList,
                onSave: notifier.saveOnList,
                onDismiss: notifier.closeDialog,
              ),

            // ── Add To Recipe Dialog ──
            if (state.scanState == BarcodeScanState.addToRecipe)
              _CheckboxDialog(
                title: 'Which recipe do you want to add\nthis product?',
                items: state.recipes,
                selected: state.selectedRecipes,
                buttonLabel: 'Save On Recipe',
                scale: scale,
                size: size,
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

// ═══════════════════════════════════════════════════════════════
// Camera background (simulated — replace with real camera plugin)
// ═══════════════════════════════════════════════════════════════
class _CameraBackground extends StatelessWidget {
  final double scale;
  const _CameraBackground({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2A1A0E), Color(0xFF3D2B1A), Color(0xFF2A1A0E)],
        ),
      ),
      child: Stack(
        children: [
          // Simulated blurred product image in background
          Positioned.fill(
            child: Image.asset(
              'assets/images/nutila.png',
              fit: BoxFit.cover,
              color: Colors.black.withValues(alpha: 0.55),
              colorBlendMode: BlendMode.darken,
              errorBuilder: (_, __, ___) => Container(color: Colors.black87),
            ),
          ),
          // Blur effect simulation with dark overlay
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.3)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Top nav icons — back (left) + close (right) — white
// ═══════════════════════════════════════════════════════════════
class _TopNavIcons extends StatelessWidget {
  final double scale;
  final VoidCallback onBack;
  final VoidCallback onClose;

  const _TopNavIcons({
    required this.scale,
    required this.onBack,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Positioned(
      top: top + 8 * scale,
      left: 16 * scale,
      right: 16 * scale,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: onBack,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 40 * scale,
              height: 40 * scale,
              alignment: Alignment.center,
              child: Icon(
                Icons.chevron_left,
                color: Colors.white,
                size: 28 * scale,
              ),
            ),
          ),
          GestureDetector(
            onTap: onClose,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 40 * scale,
              height: 40 * scale,
              alignment: Alignment.center,
              child: Icon(Icons.close, color: Colors.white, size: 22 * scale),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Frame 2.2.0 — Camera permission iOS-style dialog
// ═══════════════════════════════════════════════════════════════
class _CameraPermissionDialog extends StatelessWidget {
  final double scale;
  final Size size;
  final VoidCallback onAllow;
  final VoidCallback onDeny;

  const _CameraPermissionDialog({
    required this.scale,
    required this.size,
    required this.onAllow,
    required this.onDeny,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 48 * scale),
        constraints: BoxConstraints(maxWidth: 310 * scale),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(14 * scale),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Title + body ──
            Padding(
              padding: EdgeInsets.fromLTRB(
                16 * scale,
                20 * scale,
                16 * scale,
                16 * scale,
              ),
              child: Column(
                children: [
                  Text(
                    '"Luvco" would like to access\nthe camera',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14 * scale,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: 6 * scale),
                  Text(
                    'Lorem ipsum dolor sit amet,\nconsectetur adipiscing elit.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12 * scale,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // ── Divider ──
            Divider(height: 1, color: Colors.grey.withValues(alpha: 0.4)),

            // ── Don't Allow / OK row ──
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: onDeny,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12 * scale),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(14 * scale),
                          ),
                        ),
                      ),
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
                  VerticalDivider(
                    width: 1,
                    color: Colors.grey.withValues(alpha: 0.4),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: onAllow,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12 * scale),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(14 * scale),
                          ),
                        ),
                      ),
                      child: Text(
                        'OK',
                        style: GoogleFonts.inter(
                          fontSize: 14 * scale,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF007AFF),
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
// Frame 2.2.1 — Scan overlay with corner brackets + button
// ═══════════════════════════════════════════════════════════════
class _ScanOverlay extends StatelessWidget {
  final double scale;
  final Size size;
  final VoidCallback onScanTap;
  final VoidCallback onNotFoundTap;

  const _ScanOverlay({
    required this.scale,
    required this.size,
    required this.onScanTap,
    required this.onNotFoundTap,
  });

  @override
  Widget build(BuildContext context) {
    final frameSize = 240.0 * scale;

    return Stack(
      children: [
        // ── Dark overlay with hole in center ──
        CustomPaint(
          size: Size(size.width, size.height),
          painter: _ScanHolePainter(frameSize: frameSize, screenSize: size),
        ),

        // ── Corner brackets ──
        Center(
          child: SizedBox(
            width: frameSize,
            height: frameSize,
            child: CustomPaint(painter: _CornerBracketsPainter(scale: scale)),
          ),
        ),

        // ── Bottom "Scan A Barcode" button ──
        Positioned(
          bottom: MediaQuery.paddingOf(context).bottom + 40 * scale,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: onScanTap,
              child: Container(
                height: 52 * scale,
                padding: EdgeInsets.symmetric(horizontal: 40 * scale),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30 * scale),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.qr_code_scanner_rounded,
                      size: 20 * scale,
                      color: AppColors.black,
                    ),
                    SizedBox(width: 8 * scale),
                    Text(
                      'Scan A Barcode',
                      style: GoogleFonts.inter(
                        fontSize: 15 * scale,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Dark overlay with transparent rectangle hole
class _ScanHolePainter extends CustomPainter {
  final double frameSize;
  final Size screenSize;

  const _ScanHolePainter({required this.frameSize, required this.screenSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    final cx = size.width / 2;
    final cy = size.height / 2 - 40;
    final half = frameSize / 2;
    const r = 12.0;

    // Full screen rect
    final full = Rect.fromLTWH(0, 0, size.width, size.height);
    // Hole rect
    final hole = RRect.fromRectAndRadius(
      Rect.fromLTRB(cx - half, cy - half, cx + half, cy + half),
      const Radius.circular(r),
    );

    final path = Path()
      ..addRect(full)
      ..addRRect(hole)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// White corner bracket lines
class _CornerBracketsPainter extends CustomPainter {
  final double scale;
  const _CornerBracketsPainter({required this.scale});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.5 * scale
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final len = 28.0 * scale;
    const r = 10.0;

    // Top-left
    canvas.drawLine(const Offset(r, 0), Offset(r + len, 0), paint);
    canvas.drawLine(const Offset(0, r), Offset(0, r + len), paint);
    canvas.drawArc(
      const Rect.fromLTWH(0, 0, r * 2, r * 2),
      -3.14,
      1.57,
      false,
      paint,
    );

    // Top-right
    canvas.drawLine(
      Offset(size.width - r - len, 0),
      Offset(size.width - r, 0),
      paint,
    );
    canvas.drawLine(Offset(size.width, r), Offset(size.width, r + len), paint);
    canvas.drawArc(
      Rect.fromLTWH(size.width - r * 2, 0, r * 2, r * 2),
      -1.57,
      1.57,
      false,
      paint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(r, size.height),
      Offset(r + len, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height - r - len),
      Offset(0, size.height - r),
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(0, size.height - r * 2, r * 2, r * 2),
      1.57,
      1.57,
      false,
      paint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(size.width - r - len, size.height),
      Offset(size.width - r, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height - r - len),
      Offset(size.width, size.height - r),
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(size.width - r * 2, size.height - r * 2, r * 2, r * 2),
      0,
      1.57,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════
// Frame 2.2.2 — Product not found card
// ═══════════════════════════════════════════════════════════════
class _NotFoundCard extends StatelessWidget {
  final double scale;
  final Size size;
  final VoidCallback onRetry;

  const _NotFoundCard({
    required this.scale,
    required this.size,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onRetry,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 32 * scale),
          constraints: BoxConstraints(maxWidth: 300 * scale),
          padding: EdgeInsets.symmetric(
            horizontal: 24 * scale,
            vertical: 28 * scale,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20 * scale),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Red scan-error icon
              Container(
                width: 64 * scale,
                height: 64 * scale,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEB),
                  borderRadius: BorderRadius.circular(16 * scale),
                ),
                child: Icon(
                  Icons.document_scanner_outlined,
                  color: AppColors.errorRed,
                  size: 36 * scale,
                ),
              ),
              SizedBox(height: 16 * scale),
              Text(
                'Product not found, try to\nscan again',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15 * scale,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Frame 2.2.3 — Scanned product card overlay (bottom sheet style)
// ═══════════════════════════════════════════════════════════════
class _ProductCardOverlay extends StatelessWidget {
  final ProductModel product;
  final bool isFavorite;
  final double scale;
  final Size size;
  final VoidCallback onClose;
  final VoidCallback onToggleFavorite;
  final VoidCallback onAddToList;
  final VoidCallback onAddToRecipe;
  final VoidCallback onSeeMoreDetails;

  const _ProductCardOverlay({
    required this.product,
    required this.isFavorite,
    required this.scale,
    required this.size,
    required this.onClose,
    required this.onToggleFavorite,
    required this.onAddToList,
    required this.onAddToRecipe,
    required this.onSeeMoreDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxHeight: size.height * 0.82),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24 * scale)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag handle ──
            SizedBox(height: 10 * scale),
            Container(
              width: 40 * scale,
              height: 4 * scale,
              decoration: BoxDecoration(
                color: AppColors.clearGrey,
                borderRadius: BorderRadius.circular(2 * scale),
              ),
            ),
            SizedBox(height: 8 * scale),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20 * scale),
                child: Column(
                  children: [
                    // ── Close button row ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Spacer(),
                        GestureDetector(
                          onTap: onClose,
                          child: Icon(
                            Icons.close,
                            size: 22 * scale,
                            color: AppColors.black,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 4 * scale),

                    // ── Product name + subtitle ──
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

                    // ── Image section with badges ──
                    _CardImageSection(
                      product: product,
                      isFavorite: isFavorite,
                      scale: scale,
                      onFavoriteTap: onToggleFavorite,
                    ),

                    SizedBox(height: 20 * scale),

                    // ── Labels and Certifications ──
                    _CardSectionTitle(
                      title: 'Labels and Certifications',
                      scale: scale,
                    ),
                    SizedBox(height: 10 * scale),
                    _HexLabelRow(labels: product.labels, scale: scale),

                    SizedBox(height: 20 * scale),

                    // ── Possible allergens ──
                    _CardSectionTitle(
                      title: 'Possible allergens',
                      scale: scale,
                    ),
                    SizedBox(height: 10 * scale),
                    _HexLabelRow(labels: product.allergens, scale: scale),

                    SizedBox(height: 24 * scale),

                    // ── Add To List + Add To Recipe outline buttons ──
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onAddToList,
                            icon: Icon(
                              Icons.shopping_basket_outlined,
                              size: 16 * scale,
                              color: AppColors.royalPurple,
                            ),
                            label: Text(
                              'Add To List',
                              style: GoogleFonts.inter(
                                fontSize: 13 * scale,
                                fontWeight: FontWeight.w600,
                                color: AppColors.royalPurple,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: AppColors.royalPurple,
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30 * scale),
                              ),
                              padding: EdgeInsets.symmetric(
                                vertical: 12 * scale,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10 * scale),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onAddToRecipe,
                            icon: Icon(
                              Icons.restaurant_menu_outlined,
                              size: 16 * scale,
                              color: AppColors.royalPurple,
                            ),
                            label: Text(
                              'Add To Recipe',
                              style: GoogleFonts.inter(
                                fontSize: 13 * scale,
                                fontWeight: FontWeight.w600,
                                color: AppColors.royalPurple,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: AppColors.royalPurple,
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30 * scale),
                              ),
                              padding: EdgeInsets.symmetric(
                                vertical: 12 * scale,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 10 * scale),

                    // ── See More Details solid button ──
                    SizedBox(
                      width: double.infinity,
                      height: 50 * scale,
                      child: ElevatedButton(
                        onPressed: onSeeMoreDetails,
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

                    // ── Swipe hint ──
                    Text(
                      'Swipe up to see similar',
                      style: GoogleFonts.inter(
                        fontSize: 12 * scale,
                        color: AppColors.neutralGrey,
                      ),
                    ),

                    SizedBox(
                      height: MediaQuery.paddingOf(context).bottom + 12 * scale,
                    ),
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

// ── Card image section with badges + heart ──
class _CardImageSection extends StatelessWidget {
  final ProductModel product;
  final bool isFavorite;
  final double scale;
  final VoidCallback onFavoriteTap;

  const _CardImageSection({
    required this.product,
    required this.isFavorite,
    required this.scale,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // ── Badges top row ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 36 * scale,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16 * scale),
                        bottomRight: Radius.circular(10 * scale),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.eco_outlined,
                          color: Colors.white,
                          size: 14 * scale,
                        ),
                        SizedBox(width: 4 * scale),
                        Text(
                          'Unsustainable',
                          style: GoogleFonts.inter(
                            fontSize: 11 * scale,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 36 * scale,
                    decoration: BoxDecoration(
                      color: const Color(0xFF43A047),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(16 * scale),
                        bottomLeft: Radius.circular(10 * scale),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.flag_outlined,
                          color: Colors.white,
                          size: 14 * scale,
                        ),
                        SizedBox(width: 4 * scale),
                        Text(
                          'Safe',
                          style: GoogleFonts.inter(
                            fontSize: 11 * scale,
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

          // ── Product image ──
          Padding(
            padding: EdgeInsets.only(
              top: 46 * scale,
              bottom: 16 * scale,
              left: 16 * scale,
              right: 16 * scale,
            ),
            child: Center(
              child: product.imageAsset != null
                  ? Image.asset(
                      product.imageAsset!,
                      height: 140 * scale,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.image_outlined,
                        size: 64 * scale,
                        color: AppColors.neutralGrey,
                      ),
                    )
                  : Icon(
                      Icons.image_outlined,
                      size: 64 * scale,
                      color: AppColors.neutralGrey,
                    ),
            ),
          ),

          // ── Heart icon ──
          Positioned(
            top: 46 * scale,
            right: 12 * scale,
            child: GestureDetector(
              onTap: onFavoriteTap,
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
    );
  }
}

// ── Card section title ──
class _CardSectionTitle extends StatelessWidget {
  final String title;
  final double scale;
  const _CardSectionTitle({required this.title, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Align(
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
}

// ── Hexagon labels horizontal row ──
class _HexLabelRow extends StatelessWidget {
  final List<String> labels;
  final double scale;
  const _HexLabelRow({required this.labels, required this.scale});

  @override
  Widget build(BuildContext context) {
    final items = labels.isEmpty
        ? const ['Label', 'Label', 'Label', 'Label']
        : labels;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: items.map((label) {
          return Padding(
            padding: EdgeInsets.only(right: 10 * scale),
            child: Column(
              children: [
                Container(
                  width: 50 * scale,
                  height: 50 * scale,
                  decoration: BoxDecoration(
                    color: AppColors.pureWhite,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.clearGrey),
                  ),
                  child: Icon(
                    Icons.hexagon_outlined,
                    color: AppColors.black,
                    size: 24 * scale,
                  ),
                ),
                SizedBox(height: 5 * scale),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11 * scale,
                    color: AppColors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Frames 2.2.4 & 2.2.5 — Checkbox dialog (Add to List / Recipe)
// ═══════════════════════════════════════════════════════════════
class _CheckboxDialog extends StatelessWidget {
  final String title;
  final List<String> items;
  final List<String> selected;
  final String buttonLabel;
  final double scale;
  final Size size;
  final ValueChanged<String> onToggle;
  final VoidCallback onSave;
  final VoidCallback onDismiss;

  const _CheckboxDialog({
    required this.title,
    required this.items,
    required this.selected,
    required this.buttonLabel,
    required this.scale,
    required this.size,
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
                MediaQuery.paddingOf(context).bottom + 20 * scale,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──
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

                  SizedBox(height: 14 * scale),

                  // ── Checkbox list ──
                  ...items.map((item) {
                    final isChecked = selected.contains(item);
                    return InkWell(
                      onTap: () => onToggle(item),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 11 * scale),
                        child: Row(
                          children: [
                            Container(
                              width: 22 * scale,
                              height: 22 * scale,
                              decoration: BoxDecoration(
                                color: isChecked
                                    ? AppColors.royalPurple
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(4 * scale),
                                border: Border.all(
                                  color: isChecked
                                      ? AppColors.royalPurple
                                      : AppColors.inputBorder,
                                  width: 1.5,
                                ),
                              ),
                              child: isChecked
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

                  // ── Save button ──
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

// ── Demo product fallback ──
const _demoScannedProduct = ProductModel(
  id: 'scan_001',
  name: 'Name of the Product',
  description: 'Other data from the product.',
  imageAsset: 'assets/images/nutila.png',
  thumbnailAsset: 'assets/images/nutila.png',
  isSustainable: false,
  labels: ['Label', 'Label', 'Label', 'Label'],
  allergens: ['Label', 'Label', 'Label', 'Label'],
  ingredients: ['Ingredient Name', 'Ingredient Name'],
);
