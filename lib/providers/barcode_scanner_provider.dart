import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import '../models/shopping_list_model.dart';
import '../models/recipe_model.dart';
import '../core/network/product_api_service.dart';
import '../core/network/list_api_service.dart';
import '../core/network/recipe_api_service.dart';
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
  final List<ShoppingListModel> shoppingLists;
  final List<String> selectedLists;
  final List<RecipeModel> recipes;
  final List<String> selectedRecipes;
  final String? lastScannedBarcode; // track to avoid duplicate fetches
  final bool isSaving;

  const BarcodeScannerState({
    this.scanState = BarcodeScanState.cameraPermission,
    this.scannedProduct,
    this.isFavorite = false,
    this.shoppingLists = const [],
    this.selectedLists = const [],
    this.recipes = const [],
    this.selectedRecipes = const [],
    this.lastScannedBarcode,
    this.isSaving = false,
  });

  BarcodeScannerState copyWith({
    BarcodeScanState? scanState,
    ProductModel? scannedProduct,
    bool clearProduct = false,
    bool? isFavorite,
    List<ShoppingListModel>? shoppingLists,
    List<String>? selectedLists,
    List<RecipeModel>? recipes,
    List<String>? selectedRecipes,
    String? lastScannedBarcode,
    bool clearLastBarcode = false,
    bool? isSaving,
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
        isSaving: isSaving ?? this.isSaving,
      );
}

// ─────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────
class BarcodeScannerNotifier extends StateNotifier<BarcodeScannerState> {
  final Ref _ref;

  BarcodeScannerNotifier(this._ref) : super(const BarcodeScannerState()) {
    _loadListsAndRecipes();
  }

  Future<void> _loadListsAndRecipes() async {
    try {
      final lists = await ListApiService.instance.getLists();
      final recs = await RecipeApiService.instance.getRecipes('my-recipes');
      state = state.copyWith(
        shoppingLists: lists,
        recipes: recs,
      );
    } catch (_) {}
  }

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

  void toggleList(String listId) {
    final updated = List<String>.from(state.selectedLists);
    updated.contains(listId) ? updated.remove(listId) : updated.add(listId);
    state = state.copyWith(selectedLists: updated);
  }

  void toggleRecipe(String recipeId) {
    final updated = List<String>.from(state.selectedRecipes);
    updated.contains(recipeId) ? updated.remove(recipeId) : updated.add(recipeId);
    state = state.copyWith(selectedRecipes: updated);
  }

  Future<String?> saveOnList() async {
    final product = state.scannedProduct;
    if (product == null) return 'No product scanned';
    if (state.selectedLists.isEmpty) return 'Please select at least one list';

    state = state.copyWith(isSaving: true);
    int successCount = 0;
    for (final listId in state.selectedLists) {
      try {
        await ListApiService.instance.addItem(
          listId,
          barcode: product.id,
          productName: product.name,
          productImageUrl: product.thumbnailAsset,
          quantity: 1,
        );
        successCount++;
      } catch (_) {}
    }

    state = state.copyWith(
      scanState: BarcodeScanState.cardOpen,
      selectedLists: [],
      isSaving: false,
    );

    if (successCount > 0) {
      return successCount == 1
          ? 'Product added to shopping list!'
          : 'Product added to $successCount lists!';
    }
    return 'Failed to add product';
  }

  Future<String?> saveOnRecipe() async {
    final product = state.scannedProduct;
    if (product == null) return 'No product scanned';
    if (state.selectedRecipes.isEmpty) return 'Please select at least one recipe';

    state = state.copyWith(isSaving: true);
    int successCount = 0;
    for (final recipeId in state.selectedRecipes) {
      try {
        await RecipeApiService.instance.addLinkedProduct(recipeId, {
          'barcode': product.id,
          'productName': product.name,
          'productImageUrl': product.thumbnailAsset,
          'quantity': 1,
          'position': 1,
        });
        successCount++;
      } catch (_) {}
    }

    state = state.copyWith(
      scanState: BarcodeScanState.cardOpen,
      selectedRecipes: [],
      isSaving: false,
    );

    if (successCount > 0) {
      return successCount == 1
          ? 'Product added to recipe successfully!'
          : 'Product added to $successCount recipes!';
    }
    return 'Failed to add product to recipe';
  }

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
