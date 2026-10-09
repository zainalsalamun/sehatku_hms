import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/health_models.dart';
import '../../../../shared/widgets/medicine_label_print_dialog.dart';
import '../../application/admin_state_providers.dart';
import '../widgets/admin_table_container.dart';
import '../widgets/patient_form_dialog.dart';

class AdminPatientsTab extends ConsumerStatefulWidget {
  const AdminPatientsTab({super.key});

  @override
  ConsumerState<AdminPatientsTab> createState() => _AdminPatientsTabState();
}

class _AdminPatientsTabState extends ConsumerState<AdminPatientsTab> {
  String _searchQuery = '';
  String _selectedInsurance = 'all';
  int _currentPage = 1;
  int _itemsPerPage = 10;

  @override
  Widget build(BuildContext context) {
    final patients = ref.watch(adminPatientsProvider);

    final dynamicInsurances = <String>{
      'Umum / Mandiri',
      'BPJS Kesehatan Mandiri',
      'BPJS PBI',
      'Prudential Corporate',
      'Allianz Private',
      'Asuransi Mandiri Inhealth',
      ...patients.map((p) => p.insuranceProvider ?? '').where((s) => s.isNotEmpty),
    }.toList();
    final insuranceOptions = ['all', ...dynamicInsurances];

    final filteredPatients = patients.where((p) {
      final matchesSearch =
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.medicalRecordNumber.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          p.nik.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.phone.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesInsurance =
          _selectedInsurance == 'all' ||
          (p.insuranceProvider != null &&
              p.insuranceProvider!.toLowerCase().contains(_selectedInsurance.toLowerCase()));
      return matchesSearch && matchesInsurance;
    }).toList();

    final totalPages = (filteredPatients.length / _itemsPerPage).ceil().clamp(1, 9999);
    if (_currentPage > totalPages) {
      _currentPage = totalPages;
    }
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final paginatedPatients = filteredPatients.skip(startIndex).take(_itemsPerPage).toList();

    final wide = MediaQuery.sizeOf(context).width > 900;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminTableContainer(
            title: 'Master Data & Rekam Medis Pasien',
            subtitle:
                'Registrasi identitas demografis, No. Rekam Medis (MRN), NIK, dan penjamin asuransi.',
            badgeCount: patients.length,
            searchHint: 'Cari No. RM (MRN), NIK KTP, Nama, atau No. HP...',
            onSearchChanged: (val) => setState(() {
              _searchQuery = val;
              _currentPage = 1;
            }),
            actionLabel: 'Pasien Baru',
            actionIcon: Icons.person_add_alt_1_outlined,
            onActionPressed: () => _openPatientDialog(context),
            filterWidget: DropdownButtonFormField<String>(
              initialValue: insuranceOptions.contains(_selectedInsurance) ? _selectedInsurance : 'all',
              isExpanded: true,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(),
              ),
              items: insuranceOptions.map((ins) {
                return DropdownMenuItem(
                  value: ins,
                  child: Text(
                    ins == 'all' ? 'Semua Penjamin / Asuransi' : ins,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedInsurance = val;
                    _currentPage = 1;
                  });
                }
              },
            ),
            currentPage: _currentPage,
            totalItems: filteredPatients.length,
            itemsPerPage: _itemsPerPage,
            onPageChanged: (p) => setState(() => _currentPage = p),
            onItemsPerPageChanged: (n) => setState(() {
              _itemsPerPage = n;
              _currentPage = 1;
            }),
            child: filteredPatients.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        'Tidak ada data pasien yang sesuai dengan pencarian.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : wide
                ? _buildDesktopTable(paginatedPatients)
                : _buildMobileList(paginatedPatients),
          ),
        ],
      ),
    );
  }

  void _openPatientDialog(BuildContext context, [Patient? patient]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PatientFormDialog(patient: patient),
    );
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Widget _buildDesktopTable(List<Patient> patients) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStatePropertyAll(Colors.grey.shade50),
        columns: const [
          DataColumn(label: Text('No. Rekam Medis (MRN)')),
          DataColumn(label: Text('Nama Pasien')),
          DataColumn(label: Text('Usia / JK / Gol')),
          DataColumn(label: Text('Penjamin Asuransi')),
          DataColumn(label: Text('Kontak & Domisili')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Aksi')),
        ],
        rows: patients.map((p) {
          final age = _calculateAge(p.birthDate);

          return DataRow(
            cells: [
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.navy.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    p.medicalRecordNumber,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      color: AppTheme.navy,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      p.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (p.nik.isNotEmpty)
                      Text(
                        'NIK: ${p.nik}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
              DataCell(
                Text(
                  '$age thn • ${p.gender.substring(0, 1)} • ${p.bloodType ?? "-"}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    p.insuranceProvider ?? 'Mandiri',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.teal.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      p.phone.isNotEmpty ? p.phone : '-',
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (p.email.isNotEmpty)
                      Text(
                        p.email,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
              DataCell(
                InkWell(
                  onTap: () => ref
                      .read(adminPatientsProvider.notifier)
                      .toggleStatus(p.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: p.status == 'Aktif'
                          ? Colors.green.shade50
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      p.status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: p.status == 'Aktif'
                            ? Colors.green.shade800
                            : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.badge_outlined,
                        size: 18,
                        color: Colors.teal,
                      ),
                      tooltip: 'Cetak Label Stiker RM Pasien',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => MedicineLabelPrintDialog(
                            prescription: PharmacyPrescription(
                              id: p.id,
                              prescriptionNumber: 'RM-${p.medicalRecordNumber}',
                              patientId: p.id,
                              patientName: p.name,
                              patientMrn: p.medicalRecordNumber,
                              insurance: p.insuranceProvider ?? 'Umum',
                              doctorId: 'd1',
                              doctorName: 'Dokter Umum / Jaga',
                              doctorSpecialist: 'Klinik Umum',
                              status: 'ready',
                              statusLabel: 'Aktif',
                              createdAt: DateTime.now(),
                              items: const [],
                            ),
                            patient: p,
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Edit Pasien',
                      onPressed: () => _openPatientDialog(context, p),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMobileList(List<Patient> patients) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: patients.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final p = patients[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              p.name.substring(0, 1),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          title: Text(
            p.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${p.medicalRecordNumber} • ${p.insuranceProvider ?? "Umum"}\nTelp: ${p.phone}',
            style: const TextStyle(fontSize: 12),
          ),
          isThreeLine: true,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.badge_outlined,
                  size: 20,
                  color: Colors.teal,
                ),
                tooltip: 'Cetak Label RM',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => MedicineLabelPrintDialog(
                      prescription: PharmacyPrescription(
                        id: p.id,
                        prescriptionNumber: 'RM-${p.medicalRecordNumber}',
                        patientId: p.id,
                        patientName: p.name,
                        patientMrn: p.medicalRecordNumber,
                        insurance: p.insuranceProvider ?? 'Umum',
                        doctorId: 'd1',
                        doctorName: 'Dokter Umum / Jaga',
                        doctorSpecialist: 'Klinik Umum',
                        status: 'ready',
                        statusLabel: 'Aktif',
                        createdAt: DateTime.now(),
                        items: const [],
                      ),
                      patient: p,
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _openPatientDialog(context, p),
              ),
            ],
          ),
        );
      },
    );
  }
}
