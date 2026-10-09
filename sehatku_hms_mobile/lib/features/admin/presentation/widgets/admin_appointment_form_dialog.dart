import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/document_template_helper.dart';
import '../../../../core/utils/print_helper.dart';
import '../../../../core/utils/uuid_helper.dart';
import '../../../../shared/models/health_models.dart';
import '../../../notification/application/notifications_provider.dart';
import '../../application/admin_state_providers.dart';

class AdminAppointmentFormDialog extends ConsumerStatefulWidget {
  const AdminAppointmentFormDialog({super.key});

  @override
  ConsumerState<AdminAppointmentFormDialog> createState() =>
      _AdminAppointmentFormDialogState();
}

class _AdminAppointmentFormDialogState
    extends ConsumerState<AdminAppointmentFormDialog> {
  final _formKey = GlobalKey<FormState>();

  // Mode: 0 = Pilih Pasien Terdaftar, 1 = Pasien Baru (Walk-in Loket)
  int _patientMode = 0;

  // Existing Patient
  Patient? _selectedPatient;

  // New Patient fields
  final _newNameCtrl = TextEditingController();
  final _newNikCtrl = TextEditingController();
  final _newPhoneCtrl = TextEditingController();
  String _newGender = 'Laki-laki';
  String _newInsurance = 'Umum / Pribadi';
  final DateTime _newBirthDate = DateTime(1995, 5, 20);

  // Department & Doctor
  String? _selectedDept;
  Doctor? _selectedDoctor;

  // Date & Time
  DateTime _appointmentDate = DateTime.now();
  String _selectedTime = '09:00';

  // Reason & Status
  final _reasonCtrl = TextEditingController(
    text: 'Konsultasi dan Pemeriksaan Rutin',
  );
  String _initialStatus =
      'Checked-in'; // 'Checked-in' (Walk-in di loket) or 'Terkonfirmasi' (Booking)

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final depts = ref.read(adminDepartmentsProvider);
    if (depts.isNotEmpty) {
      _selectedDept = depts.first.name;
    }
    final doctors = ref.read(adminDoctorsProvider);
    if (doctors.isNotEmpty) {
      _selectedDoctor = doctors.first;
    }
    final patients = ref.read(adminPatientsProvider);
    if (patients.isNotEmpty) {
      _selectedPatient = patients.first;
    }
  }

  @override
  void dispose() {
    _newNameCtrl.dispose();
    _newNikCtrl.dispose();
    _newPhoneCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  String _calculateNextQueueNumber(String deptName) {
    final appointments = ref.read(adminAppointmentsProvider);
    String prefix = 'A';
    final deptLower = deptName.toLowerCase();
    if (deptLower.contains('kardiologi') || deptLower.contains('jantung')) {
      prefix = 'D';
    } else if (deptLower.contains('gigi')) {
      prefix = 'G';
    } else if (deptLower.contains('anak')) {
      prefix = 'P';
    } else if (deptLower.contains('dalam')) {
      prefix = 'I';
    } else if (deptLower.contains('umum')) {
      prefix = 'A';
    }

    final samePrefixAppts = appointments
        .where((a) => a.queueNumber.startsWith('$prefix-'))
        .toList();
    final nextSeq = samePrefixAppts.length + 1;
    return '$prefix-${nextSeq.toString().padLeft(3, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final patients = ref.watch(adminPatientsProvider);
    final depts = ref.watch(adminDepartmentsProvider);
    final allDoctors = ref.watch(adminDoctorsProvider);
    final slotConfig = ref.watch(appointmentSlotConfigProvider);
    final timeSlots = slotConfig.timeSlots;
    final quickReasons = slotConfig.quickReasons;

    final filteredDoctors = _selectedDept == null
        ? allDoctors
        : allDoctors.where((d) {
            final dept = _selectedDept!
                .toLowerCase()
                .replaceAll('poli', '')
                .trim();
            final spec = d.specialist.toLowerCase();
            return spec.contains(dept) ||
                d.hospital.toLowerCase().contains(dept);
          }).toList();

    final availableDoctors = filteredDoctors.isNotEmpty
        ? filteredDoctors
        : allDoctors;

    final dateLabel = DateFormat('dd MMM yyyy').format(_appointmentDate);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 720,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1,
                        color: Colors.blue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pendaftaran Reservasi Pasien (Loket Admin)',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Daftarkan pasien walk-in atau booking reservasi via telepon / loket resepsionis.',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Patient Type Selector Tab
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(
                      value: 0,
                      icon: Icon(Icons.people_outline),
                      label: Text('Pasien Lama / Terdaftar'),
                    ),
                    ButtonSegment(
                      value: 1,
                      icon: Icon(Icons.person_add_outlined),
                      label: Text('Pasien Baru (Walk-in Cepat)'),
                    ),
                  ],
                  selected: {_patientMode},
                  onSelectionChanged: (val) {
                    setState(() => _patientMode = val.first);
                  },
                ),
                const SizedBox(height: 16),

                // Patient Details Section
                if (_patientMode == 0) ...[
                  // Existing Patient Dropdown
                  DropdownButtonFormField<Patient>(
                    initialValue: _selectedPatient,
                    decoration: const InputDecoration(
                      labelText: 'Pilih Pasien Terdaftar',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      helperText:
                          'Cari berdasarkan nama pasien atau nomor rekam medis',
                    ),
                    isExpanded: true,
                    items: patients.map((p) {
                      return DropdownMenuItem(
                        value: p,
                        child: Text(
                          '${p.name} • ${p.medicalRecordNumber} (${p.insuranceProvider ?? "Umum"})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (p) => setState(() => _selectedPatient = p),
                    validator: (v) =>
                        v == null ? 'Pilih pasien terlebih dahulu' : null,
                  ),
                ] else ...[
                  // Quick New Patient Form
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DATA PASIEN BARU',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _newNameCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Nama Lengkap Pasien',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Nama pasien wajib diisi'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _newNikCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'NIK KTP (16 Digit)',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _newPhoneCtrl,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Nomor WhatsApp / HP',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _newGender,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Jenis Kelamin',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Laki-laki',
                                    child: Text('Laki-laki', overflow: TextOverflow.ellipsis),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Perempuan',
                                    child: Text('Perempuan', overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                                onChanged: (v) => setState(
                                  () => _newGender = v ?? 'Laki-laki',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: _newInsurance,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Penjamin Pasien',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Umum / Pribadi',
                              child: Text('Umum / Pribadi', overflow: TextOverflow.ellipsis),
                            ),
                            DropdownMenuItem(
                              value: 'BPJS Kesehatan',
                              child: Text('BPJS Kesehatan', overflow: TextOverflow.ellipsis),
                            ),
                            DropdownMenuItem(
                              value: 'Prudential Health',
                              child: Text('Prudential Health', overflow: TextOverflow.ellipsis),
                            ),
                            DropdownMenuItem(
                              value: 'Allianz Care',
                              child: Text('Allianz Care', overflow: TextOverflow.ellipsis),
                            ),
                            DropdownMenuItem(
                              value: 'Mandiri Inhealth',
                              child: Text('Mandiri Inhealth', overflow: TextOverflow.ellipsis),
                            ),
                          ],
                          onChanged: (v) => setState(
                            () => _newInsurance = v ?? 'Umum / Pribadi',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Department & Doctor Selection
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedDept,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Poli Layanan Medis',
                          prefixIcon: Icon(Icons.apartment_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: depts.map((d) {
                          return DropdownMenuItem(
                            value: d.name,
                            child: Text(d.name, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedDept = val;
                            if (availableDoctors.isNotEmpty) {
                              _selectedDoctor = availableDoctors.first;
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<Doctor>(
                        initialValue: availableDoctors.contains(_selectedDoctor)
                            ? _selectedDoctor
                            : (availableDoctors.isNotEmpty
                                  ? availableDoctors.first
                                  : null),
                        decoration: const InputDecoration(
                          labelText: 'Dokter Pemeriksa',
                          prefixIcon: Icon(Icons.medical_services_outlined),
                          border: OutlineInputBorder(),
                        ),
                        isExpanded: true,
                        items: availableDoctors.map((doc) {
                          return DropdownMenuItem(
                            value: doc,
                            child: Text(
                              '${doc.name} (${doc.specialist})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (d) => setState(() => _selectedDoctor = d),
                        validator: (v) =>
                            v == null ? 'Pilih dokter pemeriksa' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Date & Time
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final now = DateTime.now();
                          final today = DateTime(now.year, now.month, now.day);
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _appointmentDate.isBefore(today)
                                ? today
                                : _appointmentDate,
                            firstDate: today,
                            lastDate: today.add(
                              const Duration(days: 30),
                            ),
                          );
                          if (picked != null) {
                            setState(() => _appointmentDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Tanggal Kunjungan',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            dateLabel,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedTime,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Jam Praktek / Sesi',
                          prefixIcon: Icon(Icons.access_time),
                          border: OutlineInputBorder(),
                        ),
                        items: timeSlots.map((slot) {
                          return DropdownMenuItem(
                            value: slot,
                            child: Text('$slot WIB', overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => _selectedTime = val ?? '09:00'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Reason / Keluhan
                TextFormField(
                  controller: _reasonCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Keluhan Utama / Alasan Kunjungan',
                    prefixIcon: Icon(Icons.notes),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.isEmpty
                      ? 'Alasan kunjungan wajib diisi'
                      : null,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: quickReasons.map((r) {
                    return ActionChip(
                      label: Text(r, style: const TextStyle(fontSize: 11)),
                      onPressed: () => setState(() => _reasonCtrl.text = r),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Initial Status
                DropdownButtonFormField<String>(
                  initialValue: _initialStatus,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Status Awal Pendaftaran',
                    prefixIcon: Icon(Icons.how_to_reg_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Checked-in',
                      child: Text(
                        'Checked-in (Pasien Sudah Hadir di Loket / Ruang Tunggu)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Menunggu',
                      child: Text(
                        'Menunggu (Antrean Terbit, Menunggu Panggilan Dokter)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Terkonfirmasi',
                      child: Text(
                        'Terkonfirmasi (Booking / Reservasi Mendatang)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  onChanged: (val) =>
                      setState(() => _initialStatus = val ?? 'Checked-in'),
                ),
                const SizedBox(height: 24),

                // Submit Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      onPressed: _isLoading
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) return;
                              setState(() => _isLoading = true);

                              String patientId;
                              String patientName;

                              if (_patientMode == 0) {
                                patientId = _selectedPatient!.id;
                                patientName = _selectedPatient!.name;
                              } else {
                                // Create new patient
                                final randomMrn =
                                    'RM-${(1000 + (DateTime.now().millisecondsSinceEpoch % 8999))}';
                                final newPatient = Patient(
                                  id: UuidHelper.generate(),
                                  medicalRecordNumber: randomMrn,
                                  name: _newNameCtrl.text.trim(),
                                  birthDate: _newBirthDate,
                                  gender: _newGender,
                                  status: 'Aktif',
                                  insuranceProvider: _newInsurance,
                                  nik: _newNikCtrl.text.trim(),
                                  phone: _newPhoneCtrl.text.trim(),
                                );
                                ref
                                    .read(adminPatientsProvider.notifier)
                                    .registerPatient(newPatient);
                                patientId = newPatient.id;
                                patientName = newPatient.name;
                              }

                              final deptName = _selectedDept ?? 'Poli Umum';
                              final queueNumber = _calculateNextQueueNumber(
                                deptName,
                              );
                              final doctor =
                                  _selectedDoctor ?? availableDoctors.first;

                              final newAppt = Appointment(
                                id: UuidHelper.generate(),
                                doctorName: doctor.name,
                                patientName: patientName,
                                dateLabel: dateLabel,
                                time: _selectedTime,
                                status: _initialStatus,
                                queueNumber: queueNumber,
                                department: deptName,
                                reason: _reasonCtrl.text.trim(),
                                appointmentDate: _appointmentDate,
                                doctorPhotoUrl: doctor.photoUrl,
                              );

                              ref
                                  .read(adminAppointmentsProvider.notifier)
                                  .addAppointment(
                                    newAppt,
                                    patientId: patientId,
                                    doctorId: doctor.id,
                                  );

                              ref
                                  .read(notificationsProvider.notifier)
                                  .refresh();

                              if (mounted) {
                                setState(() => _isLoading = false);
                                Navigator.of(context).pop();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Pendaftaran berhasil: $patientName ($queueNumber) ke ${doctor.name} - $deptName.',
                                    ),
                                    backgroundColor: Colors.teal,
                                    action: SnackBarAction(
                                      label: 'Cetak Karcis',
                                      textColor: Colors.white,
                                      onPressed: () {
                                        final html = DocumentTemplateHelper.generateQueueTicketHtml(
                                          queueNumber: queueNumber,
                                          patientName: patientName,
                                          patientMrn: _patientMode == 0
                                              ? (_selectedPatient?.medicalRecordNumber ?? '')
                                              : '',
                                          doctorName: doctor.name,
                                          department: deptName,
                                          dateLabel: dateLabel,
                                          time: _selectedTime,
                                          insurance: _patientMode == 0
                                              ? (_selectedPatient?.insuranceProvider ?? 'Umum / Mandiri')
                                              : _newInsurance,
                                          status: 'Menunggu',
                                        );
                                        printHtmlDocument(
                                          title: 'Karcis Antrean $queueNumber - $patientName',
                                          htmlContent: html,
                                        );
                                      },
                                    ),
                                  ),
                                );
                              }
                            },
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: const Text('Daftarkan Reservasi & Antrean'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
