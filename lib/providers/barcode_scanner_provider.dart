import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';

// ─────────────────────────────────────────────────
// Scanner UI states
// ─────────────────────────────────────────────────
enum BarcodeScanState {
  cameraPermission, // 2.2.0 — asking camera access
  scanning,         // 2.2.1 — live camera with scan frame
  notFound,         // 2.2.2 — product not found card
  cardOpen,         // 2.2.3 — product card open
  addToList,        // 2.2.4 — add to shopping list dialog
  addToRecipe,      // 2.2.5 — add to recipe dialog
}

// ─────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────
class BarcodeScannerState {
  final BarcodeScanState scanState;
  final ProductModel? scannedProduct;
  final bool isFavorite;

  // Add to list
  final List<String> shoppingLists;
  final List<String> selectedLists;

  // Add to recipe
  final List<String> recipes;
  final List<String> selectedRecipes;

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
      );
}

// ─────────────────────────────────────────────────
// Demo scanned product
// ─────────────────────────────────────────────────
const _demoScannedProduct = ProductModel(
  id: 'scan_001',
  name: 'Name of the Product',
  description: 'Other data from the product.',
  imageAsset: 'assets/images/nutila.png',
  thumbnailAsset: 'assets/images/nutila.png',
  isSustainable: false,
  labels: ['Label', 'Label', 'Label', 'Label'],
  allergens: ['Label', 'Label', 'Label', 'Label'],
  ingredients: ['Ingredient Name', 'Ingredient Name', 'Ingredient Name'],
);

// ─────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────
class BarcodeScannerNotifier extends StateNotifier<BarcodeScannerState> {
  BarcodeScannerNotifier() : super(const BarcodeScannerState());

  // Camera permission
  void allowCamera() =>
      state = state.copyWith(scanState: BarcodeScanState.scanning);

  void denyCamera() {} // stay on permission screen or pop

  // Simulate barcode scan — in production replace with real scanner result
  void onBarcodeScanned(String? barcode) {
    if (barcode == null || barcode.isEmpty) {
      state = state.copyWith(scanState: BarcodeScanState.notFound);
      return;
    }
    // Demo: any valid barcode returns the demo product
    state = state.copyWith(
      scanState: BarcodeScanState.cardOpen,
      scannedProduct: _demoScannedProduct,
    );
  }

  void simulateScan() => onBarcodeScanned('1234567890');
  void simulateNotFound() =>
      state = state.copyWith(scanState: BarcodeScanState.notFound);

  void retryScanning() =>
      state = state.copyWith(
          scanState: BarcodeScanState.scanning, clearProduct: true);

  void closeCard() =>
      state = state.copyWith(
          scanState: BarcodeScanState.scanning, clearProduct: true);

  void toggleFavorite() =>
      state = state.copyWith(isFavorite: !state.isFavorite);

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

final barcodeScannerProvider =
    StateNotifierProvider.autoDispose<BarcodeScannerNotifier, BarcodeScannerState>(
  (_) => BarcodeScannerNotifier(),
);