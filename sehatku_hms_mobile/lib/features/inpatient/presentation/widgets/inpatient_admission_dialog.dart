import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/models/health_models.dart';
import '../../../admin/application/admin_state_providers.dart';
import '../../application/inpatient_state_providers.dart';

class InpatientAdmissionDialog extends ConsumerStatefulWidget {
  const InpatientAdmissionDialog({super.key, this.preselectedBed});

  final RoomBedModel? preselectedBed;

  @override
  ConsumerState<InpatientAdmissionDialog> createState() =>
      _InpatientAdmissionDialogState();
}

class _InpatientAdmissionDialogState
    extends ConsumerState<InpatientAdmissionDialog> {
  final _formKey = GlobalKey<FormState>();

  Patient? _selectedPatient;
  Doctor? _selectedDoctor;
  RoomBedModel? _selectedBed;
  String _admissionType = 'Poliklinik';
  final _diagnosisCtrl = TextEditingController(
    text: 'Observasi Klinis Lanjutan',
  );
  final _notesCtrl = TextEditingController();
  bool _isLoading = false;

  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

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
    _selectedBed = widget.preselectedBed;
    if (_selectedBed == null) {
      final beds = ref.read(inpatientBedsProvider);
      final available = beds.where((b) => b.status == 'available').toList();
      if (available.isNotEmpty) {
        _selectedBed = available.first;
      }
    }
  }

  @override
  void dispose() {
    _diagnosisCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patients = ref.watch(adminPatientsProvider);
    final doctors = ref.watch(adminDoctorsProvider);
    final beds = ref.watch(inpatientBedsProvider);
    final availableBeds = beds.where((b) => b.status == 'available').toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 680,
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
                        Icons.hotel_outlined,
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
                            'Admisi Pasien Masuk Rawat Inap (Check-In Ranap)',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Alokasikan bed kamar rawat inap, tentukan DPJP, dan buatkan berkas CPPT rekam medis.',
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

                // Pasien Selection
                DropdownButtonFormField<Patient>(
                  initialValue: _selectedPatient,
                  decoration: const InputDecoration(
                    labelText: 'Pilih Pasien Terdaftar *',
                    prefixIcon: Icon(Icons.person_search_outlined),
                    border: OutlineInputBorder(),
                    helperText: 'Pilih pasien yang akan dirawat inap',
                  ),
                  isExpanded: true,
                  items: patients.map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Text(
                        '${p.name} • ${p.medicalRecordNumber} (${p.insuranceProvider ?? "Umum"}) - NIK: ${p.nik}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (p) => setState(() => _selectedPatient = p),
                  validator: (v) =>
                      v == null ? 'Pilih pasien terlebih dahulu' : null,
                ),
                const SizedBox(height: 14),

                // DPJP & Asal Masuk
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<Doctor>(
                        initialValue: _selectedDoctor,
                        decoration: const InputDecoration(
                          labelText: 'Dokter Penanggung Jawab (DPJP) *',
                          prefixIcon: Icon(Icons.medical_services_outlined),
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
                        onChanged: (d) => setState(() => _selectedDoctor = d),
                        validator: (v) =>
                            v == null ? 'Pilih dokter DPJP' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        initialValue: _admissionType,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Asal Masuk / Rujukan',
                          prefixIcon: Icon(Icons.input_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Poliklinik',
                            child: Text('Poliklinik', overflow: TextOverflow.ellipsis),
                          ),
                          DropdownMenuItem(
                            value: 'IGD / Darurat',
                            child: Text('IGD / Darurat', overflow: TextOverflow.ellipsis),
                          ),
                          DropdownMenuItem(
                            value: 'Rujukan Luar',
                            child: Text('Rujukan Luar', overflow: TextOverflow.ellipsis),
                          ),
                          DropdownMenuItem(
                            value: 'Rawat Terencana',
                            child: Text('Rawat Terencana', overflow: TextOverflow.ellipsis),
                          ),
                        ],
                        onChanged: (v) =>
                            setState(() => _admissionType = v ?? 'Poliklinik'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Kamar & Bed Selection
                DropdownButtonFormField<RoomBedModel>(
                  initialValue: availableBeds.contains(_selectedBed)
                      ? _selectedBed
                      : (availableBeds.isNotEmpty ? availableBeds.first : null),
                  decoration: const InputDecoration(
                    labelText: 'Pilih Kamar & Bed Kosong (Available) *',
                    prefixIcon: Icon(Icons.single_bed_outlined),
                    border: OutlineInputBorder(),
                    helperText:
                        'Hanya bed yang berstatus kosong (tersedia) yang dapat dipilih',
                  ),
                  isExpanded: true,
                  items: availableBeds.map((b) {
                    return DropdownMenuItem(
                      value: b,
                      child: Text(
                        '${b.roomName} (${b.roomNumber}) - ${b.bedNumber} [${b.classType}] • ${currencyFormat.format(b.dailyRate)}/malam',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (b) => setState(() => _selectedBed = b),
                  validator: (v) =>
                      v == null ? 'Pilih bed kamar rawat inap' : null,
                ),
                const SizedBox(height: 14),

                // Diagnosa Awal
                TextFormField(
                  controller: _diagnosisCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Diagnosa Awal Masuk Rawat Inap *',
                    prefixIcon: Icon(Icons.notes),
                    border: OutlineInputBorder(),
                    hintText:
                        'Contoh: Demam Berdarah Dengue (DHF Grade II), GEA Dehidrasi Sedang',
                  ),
                  validator: (v) => v == null || v.isEmpty
                      ? 'Diagnosa awal wajib diisi'
                      : null,
                ),
                const SizedBox(height: 14),

                // Catatan & Instruksi Tambahan
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Instruksi Awal Perawatan / Terapi Infus',
                    prefixIcon: Icon(Icons.edit_note),
                    border: OutlineInputBorder(),
                    hintText:
                        'Contoh: Pasang IVFD RL 20 tpm, bedrest total, observasi TTV per 4 jam',
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
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
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onPressed: _isLoading
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) return;
                              if (_selectedBed == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Tidak ada bed kosong yang tersedia.',
                                    ),
                                  ),
                                );
                                return;
                              }

                              setState(() => _isLoading = true);

                              final res = await ref
                                  .read(inpatientAdmissionsProvider.notifier)
                                  .createAdmission(
                                    patientId: _selectedPatient!.id,
                                    doctorId: _selectedDoctor!.id,
                                    bedId: _selectedBed!.id,
                                    admissionType: _admissionType,
                                    initialDiagnosis: _diagnosisCtrl.text
                                        .trim(),
                                    notes: _notesCtrl.text.trim(),
                                  );

                              if (mounted) {
                                setState(() => _isLoading = false);
                                Navigator.of(context).pop();

                                if (res != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Admisi Berhasil: ${_selectedPatient!.name} ditempatkan di ${_selectedBed!.roomName} (${_selectedBed!.bedNumber}).',
                                      ),
                                      backgroundColor: Colors.teal,
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
                          : const Icon(Icons.check_circle_outline),
                      label: const Text('Simpan & Masuk Kamar'),
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
