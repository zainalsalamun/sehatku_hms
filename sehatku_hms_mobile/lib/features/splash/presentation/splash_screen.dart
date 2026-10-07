import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../authentication/application/auth_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    final startTime = DateTime.now();
    final hasSession =
        await ref.read(authControllerProvider.notifier).loadSavedSession();

    // Minimum splash duration for smooth branding transition
    final elapsed = DateTime.now().difference(startTime);
    if (elapsed < const Duration(milliseconds: 900)) {
      await Future<void>.delayed(const Duration(milliseconds: 900) - elapsed);
    }

    if (!mounted) return;

    if (hasSession) {
      final auth = ref.read(authControllerProvider);
      context.go('/${auth.role.name}');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.health_and_safety_rounded,
                size: 64,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'SehatKu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Healthcare, made personal.',
              style: TextStyle(color: Colors.white.withValues(alpha: .8)),
            ),
          ],
        ),
      ),
    );
  }
}
