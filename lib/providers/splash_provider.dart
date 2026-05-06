import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SplashStatus { loading, done }

class SplashNotifier extends AsyncNotifier<SplashStatus> {
  @override
  Future<SplashStatus> build() async {
    await Future.delayed(const Duration(milliseconds: 2400));
    return SplashStatus.done;
  }
}

final splashProvider = AsyncNotifierProvider<SplashNotifier, SplashStatus>(
  SplashNotifier.new,
);
