import 'dart:convert';
import 'dart:ui';

import 'package:chatapp/core/models/chat_user.dart';
import 'package:chatapp/core/theme/app_colors.dart';
import 'package:chatapp/core/widgets/gradient_button.dart';
import 'package:chatapp/core/widgets/user_avatar.dart';
import 'package:chatapp/features/chat/providers/chat_providers.dart';
import 'package:chatapp/features/profile_setup/controllers/profile_setup_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  XFile? _pickedImage;
  bool _pickingImage = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() => _pickingImage = true);
    final picker = ImagePicker();
    try {
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );
      if (image != null) {
        setState(() => _pickedImage = image);
      }
    } on PlatformException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message ?? 'Could not open your photo library.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick image: $error')),
      );
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  Widget? _savedProfileImage(ChatUser? user) {
    final photoBase64 = user?.photoBase64;
    if (photoBase64 != null && photoBase64.isNotEmpty) {
      try {
        return Image.memory(base64Decode(photoBase64), fit: BoxFit.cover);
      } on FormatException {
        return null;
      }
    }

    final photoUrl = user?.photoUrl;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return Image.network(photoUrl, fit: BoxFit.cover);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileSetupControllerProvider);
    final authState = ref.watch(authStateProvider);
    final authUser = authState.value;
    final AsyncValue<ChatUser?> profileAsync = authUser == null
        ? const AsyncValue.data(null)
        : ref.watch(currentUserProfileProvider(authUser.uid));
    final profileUser = profileAsync.value;
    final savedProfileImage = _savedProfileImage(profileUser);

    ref.listen(profileSetupControllerProvider, (previous, next) {
      if (!next.hasError) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(next.error.toString())),
      );
    });

    return Scaffold(
      body: Stack(
        children: [
          const _ProfileBackdrop(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tell us about you',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'A polished profile gives your chats the right first impression.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.74),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 240),
                            width: 172,
                            height: 172,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppGradients.indigoViolet,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.36,
                                  ),
                                  blurRadius: 30,
                                  offset: const Offset(0, 18),
                                ),
                              ],
                            ),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.06),
                              ),
                              child: ClipOval(
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    if (_pickedImage != null)
                                      FutureBuilder<ImageProvider>(
                                        future: _pickedImage!
                                            .readAsBytes()
                                            .then(
                                              (bytes) => MemoryImage(bytes),
                                            ),
                                        builder: (context, snapshot) {
                                          final image = snapshot.data;
                                          if (image != null) {
                                            return Image(
                                              image: image,
                                              fit: BoxFit.cover,
                                            );
                                          }
                                          return const Center(
                                            child:
                                                CircularProgressIndicator.adaptive(),
                                          );
                                        },
                                      )
                                    else if (savedProfileImage != null)
                                      savedProfileImage
                                    else
                                      UserAvatar(user: profileUser, radius: 78),
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: RadialGradient(
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withValues(
                                              alpha: 0.18,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Center(
                                      child: AnimatedOpacity(
                                        opacity: _pickingImage ? 0.5 : 1,
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt_rounded,
                                          color: Colors.white,
                                          size: 34,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Text(
                          authUser?.email ?? 'Signed in user',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.82),
                              ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.14),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextField(
                                  controller: _nameController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Display name',
                                    prefixIcon: Icon(Icons.badge_outlined),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                GradientButton(
                                  label: 'Get Started',
                                  isLoading: profileState.isLoading,
                                  onPressed: () async {
                                    if ((_nameController.text).trim().isEmpty) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Please enter a display name',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    await ref
                                        .read(
                                          profileSetupControllerProvider
                                              .notifier,
                                        )
                                        .submitProfile(
                                          displayName: _nameController.text,
                                          image: _pickedImage,
                                        );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileBackdrop extends StatelessWidget {
  const _ProfileBackdrop();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF111827), Color(0xFF312E81)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            left: -60,
            child: _Pulse(
              size: 220,
              color: AppColors.accent.withValues(alpha: 0.26),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -70,
            child: _Pulse(
              size: 260,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pulse extends StatelessWidget {
  const _Pulse({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0.01)],
        ),
      ),
    );
  }
}
