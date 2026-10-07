import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../admin/application/admin_state_providers.dart';
import '../../authentication/application/auth_controller.dart';
import '../application/medical_records_provider.dart';

class MedicalRecordsScreen extends ConsumerWidget {
  const MedicalRecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final patients = ref.watch(adminPatientsProvider);
    final records = ref.watch(medicalRecordsProvider);

    final patientName = auth.userFullName?.trim().isNotEmpty == true
        ? auth.userFullName!
        : (auth.email != null && auth.email!.isNotEmpty
            ? auth.email!.split('@').first
            : 'Pasien');
    final matchedPatient = patients.where((p) => p.name == patientName || p.id == auth.patientId).firstOrNull;
    final mrn = matchedPatient?.medicalRecordNumber ?? auth.patientMrn ?? '-';
    final bloodType = matchedPatient?.bloodType ?? 'O+';

    return Scaffold(
      appBar: const DashboardAppBar(
        title: 'Rekam Medis Pasien',
        subtitle: 'Riwayat klinis terenkripsi langsung dari database',
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(medicalRecordsProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.navy,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.navy.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.bloodtype_outlined, color: Colors.white, size: 38),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ringkasan Pasien Terdaftar',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$patientName ($mrn) • Gol. $bloodType',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SectionHeader(
              'Riwayat Konsultasi Medis',
              action: '${records.length} Kunjungan',
            ),
            const SizedBox(height: 10),
            if (records.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                child: Column(
                  children: const [
                    Icon(Icons.folder_open_outlined, size: 48, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'Belum ada riwayat rekam medis di database.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              ...records.map(
                (record) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                      child: const Icon(Icons.medical_information_outlined, color: AppTheme.primary),
                    ),
                    title: Text(
                      record.diagnosis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text('${record.date} • ${record.doctor} (${record.specialist})'),
                    childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                    children: [
                      if (record.anamnesis.isNotEmpty) ...[
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.notes, color: Colors.grey, size: 20),
                          title: const Text('Anamnesis & Keluhan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          subtitle: Text(record.anamnesis),
                        ),
                        const Divider(),
                      ],
                      if (record.physicalExam.isNotEmpty) ...[
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.monitor_heart_outlined, color: Colors.grey, size: 20),
                          title: const Text('Pemeriksaan Fisik / Tanda Vital', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          subtitle: Text(record.physicalExam),
                        ),
                        const Divider(),
                      ],
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.medication_outlined, color: Colors.green, size: 20),
                        title: const Text('Resep Obat (E-Prescription)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        subtitle: Text(record.medicine),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Mengunduh resume medis resmi PDF...')),
                                );
                              },
                              icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                              label: const Text('Unduh PDF', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Tautan resume medis tersalin ke clipboard.')),
                                );
                              },
                              icon: const Icon(Icons.share_outlined, size: 16),
                              label: const Text('Bagikan', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
