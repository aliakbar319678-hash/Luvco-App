import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────
class ModifyNameState {
  final String firstName;
  final String lastName;
  final bool isSaving;
  final bool saveSuccess;

  const ModifyNameState({
    this.firstName = '',
    this.lastName = '',
    this.isSaving = false,
    this.saveSuccess = false,
  });

  // Button enabled only when firstName is not empty
  bool get canSave => firstName.trim().isNotEmpty;

  ModifyNameState copyWith({
    String? firstName,
    String? lastName,
    bool? isSaving,
    bool? saveSuccess,
  }) => ModifyNameState(
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    isSaving: isSaving ?? this.isSaving,
    saveSuccess: saveSuccess ?? this.saveSuccess,
  );
}

// ─────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────
class ModifyNameNotifier extends StateNotifier<ModifyNameState> {
  ModifyNameNotifier() : super(const ModifyNameState());

  void setFirstName(String value) => state = state.copyWith(firstName: value);

  void setLastName(String value) => state = state.copyWith(lastName: value);

  Future<void> saveChanges() async {
    if (!state.canSave) return;
    state = state.copyWith(isSaving: true);
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 800));
    state = state.copyWith(isSaving: false, saveSuccess: true);
  }

  void dismissSuccess() => state = state.copyWith(saveSuccess: false);

  void reset() => state = const ModifyNameState();
}

// ── No autoDispose — name persists in session ────────────────────
final modifyNameProvider =
    StateNotifierProvider<ModifyNameNotifier, ModifyNameState>(
      (_) => ModifyNameNotifier(),
    );
