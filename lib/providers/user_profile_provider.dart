import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/user_api_service.dart';
import '../models/auth/user_model.dart';

class UserProfileNotifier extends StateNotifier<AsyncValue<UserModel>> {
  final UserApiService _api = UserApiService.instance;

  UserProfileNotifier() : super(const AsyncValue.loading()) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    state = const AsyncValue.loading();
    try {
      final profile = await _api.getProfile();
      state = AsyncValue.data(profile);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void updateProfile(UserModel updatedUser) {
    state = AsyncValue.data(updatedUser);
  }
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, AsyncValue<UserModel>>((ref) {
  return UserProfileNotifier();
});
