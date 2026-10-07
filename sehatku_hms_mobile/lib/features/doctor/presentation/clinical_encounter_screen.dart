import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/api_client_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/uuid_helper.dart';
import '../../../shared/models/health_models.dart';
import '../../admin/application/admin_state_providers.dart';
import '../../authentication/application/auth_controller.dart';
import '../../laboratory/application/laboratory_state_providers.dart';
import '../../laboratory/presentation/widgets/lab_order_create_dialog.dart';
import '../../laboratory/presentation/widgets/lab_result_print_dialog.dart';
import '../../medical_record/application/certificates_provider.dart';
import '../../medical_record/application/medical_records_provider.dart';
import '../../medical_record/presentation/widgets/medical_certificate_dialog.dart';
import '../../notification/application/notifications_provider.dart';
import '../../pharmacy/application/pharmacy_state_providers.dart';
import '../../procedures/application/procedures_provider.dart';

class PrescriptionInputItem {
  PrescriptionInputItem({
    required this.medicineName,
    required this.dosage,
    required this.frequency,
    this.route = 'oral',
    this.durationDays = 3,
    this.instruction = '',
  });

  String medicineName;
  String dosage;
  String frequency;
  String route;
  int durationDays;
  String instruction;
}

class ClinicalEncounterScreen extends ConsumerStatefulWidget {
  const ClinicalEncounterScreen({
    super.key,
    required this.appointment,
    this.patient,
  });

  final Appointment appointment;
  final Patient? patient;

  @override
  ConsumerState<ClinicalEncounterScreen> createState() =>
      _ClinicalEncounterScreenState();
}

