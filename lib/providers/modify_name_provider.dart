import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/user_api_service.dart';
import 'user_profile_provider.dart';

// ─────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────
class ModifyNameState {
  final bool isSaving;
  final bool saveSuccess;
  final String? errorMessage;

  const ModifyNameState({
    this.isSaving = false,
    this.saveSuccess = false,
    this.errorMessage,
  });

  ModifyNameState copyWith({
    bool? isSaving,
    bool? saveSuccess,
    String? errorMessage,
    bool clearError = false,
  }) => ModifyNameState(
    isSaving: isSaving ?? this.isSaving,
    saveSuccess: saveSuccess ?? this.saveSuccess,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );
}

// ─────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────
class ModifyNameNotifier extends StateNotifier<ModifyNameState> {
  final Ref _ref;

  ModifyNameNotifier(this._ref) : super(const ModifyNameState());

  Future<void> saveChanges({required String firstName, required String lastName}) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final updatedUser = await UserApiService.instance.updateName(
        firstName: firstName.trim(),
        lastName: lastName.trim(),
      );
      _ref.read(userProfileProvider.notifier).updateProfile(updatedUser);
      state = state.copyWith(isSaving: false, saveSuccess: true);
    } catch (e) {
      debugPrint("Error in updateName: $e");
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
    }
  }

  void dismissSuccess() => state = state.copyWith(saveSuccess: false, clearError: true);

  void reset() => state = const ModifyNameState();
}

final modifyNameProvider =
    StateNotifierProvider.autoDispose<ModifyNameNotifier, ModifyNameState>((ref) {
  return ModifyNameNotifier(ref);
});
