import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/health_models.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../admin/application/admin_state_providers.dart';
import '../../authentication/application/auth_controller.dart';
import '../../patient/presentation/patient_invoices_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final patients = ref.watch(adminPatientsProvider);
    final doctors = ref.watch(adminDoctorsProvider);

    final isDoctor = auth.role == UserRole.doctor;
    final isAdmin = auth.role == UserRole.admin;

    final fullName = auth.userFullName?.trim().isNotEmpty == true
        ? auth.userFullName!
        : (auth.email != null && auth.email!.isNotEmpty
            ? auth.email!.split('@').first
            : (isDoctor ? 'Dokter' : (isAdmin ? 'Admin' : 'Pasien')));
    final email = auth.email ?? (isDoctor ? 'doctor@sehatku.id' : 'user@sehatku.id');

    final initials = fullName
        .split(' ')
        .where((s) => s.isNotEmpty && !s.startsWith('dr.') && !s.startsWith('drg.'))
        .map((s) => s[0])
        .take(2)
        .join();

    // Match patient from DB
    final matchedPatient = patients.where((p) => p.name == fullName || p.id == auth.patientId).firstOrNull;
    final mrn = matchedPatient?.medicalRecordNumber ?? auth.patientMrn ?? '-';
    final insurance = matchedPatient?.insuranceProvider ?? 'BPJS Kesehatan Mandiri';
    final bloodType = matchedPatient?.bloodType ?? 'O+';
    final phone = matchedPatient?.phone ?? '-';

    // Match doctor from DB
    final matchedDoctor = doctors.where((d) => d.name == fullName || d.id == auth.doctorId).firstOrNull;
    final sip = matchedDoctor?.licenseNumber ?? '-';
    final specialist = matchedDoctor?.specialist ?? auth.doctorSpecialist ?? 'Umum';

    return Scaffold(
      appBar: const DashboardAppBar(title: 'Profil Pengguna'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CircleAvatar(
            radius: 46,
            backgroundColor: isDoctor
                ? Colors.teal.shade50
                : isAdmin
                    ? Colors.indigo.shade50
                    : const Color(0xFFE0F4F2),
            child: Text(
              initials.isNotEmpty ? initials : (isDoctor ? 'DR' : 'US'),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: isDoctor
                    ? Colors.teal.shade800
                    : isAdmin
                        ? Colors.indigo.shade800
                        : AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            fullName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            isDoctor
                ? '$specialist • $sip'
                : isAdmin
                    ? 'Hospital Administrator • SehatKu Central'
                    : '$mrn • $insurance',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // User information tiles
          _ProfileTile(
            Icons.email_outlined,
            'Email Akun',
            email,
          ),
          if (!isDoctor && !isAdmin) ...[
            _ProfileTile(
              Icons.badge_outlined,
              'Nomor Rekam Medis (MRN)',
              '$mrn (Database Aktif)',
            ),
            _ProfileTile(
              Icons.health_and_safety_outlined,
              'Informasi Klinis',
              'Golongan Darah: $bloodType • Tidak Ada Alergi Berat',
            ),
            _ProfileTile(
              Icons.verified_user_outlined,
              'Penjamin Biaya / Asuransi',
              insurance,
            ),
            _ProfileTile(
              Icons.phone_outlined,
              'Nomor Kontak Terdaftar',
              phone,
            ),
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PatientInvoicesScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: const _ProfileTile(
                Icons.receipt_long_outlined,
                'Tagihan & Kwitansi Resmi',
                'Lihat rincian faktur & bukti bayar kasir POS',
                trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14),
              ),
            ),
          ] else if (isDoctor) ...[
            _ProfileTile(
              Icons.medical_services_outlined,
              'Surat Izin Praktek (SIP / STR)',
              sip,
            ),
            _ProfileTile(
              Icons.local_hospital_outlined,
              'Poliklinik Spesialisasi',
              specialist,
            ),
            _ProfileTile(
              Icons.calendar_today_outlined,
              'Jadwal Praktek Rutin',
              matchedDoctor?.scheduleDays.join(', ') ?? 'Senin, Rabu, Jumat',
            ),
          ],
          const _ProfileTile(
            Icons.fingerprint,
            'Keamanan & Privasi',
            'Enkripsi Data Medis AES-256 Aktif',
          ),
          const SizedBox(height: 24),

          // Logout Button
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textWhite,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Keluar dari Akun (Logout)', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile(this.icon, this.title, this.subtitle, {this.trailing});
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
            child: Icon(icon, color: AppTheme.primary, size: 18),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
          trailing: trailing,
        ),
      );
}

