import 'package:chatapp/core/services/profile_repository.dart';
import 'package:chatapp/features/chat/providers/chat_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

final profileSetupControllerProvider =
    AsyncNotifierProvider<ProfileSetupController, void>(
      ProfileSetupController.new,
    );

class ProfileSetupController extends AsyncNotifier<void> {
  ProfileRepository get _profileRepository =>
      ref.read(profileRepositoryProvider);

  @override
  Future<void> build() async {}

  Future<void> submitProfile({
    required String displayName,
    required XFile? image,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final authUser = ref.read(authStateProvider).value;
      if (authUser == null) {
        throw StateError('No authenticated user.');
      }

      final avatarImage = await _profileRepository.encodeAvatar(
        image: image,
      );

      await _profileRepository.saveProfile(
        uid: authUser.uid,
        email: authUser.email ?? '',
        displayName: displayName,
        avatarImage: avatarImage,
      );
    });
  }
}
