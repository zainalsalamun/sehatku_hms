import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/uuid_helper.dart';
import '../../../../shared/models/health_models.dart';
import '../../../notification/application/notifications_provider.dart';
import '../../application/admin_state_providers.dart';

class AdminCreateAppointmentScreen extends ConsumerStatefulWidget {
  const AdminCreateAppointmentScreen({super.key});

  @override
  ConsumerState<AdminCreateAppointmentScreen> createState() =>
      _AdminCreateAppointmentScreenState();
}

class _AdminCreateAppointmentScreenState
    extends ConsumerState<AdminCreateAppointmentScreen> {
  // Mode: 0 = Pasien Terdaftar, 1 = Pasien Baru
  int _patientTab = 0;

  // Search & Filter Patients
  String _patientSearch = '';
  String _patientInsuranceFilter = 'all';
  Patient? _selectedPatient;

  // New Patient Form
  final _newNameCtrl = TextEditingController();
  final _newNikCtrl = TextEditingController();
  final _newPhoneCtrl = TextEditingController();
  final _newAddressCtrl = TextEditingController();
  String _newGender = 'Laki-laki';
  String _newInsurance = 'Umum / Pribadi';
  final DateTime _newBirthDate = DateTime(1995, 5, 20);

  // Department & Doctor Search & Selection
  String _selectedDeptFilter = 'all';
  String _doctorSearch = '';
  Doctor? _selectedDoctor;

  // Schedule & Time
  DateTime _selectedDate = DateTime.now();
  String _selectedTime = '09:00';

  // Reason & Status
  final _reasonCtrl = TextEditingController(
    text: 'Konsultasi dan Pemeriksaan Rutin',
  );
  String _initialStatus =
      'Checked-in'; // 'Checked-in', 'Menunggu', 'Terkonfirmasi'

  bool _isSubmitting = false;

  final List<String> _timeSlots = [
    '08:00',
    '08:30',
    '09:00',
    '09:30',
    '10:00',
    '10:30',
    '11:00',
    '11:30',
    '13:00',
    '13:30',
    '14:00',
    '14:30',
    '15:00',
    '15:30',
    '16:00',
    '16:30',
    '18:30',
    '19:00',
    '19:30',
    '20:00',
  ];

  final List<String> _quickReasons = [
    'Konsultasi Rutin',
    'Demam & Flu',
    'Nyeri Dada & Sesak',
    'Pemeriksaan Gigi',
    'Kontrol Pasca Rawat',
    'Pusing / Sakit Kepala',
    'Medical Checkup',
  ];

  @override
  void initState() {
    super.initState();
    final patients = ref.read(adminPatientsProvider);
    if (patients.isNotEmpty) {
      _selectedPatient = patients.first;
    }
    final doctors = ref.read(adminDoctorsProvider);
    if (doctors.isNotEmpty) {
      _selectedDoctor = doctors.first;
    }
  }

  @override
  void dispose() {
    _newNameCtrl.dispose();
    _newNikCtrl.dispose();
    _newPhoneCtrl.dispose();
    _newAddressCtrl.dispose();
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
    final departments = ref.watch(adminDepartmentsProvider);
    final allDoctors = ref.watch(adminDoctorsProvider);

    // Filter Patients
    final filteredPatients = patients.where((p) {
      final q = _patientSearch.toLowerCase();
      final matchQ =
          q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.medicalRecordNumber.toLowerCase().contains(q) ||
          p.nik.toLowerCase().contains(q) ||
          p.phone.toLowerCase().contains(q);
      final matchIns =
          _patientInsuranceFilter == 'all' ||
          (p.insuranceProvider ?? 'Umum').toLowerCase().contains(
            _patientInsuranceFilter.toLowerCase(),
          );
      return matchQ && matchIns;
    }).toList();

    // Filter Doctors
    final filteredDoctors = allDoctors.where((d) {
      final q = _doctorSearch.toLowerCase();
      final matchQ =
          q.isEmpty ||
          d.name.toLowerCase().contains(q) ||
          d.specialist.toLowerCase().contains(q);
      final matchDept =
          _selectedDeptFilter == 'all' ||
          d.specialist.toLowerCase().contains(
            _selectedDeptFilter.toLowerCase(),
          ) ||
          d.hospital.toLowerCase().contains(_selectedDeptFilter.toLowerCase());
      return matchQ && matchDept;
    }).toList();

    final isWide = MediaQuery.sizeOf(context).width >= 1000;
    final dateLabel = DateFormat('dd MMM yyyy').format(_selectedDate);
    final deptName =
        _selectedDoctor?.specialist ??
        (_selectedDeptFilter != 'all' ? _selectedDeptFilter : 'Poli Umum');
    final estimatedQueueNumber = _calculateNextQueueNumber(deptName);

    final patientDisplayName = _patientTab == 0
        ? (_selectedPatient?.name ?? 'Pilih Pasien Terlebih Dahulu')
        : (_newNameCtrl.text.isNotEmpty
              ? _newNameCtrl.text
              : 'Pasien Baru (Walk-in)');
    final patientMrn = _patientTab == 0
        ? (_selectedPatient?.medicalRecordNumber ?? '-')
        : 'RM-BARU (Auto)';
    final patientInsurance = _patientTab == 0
        ? (_selectedPatient?.insuranceProvider ?? 'Umum / Pribadi')
        : _newInsurance;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Pendaftaran Reservasi & Pasien Walk-in',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Loket Admisi & Pendaftaran Pasien Klinik',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Tutup & Kembali ke Daftar Reservasi',
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Side: Step 1 & Step 2 (Patient & Doctor)
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildPatientSelectionCard(patients, filteredPatients),
                        const SizedBox(height: 20),
                        _buildDoctorSelectionCard(departments, filteredDoctors),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),

                  // Right Side: Step 3 (Schedule, Reason, & Ticket Preview)
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildScheduleAndReasonCard(dateLabel),
                        const SizedBox(height: 20),
                        _buildQueueTicketSummary(
                          queueNumber: estimatedQueueNumber,
                          patientName: patientDisplayName,
                          patientMrn: patientMrn,
                          insurance: patientInsurance,
                          doctorName: _selectedDoctor?.name ?? 'Pilih Dokter',
                          department: deptName,
                          dateLabel: dateLabel,
                          time: _selectedTime,
                          status: _initialStatus,
                        ),
                        const SizedBox(height: 20),
                        _buildSubmitButtons(
                          patientName: patientDisplayName,
                          queueNumber: estimatedQueueNumber,
                          deptName: deptName,
                          dateLabel: dateLabel,
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPatientSelectionCard(patients, filteredPatients),
                  const SizedBox(height: 20),
                  _buildDoctorSelectionCard(departments, filteredDoctors),
                  const SizedBox(height: 20),
                  _buildScheduleAndReasonCard(dateLabel),
                  const SizedBox(height: 20),
                  _buildQueueTicketSummary(
                    queueNumber: estimatedQueueNumber,
                    patientName: patientDisplayName,
                    patientMrn: patientMrn,
                    insurance: patientInsurance,
                    doctorName: _selectedDoctor?.name ?? 'Pilih Dokter',
                    department: deptName,
                    dateLabel: dateLabel,
                    time: _selectedTime,
                    status: _initialStatus,
                  ),
                  const SizedBox(height: 20),
                  _buildSubmitButtons(
                    patientName: patientDisplayName,
                    queueNumber: estimatedQueueNumber,
                    deptName: deptName,
                    dateLabel: dateLabel,
                  ),
                ],
              ),
      ),
    );
  }

  // ===================== WIDGET: STEP 1 - PATIENT SELECTION =====================

  Widget _buildPatientSelectionCard(
    List<Patient> allPatients,
    List<Patient> filteredPatients,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue.shade50,
                  child: const Text(
                    '1',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Identitas Pasien',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Pasien Terdaftar')),
                    ButtonSegment(
                      value: 1,
                      label: Text('Pasien Baru (Walk-in)'),
                    ),
                  ],
                  selected: {_patientTab},
                  onSelectionChanged: (val) =>
                      setState(() => _patientTab = val.first),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_patientTab == 0) ...[
              // Search and Filter toolbar
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText:
                            'Ketik nama pasien, No. RM, NIK, atau No. HP...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (val) => setState(() => _patientSearch = val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: _patientInsuranceFilter,
                      isExpanded: true,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text('Semua Penjamin', overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: 'BPJS',
                          child: Text('BPJS Kesehatan', overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: 'Umum',
                          child: Text('Umum / Mandiri', overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: 'Asuransi',
                          child: Text('Asuransi Swasta', overflow: TextOverflow.ellipsis),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _patientInsuranceFilter = v ?? 'all'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Patient Cards Scroll Area
              Container(
                height: 230,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: filteredPatients.isEmpty
                    ? const Center(
                        child: Text(
                          'Tidak ada pasien yang sesuai kata kunci pencarian.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(10),
                        itemCount: filteredPatients.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, idx) {
                          final p = filteredPatients[idx];
                          final isSelected = _selectedPatient?.id == p.id;

                          return InkWell(
                            onTap: () => setState(() => _selectedPatient = p),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.teal.shade50
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.teal
                                      : Colors.grey.shade200,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: isSelected
                                        ? Colors.teal
                                        : Colors.grey.shade200,
                                    child: Icon(
                                      Icons.person,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey.shade700,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              p.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                p.medicalRecordNumber,
                                                style: TextStyle(
                                                  color: Colors.blue.shade800,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'NIK: ${p.nik.isNotEmpty ? p.nik : "-"} • ${p.gender} • Penjamin: ${p.insuranceProvider ?? "Umum"} • HP: ${p.phone.isNotEmpty ? p.phone : "-"}',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.teal,
                                      size: 22,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ] else ...[
              // New Patient Form Grid
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _newNameCtrl,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Nama Lengkap Pasien *',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _newNikCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'NIK KTP (16 Digit)',
                            prefixIcon: Icon(Icons.badge_outlined),
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
                          controller: _newPhoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Nomor WhatsApp / HP *',
                            prefixIcon: Icon(Icons.phone_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _newGender,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Jenis Kelamin',
                            prefixIcon: Icon(Icons.transgender_outlined),
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
                          onChanged: (v) =>
                              setState(() => _newGender = v ?? 'Laki-laki'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _newInsurance,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Penjamin Pasien',
                      prefixIcon: Icon(Icons.health_and_safety_outlined),
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
            ],
          ],
        ),
      ),
    );
  }

  // ===================== WIDGET: STEP 2 - DOCTOR & DEPT SELECTION =====================

  Widget _buildDoctorSelectionCard(
    List<Department> departments,
    List<Doctor> filteredDoctors,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.teal.shade50,
                  child: const Text(
                    '2',
                    style: TextStyle(
                      color: Colors.teal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Pilih Poli & Dokter Pemeriksa',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Horizontal Department Category Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Semua Poli'),
                    selected: _selectedDeptFilter == 'all',
                    onSelected: (sel) {
                      if (sel) setState(() => _selectedDeptFilter = 'all');
                    },
                  ),
                  const SizedBox(width: 8),
                  ...departments.map((dept) {
                    final isSel = _selectedDeptFilter == dept.name;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(dept.name),
                        selected: isSel,
                        onSelected: (sel) {
                          if (sel)
                            setState(() => _selectedDeptFilter = dept.name);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Doctor Search
            TextField(
              decoration: InputDecoration(
                hintText: 'Cari dokter berdasarkan nama atau spesialisasi...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (val) => setState(() => _doctorSearch = val),
            ),
            const SizedBox(height: 14),

            // Doctors Grid / List
            Container(
              height: 240,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: filteredDoctors.isEmpty
                  ? const Center(
                      child: Text(
                        'Tidak ada dokter pada poli yang dipilih.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(10),
                      itemCount: filteredDoctors.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final doc = filteredDoctors[idx];
                        final isSelected = _selectedDoctor?.id == doc.id;

                        return InkWell(
                          onTap: () => setState(() => _selectedDoctor = doc),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.teal.shade50
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.teal
                                    : Colors.grey.shade200,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.teal.shade100,
                                  child: const Icon(
                                    Icons.medical_services_outlined,
                                    color: Colors.teal,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        doc.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              '${doc.specialist} • ${doc.experience} Pengalaman',
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 11,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const Text(
                                            ' • ',
                                            style: TextStyle(fontSize: 11),
                                          ),
                                          const Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                            size: 12,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            '${doc.rating}',
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.green.shade200,
                                    ),
                                  ),
                                  child: const Text(
                                    'Praktek Hari Ini',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.teal,
                                    size: 22,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== WIDGET: STEP 3 - SCHEDULE & REASON =====================

  Widget _buildScheduleAndReasonCard(String dateLabel) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.purple.shade50,
                  child: const Text(
                    '3',
                    style: TextStyle(
                      color: Colors.purple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Jadwal & Keluhan Pasien',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Date Picker Card with quick buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 1),
                        ),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(
                      dateLabel,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Hari Ini'),
                  selected: DateUtils.isSameDay(_selectedDate, DateTime.now()),
                  onSelected: (_) =>
                      setState(() => _selectedDate = DateTime.now()),
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('Besok'),
                  selected: DateUtils.isSameDay(
                    _selectedDate,
                    DateTime.now().add(const Duration(days: 1)),
                  ),
                  onSelected: (_) => setState(
                    () => _selectedDate = DateTime.now().add(
                      const Duration(days: 1),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Time Slots Wrap
            const Text(
              'Pilih Jam Sesi / Slot Waktu:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _timeSlots.map((slot) {
                final isSel = _selectedTime == slot;
                return ChoiceChip(
                  label: Text('$slot WIB'),
                  selected: isSel,
                  onSelected: (sel) {
                    if (sel) setState(() => _selectedTime = slot);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Reason
            TextFormField(
              controller: _reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Keluhan Utama / Alasan Kunjungan *',
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: _quickReasons.map((r) {
                return ActionChip(
                  label: Text(r, style: const TextStyle(fontSize: 10)),
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
                labelText: 'Status Awal Reservasi',
                prefixIcon: Icon(Icons.how_to_reg_outlined),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Checked-in',
                  child: Text(
                    'Checked-in (Pasien Hadir Langsung di Loket)',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DropdownMenuItem(
                  value: 'Menunggu',
                  child: Text(
                    'Menunggu (Antrean Terbit, Menunggu Dokter)',
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
          ],
        ),
      ),
    );
  }

  // ===================== WIDGET: LIVE QUEUE TICKET SUMMARY =====================

  Widget _buildQueueTicketSummary({
    required String queueNumber,
    required String patientName,
    required String patientMrn,
    required String insurance,
    required String doctorName,
    required String department,
    required String dateLabel,
    required String time,
    required String status,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'KARCIS NOMOR ANTREAN',
                style: TextStyle(
                  color: Colors.tealAccent,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  fontSize: 11,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.tealAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.tealAccent),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.tealAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Big Queue Badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                queueNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          _ticketRow('Pasien', '$patientName ($patientMrn)'),
          _ticketRow('Penjamin', insurance),
          _ticketRow('Poli Tujuan', department),
          _ticketRow('Dokter', doctorName),
          _ticketRow('Jadwal Sesi', '$dateLabel • $time WIB'),
        ],
      ),
    );
  }

  Widget _ticketRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ),
          const Text(
            ': ',
            style: TextStyle(color: Colors.white60, fontSize: 11),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===================== ACTION BUTTONS =====================

  Widget _buildSubmitButtons({
    required String patientName,
    required String queueNumber,
    required String deptName,
    required String dateLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.teal.shade700,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _isSubmitting
              ? null
              : () => _submitAppointment(
                  patientName,
                  queueNumber,
                  deptName,
                  dateLabel,
                ),
          icon: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check_circle),
          label: Text(
            _isSubmitting
                ? 'Memproses Pendaftaran...'
                : 'Daftarkan Reservasi & Terbitkan Antrean',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Batal & Kembali'),
        ),
      ],
    );
  }

  Future<void> _submitAppointment(
    String patientName,
    String queueNumber,
    String deptName,
    String dateLabel,
  ) async {
    if (_patientTab == 0 && _selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih pasien terlebih dahulu.')),
      );
      return;
    }
    if (_patientTab == 1 && _newNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama pasien baru wajib diisi.')),
      );
      return;
    }
    if (_selectedDoctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih dokter pemeriksa terlebih dahulu.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    String patientId;
    String finalPatientName;

    if (_patientTab == 0) {
      patientId = _selectedPatient!.id;
      finalPatientName = _selectedPatient!.name;
    } else {
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
        address: _newAddressCtrl.text.trim(),
      );
      ref.read(adminPatientsProvider.notifier).registerPatient(newPatient);
      patientId = newPatient.id;
      finalPatientName = newPatient.name;
    }

    final doctor = _selectedDoctor!;
    final newAppt = Appointment(
      id: UuidHelper.generate(),
      doctorName: doctor.name,
      patientName: finalPatientName,
      dateLabel: dateLabel,
      time: _selectedTime,
      status: _initialStatus,
      queueNumber: queueNumber,
      department: deptName,
      reason: _reasonCtrl.text.trim(),
    );

    ref
        .read(adminAppointmentsProvider.notifier)
        .addAppointment(newAppt, patientId: patientId, doctorId: doctor.id);

    ref.read(notificationsProvider.notifier).refresh();

    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pendaftaran Berhasil: $finalPatientName ($queueNumber) ke ${doctor.name} • $deptName.',
          ),
          backgroundColor: Colors.teal,
          action: SnackBarAction(
            label: 'Cetak Karcis',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Mencetak karcis antrean $queueNumber ke printer thermal 58mm...',
                  ),
                  backgroundColor: Colors.teal,
                ),
              );
            },
          ),
        ),
      );
    }
  }
}
