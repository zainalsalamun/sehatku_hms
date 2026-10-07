import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/health_models.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../admin/application/admin_state_providers.dart';
import '../../appointment/presentation/interactive_booking_sheet.dart';
import '../../authentication/application/auth_controller.dart';
import '../../notification/application/notifications_provider.dart';
import '../../doctor/presentation/doctor_detail_sheet.dart';
import 'doctor_patient_chat_screen.dart';
import 'widgets/queue_ticket_dialog.dart';

class PatientHomeScreen extends ConsumerWidget {
  const PatientHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final doctors = ref.watch(adminDoctorsProvider);
    final appointments = ref.watch(adminAppointmentsProvider);
    final compact = MediaQuery.sizeOf(context).width < 600;

    final patientName = auth.userFullName?.trim().isNotEmpty == true
        ? auth.userFullName!
        : (auth.email != null && auth.email!.isNotEmpty
            ? auth.email!.split('@').first
            : 'Pasien');
    final patientFirst = patientName.contains(' ')
        ? patientName.split(' ').first
        : patientName;

    // Filter appointments for currently logged-in patient
    final patientAppointments = appointments.where((a) {
      final query = patientFirst.toLowerCase();
      final fullQuery = patientName.toLowerCase();
      return a.patientName.toLowerCase().contains(query) ||
          fullQuery.contains(a.patientName.toLowerCase());
    }).toList();

    final upcoming = patientAppointments.isNotEmpty
        ? patientAppointments.first
        : (appointments.isNotEmpty ? appointments.first : null);

    return Scaffold(
      appBar: DashboardAppBar(
        title: 'Halo, $patientFirst',
        subtitle: 'Bagaimana kesehatanmu hari ini?',
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(adminAppointmentsProvider.notifier).refresh();
          await ref.read(adminDoctorsProvider.notifier).refresh();
          await ref.read(notificationsProvider.notifier).refresh();
        },
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            compact ? 16 : 20,
            12,
            compact ? 16 : 20,
            32,
          ),
          children: [
            // Upcoming Appointment Interactive Banner
            if (upcoming != null)
              InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => QueueTicketDialog(appointment: upcoming),
                  );
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.bannerGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.bannerShadow,
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'RESERVASI BERIKUTNYA',
                              style: TextStyle(
                                color: AppColors.textWhite75,
                                fontSize: 11,
                                letterSpacing: 1.1,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.whiteOverlay15,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.qr_code,
                                  color: AppColors.textWhite,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Buka Tiket',
                                  style: TextStyle(
                                    color: AppColors.textWhite,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.white24,
                            backgroundImage: upcoming.displayDoctorPhotoUrl.isNotEmpty
                                ? NetworkImage(upcoming.displayDoctorPhotoUrl)
                                : null,
                            onBackgroundImageError: upcoming.displayDoctorPhotoUrl.isNotEmpty
                                ? (_, _) {}
                                : null,
                            child: upcoming.displayDoctorPhotoUrl.isEmpty
                                ? const Icon(Icons.person, color: Colors.white, size: 28)
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  upcoming.doctorName,
                                  style: const TextStyle(
                                    color: AppColors.textWhite,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${upcoming.department} • ${upcoming.dateLabel}, ${upcoming.time}',
                                  style: TextStyle(
                                    color: AppColors.textWhite90,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _pill(
                            Icons.confirmation_number_outlined,
                            'Antrean ${upcoming.queueNumber}',
                            color: AppColors.amberAccent,
                          ),
                          _pill(
                            Icons.verified_outlined,
                            upcoming.status,
                            color: upcoming.status == 'Checked-in'
                                ? AppColors.greenAccent
                                : AppColors.textWhite,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.grey300),
                ),
                child: compact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _emptyAppointmentMessage(),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () =>
                                showInteractiveBookingSheet(context),
                            child: const Text('Buat Reservasi'),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(child: _emptyAppointmentMessage()),
                          const SizedBox(width: 16),
                          FilledButton(
                            onPressed: () =>
                                showInteractiveBookingSheet(context),
                            child: const Text('Buat Reservasi'),
                          ),
                        ],
                      ),
              ),

