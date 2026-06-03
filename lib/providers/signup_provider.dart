import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/signup_model.dart';
import '../core/network/auth_api_service.dart';
import '../models/auth/register_request.dart';

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
  final Ref ref;
  SignupNotifier(this.ref) : super(const SignupState());

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

    if (!ref.read(signupTermsAcceptedProvider)) {
      state = const SignupState(
        status: SignupStatus.error,
        errorField: SignupErrorField.none,
        errorMessage: 'You must accept the Terms and Conditions',
      );
      return;
    }

    if (!ref.read(signupPrivacyAcceptedProvider)) {
      state = const SignupState(
        status: SignupStatus.error,
        errorField: SignupErrorField.none,
        errorMessage: 'You must accept the Privacy Policy',
      );
      return;
    }

    // ── API call ──
    state = state.copyWith(status: SignupStatus.loading);
    try {
      final req = RegisterRequest(
        firstName: model.firstName,
        lastName: model.lastName,
        email: model.email,
        password: model.password,
        termsAccepted: ref.read(signupTermsAcceptedProvider),
        privacyPolicyAccepted: ref.read(signupPrivacyAcceptedProvider),
      );
      
      final res = await AuthApiService.instance.register(req);

      if (res.success) {
        state = state.copyWith(status: SignupStatus.success);
      } else {
        state = SignupState(
          status: SignupStatus.error,
          errorField: SignupErrorField.email,
          errorMessage: res.message ?? 'Signup failed. Please try again.',
        );
      }
    } catch (e) {
      state = SignupState(
        status: SignupStatus.error,
        errorField: SignupErrorField.email,
        errorMessage: e.toString(),
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
  (ref) => SignupNotifier(ref),
);
