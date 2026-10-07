import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../authentication/application/auth_controller.dart';
import 'tabs/admin_appointments_tab.dart';
import 'tabs/admin_audit_logs_tab.dart';
import 'tabs/admin_billing_tab.dart';
import 'tabs/admin_certificates_tab.dart';
import 'tabs/admin_doctors_tab.dart';
import 'tabs/admin_inpatient_tab.dart';
import 'tabs/admin_laboratory_tab.dart';
import 'tabs/admin_overview_tab.dart';
import 'tabs/admin_patients_tab.dart';
import 'tabs/admin_pharmacy_tab.dart';
import 'tabs/admin_procedures_tab.dart';
import 'tabs/admin_reports_tab.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int selected = 0;

  static const menu = [
    (Icons.dashboard_outlined, 'Dashboard'),
    (Icons.analytics_outlined, 'Laporan Klinik'),
    (Icons.healing_outlined, 'Tindakan & Tarif'),
    (Icons.medical_services_outlined, 'Dokter'),
    (Icons.people_outline, 'Pasien'),
    (Icons.calendar_month_outlined, 'Reservasi'),
    (Icons.hotel_outlined, 'Rawat Inap & Bed'),
    (Icons.biotech_outlined, 'Laboratorium & LIS'),
    (Icons.local_pharmacy_outlined, 'Farmasi & Obat'),
    (Icons.payments_outlined, 'Kasir & Tagihan'),
    (Icons.description_outlined, 'Surat Medis'),
    (Icons.history_outlined, 'Audit Trail'),
  ];

  static const _tabs = [
    AdminOverviewTab(),
    AdminReportsTab(),
    AdminProceduresTab(),
    AdminDoctorsTab(),
    AdminPatientsTab(),
    AdminAppointmentsTab(),
    AdminInpatientTab(),
    AdminLaboratoryTab(),
    AdminPharmacyTab(),
    AdminBillingTab(),
    AdminCertificatesTab(),
    AdminAuditLogsTab(),
  ];

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Konfirmasi Keluar'),
          ],
        ),
        content: const Text('Apakah Anda yakin ingin keluar dari sesi Admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await ref.read(authControllerProvider.notifier).signOut();
              if (mounted) {
                context.go('/login');
              }
            },
            child: const Text('Ya, Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      drawer: !wide ? Drawer(child: _navigation()) : null,
      appBar: AppBar(
        title: Text(
          menu[selected].$2,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Buka Layar Display TV Antrean',
            onPressed: () => context.push('/queue-display'),
            icon: const Icon(Icons.tv_rounded, color: Colors.teal),
          ),
          const NotificationBellButton(),
          IconButton(
            tooltip: 'Keluar',
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Row(
        children: [
          if (wide) SizedBox(width: 250, child: _navigation()),
          Expanded(
            child: IndexedStack(index: selected, children: _tabs),
          ),
        ],
      ),
    );
  }

  Widget _navigation() => ColoredBox(
    color: AppTheme.navy,
    child: SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(24),
            child: Row(
              children: [
                Icon(Icons.health_and_safety, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SehatKu HMS',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Operations Console',
                        style: TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 8),
              itemCount: menu.length,
              itemBuilder: (context, index) {
                final item = menu[index];
                final isSelected = selected == index;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 2,
                  ),
                  child: ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    selected: isSelected,
                    selectedTileColor: Colors.white.withValues(alpha: .14),
                    leading: Icon(
                      item.$1,
                      color: isSelected ? Colors.white : Colors.white60,
                    ),
                    title: Text(
                      item.$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    onTap: () {
                      setState(() => selected = index);
                      if (MediaQuery.sizeOf(context).width < 900 &&
                          Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                );
              },
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 15,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Budi Santoso',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Hospital Admin',
                        style: TextStyle(color: Colors.white54, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Keluar / Logout',
                  icon: const Icon(Icons.logout_rounded, color: Colors.white70, size: 20),
                  onPressed: _handleLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
