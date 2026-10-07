import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/health_models.dart';
import '../../application/admin_state_providers.dart';

class DoctorFormDialog extends ConsumerStatefulWidget {
  const DoctorFormDialog({super.key, this.doctor});

  final Doctor? doctor;

  @override
  ConsumerState<DoctorFormDialog> createState() => _DoctorFormDialogState();
}

class _DoctorFormDialogState extends ConsumerState<DoctorFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _licenseController;
  late final TextEditingController _specialistController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _experienceController;

  late String _selectedDepartment;
  late List<String> _selectedDays;
  late bool _isActive;

  final List<String> _allDays = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
  ];

  @override
  void initState() {
    super.initState();
    final d = widget.doctor;
    _nameController = TextEditingController(text: d?.name ?? '');
    _licenseController = TextEditingController(text: d?.licenseNumber ?? '');
    _specialistController = TextEditingController(text: d?.specialist ?? '');
    _phoneController = TextEditingController(text: d?.phone ?? '');
    _emailController = TextEditingController(text: d?.email ?? '');
    _experienceController = TextEditingController(
      text: d != null ? d.experience.toString() : '5',
    );

    _selectedDepartment = d?.departmentId ?? 'dept-1';
    _selectedDays = d?.scheduleDays != null
        ? List<String>.from(d!.scheduleDays)
        : ['Senin', 'Rabu', 'Jumat'];
    _isActive = d?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _licenseController.dispose();
    _specialistController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final isEdit = widget.doctor != null;
    final doctor = Doctor(
      id: isEdit
          ? widget.doctor!.id
          : 'd-${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      specialist: _specialistController.text.trim(),
      hospital: 'SehatKu Medical Center',
      experience: int.tryParse(_experienceController.text) ?? 5,
      rating: widget.doctor?.rating ?? 5.0,
      availableToday: _selectedDays.contains('Senin'),
      licenseNumber: _licenseController.text.trim(),
      departmentId: _selectedDepartment,
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      scheduleDays: _selectedDays,
      isActive: _isActive,
    );

    if (isEdit) {
      ref.read(adminDoctorsProvider.notifier).updateDoctor(doctor);
    } else {
      ref.read(adminDoctorsProvider.notifier).addDoctor(doctor);
    }

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEdit
              ? 'Data ${doctor.name} berhasil diperbarui'
              : 'Dokter baru ${doctor.name} berhasil ditambahkan',
        ),
        backgroundColor: Colors.green.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final departments = ref.watch(adminDepartmentsProvider);
    final isEdit = widget.doctor != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 620,
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
                        isEdit ? Icons.edit : Icons.person_add,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEdit ? 'Edit Data Dokter' : 'Tambah Dokter Baru',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            isEdit
                                ? 'Perbarui informasi dan jadwal praktek'
                                : 'Masukkan kredensial SIP dan departemen',
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

                // Form Fields
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap Beserta Gelar *',
                    hintText: 'dr. Nama Lengkap, Sp.XX',
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _licenseController,
                        decoration: const InputDecoration(
                          labelText: 'Nomor SIP / STR *',
                          hintText: 'SIP.449.1/...',
                          prefixIcon: Icon(Icons.verified_user_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Nomor SIP wajib diisi'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Builder(
                      builder: (context) {
                        final deptIds = departments.map((d) => d.id).toSet();
                        final effectiveDept = deptIds.contains(_selectedDepartment)
                            ? _selectedDepartment
                            : (departments.isNotEmpty ? departments.first.id : null);

                        return Expanded(
                          child: DropdownButtonFormField<String>(
                            value: effectiveDept,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Departemen / Poli *',
                              prefixIcon: Icon(Icons.local_hospital_outlined),
                              border: OutlineInputBorder(),
                            ),
                            items: departments.map((dept) {
                              return DropdownMenuItem(
                                value: dept.id,
                                child: Text(
                                  dept.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedDepartment = val);
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _specialistController,
                        decoration: const InputDecoration(
                          labelText: 'Spesialisasi *',
                          hintText: 'Kardiologi, Bedah, dll',
                          prefixIcon: Icon(Icons.medical_services_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Spesialisasi wajib diisi'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _experienceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Pengalaman (Tahun)',
                          prefixIcon: Icon(Icons.history_edu_outlined),
                          border: OutlineInputBorder(),
                        ),
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
                        decoration: const InputDecoration(
                          labelText: 'Email Rumah Sakit',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Schedule Days
                const Text(
                  'Hari Praktek Rutin:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _allDays.map((day) {
                    final isSelected = _selectedDays.contains(day);
                    return FilterChip(
                      label: Text(day),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedDays.add(day);
                          } else {
                            _selectedDays.remove(day);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Status Toggle
                SwitchListTile(
                  title: const Text('Status Dokter Aktif'),
                  subtitle: const Text(
                    'Dokter aktif dapat menerima booking dan antrean pasien',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _isActive,
                  onChanged: (val) => setState(() => _isActive = val),
                  contentPadding: EdgeInsets.zero,
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
                        isEdit ? 'Simpan Perubahan' : 'Tambah Dokter',
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
