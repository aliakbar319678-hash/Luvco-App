import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import '../core/network/product_api_service.dart';
import 'favorites_provider.dart';

// ─────────────────────────────────────────────────
// Scanner UI states
// ─────────────────────────────────────────────────
enum BarcodeScanState {
  cameraPermission, // 2.2.0 — asking camera access
  scanning,         // 2.2.1 — live camera with scan frame
  loading,          // 2.2.x — fetching product from API
  notFound,         // 2.2.2 — product not found card
  cardOpen,         // 2.2.3 — product card open
  addToList,        // 2.2.4 — add to shopping list dialog
  addToRecipe,      // 2.2.5 — add to recipe dialog
}

// ─────────────────────────────────────────────────
// Immutable State
// ─────────────────────────────────────────────────
class BarcodeScannerState {
  final BarcodeScanState scanState;
  final ProductModel? scannedProduct;
  final bool isFavorite;
  final List<String> shoppingLists;
  final List<String> selectedLists;
  final List<String> recipes;
  final List<String> selectedRecipes;
  final String? lastScannedBarcode; // track to avoid duplicate fetches

  const BarcodeScannerState({
    this.scanState = BarcodeScanState.cameraPermission,
    this.scannedProduct,
    this.isFavorite = false,
    this.shoppingLists = const [
      'Shopping List 01',
      'Shopping List 02',
      'Shopping List 03',
      'Shopping List 04',
    ],
    this.selectedLists = const [],
    this.recipes = const ['Recipe 01', 'Recipe 02', 'Recipe 03'],
    this.selectedRecipes = const [],
    this.lastScannedBarcode,
  });

  BarcodeScannerState copyWith({
    BarcodeScanState? scanState,
    ProductModel? scannedProduct,
    bool clearProduct = false,
    bool? isFavorite,
    List<String>? shoppingLists,
    List<String>? selectedLists,
    List<String>? recipes,
    List<String>? selectedRecipes,
    String? lastScannedBarcode,
    bool clearLastBarcode = false,
  }) =>
      BarcodeScannerState(
        scanState: scanState ?? this.scanState,
        scannedProduct:
            clearProduct ? null : scannedProduct ?? this.scannedProduct,
        isFavorite: isFavorite ?? this.isFavorite,
        shoppingLists: shoppingLists ?? this.shoppingLists,
        selectedLists: selectedLists ?? this.selectedLists,
        recipes: recipes ?? this.recipes,
        selectedRecipes: selectedRecipes ?? this.selectedRecipes,
        lastScannedBarcode: clearLastBarcode
            ? null
            : lastScannedBarcode ?? this.lastScannedBarcode,
      );
}

// ─────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────
class BarcodeScannerNotifier extends StateNotifier<BarcodeScannerState> {
  final Ref _ref;

  BarcodeScannerNotifier(this._ref) : super(const BarcodeScannerState());

  void allowCamera() =>
      state = state.copyWith(scanState: BarcodeScanState.scanning);

  void denyCamera() {}

  /// Called every time the mobile_scanner detects a barcode.
  /// Debounced: if same barcode is already loading/shown, skip.
  Future<void> onBarcodeScanned(String? barcode) async {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🔍 BARCODE SCANNED: $barcode');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    if (barcode == null || barcode.isEmpty) {
      state = state.copyWith(scanState: BarcodeScanState.notFound);
      return;
    }

    // Debounce: skip if same barcode is already being processed or shown
    if (barcode == state.lastScannedBarcode &&
        (state.scanState == BarcodeScanState.loading ||
            state.scanState == BarcodeScanState.cardOpen)) {
      return;
    }

    // Show loading state
    state = state.copyWith(
      scanState: BarcodeScanState.loading,
      lastScannedBarcode: barcode,
      clearProduct: true,
    );

    try {
      debugPrint('📡 Calling API: GET /products/$barcode');
      final product =
          await ProductApiService.instance.lookupProduct(barcode);

      if (!mounted) return;

      final isFav = _ref
          .read(favoritesProvider)
          .items
          .any((i) => i.barcode == barcode);

      state = state.copyWith(
        scanState: BarcodeScanState.cardOpen,
        scannedProduct: product,
        isFavorite: isFav,
      );

      debugPrint('✅ Product loaded: ${product.name}');
    } catch (e) {
      if (!mounted) return;
      debugPrint('❌ Product lookup failed: $e');
      state = state.copyWith(
        scanState: BarcodeScanState.notFound,
        clearProduct: true,
        clearLastBarcode: true,
      );
    }
  }

  /// Simulates a successful scan (for dev/testing)
  void simulateScan() => onBarcodeScanned('8000500140001');

  /// Simulates a failed scan → goes to notFound (frame 2.2.2)
  void simulateNotFound() =>
      state = state.copyWith(scanState: BarcodeScanState.notFound);

  void retryScanning() => state = state.copyWith(
        scanState: BarcodeScanState.scanning,
        clearProduct: true,
        clearLastBarcode: true,
      );

  void closeCard() => state = state.copyWith(
        scanState: BarcodeScanState.scanning,
        clearProduct: true,
        clearLastBarcode: true,
      );

  Future<void> toggleFavorite() async {
    final product = state.scannedProduct;
    if (product == null) return;

    final barcode = product.id;
    final isFav = state.isFavorite;

    // Optimistic UI state toggle
    state = state.copyWith(isFavorite: !isFav);

    try {
      if (isFav) {
        await _ref.read(favoritesProvider.notifier).removeItem(barcode);
      } else {
        await _ref.read(favoritesProvider.notifier).addFavorite(
              barcode: barcode,
              productName: product.name,
              productImageUrl: product.thumbnailAsset,
            );
      }
    } catch (e) {
      // Rollback on failure
      state = state.copyWith(isFavorite: isFav);
    }
  }

  void openAddToList() =>
      state = state.copyWith(scanState: BarcodeScanState.addToList);

  void openAddToRecipe() =>
      state = state.copyWith(scanState: BarcodeScanState.addToRecipe);

  void closeDialog() =>
      state = state.copyWith(scanState: BarcodeScanState.cardOpen);

  void toggleList(String list) {
    final updated = List<String>.from(state.selectedLists);
    updated.contains(list) ? updated.remove(list) : updated.add(list);
    state = state.copyWith(selectedLists: updated);
  }

  void toggleRecipe(String recipe) {
    final updated = List<String>.from(state.selectedRecipes);
    updated.contains(recipe) ? updated.remove(recipe) : updated.add(recipe);
    state = state.copyWith(selectedRecipes: updated);
  }

  void saveOnList() => state = state.copyWith(
        scanState: BarcodeScanState.cardOpen,
        selectedLists: [],
      );

  void saveOnRecipe() => state = state.copyWith(
        scanState: BarcodeScanState.cardOpen,
        selectedRecipes: [],
      );

  void reset() => state = const BarcodeScannerState();
}

// ─────────────────────────────────────────────────
// Provider (autoDispose — cleans up when screen is popped)
// ─────────────────────────────────────────────────
final barcodeScannerProvider =
    StateNotifierProvider.autoDispose<
      BarcodeScannerNotifier,
      BarcodeScannerState
    >((ref) => BarcodeScannerNotifier(ref));
