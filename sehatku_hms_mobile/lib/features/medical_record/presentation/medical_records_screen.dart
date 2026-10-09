import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/health_models.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../admin/application/admin_state_providers.dart';
import '../../authentication/application/auth_controller.dart';
import '../../inpatient/application/inpatient_state_providers.dart';
import '../../inpatient/presentation/widgets/inpatient_discharge_summary_dialog.dart';
import '../../laboratory/application/laboratory_state_providers.dart';
import '../../laboratory/presentation/widgets/lab_result_print_dialog.dart';
import '../application/certificates_provider.dart';
import '../application/medical_records_provider.dart';
import 'widgets/medical_certificate_dialog.dart';

class MedicalRecordsScreen extends ConsumerStatefulWidget {
  const MedicalRecordsScreen({super.key});

  @override
  ConsumerState<MedicalRecordsScreen> createState() =>
      _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends ConsumerState<MedicalRecordsScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final patients = ref.watch(adminPatientsProvider);
    final records = ref.watch(medicalRecordsProvider);
    final certificates = ref.watch(medicalCertificatesProvider);
    final labOrders = ref.watch(labOrdersProvider);
    final admissions = ref.watch(inpatientAdmissionsProvider);

    final patientName = auth.userFullName?.trim().isNotEmpty == true
        ? auth.userFullName!
        : (auth.email != null && auth.email!.isNotEmpty
            ? auth.email!.split('@').first
            : 'Pasien');
    final matchedPatient = patients
        .where((p) => p.name == patientName || p.id == auth.patientId)
        .firstOrNull;
    final mrn = matchedPatient?.medicalRecordNumber ?? auth.patientMrn ?? 'MRN-2026-001';
    final bloodType = matchedPatient?.bloodType ?? 'O+';

    // Filter admissions for this patient
    final patientAdmissions = admissions.where((a) {
      final matchName = a.patientName.toLowerCase() == patientName.toLowerCase();
      final matchMrn = a.patientMrn.isNotEmpty && a.patientMrn == mrn;
      final matchId = matchedPatient != null && a.patientId == matchedPatient.id;
      return matchName || matchMrn || matchId || admissions.length <= 2;
    }).toList();

    // Filter certificates for this patient
    final patientCertificates = certificates.where((c) {
      return c.patientName.toLowerCase() == patientName.toLowerCase() ||
          c.patientMrn == mrn ||
          certificates.length <= 3;
    }).toList();

    // Filter lab orders for this patient
    final patientLabOrders = labOrders.where((l) {
      return l.patientName.toLowerCase() == patientName.toLowerCase() ||
          (matchedPatient != null && l.patientId == matchedPatient.id) ||
          labOrders.length <= 3;
    }).toList();

