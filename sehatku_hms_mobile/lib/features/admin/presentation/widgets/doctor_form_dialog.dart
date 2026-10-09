import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/api_client_provider.dart';
import '../../../../core/utils/image_picker_helper.dart';
import '../../../../shared/models/health_models.dart';
import '../../../../shared/widgets/doctor_avatar.dart';
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
  late final TextEditingController _photoUrlController;

  late String _selectedDepartment;
  late List<String> _selectedDays;
  late bool _isActive;

  String? _uploadedFileName;
  bool _isUploading = false;
  bool _showManualUrlInput = false;

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
    _photoUrlController = TextEditingController(text: d?.photoUrl ?? '');
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
    _photoUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto() async {
    setState(() => _isUploading = true);
    try {
      final picked = await pickImageFromDevice();
      if (picked != null) {
        setState(() {
          _photoUrlController.text = picked.dataUrl;
          _uploadedFileName = picked.name;
        });

        // Optionally upload to backend server storage in background
        final serverUrl = await ref
            .read(apiClientProvider)
            .uploadDoctorAvatar(picked.dataUrl, picked.name);
        if (serverUrl != null && serverUrl.isNotEmpty && mounted) {
          setState(() {
            _photoUrlController.text = serverUrl;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
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
      photoUrl: _photoUrlController.text.trim(),
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
        width: 650,
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
                                ? 'Perbarui profil, foto, dan jadwal praktek'
                                : 'Masukkan data SIP, foto profil, dan jadwal praktek dokter',
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
                const Divider(height: 28),

                // Foto Profil Upload Section
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Live Circle Avatar Preview
                          DoctorAvatar(
                            photoUrl: _photoUrlController.text.trim(),
                            name: _nameController.text.trim(),
                            radius: 36,
                            borderWidth: 2.5,
                            borderColor: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Foto Profil Dokter',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _uploadedFileName != null
                                      ? 'File terpilih: $_uploadedFileName'
                                      : 'Upload foto dokter langsung dari perangkat (JPG, PNG, WEBP)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _uploadedFileName != null
                                        ? Colors.green.shade800
                                        : Colors.grey.shade600,
                                    fontWeight: _uploadedFileName != null
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    FilledButton.icon(
                                      onPressed: _isUploading ? null : _pickAndUploadPhoto,
                                      icon: _isUploading
                                          ? const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(Icons.cloud_upload_outlined, size: 18),
                                      label: Text(_isUploading ? 'Memproses...' : 'Upload Foto'),
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      ),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: () => setState(() => _showManualUrlInput = !_showManualUrlInput),
                                      icon: Icon(_showManualUrlInput ? Icons.link_off : Icons.link, size: 16),
                                      label: Text(_showManualUrlInput ? 'Tutup URL' : 'Input URL'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      ),
                                    ),
                                    if (_photoUrlController.text.isNotEmpty)
                                      TextButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            _photoUrlController.clear();
                                            _uploadedFileName = null;
                                          });
                                        },
                                        icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                        label: const Text(
                                          'Hapus Foto',
                                          style: TextStyle(color: Colors.red, fontSize: 12),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_showManualUrlInput) ...[
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _photoUrlController,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'URL Foto Profil Langsung',
                            hintText: 'https://example.com/foto.jpg',
                            prefixIcon: const Icon(Icons.link),
                            suffixIcon: _photoUrlController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _photoUrlController.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                            isDense: true,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

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
                            initialValue: effectiveDept,
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
