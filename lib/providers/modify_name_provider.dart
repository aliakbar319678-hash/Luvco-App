import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/user_api_service.dart';
import 'user_profile_provider.dart';

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
  final Ref _ref;

  ModifyNameNotifier(this._ref) : super(const ModifyNameState());

  void loadCurrentName(String first, String last) {
    state = state.copyWith(firstName: first, lastName: last);
  }

  void setFirstName(String value) => state = state.copyWith(firstName: value);

  void setLastName(String value) => state = state.copyWith(lastName: value);

  Future<void> saveChanges() async {
    if (!state.canSave) return;
    state = state.copyWith(isSaving: true);
    try {
      final updatedUser = await UserApiService.instance.updateName(
        firstName: state.firstName.trim(),
        lastName: state.lastName.trim(),
      );
      _ref.read(userProfileProvider.notifier).updateProfile(updatedUser);
      state = state.copyWith(isSaving: false, saveSuccess: true);
    } catch (_) {
      state = state.copyWith(isSaving: false);
    }
  }

  void dismissSuccess() => state = state.copyWith(saveSuccess: false);

  void reset() => state = const ModifyNameState();
}

// ── No autoDispose — name persists in session ────────────────────
final modifyNameProvider =
    StateNotifierProvider<ModifyNameNotifier, ModifyNameState>((ref) {
  return ModifyNameNotifier(ref);
});