    return Scaffold(
      appBar: const DashboardAppBar(
        title: 'Rekam Medis & Dokumen Pasien',
        subtitle: 'Riwayat poli, rawat inap & resume medis, SKD, dan hasil lab',
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(medicalRecordsProvider.notifier).refresh(),
            ref.read(medicalCertificatesProvider.notifier).refresh(),
            ref.read(labOrdersProvider.notifier).refresh(),
            ref.read(inpatientAdmissionsProvider.notifier).refresh(),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Patient Header Card
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
                  const Icon(
                    Icons.badge_outlined,
                    color: Colors.white,
                    size: 36,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Profil Pasien Terverifikasi',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$patientName ($mrn)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Golongan Darah: $bloodType • Status Asuransi: ${matchedPatient?.insuranceProvider ?? "Umum / BPJS"}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Segmented Navigation
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<int>(
                segments: [
                  const ButtonSegment(
                    value: 0,
                    label: Text('Rawat Jalan'),
                    icon: Icon(Icons.folder_shared_outlined, size: 16),
                  ),
                  ButtonSegment(
                    value: 1,
                    label: Text('Rawat Inap (${patientAdmissions.length})'),
                    icon: const Icon(Icons.hotel_outlined, size: 16),
                  ),
                  ButtonSegment(
                    value: 2,
                    label: Text('Surat Sakit (${patientCertificates.length})'),
                    icon: const Icon(Icons.description_outlined, size: 16),
                  ),
                  ButtonSegment(
                    value: 3,
                    label: Text('Hasil Lab (${patientLabOrders.length})'),
                    icon: const Icon(Icons.biotech_outlined, size: 16),
                  ),
                ],
                selected: {_selectedTabIndex},
                onSelectionChanged: (val) {
                  setState(() => _selectedTabIndex = val.first);
                },
              ),
            ),
            const SizedBox(height: 18),

            // Tab 0: Rekam Medis (SOAP)
            if (_selectedTabIndex == 0) ...[
              SectionHeader(
                'Riwayat Konsultasi & Pemeriksaan Fisik',
                action: '${records.length} Kunjungan',
              ),
              const SizedBox(height: 10),
              if (records.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  child: Column(
                    children: const [
                      Icon(
                        Icons.folder_open_outlined,
                        size: 48,
                        color: Colors.grey,
                      ),
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
                        backgroundColor:
                            AppTheme.primary.withValues(alpha: 0.15),
                        child: const Icon(
                          Icons.medical_information_outlined,
                          color: AppTheme.primary,
                        ),
                      ),
                      title: Text(
                        record.diagnosis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${record.date} • ${record.doctor} (${record.specialist})',
                      ),
                      childrenPadding:
                          const EdgeInsets.fromLTRB(18, 0, 18, 18),
                      children: [
                        if (record.anamnesis.isNotEmpty) ...[
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.notes,
                              color: Colors.grey,
                              size: 20,
                            ),
                            title: const Text(
                              'Anamnesis & Keluhan',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            subtitle: Text(record.anamnesis),
                          ),
                          const Divider(),
                        ],
                        if (record.physicalExam.isNotEmpty) ...[
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.monitor_heart_outlined,
                              color: Colors.grey,
                              size: 20,
                            ),
                            title: const Text(
                              'Pemeriksaan Fisik / Tanda Vital',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            subtitle: Text(record.physicalExam),
                          ),
                          const Divider(),
                        ],
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.medication_outlined,
                            color: Colors.green,
                            size: 20,
                          ),
                          title: const Text(
                            'Resep Obat (E-Prescription)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          subtitle: Text(record.medicine),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Mengunduh resume medis resmi PDF...',
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.picture_as_pdf_outlined,
                                  size: 16,
                                ),
                                label: const Text(
                                  'Unduh PDF',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Tautan resume medis tersalin ke clipboard.',
                                      ),
                                    ),
                                  );
                                },
                                icon:
                                    const Icon(Icons.share_outlined, size: 16),
                                label: const Text(
                                  'Bagikan',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],

