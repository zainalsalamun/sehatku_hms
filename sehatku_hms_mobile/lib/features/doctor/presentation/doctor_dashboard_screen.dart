import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/config/app_env.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/health_models.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/doctor_avatar.dart';
import '../../admin/application/admin_state_providers.dart';
import '../../authentication/application/auth_controller.dart';
import '../../inpatient/application/inpatient_state_providers.dart';
import '../../inpatient/presentation/widgets/inpatient_cppt_dialog.dart';
import '../../inpatient/presentation/widgets/inpatient_discharge_dialog.dart';
import '../../inpatient/presentation/widgets/inpatient_discharge_summary_dialog.dart';
import '../../notification/application/notifications_provider.dart';
import '../../queue/application/queue_display_provider.dart';
import 'clinical_encounter_screen.dart';
import 'widgets/doctor_chat_inbox_dialog.dart';

class DoctorDashboardScreen extends ConsumerStatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  ConsumerState<DoctorDashboardScreen> createState() =>
      _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends ConsumerState<DoctorDashboardScreen> {
  int currentQueueIndex = 0;
  int _selectedServiceTab = 0; // 0 = Rawat Jalan (Poli), 1 = Rawat Inap (Visite DPJP)
  String _inpatientFilter = 'all'; // 'all', 'pending', 'done'
  bool _showAllHospitalAdmissions = false;

  String _cleanDoctorName(String name) {
    return name
        .replaceAll(RegExp(r'^(drg?\.\s*|dr\.\s*)', caseSensitive: false), '')
        .split(',')
        .first
        .trim()
        .toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final allAppointments = ref.watch(adminAppointmentsProvider);
    final allAdmissions = ref.watch(inpatientAdmissionsProvider);

    // Filter appointments strictly for the currently logged-in doctor
    final doctorName = auth.userFullName ?? 'dr. Maya Pratama, Sp.JP';
    final doctorDept = auth.doctorDepartment ?? 'Kardiologi & Vaskular';

    final cleanCurrentDoc = _cleanDoctorName(doctorName);
    final doctorAppointments = allAppointments.where((a) {
      if (auth.doctorId != null &&
          auth.doctorId!.isNotEmpty &&
          a.doctorId == auth.doctorId) {
        return true;
      }
      if (cleanCurrentDoc.isNotEmpty) {
        final cleanApptDoc = _cleanDoctorName(a.doctorName);
        if (cleanApptDoc.isNotEmpty &&
            (cleanApptDoc.contains(cleanCurrentDoc) ||
                cleanCurrentDoc.contains(cleanApptDoc))) {
          return true;
        }
      }
      return false;
    }).toList();

    final appointments = doctorAppointments;

    final waitingAppointments = appointments
        .where((a) =>
            !a.isExpired &&
            a.status != 'Selesai' &&
            a.status != 'Dibatalkan' &&
            a.status != 'Tidak Berlaku')
        .toList();
    final completedAppointments = appointments
        .where((a) => a.status == 'Selesai')
        .toList();

    // Filter inpatient admissions
    final activeAdmissions = allAdmissions
        .where((a) => a.status == 'admitted' || a.status == 'active')
        .toList();

    final doctorAdmissions = activeAdmissions.where((a) {
      if (auth.doctorId != null &&
          auth.doctorId!.isNotEmpty &&
          a.doctorId == auth.doctorId) {
        return true;
      }
      if (cleanCurrentDoc.isNotEmpty) {
        final cleanAdmDoc = _cleanDoctorName(a.doctorName);
        if (cleanAdmDoc.isNotEmpty &&
            (cleanAdmDoc.contains(cleanCurrentDoc) ||
                cleanCurrentDoc.contains(cleanAdmDoc))) {
          return true;
        }
      }
      return false;
    }).toList();

    final displayAdmissions = _showAllHospitalAdmissions
        ? activeAdmissions
        : doctorAdmissions;

    final now = DateTime.now();
    final visitedToday = displayAdmissions.where((a) {
      if (a.latestCPPT == null) return false;
      final cpptDate = a.latestCPPT!.recordedAt;
      return cpptDate.year == now.year &&
          cpptDate.month == now.month &&
          cpptDate.day == now.day;
    }).toList();
    final pendingVisit = displayAdmissions.length - visitedToday.length;

    return Scaffold(
      appBar: DashboardAppBar(
        title: 'Selamat Datang, $doctorName',
        subtitle: 'Poli $doctorDept • Live Database',
        extraActions: [
          IconButton(
            tooltip: 'Telekonsultasi & Pesan Pasien',
            icon: const Badge(
              label: Text('2'),
              child: Icon(Icons.forum_outlined),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => DoctorChatInboxDialog(
                  doctorName: doctorName,
                  specialist: doctorDept,
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(adminAppointmentsProvider.notifier).refresh();
          await ref.read(notificationsProvider.notifier).refresh();
          await ref.read(inpatientAdmissionsProvider.notifier).refresh();
          await ref.read(inpatientBedsProvider.notifier).refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(
            MediaQuery.sizeOf(context).width < 600 ? 16 : 22,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDoctorProfileHeader(
                context,
                doctorName,
                doctorDept,
                auth.avatarUrl,
                auth.doctorLicenseNumber,
                auth.doctorPracticeStatus ?? 'Aktif Melayani',
              ),
              _buildServiceSegmentSwitcher(
                context,
                waitingClinicCount: waitingAppointments.length,
                activeInpatientCount: doctorAdmissions.length,
              ),
              if (_selectedServiceTab == 0)
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
                )
              else
                _buildInpatientVisiteView(
                  context,
                  admissions: displayAdmissions,
                  allActiveAdmissions: activeAdmissions,
                  doctorAdmissionsCount: doctorAdmissions.length,
                  doctorName: doctorName,
                  visitedTodayCount: visitedToday.length,
                  pendingVisitCount: pendingVisit,
                  showAllAdmissions: _showAllHospitalAdmissions,
                  onToggleShowAll: (val) {
                    setState(() {
                      _showAllHospitalAdmissions = val;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorProfileHeader(
    BuildContext context,
    String doctorName,
    String doctorDept,
    String? avatarUrl,
    String? licenseNumber,
    String practiceStatus,
  ) {
    Color statusBg;
    Color statusBorder;
    Color statusText;
    IconData statusIcon;

    switch (practiceStatus) {
      case 'Istirahat / Break':
        statusBg = Colors.orange.shade50;
        statusBorder = Colors.orange.shade200;
        statusText = Colors.orange.shade900;
        statusIcon = Icons.pause_circle_outline;
        break;
      case 'Selesai Praktek':
        statusBg = Colors.red.shade50;
        statusBorder = Colors.red.shade200;
        statusText = Colors.red.shade800;
        statusIcon = Icons.cancel_outlined;
        break;
      case 'Aktif Melayani':
      default:
        statusBg = Colors.green.shade50;
        statusBorder = Colors.green.shade200;
        statusText = Colors.green.shade800;
        statusIcon = Icons.check_circle_outline;
        break;
    }

    final sip = (licenseNumber != null && licenseNumber.isNotEmpty)
        ? licenseNumber
        : 'SIP.449.1/023/2021';

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
          DoctorAvatar(
            photoUrl: avatarUrl ?? '',
            name: doctorName,
            radius: 28,
            borderWidth: 1.5,
            borderColor: AppTheme.navy.withValues(alpha: 0.2),
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
                    PopupMenuButton<String>(
                      tooltip: 'Ubah Status Praktek',
                      onSelected: (newStatus) async {
                        await ref
                            .read(authControllerProvider.notifier)
                            .updateDoctorPracticeStatus(newStatus);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Status praktek diubah ke: $newStatus',
                              ),
                              backgroundColor: AppTheme.navy,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'Aktif Melayani',
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                color: Colors.green,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text('Aktif Melayani'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'Istirahat / Break',
                          child: Row(
                            children: [
                              Icon(
                                Icons.pause_circle_outline,
                                color: Colors.orange,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text('Istirahat / Break'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'Selesai Praktek',
                          child: Row(
                            children: [
                              Icon(
                                Icons.cancel_outlined,
                                color: Colors.red,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text('Selesai Praktek'),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: statusBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 12, color: statusText),
                            const SizedBox(width: 4),
                            Text(
                              practiceStatus,
                              style: TextStyle(
                                color: statusText,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.arrow_drop_down,
                              size: 14,
                              color: statusText,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'SIP: $sip • Spesialis $doctorDept',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => DoctorChatInboxDialog(
                        doctorName: doctorName,
                        specialist: doctorDept,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.navy.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.forum_outlined, size: 13, color: AppTheme.navy),
                        SizedBox(width: 4),
                        Text(
                          'Pesan Pasien (2 Menunggu)',
                          style: TextStyle(
                            color: AppTheme.navy,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.chevron_right, size: 14, color: AppTheme.navy),
                      ],
                    ),
                  ),
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
          final isWide = constraints.maxWidth >= 650;
          if (isWide) {
            return Row(
              children: [
                Expanded(
                  child: MetricCard(
                    label: 'Janji Hari Ini',
                    value: '$totalCount',
                    icon: Icons.calendar_month_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricCard(
                    label: 'Dalam Antrean',
                    value: '$waitingCount',
                    icon: Icons.hourglass_bottom,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricCard(
                    label: 'Konsultasi Selesai',
                    value: '$completedCount',
                    icon: Icons.task_alt,
                    color: AppTheme.success,
                  ),
                ),
              ],
            );
          }
          return Column(
            children: [
              MetricCard(
                label: 'Janji Hari Ini',
                value: '$totalCount',
                icon: Icons.calendar_month_outlined,
              ),
              const SizedBox(height: 10),
              MetricCard(
                label: 'Dalam Antrean',
                value: '$waitingCount',
                icon: Icons.hourglass_bottom,
                color: Colors.orange,
              ),
              const SizedBox(height: 10),
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
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.event_busy_outlined,
                    size: 44,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tidak Ada Antrean Pasien Hari Ini',
                    style: TextStyle(
                      color: AppTheme.navy,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Belum ada pasien yang didaftarkan ke jadwal praktek Anda hari ini.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
        )
      else
        Card(
          child: Column(
            children: [
              for (int idx = 0; idx < appointments.length; idx++) ...[
                if (idx > 0) const Divider(height: 1),
                _buildAppointmentItemTile(context, appointments[idx]),
              ],
            ],
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

  Widget _buildAppointmentItemTile(BuildContext context, Appointment a) {
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
  }

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
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 16,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.done_all_rounded,
                          size: 40,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Tidak Ada Pasien Menunggu',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          waitingList.isEmpty
                              ? 'Semua antrean pasien telah selesai diperiksa atau belum ada pasien aktif.'
                              : 'Antrean berikutnya belum tersedia.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12,
                          ),
                        ),
                      ],
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

  Widget _buildServiceSegmentSwitcher(
    BuildContext context, {
    required int waitingClinicCount,
    required int activeInpatientCount,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedServiceTab = 0),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedServiceTab == 0
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedServiceTab == 0
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.medical_services_outlined,
                      size: 18,
                      color: _selectedServiceTab == 0
                          ? AppTheme.primary
                          : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Rawat Jalan (Poli)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: _selectedServiceTab == 0
                            ? AppTheme.navy
                            : Colors.grey.shade600,
                      ),
                    ),
                    if (waitingClinicCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedServiceTab == 0
                              ? Colors.orange.shade100
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$waitingClinicCount',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _selectedServiceTab == 0
                                ? Colors.orange.shade900
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedServiceTab = 1),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedServiceTab == 1
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedServiceTab == 1
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.hotel_rounded,
                      size: 18,
                      color: _selectedServiceTab == 1
                          ? Colors.deepPurple
                          : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Rawat Inap (DPJP Visite)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: _selectedServiceTab == 1
                            ? AppTheme.navy
                            : Colors.grey.shade600,
                      ),
                    ),
                    if (activeInpatientCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedServiceTab == 1
                              ? Colors.deepPurple.shade100
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$activeInpatientCount',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _selectedServiceTab == 1
                                ? Colors.deepPurple.shade900
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInpatientVisiteView(
    BuildContext context, {
    required List<InpatientAdmissionModel> admissions,
    required List<InpatientAdmissionModel> allActiveAdmissions,
    required int doctorAdmissionsCount,
    required String doctorName,
    required int visitedTodayCount,
    required int pendingVisitCount,
    required bool showAllAdmissions,
    required ValueChanged<bool> onToggleShowAll,
  }) {
    final now = DateTime.now();
    final filtered = admissions.where((a) {
      final isVisited = a.latestCPPT != null &&
          a.latestCPPT!.recordedAt.year == now.year &&
          a.latestCPPT!.recordedAt.month == now.month &&
          a.latestCPPT!.recordedAt.day == now.day;

      if (_inpatientFilter == 'pending') return !isVisited;
      if (_inpatientFilter == 'done') return isVisited;
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (doctorAdmissionsCount == 0) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber.shade900, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    showAllAdmissions
                        ? 'Mode Pemantauan RS: Menampilkan seluruh ${allActiveAdmissions.length} pasien rawat inap rumah sakit.'
                        : 'Anda tidak memiliki pasien rawat inap aktif di bawah DPJP Anda saat ini. Anda dapat meninjau seluruh pasien rawat inap rumah sakit.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.brown.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => onToggleShowAll(!showAllAdmissions),
                  icon: Icon(
                    showAllAdmissions
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 16,
                    color: Colors.amber.shade900,
                  ),
                  label: Text(
                    showAllAdmissions
                        ? 'Pasien Saya Saja (0)'
                        : 'Lihat Semua RS (${allActiveAdmissions.length})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 900;
            final isTablet = constraints.maxWidth >= 550 && !isDesktop;

            if (isDesktop) {
              return Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      label: 'Pasien DPJP Aktif',
                      value: '${admissions.length}',
                      icon: Icons.hotel_outlined,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MetricCard(
                      label: 'Perlu Visite Hari Ini',
                      value: '$pendingVisitCount',
                      icon: Icons.pending_actions_outlined,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MetricCard(
                      label: 'Visite Selesai',
                      value: '$visitedTodayCount',
                      icon: Icons.check_circle_outline,
                      color: AppTheme.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MetricCard(
                      label: 'Total Bed Terisi',
                      value: '${allActiveAdmissions.length}',
                      icon: Icons.single_bed_outlined,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              );
            } else if (isTablet) {
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: MetricCard(
                          label: 'Pasien DPJP Aktif',
                          value: '${admissions.length}',
                          icon: Icons.hotel_outlined,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MetricCard(
                          label: 'Perlu Visite Hari Ini',
                          value: '$pendingVisitCount',
                          icon: Icons.pending_actions_outlined,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: MetricCard(
                          label: 'Visite Selesai',
                          value: '$visitedTodayCount',
                          icon: Icons.check_circle_outline,
                          color: AppTheme.success,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MetricCard(
                          label: 'Total Bed Terisi',
                          value: '${allActiveAdmissions.length}',
                          icon: Icons.single_bed_outlined,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }

            return Column(
              children: [
                MetricCard(
                  label: 'Pasien DPJP Aktif',
                  value: '${admissions.length}',
                  icon: Icons.hotel_outlined,
                  color: AppTheme.primary,
                ),
                const SizedBox(height: 10),
                MetricCard(
                  label: 'Perlu Visite Hari Ini',
                  value: '$pendingVisitCount',
                  icon: Icons.pending_actions_outlined,
                  color: Colors.orange,
                ),
                const SizedBox(height: 10),
                MetricCard(
                  label: 'Visite Selesai',
                  value: '$visitedTodayCount',
                  icon: Icons.check_circle_outline,
                  color: AppTheme.success,
                ),
                const SizedBox(height: 10),
                MetricCard(
                  label: 'Total Bed Terisi',
                  value: '${allActiveAdmissions.length}',
                  icon: Icons.single_bed_outlined,
                  color: Colors.deepPurple,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 22),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 10,
          children: [
            const SectionHeader('Daftar Pasien Rawat Inap (DPJP)'),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ChoiceChip(
                  label: Text('Semua (${admissions.length})'),
                  selected: _inpatientFilter == 'all',
                  onSelected: (_) => setState(() => _inpatientFilter = 'all'),
                ),
                ChoiceChip(
                  label: Text('Perlu Visite ($pendingVisitCount)'),
                  selected: _inpatientFilter == 'pending',
                  onSelected: (_) =>
                      setState(() => _inpatientFilter = 'pending'),
                ),
                ChoiceChip(
                  label: Text('Sudah Visite ($visitedTodayCount)'),
                  selected: _inpatientFilter == 'done',
                  onSelected: (_) =>
                      setState(() => _inpatientFilter = 'done'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 36,
                horizontal: 20,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.hotel_class_outlined,
                      size: 44,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      admissions.isEmpty
                          ? 'Tidak Ada Pasien Rawat Inap Ditugaskan ke Anda'
                          : 'Tidak Ada Pasien Rawat Inap pada Kategori Ini',
                      style: const TextStyle(
                        color: AppTheme.navy,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      admissions.isEmpty
                          ? 'Saat ini tidak ada pasien rawat inap yang terdaftar di bawah penanganan DPJP Anda ($doctorName).'
                          : 'Semua pasien telah ditinjau atau belum ada pasien aktif pada filter ini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Column(
            children: [
              for (int idx = 0; idx < filtered.length; idx++) ...[
                if (idx > 0) const SizedBox(height: 12),
                _buildInpatientPatientCard(
                  context,
                  filtered[idx],
                  filtered[idx].latestCPPT != null &&
                      filtered[idx].latestCPPT!.recordedAt.year == now.year &&
                      filtered[idx].latestCPPT!.recordedAt.month == now.month &&
                      filtered[idx].latestCPPT!.recordedAt.day == now.day,
                ),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildInpatientPatientCard(
    BuildContext context,
    InpatientAdmissionModel admission,
    bool isVisitedToday,
  ) {
    Color classColor;
    switch (admission.classType.toLowerCase()) {
      case 'vip':
      case 'vvip':
        classColor = Colors.purple;
        break;
      case 'kelas 1':
        classColor = Colors.blue;
        break;
      case 'kelas 2':
        classColor = Colors.teal;
        break;
      default:
        classColor = Colors.grey.shade700;
        break;
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isVisitedToday ? Colors.grey.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.hotel_rounded,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${admission.roomName} (${admission.bedNumber})',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: classColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              admission.classType,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: classColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Admisi: ${admission.admissionNumber} • Masuk: ${DateFormat('d MMM yyyy', 'id_ID').format(admission.admissionDate)} (${admission.totalDays} hari dirawat)',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        admission.patientName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.navy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'MRN: ${admission.patientMrn} • ${admission.patientGender} • Penjamin: ${admission.patientInsurance}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.medical_information_outlined,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Diagnosa Masuk: ${admission.initialDiagnosis ?? "Pemeriksaan lanjutan DPJP"}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: isVisitedToday
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isVisitedToday
                      ? Colors.green.shade200
                      : Colors.orange.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isVisitedToday
                        ? Icons.check_circle_rounded
                        : Icons.pending_actions_rounded,
                    size: 18,
                    color: isVisitedToday
                        ? Colors.green.shade800
                        : Colors.orange.shade900,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isVisitedToday
                          ? 'Visite Hari Ini Telah Selesai Dicatat (${DateFormat('HH:mm', 'id_ID').format(admission.latestCPPT!.recordedAt)} WIB)'
                          : 'Perlu Kunjungan Visite DPJP & Catatan CPPT Hari Ini',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isVisitedToday
                            ? Colors.green.shade900
                            : Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (admission.latestCPPT != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Instruksi Medis Terakhir: ${(admission.latestCPPT?.instruction != null && admission.latestCPPT!.instruction!.isNotEmpty) ? admission.latestCPPT!.instruction! : ((admission.latestCPPT?.plan != null && admission.latestCPPT!.plan!.isNotEmpty) ? admission.latestCPPT!.plan! : "-")}',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: isVisitedToday
                          ? AppTheme.navy
                          : Colors.teal.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => InpatientCPPTDialog(
                          admissionId: admission.id,
                        ),
                      ).then((_) {
                        ref
                            .read(inpatientAdmissionsProvider.notifier)
                            .refresh();
                      });
                    },
                    icon: const Icon(Icons.notes_rounded, size: 18),
                    label: Text(
                      isVisitedToday ? 'Buka Lembar CPPT' : 'Visite & Catat CPPT',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green.shade800,
                      side: BorderSide(color: Colors.green.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => InpatientDischargeDialog(
                          admission: admission,
                        ),
                      ).then((_) {
                        ref
                            .read(inpatientAdmissionsProvider.notifier)
                            .refresh();
                      });
                    },
                    icon: const Icon(Icons.output_rounded, size: 18),
                    label: const Text('Rencana Pulang'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Lembar Resume Medis & Surat Kontrol',
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.navy.withValues(alpha: 0.1),
                    foregroundColor: AppTheme.navy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(10),
                  ),
                  onPressed: () {
                    showInpatientDischargeSummaryDialog(
                      context,
                      admission,
                    );
                  },
                  icon: const Icon(Icons.description_outlined, size: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