class _ClinicalEncounterScreenState
    extends ConsumerState<ClinicalEncounterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Vital signs controllers
  final _systolicController = TextEditingController(text: '120');
  final _diastolicController = TextEditingController(text: '80');
  final _heartRateController = TextEditingController(text: '76');
  final _respiratoryRateController = TextEditingController(text: '18');
  final _temperatureController = TextEditingController(text: '36.5');
  final _spo2Controller = TextEditingController(text: '99');
  final _heightController = TextEditingController(text: '168');
  final _weightController = TextEditingController(text: '62');

  // SOAP controllers
  late final TextEditingController _subjectiveController;
  final _objectiveController = TextEditingController(
    text:
        'Keadaan Umum: Tampak sehat, Compos Mentis.\nThorax: Cor S1-S2 murni reguler, Pulmo vesikuler +/+ ronki -/-.\nAbdomen: Supel, bising usus normal, nyeri tekan (-).\nEkstremitas: Hangat, CRT < 2 detik, edema (-).',
  );
  final _planController = TextEditingController(
    text:
        '1. Edukasi pola makan rendah garam dan olahraga teratur.\n2. Lanjutkan konsumsi obat sesuai anjuran.\n3. Kontrol ulang dalam 30 hari.',
  );

  // Diagnoses
  final List<Map<String, String>> _selectedDiagnoses = [
    {
      'code': 'I10',
      'name': 'Essential (primary) hypertension',
      'type': 'primary',
    },
  ];

  // Prescriptions
  final List<PrescriptionInputItem> _prescriptions = [
    PrescriptionInputItem(
      medicineName: 'Amlodipine Besylate 5mg',
      dosage: '5 mg',
      frequency: '1x sehari pagi',
      durationDays: 30,
      instruction: 'Diminum sesudah makan pagi',
    ),
  ];

  // Clinic Procedures
  final List<ClinicProcedure> _selectedProcedures = [];

  // Medical Certificate (SKD)
  bool _issueSickLeaveCert = false;
  int _sickLeaveDays = 2;
  final _sickLeaveNotesCtrl = TextEditingController(
    text:
        'Pasien memerlukan istirahat tirah baring untuk pemulihan kondisi fisik.',
  );

  bool _isSubmitting = false;
  double _bmi = 22.0;
  String _bmiCategory = 'Normal / Ideal';
  Color _bmiColor = Colors.green;

  List<Map<String, String>> _icd10Catalog = [];
  List<Map<String, dynamic>> _formularyCatalog = [];

  @override
  void initState() {
    super.initState();
    _subjectiveController = TextEditingController(
      text:
          'Keluhan: ${widget.appointment.reason}.\nPasien merasakan keluhan sejak beberapa hari terakhir tanpa demam tinggi.',
    );
    _calculateBmi();
    _fetchCatalogs();
  }

  Future<void> _fetchCatalogs() async {
    final client = ref.read(apiClientProvider);
    final icd = await client.getIcd10Catalog();
    final form = await client.getFormularyCatalog();
    if (mounted) {
      setState(() {
        _icd10Catalog = icd;
        _formularyCatalog = form;
      });
    }
  }

  void _calculateBmi() {
    final hCm = double.tryParse(_heightController.text) ?? 0;
    final wKg = double.tryParse(_weightController.text) ?? 0;
    if (hCm > 50 && wKg > 10) {
      final hM = hCm / 100.0;
      final calculated = wKg / (hM * hM);
      setState(() {
        _bmi = calculated;
        if (_bmi < 18.5) {
          _bmiCategory = 'Underweight (Kurang)';
          _bmiColor = Colors.amber.shade700;
        } else if (_bmi < 25.0) {
          _bmiCategory = 'Normal / Ideal';
          _bmiColor = Colors.green;
        } else if (_bmi < 30.0) {
          _bmiCategory = 'Overweight (Berlebih)';
          _bmiColor = Colors.orange;
        } else {
          _bmiCategory = 'Obesitas';
          _bmiColor = Colors.red;
        }
      });
    }
  }

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _heartRateController.dispose();
    _respiratoryRateController.dispose();
    _temperatureController.dispose();
    _spo2Controller.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _subjectiveController.dispose();
    _objectiveController.dispose();
    _planController.dispose();
    _sickLeaveNotesCtrl.dispose();
    super.dispose();
  }

  void _showAddProcedureDialog() {
    final availableProcedures = ref.read(clinicProceduresProvider);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.medical_services_outlined, color: AppTheme.primary),
              SizedBox(width: 8),
              Text(
                'Pilih Tindakan Medis Klinik',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            height: 380,
            child: ListView.separated(
              itemCount: availableProcedures.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, idx) {
                final proc = availableProcedures[idx];
                final isSelected = _selectedProcedures.any(
                  (p) => p.code == proc.code,
                );
                final currency = NumberFormat.currency(
                  locale: 'id_ID',
                  symbol: 'Rp ',
                  decimalDigits: 0,
                );

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isSelected
                        ? Colors.teal
                        : Colors.grey.shade200,
                    child: Icon(
                      isSelected ? Icons.check : Icons.healing_outlined,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    proc.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    '${proc.category} • ${proc.description}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: Text(
                    currency.format(proc.price),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.teal,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedProcedures.removeWhere(
                          (p) => p.code == proc.code,
                        );
                      } else {
                        _selectedProcedures.add(proc);
                      }
                    });
                    Navigator.of(ctx).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  void _showPreviewCertificateDialog() {
    final auth = ref.read(authControllerProvider);
    final diagSummary = _selectedDiagnoses.isNotEmpty
        ? _selectedDiagnoses
              .map((d) => '${d['name']} (${d['code']})')
              .join(', ')
        : 'Pemeriksaan Rutin Klinik';

    final tempCert = MedicalCertificate(
      id: UuidHelper.generate(),
      certificateNumber:
          'SKD/${DateTime.now().year}/${(DateTime.now().month).toString().padLeft(2, '0')}/DRAFT',
      type: 'sick_leave',
      patientName: widget.appointment.patientName,
      patientMrn: widget.patient?.medicalRecordNumber ?? 'MRN-2026-001',
      doctorName: auth.userFullName ?? widget.appointment.doctorName,
      doctorSpecialist: auth.doctorSpecialist ?? widget.appointment.department,
      diagnosis: diagSummary,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(Duration(days: _sickLeaveDays)),
      durationDays: _sickLeaveDays,
      notes: _sickLeaveNotesCtrl.text.trim(),
    );

    showMedicalCertificateDialog(context, tempCert);
  }

  Future<void> _submitEncounter() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDiagnoses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pilih minimal satu diagnosis ICD-10 sebelum menyelesaikan pemeriksaan.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final auth = ref.read(authControllerProvider);
    final patientId = widget.patient?.id ?? 'p1';
    final doctorId = auth.doctorId ?? 'd1';

    final diagSummary = _selectedDiagnoses.isNotEmpty
        ? _selectedDiagnoses
              .map((d) => '${d['name']} (${d['code']})')
              .join(', ')
        : 'Pemeriksaan Rawat Jalan Poli';

    final physicalExamText =
        'TD: ${_systolicController.text}/${_diastolicController.text} mmHg, HR: ${_heartRateController.text} bpm, RR: ${_respiratoryRateController.text}x/mnt, Suhu: ${_temperatureController.text}°C, SpO2: ${_spo2Controller.text}%, TB: ${_heightController.text}cm, BB: ${_weightController.text}kg (BMI ${_bmi.toStringAsFixed(1)} - $_bmiCategory).\n\n${_objectiveController.text.trim()}';

    final data = {
      'patientId': patientId,
      'doctorId': doctorId,
      'appointmentId': widget.appointment.id,
      'anamnesis': _subjectiveController.text.trim(),
      'physicalExam': physicalExamText,
      'diagnosisSummary': diagSummary,
      'diagnoses': _selectedDiagnoses
          .map(
            (d) => {
              'icd10Code': d['code'],
              'description': d['name'],
              'type': d['type'] ?? 'primary',
            },
          )
          .toList(),
      'prescriptions': _prescriptions
          .map(
            (p) => {
              'medicineName': p.medicineName,
              'dosage': p.dosage,
              'frequency': p.frequency,
              'route': p.route,
              'durationDays': p.durationDays,
              'instruction': p.instruction,
            },
          )
          .toList(),
      'procedures': _selectedProcedures
          .map((p) => {'procedureId': p.id, 'name': p.name, 'price': p.price})
          .toList(),
      'certificate': _issueSickLeaveCert
          ? {
              'type': 'sick_leave',
              'durationDays': _sickLeaveDays,
              'notes': _sickLeaveNotesCtrl.text.trim(),
            }
          : null,
      'notes': _planController.text.trim(),
    };

    final client = ref.read(apiClientProvider);
    final success = await client.createMedicalRecord(data);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        // Create local record for instant patient reflection
        final newRecord = MedicalRecord(
          id: UuidHelper.generate(),
          date: DateFormat('d MMM yyyy', 'id_ID').format(DateTime.now()),
          doctor: auth.userFullName ?? widget.appointment.doctorName,
          specialist: auth.doctorSpecialist ?? widget.appointment.department,
          diagnosis: diagSummary,
          medicine: _prescriptions.isNotEmpty
              ? _prescriptions
                    .map((p) => '${p.medicineName} (${p.dosage})')
                    .join(', ')
              : 'Resep obat standar',
          anamnesis: _subjectiveController.text.trim(),
          physicalExam: physicalExamText,
          status: 'signed',
        );

        // Refresh and add to local state
        ref.read(medicalRecordsProvider.notifier).addRecord(newRecord);
        ref
            .read(adminAppointmentsProvider.notifier)
            .completeAppointment(widget.appointment.id);
        ref.read(medicalRecordsProvider.notifier).refresh();
        ref.read(pharmacyPrescriptionsProvider.notifier).refresh();

        // If certificate issued, add to local certificates provider
        if (_issueSickLeaveCert) {
          final newCert = MedicalCertificate(
            id: UuidHelper.generate(),
            certificateNumber:
                'SKD/${DateTime.now().year}/${(DateTime.now().month).toString().padLeft(2, '0')}/${(100 + DateTime.now().second).toString()}',
            type: 'sick_leave',
            patientName: widget.appointment.patientName,
            patientMrn: widget.patient?.medicalRecordNumber ?? 'MRN-2026-001',
            doctorName: auth.userFullName ?? widget.appointment.doctorName,
            doctorSpecialist:
                auth.doctorSpecialist ?? widget.appointment.department,
            diagnosis: diagSummary,
            startDate: DateTime.now(),
            endDate: DateTime.now().add(Duration(days: _sickLeaveDays)),
            durationDays: _sickLeaveDays,
            notes: _sickLeaveNotesCtrl.text.trim(),
          );
          ref
              .read(medicalCertificatesProvider.notifier)
              .addCertificate(newCert);
        }

        // Add instant notification for Patient and Doctor
        ref
            .read(notificationsProvider.notifier)
            .addNotification(
              AppNotification(
                id: UuidHelper.generate(),
                role: 'patient',
                title: 'Hasil Pemeriksaan & Rekam Medis Terbit',
                message:
                    'Pemeriksaan oleh ${newRecord.doctor} telah selesai. Diagnosa: $diagSummary. Rekam medis dan e-resep telah diterbitkan.',
                type: 'clinical',
                targetId: newRecord.id,
                isRead: false,
                createdAt: DateTime.now(),
              ),
            );
        ref.read(notificationsProvider.notifier).refresh();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pemeriksaan untuk ${widget.appointment.patientName} berhasil disimpan ke rekam medis & e-prescription diterbitkan!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Gagal menyimpan rekam medis. Periksa koneksi backend.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddDiagnosisDialog() {
    String searchQuery = '';
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filtered = _icd10Catalog.where((item) {
              final q = searchQuery.toLowerCase();
              return (item['code'] ?? '').toLowerCase().contains(q) ||
                  (item['name'] ?? '').toLowerCase().contains(q) ||
                  (item['category'] ?? '').toLowerCase().contains(q);
            }).toList();

            return AlertDialog(
              title: const Text(
                'Pilih Diagnosis ICD-10',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              content: SizedBox(
                width: 500,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Cari kode ICD-10 atau nama penyakit...',
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) {
                        setDialogState(() => searchQuery = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Text('Tidak ada kode ICD-10 yang cocok.'),
                            )
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (c, i) {
                                final item = filtered[i];
                                final code = item['code'] ?? '';
                                final name = item['name'] ?? '';
                                return ListTile(
                                  dense: true,
                                  leading: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      code,
                                      style: const TextStyle(
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    item['category'] ?? '',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _selectedDiagnoses.add({
                                        'code': code,
                                        'name': name,
                                        'type': _selectedDiagnoses.isEmpty
                                            ? 'primary'
                                            : 'secondary',
                                      });
                                    });
                                    Navigator.of(ctx).pop();
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Batal'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddMedicineDialog() {
    String selectedMed = _formularyCatalog.isNotEmpty
        ? (_formularyCatalog[0]['name'] as String)
        : 'Paracetamol 500mg';
    final doseCtrl = TextEditingController(text: '500 mg');
    final freqCtrl = TextEditingController(text: '3x sehari sesudah makan');
    final durationCtrl = TextEditingController(text: '3');
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Tambah Obat E-Prescription',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: selectedMed,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Nama Obat Formularium *',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            (_formularyCatalog.isNotEmpty
                                    ? _formularyCatalog
                                    : [
                                        {
                                          'name': 'Paracetamol 500mg',
                                          'defaultDose': '500 mg',
                                          'defaultFrequency': '3x sehari',
                                        },
                                        {
                                          'name': 'Amlodipine Besylate 5mg',
                                          'defaultDose': '5 mg',
                                          'defaultFrequency': '1x sehari pagi',
                                        },
                                        {
                                          'name': 'Amoxicillin 500mg',
                                          'defaultDose': '500 mg',
                                          'defaultFrequency':
                                              '3x sehari (habiskan)',
                                        },
                                      ])
                                .map(
                                  (f) => DropdownMenuItem(
                                    value: f['name'] as String,
                                    child: Text(
                                      f['name'] as String,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedMed = val;
                              final match = _formularyCatalog.firstWhere(
                                (item) => item['name'] == val,
                                orElse: () => {},
                              );
                              if (match.isNotEmpty) {
                                doseCtrl.text =
                                    match['defaultDose']?.toString() ??
                                    '1 tablet';
                                freqCtrl.text =
                                    match['defaultFrequency']?.toString() ??
                                    '1x sehari';
                              }
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: doseCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Dosis *',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: durationCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Durasi (Hari) *',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: freqCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Frekuensi & Aturan Minum *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: noteCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Instruksi Khusus (Opsional)',
                          hintText: 'Contoh: Minum sebelum makan / prn demam',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _prescriptions.add(
                        PrescriptionInputItem(
                          medicineName: selectedMed,
                          dosage: doseCtrl.text.trim(),
                          frequency: freqCtrl.text.trim(),
                          durationDays: int.tryParse(durationCtrl.text) ?? 3,
                          instruction: noteCtrl.text.trim(),
                        ),
                      );
                    });
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Tambahkan ke Resep'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final patientName = widget.appointment.patientName;
    final mrn = widget.patient?.medicalRecordNumber ?? 'MRN-2026-001';
    final insurance =
        widget.patient?.insuranceProvider ?? 'BPJS Kesehatan Mandiri';

    return Scaffold(
      appBar: AppBar(
        title: Text('Ruang Konsultasi • ${widget.appointment.queueNumber}'),
        backgroundColor: AppTheme.navy,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Riwayat Kunjungan Pasien',
            icon: const Icon(Icons.history_edu_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Membuka rekam medis kunjungan terdahulu...'),
                ),
              );
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Patient Header Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                    child: Text(
                      patientName.isNotEmpty ? patientName[0] : 'P',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              patientName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                mrn,
                                style: TextStyle(
                                  color: Colors.blue.shade800,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Keluhan Booking: "${widget.appointment.reason}"',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.verified_user_outlined,
                              size: 14,
                              color: Colors.teal,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              insurance,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.teal,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Icon(
                              Icons.warning_amber_rounded,
                              size: 14,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Alergi: Penicillin (Ringan)',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // SECTION 1: TANDA-TANDA VITAL & BMI
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.monitor_heart_outlined,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Tanda-Tanda Vital & Indeks Massa Tubuh (BMI)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _bmiColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _bmiColor.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            'BMI ${_bmi.toStringAsFixed(1)} • $_bmiCategory',
                            style: TextStyle(
                              color: _bmiColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _systolicController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'TD Sistolik',
                              suffixText: 'mmHg',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _diastolicController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'TD Diastolik',
                              suffixText: 'mmHg',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _heartRateController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Denyut Nadi',
                              suffixText: 'bpm',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _temperatureController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Suhu Tubuh',
                              suffixText: '°C',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _spo2Controller,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Saturasi SpO2',
                              suffixText: '%',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _heightController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Tinggi Badan',
                              suffixText: 'cm',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => _calculateBmi(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _weightController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Berat Badan',
                              suffixText: 'kg',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => _calculateBmi(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // SECTION 2: SOAP ANAMNESIS & PEMERIKSAAN
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.notes, color: AppTheme.primary),
                        SizedBox(width: 8),
                        Text(
                          'Catatan Klinis Terstruktur (SOAP)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    TextFormField(
                      controller: _subjectiveController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText:
                            'S (Subjective) - Anamnesis & Riwayat Penyakit *',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Anamnesis wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _objectiveController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText:
                            'O (Objective) - Pemeriksaan Fisik Lengkap *',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Pemeriksaan fisik wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _planController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText:
                            'P (Plan) - Rencana Terapi & Edukasi Pasien *',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // SECTION 3: ICD-10 DIAGNOSES
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.healing_outlined, color: Colors.teal),
                            SizedBox(width: 8),
                            Text(
                              'A (Assessment) - Diagnosis ICD-10 Resmi',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: _showAddDiagnosisDialog,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Tambah Diagnosis'),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    if (_selectedDiagnoses.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Belum ada diagnosis ICD-10 yang dipilih. Klik tombol di atas untuk mencari kode ICD-10.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      ..._selectedDiagnoses.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final d = entry.value;
                        final isPrimary = d['type'] == 'primary';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isPrimary
                                ? Colors.teal.shade50
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isPrimary
                                  ? Colors.teal.shade200
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isPrimary
                                      ? Colors.teal
                                      : Colors.grey.shade700,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  d['code'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      d['name'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      isPrimary
                                          ? 'Diagnosis Utama (Primary)'
                                          : 'Diagnosis Sekunder',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isPrimary
                                            ? Colors.teal.shade900
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  setState(
                                    () => _selectedDiagnoses.removeAt(idx),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // SECTION 4: E-PRESCRIPTION
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.medication_liquid_outlined,
                              color: Colors.indigo,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Resep Obat Elektronik (E-Prescription)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: _showAddMedicineDialog,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Tambah Obat'),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    if (_prescriptions.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Tidak ada resep obat (hanya tindakan/konseling non-farmakologis).',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      ..._prescriptions.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final p = entry.value;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.indigo.shade100),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.indigo,
                                child: Text(
                                  '${idx + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${p.medicineName} (${p.dosage})',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Aturan: ${p.frequency} • Durasi: ${p.durationDays} hari',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.indigo.shade900,
                                      ),
                                    ),
                                    if (p.instruction.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Catatan: ${p.instruction}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  setState(() => _prescriptions.removeAt(idx));
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // SECTION 5: TINDAKAN MEDIS & TARIF KLINIK
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.medical_services_outlined,
                              color: Colors.teal,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Tindakan Medis & Layanan Klinik',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: _showAddProcedureDialog,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Pilih Tindakan'),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    if (_selectedProcedures.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          'Belum ada tindakan medis tambahan yang dipilih untuk pasien ini.',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      )
                    else
                      ..._selectedProcedures.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final proc = entry.value;
                        final currency = NumberFormat.currency(
                          locale: 'id_ID',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        );

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.teal.shade200),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.teal,
                                child: Text(
                                  '${idx + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      proc.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      '${proc.category} • ${currency.format(proc.price)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.teal.shade900,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  setState(
                                    () => _selectedProcedures.removeAt(idx),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // SECTION 5.5: PEMERIKSAAN LABORATORIUM & DIAGNOSTIK (LIS)
            Consumer(
              builder: (context, ref, _) {
                final allLabOrders = ref.watch(labOrdersProvider);
                final patients = ref.watch(adminPatientsProvider);
                final doctors = ref.watch(adminDoctorsProvider);

                final patientObj =
                    widget.patient ??
                    patients
                        .where((p) => p.name == widget.appointment.patientName)
                        .firstOrNull;
                final doctorObj = doctors
                    .where((d) => d.name == widget.appointment.doctorName)
                    .firstOrNull;

                final patientLabOrders = allLabOrders
                    .where(
                      (o) =>
                          o.appointmentId == widget.appointment.id ||
                          (patientObj != null && o.patientId == patientObj.id),
                    )
                    .toList();

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: const [
                                Icon(
                                  Icons.biotech_outlined,
                                  color: Colors.purple,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Pemeriksaan Laboratorium & Diagnostik',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            FilledButton.tonalIcon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => LabOrderCreateDialog(
                                    appointmentId: widget.appointment.id,
                                    preselectedPatient: patientObj,
                                    preselectedDoctor: doctorObj,
                                    initialDiagnosis:
                                        _selectedDiagnoses.isNotEmpty
                                        ? _selectedDiagnoses
                                              .map((d) => d['name'])
                                              .join(', ')
                                        : 'Pemeriksaan Poli ${widget.appointment.department}',
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Order Lab Baru'),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        if (patientLabOrders.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              'Belum ada permintaan pemeriksaan lab untuk kunjungan ini.',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          )
                        else
                          ...patientLabOrders.map((order) {
                            final isCompleted = order.status == 'completed';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.purple.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Colors.purple.shade700,
                                    child: const Icon(
                                      Icons.science,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${order.orderNumber} • ${order.items.length} Parameter Uji (${order.priority})',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          'Status: ${isCompleted ? "HASIL SELESAI & VALID" : "DALAM PROSES LAB"} • Item: ${order.items.map((i) => i.testName).join(", ")}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isCompleted
                                                ? Colors.green.shade900
                                                : Colors.purple.shade900,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isCompleted)
                                    IconButton(
                                      tooltip: 'Lihat & Cetak Hasil Lab',
                                      icon: const Icon(
                                        Icons.print_outlined,
                                        color: Colors.teal,
                                      ),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => LabResultPrintDialog(
                                            order: order,
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // SECTION 6: SURAT KETERANGAN DOKTER (SKD / SURAT SEHAT)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.description_outlined,
                          color: Colors.deepOrange,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Surat Keterangan Dokter (SKD / Surat Izin Sakit)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Switch(
                          value: _issueSickLeaveCert,
                          activeThumbColor: Colors.deepOrange,
                          onChanged: (val) =>
                              setState(() => _issueSickLeaveCert = val),
                        ),
                      ],
                    ),
                    if (_issueSickLeaveCert) ...[
                      const Divider(height: 20),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.deepOrange.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Durasi Istirahat Tirah Baring:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SegmentedButton<int>(
                                  segments: const [
                                    ButtonSegment(
                                      value: 1,
                                      label: Text('1 Hari'),
                                    ),
                                    ButtonSegment(
                                      value: 2,
                                      label: Text('2 Hari'),
                                    ),
                                    ButtonSegment(
                                      value: 3,
                                      label: Text('3 Hari'),
                                    ),
                                    ButtonSegment(
                                      value: 5,
                                      label: Text('5 Hari'),
                                    ),
                                  ],
                                  selected: {_sickLeaveDays},
                                  onSelectionChanged: (set) => setState(
                                    () => _sickLeaveDays = set.first,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _sickLeaveNotesCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Anjuran / Catatan Istirahat Medis',
                                isDense: true,
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _showPreviewCertificateDialog,
                              icon: const Icon(
                                Icons.visibility_outlined,
                                size: 16,
                              ),
                              label: const Text(
                                'Pratinjau Surat Izin Sakit (SKD)',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.deepOrange.shade800,
                                side: BorderSide(
                                  color: Colors.deepOrange.shade300,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Batal / Kembali'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isSubmitting ? null : _submitEncounter,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(
                      _isSubmitting
                          ? 'Menyimpan Rekam Medis...'
                          : 'Selesaikan Pemeriksaan & Terbitkan Resep',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
