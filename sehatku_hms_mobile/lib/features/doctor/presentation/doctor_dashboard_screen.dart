import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_env.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/health_models.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../admin/application/admin_state_providers.dart';
import '../../authentication/application/auth_controller.dart';
import '../../notification/application/notifications_provider.dart';
import '../../queue/application/queue_display_provider.dart';
import 'clinical_encounter_screen.dart';

class DoctorDashboardScreen extends ConsumerStatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  ConsumerState<DoctorDashboardScreen> createState() =>
      _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends ConsumerState<DoctorDashboardScreen> {
  int currentQueueIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final allAppointments = ref.watch(adminAppointmentsProvider);

    // Filter appointments for the currently logged-in doctor
    final doctorName = auth.userFullName ?? 'dr. Maya Pratama, Sp.JP';
    final doctorDept = auth.doctorDepartment ?? 'Kardiologi & Vaskular';

    final doctorAppointments = allAppointments.where((a) {
      if (auth.userFullName == null) return true;
      final docFirst = doctorName.toLowerCase().split(' ').first;
      return a.doctorName.toLowerCase().contains(docFirst) ||
          doctorName.toLowerCase().contains(a.doctorName.toLowerCase()) ||
          allAppointments.length <= 4;
    }).toList();

    final appointments = doctorAppointments.isNotEmpty
        ? doctorAppointments
        : allAppointments;

    final waitingAppointments = appointments
        .where((a) => a.status != 'Selesai' && a.status != 'Dibatalkan')
        .toList();
    final completedAppointments = appointments
        .where((a) => a.status == 'Selesai')
        .toList();

    return Scaffold(
      appBar: DashboardAppBar(
        title: 'Selamat Datang, $doctorName',
        subtitle: 'Poli $doctorDept • Live Database',
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(adminAppointmentsProvider.notifier).refresh();
          await ref.read(notificationsProvider.notifier).refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(
            MediaQuery.sizeOf(context).width < 600 ? 16 : 22,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDoctorProfileHeader(doctorName, doctorDept, auth.avatarUrl),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 900;
                  final overviewWidget = _buildOverview(
                    context,
                    totalCount: appointments.length,
                    waitingCount: waitingAppointments.length,
                    completedCount: completedAppointments.length,
                    appointments: appointments,
                  );
                  final queueWidget = _buildQueuePanel(
                    context,
                    waitingAppointments,
                    auth.doctorId ?? 'd1',
                  );

                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: overviewWidget),
                        const SizedBox(width: 20),
                        Expanded(flex: 2, child: queueWidget),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      overviewWidget,
                      const SizedBox(height: 20),
                      queueWidget,
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorProfileHeader(String doctorName, String doctorDept, String? avatarUrl) {
    final photo = AppEnv.resolveMediaUrl(avatarUrl);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppTheme.navy.withValues(alpha: 0.1),
            backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
            onBackgroundImageError: photo.isNotEmpty ? (_, _) {} : null,
            child: photo.isEmpty
                ? const Icon(Icons.person, color: AppTheme.navy, size: 28)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        doctorName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.navy,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Text(
                        'Praktek Aktif',
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Spesialis $doctorDept • SehatKu Medical Center (SIP Aktif)',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverview(
    BuildContext context, {
    required int totalCount,
    required int waitingCount,
    required int completedCount,
    required List<Appointment> appointments,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 700
              ? 3
              : constraints.maxWidth >= 420
              ? 2
              : 1;
          return GridView.count(
            crossAxisCount: columns,
            childAspectRatio: columns == 1
                ? 3.6
                : columns == 2
                ? 2.2
                : 2.5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              MetricCard(
                label: 'Janji Hari Ini',
                value: '$totalCount',
                icon: Icons.calendar_month_outlined,
              ),
              MetricCard(
                label: 'Dalam Antrean',
                value: '$waitingCount',
                icon: Icons.hourglass_bottom,
                color: Colors.orange,
              ),
              MetricCard(
                label: 'Konsultasi Selesai',
                value: '$completedCount',
                icon: Icons.task_alt,
                color: AppTheme.success,
              ),
            ],
          );
        },
      ),
      const SizedBox(height: 22),
      const SectionHeader('Daftar Antrean Poli Hari Ini'),
      const SizedBox(height: 10),
      if (appointments.isEmpty)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'Belum ada pasien terdaftar untuk poli ini hari ini.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ),
        )
      else
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: appointments.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, idx) {
              final a = appointments[idx];
              final isCheckedIn = a.status == 'Checked-in';
              final isDone = a.status == 'Selesai';

              return ListTile(
                leading: Container(
                  width: 60,
                  height: 38,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDone
                        ? Colors.green.shade50
                        : isCheckedIn
                        ? Colors.blue.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDone
                          ? Colors.green.shade200
                          : isCheckedIn
                          ? Colors.blue.shade200
                          : Colors.orange.shade200,
                    ),
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        a.queueNumber,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 0.5,
                          color: isDone
                              ? Colors.green.shade800
                              : isCheckedIn
                              ? Colors.blue.shade800
                              : Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ),
                ),
                title: Text(
                  a.patientName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text('${a.time} • ${a.reason}'),
                trailing: Chip(
                  label: Text(a.status, style: const TextStyle(fontSize: 11)),
                  backgroundColor: isDone
                      ? Colors.green.shade50
                      : isCheckedIn
                      ? Colors.blue.shade50
                      : Colors.orange.shade50,
                ),
              );
            },
          ),
        ),
      const SizedBox(height: 22),
      const SectionHeader('Catatan Klinis Dokter'),
      const SizedBox(height: 8),
      const TextField(
        maxLines: 3,
        decoration: InputDecoration(
          hintText:
              'Tulis catatan anamnesis cepat atau pengingat konsultasi...',
          border: OutlineInputBorder(),
        ),
      ),
    ],
  );

  Widget _buildQueuePanel(
    BuildContext context,
    List<Appointment> waitingList,
    String currentDoctorId,
  ) {
    final currentAppt = waitingList.isNotEmpty
        ? waitingList[currentQueueIndex.clamp(0, waitingList.length - 1)]
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Pemanggilan Antrean Live'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.navy, AppTheme.navy.withValues(alpha: 0.85)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppTheme.navy.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: currentAppt == null
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'Semua antrean pasien telah selesai diperiksa.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                )
              : Column(
                  children: [
                    const Text(
                      'PASIEN ANTRIAN BERIKUTNYA',
                      style: TextStyle(
                        color: Colors.white70,
                        letterSpacing: 1.2,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      currentAppt.queueNumber,
                      style: const TextStyle(
                        color: Colors.amberAccent,
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currentAppt.patientName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      currentAppt.reason,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        final patients = ref.read(adminPatientsProvider);
                        final patient = patients
                            .where((p) => p.name == currentAppt.patientName)
                            .firstOrNull;

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ClinicalEncounterScreen(
                              appointment: currentAppt,
                              patient: patient,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.assignment_turned_in_outlined,
                        size: 20,
                      ),
                      label: const Text(
                        'Mulai Konsultasi & Rekam Medis (SOAP)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white54),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              final deptName =
                                  currentAppt.department.startsWith('Poli')
                                  ? currentAppt.department
                                  : 'Poli ${currentAppt.department}';
                              ref
                                  .read(queueDisplayProvider.notifier)
                                  .callPatient(
                                    queueNumber: currentAppt.queueNumber,
                                    patientName: currentAppt.patientName,
                                    destination:
                                        '$deptName, Ruang Periksa Dokter',
                                  );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Memanggil suara antrean ${currentAppt.queueNumber} (${currentAppt.patientName}) ke ${currentAppt.department}...',
                                  ),
                                  backgroundColor: Colors.teal,
                                ),
                              );
                            },
                            icon: const Icon(Icons.volume_up, size: 18),
                            label: const Text('Panggil Suara'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.greenAccent,
                              side: const BorderSide(color: Colors.greenAccent),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              ref
                                  .read(adminAppointmentsProvider.notifier)
                                  .completeAppointment(currentAppt.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Pemeriksaan untuk ${currentAppt.patientName} (${currentAppt.queueNumber}) selesai.',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.check_circle_outline,
                              size: 18,
                            ),
                            label: const Text('Selesai Cepat'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => context.push('/queue-display'),
                      icon: const Icon(Icons.tv_rounded, size: 18),
                      label: const Text(
                        'Buka Layar TV Antrean Ruang Tunggu',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
