import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/models/health_models.dart';
import '../../../admin/application/admin_state_providers.dart';
import '../../application/laboratory_state_providers.dart';

class LabOrderCreateDialog extends ConsumerStatefulWidget {
  const LabOrderCreateDialog({
    super.key,
    this.preselectedPatient,
    this.preselectedDoctor,
    this.appointmentId,
    this.admissionId,
    this.initialDiagnosis,
  });

  final Patient? preselectedPatient;
  final Doctor? preselectedDoctor;
  final String? appointmentId;
  final String? admissionId;
  final String? initialDiagnosis;

  @override
  ConsumerState<LabOrderCreateDialog> createState() =>
      _LabOrderCreateDialogState();
}

class _LabOrderCreateDialogState extends ConsumerState<LabOrderCreateDialog> {
  final _formKey = GlobalKey<FormState>();

  Patient? _selectedPatient;
  Doctor? _selectedDoctor;
  String _priority = 'Normal';
  late TextEditingController _diagnosisCtrl;
  final _notesCtrl = TextEditingController();
  final Set<LabTestCatalogModel> _selectedTests = {};
  String _categoryFilter = 'all';
  String _catalogSearch = '';
  bool _isLoading = false;

  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _selectedPatient = widget.preselectedPatient;
    if (_selectedPatient == null) {
      final patients = ref.read(adminPatientsProvider);
      if (patients.isNotEmpty) _selectedPatient = patients.first;
    }

    _selectedDoctor = widget.preselectedDoctor;
    if (_selectedDoctor == null) {
      final doctors = ref.read(adminDoctorsProvider);
      if (doctors.isNotEmpty) _selectedDoctor = doctors.first;
    }

