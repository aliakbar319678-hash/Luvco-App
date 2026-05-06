import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/signup_model.dart';

// ── Individual field providers ────────────────────────────────────
final signupFirstNameProvider = StateProvider<String>((ref) => '');
final signupLastNameProvider = StateProvider<String>((ref) => '');
final signupEmailProvider = StateProvider<String>((ref) => '');
final signupPasswordProvider = StateProvider<String>((ref) => '');

final signupObscurePasswordProvider = StateProvider<bool>((ref) => true);
final signupTermsAcceptedProvider = StateProvider<bool>((ref) => false);
final signupPrivacyAcceptedProvider = StateProvider<bool>((ref) => false);

// ── Signup status enum ────────────────────────────────────────────
enum SignupStatus { idle, loading, success, error }

// ── Field-level error keys ────────────────────────────────────────
enum SignupErrorField { none, firstName, lastName, email, password }

// ── State ─────────────────────────────────────────────────────────
class SignupState {
  final SignupStatus status;
  final SignupErrorField errorField;
  final String? errorMessage;

  const SignupState({
    this.status = SignupStatus.idle,
    this.errorField = SignupErrorField.none,
    this.errorMessage,
  });

  bool get hasError => status == SignupStatus.error;
  bool get isSuccess => status == SignupStatus.success;

  bool fieldHasError(SignupErrorField field) => hasError && errorField == field;

  SignupState copyWith({
    SignupStatus? status,
    SignupErrorField? errorField,
    String? errorMessage,
  }) => SignupState(
    status: status ?? this.status,
    errorField: errorField ?? this.errorField,
    errorMessage: errorMessage ?? this.errorMessage,
  );
}

// ── Notifier ──────────────────────────────────────────────────────
class SignupNotifier extends StateNotifier<SignupState> {
  SignupNotifier() : super(const SignupState());

  Future<void> signup(SignupModel model) async {
    // ── Client-side validation ──
    if (model.firstName.trim().isEmpty) {
      state = const SignupState(
        status: SignupStatus.error,
        errorField: SignupErrorField.firstName,
        errorMessage: 'Please fill out this field',
      );
      return;
    }

    if (model.lastName.trim().isEmpty) {
      state = const SignupState(
        status: SignupStatus.error,
        errorField: SignupErrorField.lastName,
        errorMessage: 'Please fill out this field',
      );
      return;
    }

    if (model.email.trim().isEmpty) {
      state = const SignupState(
        status: SignupStatus.error,
        errorField: SignupErrorField.email,
        errorMessage: 'Please fill out this field',
      );
      return;
    }

    if (model.password.length < 8) {
      state = const SignupState(
        status: SignupStatus.error,
        errorField: SignupErrorField.password,
        errorMessage: 'Use 8 or more characters',
      );
      return;
    }

    // ── Simulate API call ──
    state = state.copyWith(status: SignupStatus.loading);
    try {
      await Future.delayed(const Duration(seconds: 1));

      if (model.email == 'test@luvco.com') {
        state = const SignupState(
          status: SignupStatus.error,
          errorField: SignupErrorField.email,
          errorMessage: 'Email is already associated to an account',
        );
        return;
      }

      state = state.copyWith(status: SignupStatus.success);
    } catch (_) {
      state = const SignupState(
        status: SignupStatus.error,
        errorField: SignupErrorField.email,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  /// Call this whenever the user starts editing a field to clear the error.
  void clearError() => state = const SignupState();

  /// Reset state after successful signup or when needed.
  void reset() => state = const SignupState();
}

// ── Provider ──────────────────────────────────────────────────────
final signupProvider = StateNotifierProvider<SignupNotifier, SignupState>(
  (_) => SignupNotifier(),
);
