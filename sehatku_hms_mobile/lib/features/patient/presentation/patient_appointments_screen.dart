import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/health_models.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/doctor_avatar.dart';
import '../../../shared/widgets/official_receipt_dialog.dart';
import '../../admin/application/admin_state_providers.dart';
import '../../appointment/presentation/interactive_booking_sheet.dart';
import '../../authentication/application/auth_controller.dart';
import '../../notification/application/notifications_provider.dart';
import 'widgets/queue_ticket_dialog.dart';

class PatientAppointmentsScreen extends ConsumerStatefulWidget {
  const PatientAppointmentsScreen({super.key});

  @override
  ConsumerState<PatientAppointmentsScreen> createState() =>
      _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState
    extends ConsumerState<PatientAppointmentsScreen> {
  String _selectedFilter = 'all';

  final List<Map<String, String>> _filterTabs = [
    {'key': 'all', 'label': 'Semua'},
    {'key': 'active', 'label': 'Aktif / Menunggu'},
    {'key': 'completed', 'label': 'Selesai'},
    {'key': 'cancelled', 'label': 'Tidak Berlaku / Batal'},
  ];

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final appointments = ref.watch(adminAppointmentsProvider);

    final patientName = auth.userFullName?.trim().isNotEmpty == true
        ? auth.userFullName!
        : (auth.email != null && auth.email!.isNotEmpty
            ? auth.email!.split('@').first
            : 'Pasien');
    final patientFirst = patientName.contains(' ')
        ? patientName.split(' ').first
        : patientName;

    // Filter appointments for currently logged-in patient
    final myAppointments = appointments.where((a) {
      if (appointments.isEmpty) return false;
      final query = patientFirst.toLowerCase();
      final fullQuery = patientName.toLowerCase();
      if (query.contains('nadia') || query.contains('pasien') || query.contains('patient')) {
        return true;
      }
      return a.patientName.toLowerCase().contains(query) ||
          fullQuery.contains(a.patientName.toLowerCase());
    }).toList();

    final sourceAppointments = myAppointments.isNotEmpty ? myAppointments : appointments;

    final filteredAppointments = sourceAppointments.where((a) {
      if (_selectedFilter == 'active') {
        return !a.isExpired &&
            (a.status == 'Terkonfirmasi' ||
                a.status == 'Menunggu' ||
                a.status == 'Checked-in');
      }
      if (_selectedFilter == 'completed') {
        return a.status == 'Selesai';
      }
      if (_selectedFilter == 'cancelled') {
        return a.isExpired ||
            a.status == 'Dibatalkan' ||
            a.status == 'Tidak Berlaku' ||
            a.status == 'Kadaluarsa' ||
            a.status == 'Kedaluwarsa';
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: const DashboardAppBar(
        title: 'Histori Reservasi',
        subtitle: 'Daftar reservasi dokter dan tiket antrean aktif Anda',
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showInteractiveBookingSheet(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: AppColors.textWhite),
        label: const Text(
          'Buat Reservasi',
          style: TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(adminAppointmentsProvider.notifier).refresh();
          await ref.read(notificationsProvider.notifier).refresh();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
          children: [
            // Filter Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filterTabs.map((tab) {
                  final isSelected = _selectedFilter == tab['key'];
                  final count = tab['key'] == 'all'
                      ? myAppointments.length
                      : myAppointments.where((a) {
                          if (tab['key'] == 'active') {
                            return !a.isExpired &&
                                (a.status == 'Terkonfirmasi' ||
                                    a.status == 'Menunggu' ||
                                    a.status == 'Checked-in');
                          }
                          if (tab['key'] == 'completed') {
                            return a.status == 'Selesai';
                          }
                          if (tab['key'] == 'cancelled') {
                            return a.isExpired ||
                                a.status == 'Dibatalkan' ||
                                a.status == 'Tidak Berlaku' ||
                                a.status == 'Kadaluarsa' ||
                                a.status == 'Kedaluwarsa';
                          }
                          return true;
                        }).length;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text('${tab['label']} ($count)'),
                      selectedColor: AppColors.primaryOverlay15,
                      checkmarkColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.primary : AppColors.grey700,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) {
                        setState(() => _selectedFilter = tab['key']!);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            if (filteredAppointments.isEmpty)
              Container(
                padding: const EdgeInsets.all(40),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    const Icon(
                      Icons.event_busy_outlined,
                      size: 64,
                      color: AppColors.grey400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Belum ada reservasi pada kategori ini',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.grey700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Pilih dokter spesialis untuk membuat reservasi dokter baru.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => showInteractiveBookingSheet(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Buat Reservasi Baru'),
                    ),
                  ],
                ),
              )
            else
              ...filteredAppointments.map((appt) => _buildAppointmentCard(context, appt)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(BuildContext context, Appointment appt) {
    final displayStatus = appt.displayStatus;
    final statusBg = AppColors.getStatusBg(displayStatus);
    final statusText = AppColors.getStatusText(displayStatus);
    IconData statusIcon;

    if (appt.isExpired) {
      statusIcon = Icons.event_busy;
    } else {
      switch (appt.status) {
        case 'Checked-in':
          statusIcon = Icons.check_circle_outline;
          break;
        case 'Selesai':
          statusIcon = Icons.task_alt;
          break;
        case 'Dibatalkan':
          statusIcon = Icons.cancel_outlined;
          break;
        default:
          statusIcon = Icons.access_time;
      }
    }

    final isPast = appt.status == 'Selesai' || appt.status == 'Dibatalkan' || appt.isExpired;
    final doctors = ref.watch(adminDoctorsProvider);
    final matchingDoctor = doctors.cast<Doctor?>().firstWhere(
      (d) =>
          d?.name.trim().toLowerCase() == appt.doctorName.trim().toLowerCase() ||
          (appt.doctorName.toLowerCase().contains(d?.name.toLowerCase() ?? '---')),
      orElse: () => null,
    );
    final resolvedPhotoUrl = appt.doctorPhotoUrl.trim().isNotEmpty
        ? appt.doctorPhotoUrl.trim()
        : (matchingDoctor?.photoUrl.trim() ?? '');

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: appt.status == 'Terkonfirmasi' || appt.status == 'Checked-in'
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.grey200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DoctorAvatar(
                  photoUrl: resolvedPhotoUrl,
                  name: appt.doctorName,
                  radius: 24,
                  borderColor: isPast ? AppColors.grey300 : AppTheme.primary,
                  borderWidth: 1.5,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appt.doctorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${appt.department} • SehatKu Medical Center',
                        style: const TextStyle(
                          color: AppColors.grey600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusText.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusText, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        displayStatus,
                        style: TextStyle(
                          color: statusText,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                _InfoPill(
                  icon: Icons.calendar_today_outlined,
                  label: appt.dateLabel,
                ),
                const SizedBox(width: 8),
                _InfoPill(
                  icon: Icons.schedule_outlined,
                  label: appt.time,
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Antrean ${appt.queueNumber}',
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            if (appt.isExpired) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event_busy, size: 16, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Reservasi ini sudah tidak berlaku karena telah melewati hari H pelaksanaan.',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (appt.reason.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Keluhan: ${appt.reason}',
                  style: const TextStyle(fontSize: 12, color: AppColors.grey800),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => QueueTicketDialog(appointment: appt),
                      );
                    },
                    icon: const Icon(Icons.qr_code, size: 18),
                    label: const Text(
                      'Buka Tiket',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                if (appt.status == 'Selesai' ||
                    appt.status == 'Terkonfirmasi' ||
                    appt.status == 'Checked-in') ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: () {
                        final billing = ref.read(adminBillingProvider);
                        final inv = billing
                                .where((b) =>
                                    b.patientName == appt.patientName ||
                                    b.doctorName == appt.doctorName)
                                .firstOrNull ??
                            Invoice(
                              id: 'inv-${appt.id}',
                              invoiceNumber: 'INV-2026-001',
                              patientName: appt.patientName,
                              doctorName: appt.doctorName,
                              serviceName: 'Konsultasi Poli ${appt.department}',
                              amount: 350000,
                              status: 'Lunas',
                              createdAt: DateTime.now(),
                              paymentMethod: 'QRIS Dinamis',
                            );
                        showOfficialReceiptDialog(context, inv);
                      },
                      icon: const Icon(Icons.receipt_long, size: 18),
                      label: const Text(
                        'Kwitansi',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (!isPast) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _confirmCancel(context, appt),
                  icon: const Icon(Icons.close, size: 15, color: AppColors.error),
                  label: const Text(
                    'Batalkan Reservasi',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmCancel(BuildContext context, Appointment appt) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Batalkan Reservasi?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Apakah Anda yakin ingin membatalkan reservasi dengan ${appt.doctorName}?'),
            const SizedBox(height: 14),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Alasan pembatalan',
                hintText: 'Misal: Ada halangan mendadak',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Kembali'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              final reason = reasonController.text.trim().isNotEmpty
                  ? reasonController.text.trim()
                  : 'Dibatalkan oleh pasien';
              ref.read(adminAppointmentsProvider.notifier).cancelAppointment(
                    appt.id,
                    reason,
                  );
              ref.read(notificationsProvider.notifier).refresh();
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reservasi berhasil dibatalkan.'),
                  backgroundColor: AppColors.warning,
                ),
              );
            },
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.grey700),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.grey800,
            ),
          ),
        ],
      ),
    );
  }
}
