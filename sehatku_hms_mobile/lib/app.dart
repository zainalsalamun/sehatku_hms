import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/admin/presentation/admin_dashboard_screen.dart';
import 'features/admin/presentation/screens/admin_create_appointment_screen.dart';
import 'features/authentication/application/auth_controller.dart';
import 'features/authentication/presentation/login_screen.dart';
import 'features/doctor/presentation/doctor_dashboard_screen.dart';
import 'features/patient/presentation/patient_shell.dart';
import 'features/queue/presentation/queue_tv_display_screen.dart';
import 'features/splash/presentation/splash_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final isAuth = auth.isAuthenticated;

      // Allow public queue display without login
      if (loc == '/queue-display') return null;

      // If at root '/' splash location
      if (loc == '/') {
        return isAuth ? '/${auth.role.name}' : '/login';
      }

      // If visiting /login while already logged in
      if (loc == '/login' && isAuth) {
        return '/${auth.role.name}';
      }

      // If visiting protected areas without authentication
      if (!isAuth && (loc.startsWith('/patient') || loc.startsWith('/doctor') || loc.startsWith('/admin'))) {
        return '/login';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/patient', builder: (_, _) => const PatientShell()),
      GoRoute(
        path: '/doctor',
        builder: (_, _) => const DoctorDashboardScreen(),
      ),
      GoRoute(path: '/admin', builder: (_, _) => const AdminDashboardScreen()),
      GoRoute(
        path: '/admin/appointments/create',
        builder: (_, _) => const AdminCreateAppointmentScreen(),
      ),
      GoRoute(
        path: '/queue-display',
        builder: (_, _) => const QueueTvDisplayScreen(),
      ),
    ],
  );
});

class SehatKuApp extends ConsumerWidget {
  const SehatKuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'SehatKu HMS',
      theme: AppTheme.light,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
