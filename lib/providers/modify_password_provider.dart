import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/user_api_service.dart';

// ─────────────────────────────────────────────────────────────────
// Validation error types
// ─────────────────────────────────────────────────────────────────
enum PasswordFieldError {
  none,
  wrongCurrent, // frame 1.6.16 — wrong current password
  weakNew, // frame 1.6.18 — new pw < 8 chars or no mix
  mismatch, // frame 1.6.17 — confirm ≠ new
}

// ─────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────
class ModifyPasswordState {
  final String currentPassword;
  final String newPassword;
  final String confirmPassword;

  final bool obscureCurrent;
  final bool obscureNew;
  final bool obscureConfirm;

  final PasswordFieldError currentError;
  final PasswordFieldError newError;
  final PasswordFieldError confirmError;

  final bool isSaving;
  final bool saveSuccess;

  const ModifyPasswordState({
    this.currentPassword = '',
    this.newPassword = '',
    this.confirmPassword = '',
    this.obscureCurrent = true,
    this.obscureNew = true,
    this.obscureConfirm = true,
    this.currentError = PasswordFieldError.none,
    this.newError = PasswordFieldError.none,
    this.confirmError = PasswordFieldError.none,
    this.isSaving = false,
    this.saveSuccess = false,
  });

  bool get canSave =>
      currentPassword.isNotEmpty &&
      newPassword.isNotEmpty &&
      confirmPassword.isNotEmpty;

  ModifyPasswordState copyWith({
    String? currentPassword,
    String? newPassword,
    String? confirmPassword,
    bool? obscureCurrent,
    bool? obscureNew,
    bool? obscureConfirm,
    PasswordFieldError? currentError,
    PasswordFieldError? newError,
    PasswordFieldError? confirmError,
    bool? isSaving,
    bool? saveSuccess,
  }) => ModifyPasswordState(
    currentPassword: currentPassword ?? this.currentPassword,
    newPassword: newPassword ?? this.newPassword,
    confirmPassword: confirmPassword ?? this.confirmPassword,
    obscureCurrent: obscureCurrent ?? this.obscureCurrent,
    obscureNew: obscureNew ?? this.obscureNew,
    obscureConfirm: obscureConfirm ?? this.obscureConfirm,
    currentError: currentError ?? this.currentError,
    newError: newError ?? this.newError,
    confirmError: confirmError ?? this.confirmError,
    isSaving: isSaving ?? this.isSaving,
    saveSuccess: saveSuccess ?? this.saveSuccess,
  );
}

// ─────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────
class ModifyPasswordNotifier extends StateNotifier<ModifyPasswordState> {
  ModifyPasswordNotifier() : super(const ModifyPasswordState());

  void setCurrentPassword(String v) => state = state.copyWith(
    currentPassword: v,
    currentError: PasswordFieldError.none,
  );

  void setNewPassword(String v) => state = state.copyWith(
    newPassword: v,
    newError: PasswordFieldError.none,
    confirmError: PasswordFieldError.none,
  );

  void setConfirmPassword(String v) => state = state.copyWith(
    confirmPassword: v,
    confirmError: PasswordFieldError.none,
  );

  void toggleObscureCurrent() =>
      state = state.copyWith(obscureCurrent: !state.obscureCurrent);

  void toggleObscureNew() =>
      state = state.copyWith(obscureNew: !state.obscureNew);

  void toggleObscureConfirm() =>
      state = state.copyWith(obscureConfirm: !state.obscureConfirm);

  // Password strength: at least 8 chars with letters + numbers + symbols
  bool _isStrongPassword(String pw) {
    if (pw.length < 8) return false;
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(pw);
    final hasDigit = RegExp(r'[0-9]').hasMatch(pw);
    final hasSymbol = RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(pw);
    return hasLetter && hasDigit && hasSymbol;
  }

  Future<void> saveChanges() async {
    // Validate new password strength
    if (!_isStrongPassword(state.newPassword)) {
      state = state.copyWith(newError: PasswordFieldError.weakNew);
      return;
    }

    // Validate confirm matches new
    if (state.newPassword != state.confirmPassword) {
      state = state.copyWith(confirmError: PasswordFieldError.mismatch);
      return;
    }

    // All valid — call backend change password
    state = state.copyWith(isSaving: true);
    try {
      await UserApiService.instance.changePassword(
        currentPassword: state.currentPassword,
        newPassword: state.newPassword,
      );
      state = state.copyWith(isSaving: false, saveSuccess: true);
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('invalid_password') || errStr.contains('incorrect') || errStr.contains('current password')) {
        state = state.copyWith(
          isSaving: false,
          currentError: PasswordFieldError.wrongCurrent,
        );
      } else if (errStr.contains('weak') || errStr.contains('characters')) {
        state = state.copyWith(
          isSaving: false,
          newError: PasswordFieldError.weakNew,
        );
      } else {
        state = state.copyWith(isSaving: false);
      }
    }
  }

  void dismissSuccess() => state = state.copyWith(saveSuccess: false);
}

// ─────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────
final modifyPasswordProvider =
    StateNotifierProvider.autoDispose<
      ModifyPasswordNotifier,
      ModifyPasswordState
    >((_) => ModifyPasswordNotifier());
