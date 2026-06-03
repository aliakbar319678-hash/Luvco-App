import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/auth_api_service.dart';

// ── Individual field values ───────────────────────────────────────
final newPasswordProvider = StateProvider<String>((ref) => '');
final confirmPasswordProvider = StateProvider<String>((ref) => '');

// ── Visibility toggles ────────────────────────────────────────────
final newPasswordVisibleProvider = StateProvider<bool>((ref) => false);
final confirmPasswordVisibleProvider = StateProvider<bool>((ref) => false);

// ── Status ────────────────────────────────────────────────────────
enum NewPasswordStatus { idle, loading, success, error }

class NewPasswordState {
  final NewPasswordStatus status;
  final String? errorMessage;

  const NewPasswordState({
    this.status = NewPasswordStatus.idle,
    this.errorMessage,
  });

  bool get isLoading => status == NewPasswordStatus.loading;
  bool get isSuccess => status == NewPasswordStatus.success;
  bool get hasError => status == NewPasswordStatus.error;

  NewPasswordState copyWith({
    NewPasswordStatus? status,
    String? errorMessage,
  }) => NewPasswordState(
    status: status ?? this.status,
    errorMessage: errorMessage,
  );
}

class NewPasswordNotifier extends StateNotifier<NewPasswordState> {
  NewPasswordNotifier() : super(const NewPasswordState());

  Future<void> submit({
    required String email,
    required String code,
    required String newPassword,
    required String confirmPassword,
  }) async {
    // ── Client-side validation ─────────────────────────────────
    if (newPassword.length < 8) {
      state = state.copyWith(
        status: NewPasswordStatus.error,
        errorMessage:
            'Use 8 or more characters with a mix of letters, numbers & symbols',
      );
      return;
    }
    if (newPassword != confirmPassword) {
      state = state.copyWith(
        status: NewPasswordStatus.error,
        errorMessage: 'Passwords do not match',
      );
      return;
    }

    state = state.copyWith(status: NewPasswordStatus.loading);
    try {
      final res = await AuthApiService.instance.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );

      if (res.success) {
        state = state.copyWith(status: NewPasswordStatus.success);
      } else {
        state = state.copyWith(
          status: NewPasswordStatus.error,
          errorMessage: res.message ?? 'Failed to reset password. Please try again.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: NewPasswordStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() => state = const NewPasswordState();
}

final newPasswordStateProvider =
    StateNotifierProvider<NewPasswordNotifier, NewPasswordState>(
      (_) => NewPasswordNotifier(),
    );
