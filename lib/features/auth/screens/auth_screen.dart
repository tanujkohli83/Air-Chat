import 'package:chatapp/core/theme/app_colors.dart';
import 'package:chatapp/core/widgets/glass_card.dart';
import 'package:chatapp/core/widgets/gradient_button.dart';
import 'package:chatapp/features/auth/controllers/auth_controller.dart';
import 'package:chatapp/features/chat/providers/chat_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final mode = ref.watch(authFormModeProvider);
    final isSignUp = mode == AuthFormMode.signUp;

    return Scaffold(
      body: Stack(
        children: [
          const _AuthBackdrop(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSignUp ? 'Create your space' : 'Welcome back',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(color: Colors.white, height: 1.05),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isSignUp
                            ? 'Build a private, beautiful chat layer for your people.'
                            : 'Sign in and jump straight into realtime conversations.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.76),
                        ),
                      ),
                      const SizedBox(height: 28),
                      _ModeToggle(
                        isSignUp: isSignUp,
                        onChanged: (value) {
                          ref.read(authFormModeProvider.notifier).state = value
                              ? AuthFormMode.signUp
                              : AuthFormMode.signIn;
                        },
                      ),
                      const SizedBox(height: 18),
                      GlassCard(
                        padding: const EdgeInsets.all(22),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                isSignUp ? 'Join the beta' : 'Secure login',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 18),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(
                                    Icons.alternate_email_rounded,
                                  ),
                                ),
                                validator: (value) {
                                  final text = value?.trim() ?? '';
                                  if (text.isEmpty) {
                                    return 'Enter your email';
                                  }
                                  if (!text.contains('@')) {
                                    return 'Enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: Icon(Icons.lock_outline_rounded),
                                ),
                                validator: (value) {
                                  final text = value ?? '';
                                  if (text.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              AnimatedSize(
                                duration: const Duration(milliseconds: 220),
                                child: isSignUp
                                    ? Padding(
                                        padding: const EdgeInsets.only(top: 14),
                                        child: TextFormField(
                                          controller:
                                              _confirmPasswordController,
                                          obscureText: true,
                                          decoration: const InputDecoration(
                                            labelText: 'Confirm password',
                                            prefixIcon: Icon(
                                              Icons.verified_user_outlined,
                                            ),
                                          ),
                                          validator: (value) {
                                            if (!isSignUp) {
                                              return null;
                                            }
                                            if ((value ?? '').trim() !=
                                                _passwordController.text
                                                    .trim()) {
                                              return 'Passwords do not match';
                                            }
                                            return null;
                                          },
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                              const SizedBox(height: 20),
                              GradientButton(
                                label: isSignUp ? 'Create account' : 'Sign in',
                                isLoading: authState.isLoading,
                                onPressed: () async {
                                  if (!_formKey.currentState!.validate()) {
                                    return;
                                  }
                                  final controller = ref.read(
                                    authControllerProvider.notifier,
                                  );
                                  final email = _emailController.text.trim();
                                  final password = _passwordController.text
                                      .trim();
                                  if (isSignUp) {
                                    await controller.signUp(
                                      email: email,
                                      password: password,
                                    );
                                  } else {
                                    await controller.signIn(
                                      email: email,
                                      password: password,
                                    );
                                  }
                                },
                              ),
                              if (authState.hasError) ...[
                                const SizedBox(height: 12),
                                Text(
                                  authState.error.toString(),
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: AppColors.danger),
                                ),
                              ],
                              const SizedBox(height: 10),
                              TextButton(
                                onPressed: () {
                                  ref
                                      .read(authFormModeProvider.notifier)
                                      .state = isSignUp
                                      ? AuthFormMode.signIn
                                      : AuthFormMode.signUp;
                                },
                                child: Text(
                                  isSignUp
                                      ? 'Already have an account? Sign in'
                                      : 'New here? Create an account',
                                ),
                              ),
                            ],
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

class _AuthBackdrop extends StatelessWidget {
  const _AuthBackdrop();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF111827), Color(0xFF1E1B4B), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -40,
            child: _GlowBlob(
              color: AppColors.accent.withValues(alpha: 0.44),
              size: 220,
            ),
          ),
          Positioned(
            bottom: -120,
            left: -70,
            child: _GlowBlob(
              color: Colors.white.withValues(alpha: 0.12),
              size: 280,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0.02)],
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.isSignUp, required this.onChanged});

  final bool isSignUp;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!isSignUp),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutBack,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              alignment: isSignUp
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Container(
                width: 148,
                height: 46,
                decoration: BoxDecoration(
                  gradient: AppGradients.indigoViolet,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 46,
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        'Sign in',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: isSignUp
                              ? Colors.white.withValues(alpha: 0.82)
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Sign up',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: isSignUp
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.82),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
