import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/api_client_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../admin/application/admin_state_providers.dart';
import '../../application/certificates_provider.dart';

class CreateMedicalCertificateDialog extends ConsumerStatefulWidget {
  const CreateMedicalCertificateDialog({super.key});

  @override
  ConsumerState<CreateMedicalCertificateDialog> createState() =>
      _CreateMedicalCertificateDialogState();
}

class _CreateMedicalCertificateDialogState
    extends ConsumerState<CreateMedicalCertificateDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedPatientId;
  String? _selectedDoctorId;
  String _type = 'sick_leave'; // 'sick_leave' or 'healthy'
  int _durationDays = 2;
  DateTime _startDate = DateTime.now();
  final _diagnosisController = TextEditingController(text: 'Hipertensi Primer & Kelelahan Fisik Akut');
  final _notesController = TextEditingController(text: 'Pasien memerlukan istirahat tirah baring untuk pemulihan kondisi.');
  bool _isLoading = false;

  @override
  void dispose() {
    _diagnosisController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patients = ref.watch(adminPatientsProvider);
    final doctors = ref.watch(adminDoctorsProvider);
    final isSickLeave = _type == 'sick_leave';
    final dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');

    // Default select if not set
    if (_selectedPatientId == null && patients.isNotEmpty) {
      _selectedPatientId = patients.first.id;
    }
    if (_selectedDoctorId == null && doctors.isNotEmpty) {
      _selectedDoctorId = doctors.first.id;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 540,
        padding: const EdgeInsets.all(24),
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
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.note_add_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Terbitkan Surat Keterangan Medis',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.navy,
                              ),
                        ),
                        Text(
                          'Input Surat Keterangan Sakit (SKD) atau Surat Keterangan Sehat resmi',
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
              const SizedBox(height: 20),

              // Certificate Type Segmented Control
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'sick_leave',
                    label: Text('Surat Sakit (SKD)'),
                    icon: Icon(Icons.sick_outlined, size: 16),
                  ),
                  ButtonSegment(
                    value: 'healthy',
                    label: Text('Surat Keterangan Sehat'),
                    icon: Icon(Icons.health_and_safety_outlined, size: 16),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (set) => setState(() {
                  _type = set.first;
                  if (_type == 'healthy') {
                    _diagnosisController.text = 'Pemeriksaan Kesehatan Jasmani (Sehat)';
                    _notesController.text = 'Dinyatakan sehat secara fisik untuk keperluan administratif/kedinasan.';
                  } else {
                    _diagnosisController.text = 'Hipertensi Primer & Kelelahan Fisik Akut';
                    _notesController.text = 'Pasien memerlukan istirahat tirah baring untuk pemulihan.';
                  }
                }),
              ),
              const SizedBox(height: 16),

              // Patient Selection Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedPatientId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Pilih Pasien',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                items: patients.map((p) {
                  return DropdownMenuItem(
                    value: p.id,
                    child: Text(
                      '${p.name} (${p.medicalRecordNumber})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedPatientId = val),
                validator: (v) => v == null ? 'Pilih pasien' : null,
              ),
              const SizedBox(height: 14),

              // Doctor Selection Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedDoctorId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Dokter Pemeriksa (DPJP)',
                  prefixIcon: Icon(Icons.medical_services_outlined),
                  border: OutlineInputBorder(),
                ),
                items: doctors.map((d) {
                  return DropdownMenuItem(
                    value: d.id,
                    child: Text(
                      '${d.name} (${d.specialist})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedDoctorId = val),
                validator: (v) => v == null ? 'Pilih dokter' : null,
              ),
              const SizedBox(height: 14),

              // Duration & Start Date (if sick_leave)
              if (isSickLeave) ...[
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<int>(
                        initialValue: _durationDays,
                        decoration: const InputDecoration(
                          labelText: 'Durasi Istirahat',
                          prefixIcon: Icon(Icons.timer_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('1 Hari')),
                          DropdownMenuItem(value: 2, child: Text('2 Hari')),
                          DropdownMenuItem(value: 3, child: Text('3 Hari')),
                          DropdownMenuItem(value: 5, child: Text('5 Hari')),
                          DropdownMenuItem(value: 7, child: Text('7 Hari')),
                        ],
                        onChanged: (val) =>
                            setState(() => _durationDays = val ?? 2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _startDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 7)),
                            lastDate: DateTime.now().add(const Duration(days: 30)),
                          );
                          if (picked != null) {
                            setState(() => _startDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Mulai Tanggal',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            dateFormat.format(_startDate),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],

              // Diagnosis Input
              TextFormField(
                controller: _diagnosisController,
                decoration: const InputDecoration(
                  labelText: 'Diagnosa Medis',
                  prefixIcon: Icon(Icons.biotech_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Diagnosa wajib diisi' : null,
              ),
              const SizedBox(height: 14),

              // Notes Input
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Catatan / Anjuran Dokter',
                  prefixIcon: Icon(Icons.notes_outlined),
                  border: OutlineInputBorder(),
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
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onPressed: _isLoading
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;
                            setState(() => _isLoading = true);

                            final selectedPat = patients.firstWhere(
                              (p) => p.id == _selectedPatientId,
                              orElse: () => patients.first,
                            );
                            final selectedDoc = doctors.firstWhere(
                              (d) => d.id == _selectedDoctorId,
                              orElse: () => doctors.first,
                            );

                            final endDate = _startDate.add(
                              Duration(days: _durationDays),
                            );

                            final client = ref.read(apiClientProvider);
                            final messenger = ScaffoldMessenger.of(context);
                            final navigator = Navigator.of(context);
                            final success = await client.createMedicalCertificate({
                              'patientId': selectedPat.id,
                              'doctorId': selectedDoc.id,
                              'type': _type,
                              'diagnosis': _diagnosisController.text.trim(),
                              'durationDays': isSickLeave ? _durationDays : 1,
                              'startDate': _startDate.toIso8601String(),
                              'endDate': endDate.toIso8601String(),
                              'notes': _notesController.text.trim(),
                            });

                            if (mounted) {
                              setState(() => _isLoading = false);
                              if (success) {
                                await ref
                                    .read(medicalCertificatesProvider.notifier)
                                    .refresh();
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Surat Keterangan Medis untuk ${selectedPat.name} berhasil diterbitkan!',
                                    ),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                                navigator.pop();
                              } else {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Gagal menerbitkan surat medis. Periksa koneksi server.'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          },
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check, size: 18),
                    label: const Text('Terbitkan Surat Sekarang'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
