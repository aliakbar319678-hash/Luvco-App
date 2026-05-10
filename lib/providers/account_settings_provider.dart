import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AccountSettingsState {
  final File? profileImage;
  final File? pendingImage;
  final bool isSaving;
  final bool saveSuccess;

  const AccountSettingsState({
    this.profileImage,
    this.pendingImage,
    this.isSaving = false,
    this.saveSuccess = false,
  });

  AccountSettingsState copyWith({
    File? profileImage,
    File? pendingImage,
    bool clearPending = false,
    bool? isSaving,
    bool? saveSuccess,
  }) => AccountSettingsState(
    profileImage: profileImage ?? this.profileImage,
    pendingImage: clearPending ? null : (pendingImage ?? this.pendingImage),
    isSaving: isSaving ?? this.isSaving,
    saveSuccess: saveSuccess ?? this.saveSuccess,
  );
}

class AccountSettingsNotifier extends StateNotifier<AccountSettingsState> {
  AccountSettingsNotifier() : super(const AccountSettingsState());

  void setPendingImage(File image) {
    state = state.copyWith(pendingImage: image);
  }

  Future<void> saveProfileImage() async {
    if (state.pendingImage == null) return;
    state = state.copyWith(isSaving: true);
    await Future.delayed(const Duration(milliseconds: 900));
    // Save pendingImage → profileImage, clear pending, show success
    state = AccountSettingsState(
      profileImage: state.pendingImage,
      pendingImage: null,
      isSaving: false,
      saveSuccess: true,
    );
  }

  void cancelPendingImage() {
    state = state.copyWith(clearPending: true);
  }

  void dismissSuccess() {
    state = state.copyWith(saveSuccess: false);
  }
}

// ── NO .autoDispose — state must survive navigation ──────────────
final accountSettingsProvider =
    StateNotifierProvider<AccountSettingsNotifier, AccountSettingsState>(
      (_) => AccountSettingsNotifier(),
    );
