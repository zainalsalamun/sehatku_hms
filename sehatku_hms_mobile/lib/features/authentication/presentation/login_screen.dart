import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/health_models.dart';
import '../application/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late final TextEditingController emailController;
  late final TextEditingController passwordController;
  bool obscure = true;

  @override
  void initState() {
    super.initState();
    final initialRole = ref.read(authControllerProvider).role;
    emailController = TextEditingController(text: _getDefaultEmailForRole(initialRole));
    passwordController = TextEditingController(text: 'password123');
  }

  String _getDefaultEmailForRole(UserRole role) {
    return switch (role) {
      UserRole.patient => 'patient@sehatku.id',
      UserRole.doctor => 'doctor@sehatku.id',
      UserRole.admin => 'admin@sehatku.id',
    };
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _onRoleChanged(UserRole role) {
    ref.read(authControllerProvider.notifier).selectRole(role);
    setState(() {
      emailController.text = _getDefaultEmailForRole(role);
      passwordController.text = 'password123';
    });
  }

  Future<void> _login() async {
    final success = await ref
        .read(authControllerProvider.notifier)
        .signInWithCredentials(
          emailController.text.trim(),
          passwordController.text.trim(),
        );

    if (!mounted) return;

    if (success) {
      final role = ref.read(authControllerProvider).role;
      context.go('/${role.name}');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login gagal. Periksa email dan password Anda.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final compact = MediaQuery.sizeOf(context).width < 480;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(compact ? 16 : 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(compact ? 20 : 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: CircleAvatar(
                          radius: 29,
                          backgroundColor: Color(0xFFE0F4F2),
                          child: Icon(
                            Icons.health_and_safety_rounded,
                            color: AppTheme.primary,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Selamat datang',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 7),
                      const Text('Masuk ke ekosistem layanan SehatKu HMS.'),
                      const SizedBox(height: 24),
                      SegmentedButton<UserRole>(
                        segments: UserRole.values
                            .map(
                              (role) => ButtonSegment(
                                value: role,
                                label: Text(role.label),
                                icon: compact
                                    ? null
                                    : Icon(switch (role) {
                                        UserRole.patient =>
                                          Icons.person_outline,
                                        UserRole.doctor =>
                                          Icons.medical_services_outlined,
                                        UserRole.admin =>
                                          Icons.admin_panel_settings_outlined,
                                      }),
                              ),
                            )
                            .toList(),
                        selected: {auth.role},
                        onSelectionChanged: (value) =>
                            _onRoleChanged(value.first),
                      ),
                      if (auth.role == UserRole.doctor) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F8F8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.primary.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.badge_outlined,
                                    size: 15,
                                    color: AppTheme.navy,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Pilih Akun Dokter Pengujian:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.navy,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _DoctorQuickChip(
                                    label: 'dr. Maya Pratama (Kardio)',
                                    isSelected:
                                        emailController.text ==
                                        'doctor@sehatku.id',
                                    onTap: () {
                                      setState(() {
                                        emailController.text =
                                            'doctor@sehatku.id';
                                        passwordController.text = 'password123';
                                      });
                                    },
                                  ),
                                  _DoctorQuickChip(
                                    label: 'drg. Rafi Akbar (Gigi)',
                                    isSelected:
                                        emailController.text ==
                                        'rafi@sehatku.id',
                                    onTap: () {
                                      setState(() {
                                        emailController.text =
                                            'rafi@sehatku.id';
                                        passwordController.text = 'password123';
                                      });
                                    },
                                  ),
                                  _DoctorQuickChip(
                                    label: 'dr. Hendra Wijaya (Interna)',
                                    isSelected:
                                        emailController.text ==
                                        'hendra.wijaya@sehatku-hospital.id',
                                    onTap: () {
                                      setState(() {
                                        emailController.text =
                                            'hendra.wijaya@sehatku-hospital.id';
                                        passwordController.text = 'password123';
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.mail_outline),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: passwordController,
                        obscureText: obscure,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => obscure = !obscure),
                            icon: Icon(
                              obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text('Lupa password?'),
                        ),
                      ),
                      FilledButton(
                        onPressed: auth.isLoading ? null : _login,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: auth.isLoading
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Masuk'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _login,
                        icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                        label: const Text('Lanjutkan dengan Google'),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Demo: pilih role lalu tekan Masuk untuk login API.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DoctorQuickChip extends StatelessWidget {
  const _DoctorQuickChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.navy : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.navy : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.navy.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
