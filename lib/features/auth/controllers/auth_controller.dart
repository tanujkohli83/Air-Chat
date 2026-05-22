import 'package:chatapp/core/services/auth_repository.dart';
import 'package:chatapp/features/chat/providers/chat_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<void> {
  AuthRepository get _authRepository => ref.read(authRepositoryProvider);

  @override
  Future<void> build() async {}

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _authRepository.signIn(email: email, password: password);
    });
  }

  Future<void> signUp({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _authRepository.signUp(email: email, password: password);
    });
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
  }
}