            const SizedBox(height: 24),
            const SectionHeader('Akses cepat'),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: compact ? 2 : 4,
              childAspectRatio: compact ? 1.55 : 1.05,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _QuickAction(
                  Icons.search,
                  'Cari dokter',
                  () => _showDoctors(context, doctors),
                ),
                _QuickAction(
                  Icons.calendar_month_outlined,
                  'Reservasi',
                  () => showInteractiveBookingSheet(context),
                ),
                _QuickAction(Icons.qr_code_2, 'Tiket Antrean', () {
                  if (upcoming != null) {
                    showDialog(
                      context: context,
                      builder: (_) => QueueTicketDialog(appointment: upcoming),
                    );
                  } else {
                    showInteractiveBookingSheet(context);
                  }
                }),
                _QuickAction(
                  Icons.chat_bubble_outline,
                  'Chat dokter',
                  () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DoctorPatientChatScreen(
                        doctorName: upcoming?.doctorName ?? 'dr. Maya Pratama, Sp.JP',
                        specialist: upcoming?.department ?? 'Spesialis Jantung & Pembuluh Darah',
                        doctorPhotoUrl: upcoming?.displayDoctorPhotoUrl ?? '',
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (patientAppointments.length > 1) ...[
              const SizedBox(height: 24),
              SectionHeader(
                'Daftar Reservasi Saya',
                action: '${patientAppointments.length} Reservasi',
              ),
              const SizedBox(height: 10),
              ...patientAppointments
                  .skip(1)
                  .take(3)
                  .map(
                    (appt) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryOverlay10,
                          backgroundImage: appt.displayDoctorPhotoUrl.isNotEmpty
                              ? NetworkImage(appt.displayDoctorPhotoUrl)
                              : null,
                          onBackgroundImageError: appt.displayDoctorPhotoUrl.isNotEmpty
                              ? (_, _) {}
                              : null,
                          child: appt.displayDoctorPhotoUrl.isEmpty
                              ? const Icon(Icons.person, color: AppTheme.primary, size: 22)
                              : null,
                        ),
                        title: Text(
                          appt.doctorName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${appt.department} • ${appt.dateLabel}, ${appt.time}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.getStatusBg(appt.status),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                appt.status,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.getStatusText(appt.status),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.qr_code, size: 20),
                              tooltip: 'Lihat Tiket',
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) =>
                                      QueueTicketDialog(appointment: appt),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
            ],

            const SizedBox(height: 24),
            SectionHeader(
              'Dokter spesialis tersedia',
              action: 'Lihat semua (${doctors.length})',
            ),
            const SizedBox(height: 10),
            ...doctors
                .take(4)
                .map(
                  (doctor) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      leading: CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.primaryOverlay12,
                        backgroundImage: NetworkImage(doctor.displayPhotoUrl),
                        onBackgroundImageError: (_, _) {},
                        child: doctor.displayPhotoUrl.isEmpty
                            ? const Icon(
                                Icons.medical_services_outlined,
                                color: AppColors.primary,
                                size: 24,
                              )
                            : null,
                      ),
                      title: Text(
                        doctor.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Row(
                        children: [
                          Flexible(
                            child: Text(
                              doctor.specialist,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Text(
                            ' • ',
                            style: TextStyle(fontSize: 12),
                          ),
                          const Icon(Icons.star, color: AppColors.star, size: 13),
                          const SizedBox(width: 2),
                          Text(
                            '${doctor.rating} (${doctor.experience} thn)',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      trailing: FilledButton.tonal(
                        onPressed: () => showInteractiveBookingSheet(
                          context,
                          initialDoctor: doctor,
                        ),
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                        ),
                        child: const Text(
                          'Booking',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ),

            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.insuranceBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.insuranceBorder),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.insuranceIconBg,
                    child: Icon(
                      Icons.shield_outlined,
                      color: AppColors.insuranceIcon,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Layanan BPJS Kesehatan & Asuransi Swasta terintegrasi langsung di Rumah Sakit SehatKu.',
                      style: TextStyle(fontSize: 12, height: 1.3),
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

  Widget _pill(IconData icon, String label, {Color color = AppColors.textWhite}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.whiteOverlay15,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );

  Widget _emptyAppointmentMessage() => const Row(
    children: [
      CircleAvatar(
        backgroundColor: AppColors.primary,
        child: Icon(Icons.calendar_today, color: AppColors.textWhite),
      ),
      SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Belum Ada Reservasi Aktif',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Pilih dokter spesialis untuk membuat reservasi baru.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    ],
  );

  void _showDoctors(BuildContext context, List<Doctor> doctors) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SizedBox(
        height: MediaQuery.sizeOf(context).height * .75,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Cari Dokter Spesialis',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            const TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Nama dokter atau spesialisasi...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ...doctors.map(
              (doctor) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryOverlay10,
                    backgroundImage: NetworkImage(doctor.displayPhotoUrl),
                    onBackgroundImageError: (_, _) {},
                    child: doctor.displayPhotoUrl.isEmpty
                        ? const Icon(Icons.person, color: AppColors.primary)
                        : null,
                  ),
                  title: Text(
                    doctor.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Row(
                    children: [
                      Flexible(
                        child: Text(
                          doctor.specialist,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Text(
                        ' • ',
                        style: TextStyle(fontSize: 12),
                      ),
                      const Icon(Icons.star, color: AppColors.star, size: 13),
                      const SizedBox(width: 2),
                      Text(
                        '${doctor.rating}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      showInteractiveBookingSheet(
                        context,
                        initialDoctor: doctor,
                      );
                    },
                    child: const Text('Pilih', style: TextStyle(fontSize: 12)),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    showDoctorDetailSheet(context, doctor);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primary, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