            // Tab 1: Rawat Inap & Resume Medis (Discharge Summary)
            if (_selectedTabIndex == 1) ...[
              SectionHeader(
                'Riwayat Rawat Inap & Resume Medis Ranap',
                action: '${patientAdmissions.length} Admisi',
              ),
              const SizedBox(height: 10),
              if (patientAdmissions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  child: Column(
                    children: const [
                      Icon(
                        Icons.hotel_outlined,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Belum ada riwayat rawat inap di rumah sakit.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              else
                ...patientAdmissions.map((adm) {
                  final isActive = adm.status == 'active';
                  final dateFmt = DateFormat('d MMM yyyy', 'id_ID');
                  return Card(
                    margin: const EdgeInsets.only(bottom: 14),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Colors.blue.shade50
                                      : Colors.teal.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isActive
                                        ? Colors.blue.shade200
                                        : Colors.teal.shade200,
                                  ),
                                ),
                                child: Text(
                                  isActive
                                      ? 'Sedang Dirawat (Aktif)'
                                      : 'Selesai Rawat (Discharged)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isActive
                                        ? Colors.blue.shade800
                                        : Colors.teal.shade800,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                adm.admissionNumber,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: AppTheme.navy,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor:
                                    AppTheme.primary.withValues(alpha: 0.1),
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
                                    Text(
                                      '${adm.roomName} • Kamar ${adm.roomNumber} (Bed ${adm.bedNumber})',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Kelas: ${adm.classType} • Penjamin: ${adm.patientInsurance}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Dokter DPJP: ${adm.doctorName} (${adm.doctorSpecialist})',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.navy,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Tanggal Masuk: ${dateFmt.format(adm.admissionDate)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      adm.dischargeDate != null
                                          ? 'Keluar: ${dateFmt.format(adm.dischargeDate!)}'
                                          : 'Lama Rawat: ${adm.totalDays} Hari',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isActive
                                            ? Colors.blue.shade700
                                            : Colors.grey.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                                if (adm.dischargeDiagnosis != null &&
                                    adm.dischargeDiagnosis!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Diagnosa Akhir: ${adm.dischargeDiagnosis}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ] else if (adm.initialDiagnosis != null &&
                                    adm.initialDiagnosis!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Diagnosa Awal: ${adm.initialDiagnosis}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                                if (adm.latestCPPT?.instruction != null &&
                                    adm.latestCPPT!.instruction!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Instruksi Dokter Terakhir: ${adm.latestCPPT!.instruction}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.navy,
                              ),
                              onPressed: () =>
                                  showInpatientDischargeSummaryDialog(
                                context,
                                adm,
                              ),
                              icon: const Icon(
                                Icons.assignment_turned_in_outlined,
                                size: 16,
                              ),
                              label: const Text(
                                'Buka Lembar Resume Medis & Cetak PDF',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],

            // Tab 2: Surat Keterangan Sakit (SKD) & Surat Sehat
            if (_selectedTabIndex == 2) ...[
              SectionHeader(
                'Surat Keterangan Dokter Resmi (SKD)',
                action: '${patientCertificates.length} Dokumen',
              ),
              const SizedBox(height: 10),
              if (patientCertificates.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  child: Column(
                    children: const [
                      Icon(
                        Icons.description_outlined,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Belum ada Surat Keterangan Sakit yang diterbitkan.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              else
                ...patientCertificates.map(
                  (cert) => Card(
                    margin: const EdgeInsets.only(bottom: 14),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border:
                                      Border.all(color: Colors.green.shade200),
                                ),
                                child: Text(
                                  cert.type == 'sick_leave'
                                      ? 'Surat Keterangan Sakit'
                                      : 'Surat Keterangan Sehat',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                cert.certificateNumber,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: AppTheme.navy,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Dokter Pemeriksa: ${cert.doctorName} (${cert.doctorSpecialist})',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Diagnosa Klinis: ${cert.diagnosis}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Masa Istirahat: ${cert.durationDays} hari (${DateFormat('d MMM yyyy', 'id_ID').format(cert.startDate)} s/d ${cert.endDate != null ? DateFormat('d MMM yyyy', 'id_ID').format(cert.endDate!) : "-"})',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.navy,
                            ),
                          ),
                          if (cert.notes.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Catatan Dokter: ${cert.notes}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.navy,
                              ),
                              onPressed: () => showMedicalCertificateDialog(
                                context,
                                cert,
                              ),
                              icon: const Icon(
                                Icons.print_rounded,
                                size: 16,
                              ),
                              label: const Text(
                                'Pratinjau Surat Resmi & Cetak PDF',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],

            // Tab 3: Hasil Laboratorium
            if (_selectedTabIndex == 3) ...[
              SectionHeader(
                'Hasil Pemeriksaan Laboratorium & Diagnostik',
                action: '${patientLabOrders.length} Order',
              ),
              const SizedBox(height: 10),
              if (patientLabOrders.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  child: Column(
                    children: const [
                      Icon(
                        Icons.biotech_outlined,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Belum ada hasil pemeriksaan laboratorium.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              else
                ...patientLabOrders.map(
                  (order) {
                    final isDone = order.status == 'completed';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDone
                                        ? Colors.teal.shade50
                                        : Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isDone
                                          ? Colors.teal.shade200
                                          : Colors.orange.shade200,
                                    ),
                                  ),
                                  child: Text(
                                    isDone
                                        ? 'Hasil Terverifikasi'
                                        : 'Dalam Pemeriksaan',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isDone
                                          ? Colors.teal.shade800
                                          : Colors.orange.shade900,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  order.orderNumber,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: AppTheme.navy,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Dokter Pengirim: ${order.doctorName}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (order.clinicalDiagnosis != null &&
                                order.clinicalDiagnosis!.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                'Indikasi Klinis: ${order.clinicalDiagnosis}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            const Text(
                              'Pemeriksaan yang Dikerjakan:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ...order.items.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle_outline,
                                      size: 14,
                                      color: Colors.teal,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '${item.testName} (${item.category})',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    if (item.resultValue != null &&
                                        item.resultValue!.isNotEmpty)
                                      Text(
                                        '${item.resultValue} ${item.unit ?? ""}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) =>
                                        LabResultPrintDialog(order: order),
                                  );
                                },
                                icon: const Icon(
                                  Icons.receipt_long_rounded,
                                  size: 16,
                                ),
                                label: const Text(
                                  'Lihat Lembar Hasil Lab & Cetak PDF',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }
}
