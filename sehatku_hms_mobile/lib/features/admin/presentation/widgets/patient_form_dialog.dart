import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/health_models.dart';
import '../../application/admin_state_providers.dart';

class PatientFormDialog extends ConsumerStatefulWidget {
  const PatientFormDialog({super.key, this.patient});

  final Patient? patient;

  @override
  ConsumerState<PatientFormDialog> createState() => _PatientFormDialogState();
}

class _PatientFormDialogState extends ConsumerState<PatientFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _mrnController;
  late final TextEditingController _nikController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _emergencyController;

  late String _gender;
  late String _bloodType;
  late String _insurance;
  late DateTime _birthDate;

  final List<String> _genders = ['Laki-laki', 'Perempuan'];
  final List<String> _bloodTypes = [
    'A+',
    'B+',
    'AB+',
    'O+',
    'A-',
    'B-',
    'AB-',
    'O-',
  ];
  final List<String> _insurances = [
    'BPJS Kesehatan Mandiri',
    'BPJS PBI',
    'Prudential Corporate',
    'Allianz Private',
    'Umum / Mandiri (Tanpa Asuransi)',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.patient;
    _nameController = TextEditingController(text: p?.name ?? '');
    _mrnController = TextEditingController(
      text:
          p?.medicalRecordNumber ??
          'MRN-2026-${(100 + (DateTime.now().millisecond % 900)).toString()}',
    );
    _nikController = TextEditingController(text: p?.nik ?? '');
    _phoneController = TextEditingController(text: p?.phone ?? '');
    _emailController = TextEditingController(text: p?.email ?? '');
    _addressController = TextEditingController(text: p?.address ?? '');
    _emergencyController = TextEditingController(
      text: p?.emergencyContact ?? '',
    );

    _gender = p?.gender ?? 'Perempuan';
    _bloodType = p?.bloodType ?? 'O+';
    _insurance = p?.insuranceProvider ?? 'BPJS Kesehatan Mandiri';
    _birthDate = p?.birthDate ?? DateTime(1995, 1, 1);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mrnController.dispose();
    _nikController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _emergencyController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final isEdit = widget.patient != null;
    final patient = Patient(
      id: isEdit
          ? widget.patient!.id
          : 'p-${DateTime.now().millisecondsSinceEpoch}',
      medicalRecordNumber: _mrnController.text.trim(),
      name: _nameController.text.trim(),
      birthDate: _birthDate,
      gender: _gender,
      status: widget.patient?.status ?? 'Aktif',
      bloodType: _bloodType,
      insuranceProvider: _insurance,
      nik: _nikController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      emergencyContact: _emergencyController.text.trim(),
    );

    if (isEdit) {
      ref.read(adminPatientsProvider.notifier).updatePatient(patient);
    } else {
      ref.read(adminPatientsProvider.notifier).registerPatient(patient);
    }

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEdit
              ? 'Data pasien ${patient.name} berhasil diperbarui'
              : 'Pasien baru ${patient.name} (${patient.medicalRecordNumber}) berhasil didaftarkan',
        ),
        backgroundColor: Colors.green.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.patient != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 640,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      child: Icon(
                        isEdit ? Icons.edit : Icons.person_add_alt_1,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEdit
                                ? 'Edit Data Pasien'
                                : 'Registrasi Pasien Baru',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            isEdit
                                ? 'Perbarui data rekam medis dan asuransi'
                                : 'Pendaftaran identitas rekam medis (MRN)',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
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
                const Divider(height: 32),

                // Fields
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _mrnController,
                        decoration: const InputDecoration(
                          labelText: 'No. Rekam Medis (MRN) *',
                          prefixIcon: Icon(Icons.pin_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'No. Rekam Medis wajib diisi'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _nikController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Nomor Induk Kependudukan (NIK) *',
                          hintText: '16 digit NIK KTP',
                          prefixIcon: Icon(Icons.credit_card_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().length < 16
                            ? 'NIK minimal 16 digit'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap Pasien Sesuai KTP *',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
                ),
                const SizedBox(height: 16),

                // Birth Date & Gender Row
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _pickBirthDate,
                        borderRadius: BorderRadius.circular(4),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Tanggal Lahir *',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            '${_birthDate.day}/${_birthDate.month}/${_birthDate.year}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _gender,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Jenis Kelamin *',
                          prefixIcon: Icon(Icons.transgender_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: _genders
                            .map(
                              (g) => DropdownMenuItem(
                                value: g,
                                child: Text(g, overflow: TextOverflow.ellipsis),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _gender = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Blood Type & Insurance Provider Row
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        initialValue: _bloodType,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Gol. Darah',
                          prefixIcon: Icon(Icons.bloodtype_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: _bloodTypes
                            .map(
                              (b) => DropdownMenuItem(
                                value: b,
                                child: Text(b, overflow: TextOverflow.ellipsis),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _bloodType = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        initialValue: _insurance,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Penjamin / Asuransi *',
                          prefixIcon: Icon(Icons.health_and_safety_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: _insurances
                            .map(
                              (ins) => DropdownMenuItem(
                                value: ins,
                                child: Text(ins, overflow: TextOverflow.ellipsis),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _insurance = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Nomor WhatsApp / HP',
                          prefixIcon: Icon(Icons.phone_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Alamat Email',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Alamat Domisili',
                    prefixIcon: Icon(Icons.home_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _emergencyController,
                  decoration: const InputDecoration(
                    labelText: 'Kontak Darurat (Nama & No. HP)',
                    hintText: 'Contoh: Ibu Rina (0812-xxxx-xxxx)',
                    prefixIcon: Icon(Icons.contact_emergency_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save_outlined, size: 18),
                      label: Text(
                        isEdit ? 'Simpan Perubahan' : 'Daftarkan Pasien',
                      ),
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
