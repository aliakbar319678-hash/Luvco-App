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
enum SignupErrorField { none, firstName, lastName, email, password, terms, privacy }

// ── State ─────────────────────────────────────────────────────────
class SignupState {
  final SignupStatus status;
  final Map<SignupErrorField, String> errors;
  final String? globalErrorMessage;

  const SignupState({
    this.status = SignupStatus.idle,
    this.errors = const {},
    this.globalErrorMessage,
  });

  bool get hasError => status == SignupStatus.error || errors.isNotEmpty || globalErrorMessage != null;
  bool get isSuccess => status == SignupStatus.success;

  bool fieldHasError(SignupErrorField field) => errors.containsKey(field);
  String? fieldErrorMessage(SignupErrorField field) => errors[field];

  SignupState copyWith({
    SignupStatus? status,
    Map<SignupErrorField, String>? errors,
    String? globalErrorMessage,
  }) => SignupState(
    status: status ?? this.status,
    errors: errors ?? this.errors,
    globalErrorMessage: globalErrorMessage ?? this.globalErrorMessage,
  );
}

// ── Notifier ──────────────────────────────────────────────────────
class SignupNotifier extends StateNotifier<SignupState> {
  final Ref ref;
  SignupNotifier(this.ref) : super(const SignupState());

  Future<void> signup(SignupModel model) async {
    final newErrors = <SignupErrorField, String>{};

    // ── Client-side validation ──
    if (model.firstName.trim().isEmpty) {
      newErrors[SignupErrorField.firstName] = 'Please fill out this field';
    }

    if (model.lastName.trim().isEmpty) {
      newErrors[SignupErrorField.lastName] = 'Please fill out this field';
    }

    if (model.email.trim().isEmpty) {
      newErrors[SignupErrorField.email] = 'Please fill out this field';
    }

    if (model.password.isEmpty) {
      newErrors[SignupErrorField.password] = 'Please fill out this field';
    } else if (model.password.length < 8) {
      newErrors[SignupErrorField.password] = 'Use 8 or more characters';
    }

    final termsAccepted = ref.read(signupTermsAcceptedProvider);
    final privacyAccepted = ref.read(signupPrivacyAcceptedProvider);
    
    if (!termsAccepted) {
      newErrors[SignupErrorField.terms] = 'Please accept Terms & Conditions';
    }
    
    if (!privacyAccepted) {
      newErrors[SignupErrorField.privacy] = 'Please accept Privacy Policy';
    }

    if (newErrors.isNotEmpty) {
      state = SignupState(
        status: SignupStatus.error,
        errors: newErrors,
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
        final message = res.message ?? 'Signup failed. Please try again.';
        SignupErrorField errorField = SignupErrorField.email;
        if (message.toLowerCase().contains('password')) {
          errorField = SignupErrorField.password;
        } else if (message.toLowerCase().contains('first name')) {
          errorField = SignupErrorField.firstName;
        } else if (message.toLowerCase().contains('last name')) {
          errorField = SignupErrorField.lastName;
        }
        state = SignupState(
          status: SignupStatus.error,
          errors: {errorField: message},
        );
      }
    } catch (e) {
      final message = e.toString();
      SignupErrorField errorField = SignupErrorField.email;
      if (message.toLowerCase().contains('password')) {
        errorField = SignupErrorField.password;
      } else if (message.toLowerCase().contains('first name')) {
        errorField = SignupErrorField.firstName;
      } else if (message.toLowerCase().contains('last name')) {
        errorField = SignupErrorField.lastName;
      }
      state = SignupState(
        status: SignupStatus.error,
        errors: {errorField: message},
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