    _diagnosisCtrl = TextEditingController(
      text: widget.initialDiagnosis ?? 'Pemeriksaan Diagnostik Penunjang',
    );
  }

  @override
  void dispose() {
    _diagnosisCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _totalPrice =>
      _selectedTests.fold(0.0, (sum, item) => sum + item.price);

  @override
  Widget build(BuildContext context) {
    final patients = ref.watch(adminPatientsProvider);
    final doctors = ref.watch(adminDoctorsProvider);
    final catalog = ref.watch(labCatalogProvider);

    final filteredCatalog = catalog.where((c) {
      final matchCat =
          _categoryFilter == 'all' ||
          c.category.toLowerCase() == _categoryFilter.toLowerCase();
      final matchSearch =
          _catalogSearch.isEmpty ||
          c.name.toLowerCase().contains(_catalogSearch.toLowerCase()) ||
          c.code.toLowerCase().contains(_catalogSearch.toLowerCase());
      return matchCat && matchSearch;
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 820,
        height: 720,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.science_outlined,
                      color: Colors.purple,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Permintaan Order Laboratorium & Diagnostik',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Pilih parameter tes hematologi, kimia darah, urinalisis, atau radiologi untuk dikirim ke Instalasi Laboratorium.',
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
              const Divider(height: 20),

              // Top Row: Patient & Doctor & Priority
              Row(
                children: [
                  // Patient
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<Patient>(
                      initialValue: _selectedPatient,
                      decoration: const InputDecoration(
                        labelText: 'Pasien *',
                        prefixIcon: Icon(Icons.person_search),
                        isDense: true,
                        border: OutlineInputBorder(),
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
                      onChanged: widget.preselectedPatient != null
                          ? null
                          : (p) => setState(() => _selectedPatient = p),
                      validator: (v) => v == null ? 'Pilih pasien' : null,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Doctor
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<Doctor>(
                      initialValue: _selectedDoctor,
                      decoration: const InputDecoration(
                        labelText: 'Dokter Pengirim (DPJP) *',
                        prefixIcon: Icon(Icons.medical_services_outlined),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      isExpanded: true,
                      items: doctors.map((d) {
                        return DropdownMenuItem(
                          value: d,
                          child: Text(
                            '${d.name} (${d.specialist})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: widget.preselectedDoctor != null
                          ? null
                          : (d) => setState(() => _selectedDoctor = d),
                      validator: (v) => v == null ? 'Pilih dokter' : null,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Priority
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: _priority,
                      decoration: const InputDecoration(
                        labelText: 'Prioritas *',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Normal',
                          child: Text('Normal (Rutin)'),
                        ),
                        DropdownMenuItem(
                          value: 'CITO',
                          child: Text('CITO (Darurat / Cepat)'),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _priority = v ?? 'Normal'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Clinical Diagnosis & Notes
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _diagnosisCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Diagnosa Klinis Pengantar *',
                        prefixIcon: Icon(Icons.notes),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Diagnosa pengantar wajib diisi'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Catatan Khusus untuk Analis Lab (Opsional)',
                        prefixIcon: Icon(Icons.edit_note),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Test Selection Area
              const Text(
                'PILIH PARAMETER PEMERIKSAAN LABORATORIUM',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 6),

              // Category Filter Chips & Search
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _filterChip('Semua Kategori', 'all'),
                          _filterChip('Hematologi', 'Hematologi'),
                          _filterChip('Kimia Klinik', 'Kimia Klinik'),
                          _filterChip('Urinalisis', 'Urinalisis'),
                          _filterChip(
                            'Imunologi & Serologi',
                            'Imunologi & Serologi',
                          ),
                          _filterChip('Radiologi', 'Radiologi'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 200,
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Cari tes...',
                        prefixIcon: Icon(Icons.search, size: 16),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) => setState(() => _catalogSearch = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Test Grid
              Expanded(
                child: filteredCatalog.isEmpty
                    ? const Center(
                        child: Text('Tidak ada parameter tes yang cocok.'),
                      )
                    : ListView.builder(
                        itemCount: filteredCatalog.length,
                        itemBuilder: (context, idx) {
                          final item = filteredCatalog[idx];
                          final isSelected = _selectedTests.contains(item);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 6),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: isSelected
                                    ? Colors.purple.shade400
                                    : Colors.grey.shade200,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            color: isSelected
                                ? Colors.purple.shade50
                                : Colors.white,
                            child: CheckboxListTile(
                              dense: true,
                              value: isSelected,
                              activeColor: Colors.purple.shade700,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedTests.add(item);
                                  } else {
                                    _selectedTests.remove(item);
                                  }
                                });
                              },
                              title: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      item.code,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    currencyFormat.format(item.price),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple.shade900,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                'Kategori: ${item.category} • Sampel: ${item.sampleType} • Rujukan: ${item.normalRangeText ?? "-"}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const Divider(height: 16),

              // Bottom Bar: Selected Count & Total & Submit
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Terpilih: ${_selectedTests.length} Pemeriksaan',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        currencyFormat.format(_totalPrice),
                        style: TextStyle(
                          color: Colors.purple.shade900,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.purple.shade700,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onPressed: _isLoading
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;
                            if (_selectedTests.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Pilih minimal 1 parameter tes laboratorium.',
                                  ),
                                ),
                              );
                              return;
                            }

                            setState(() => _isLoading = true);

                            final itemsData = _selectedTests
                                .map(
                                  (t) => {
                                    'testCatalogId': t.id,
                                    'testCode': t.code,
                                    'testName': t.name,
                                    'category': t.category,
                                    'price': t.price,
                                    'unit': t.unit,
                                    'normalRangeText': t.normalRangeText,
                                  },
                                )
                                .toList();

                            final res = await ref
                                .read(labOrdersProvider.notifier)
                                .createOrder(
                                  patientId: _selectedPatient!.id,
                                  doctorId: _selectedDoctor!.id,
                                  appointmentId: widget.appointmentId,
                                  admissionId: widget.admissionId,
                                  priority: _priority,
                                  clinicalDiagnosis: _diagnosisCtrl.text.trim(),
                                  clinicalNotes: _notesCtrl.text.trim(),
                                  items: itemsData,
                                );

                            if (mounted) {
                              setState(() => _isLoading = false);
                              Navigator.of(context).pop();

                              if (res != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Order Lab Berhasil Dibuat: ${res.orderNumber} untuk ${res.patientName}. Tagihan otomatis diteruskan ke Kasir.',
                                    ),
                                    backgroundColor: Colors.purple.shade700,
                                  ),
                                );
                              }
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
                        : const Icon(Icons.send_outlined),
                    label: const Text('Kirim Order ke Laboratorium'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _categoryFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        selected: isSelected,
        onSelected: (sel) {
          if (sel) setState(() => _categoryFilter = value);
        },
      ),
    );
  }
}
