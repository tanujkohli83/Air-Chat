import 'package:chatapp/core/theme/app_theme.dart';
import 'package:chatapp/features/auth/screens/auth_screen.dart';
import 'package:chatapp/features/dashboard/screens/dashboard_screen.dart';
import 'package:chatapp/features/profile_setup/screens/profile_setup_screen.dart';
import 'package:chatapp/features/chat/providers/chat_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Velvet Chat',
      theme: AppTheme.light(),
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends ConsumerStatefulWidget {
  const _AuthGate();

  @override
  ConsumerState<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<_AuthGate> {
  String? _registeredUid;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final authUser = authState.value;

    if (authUser != null && authUser.uid != _registeredUid) {
      _registeredUid = authUser.uid;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(pushNotificationServiceProvider)
            .registerDeviceForUser(userId: authUser.uid);
      });
    }

    if (authState.isLoading) {
      return const _SplashScreen();
    }

    if (authUser == null) {
      return const AuthScreen();
    }

    final profileAsync = ref.watch(currentUserProfileProvider(authUser.uid));
    return profileAsync.when(
      data: (profile) {
        final hasCompletedProfile = profile?.hasCompletedProfile ?? false;
        if (!hasCompletedProfile) {
          return const ProfileSetupScreen();
        }
        return const DashboardScreen();
      },
      loading: () => const _SplashScreen(),
      error: (error, stackTrace) => const AuthScreen(),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator.adaptive()),
    );
  }
}
