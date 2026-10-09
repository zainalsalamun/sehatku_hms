import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/health_models.dart';
import '../../../../shared/widgets/doctor_avatar.dart';
import '../../application/admin_state_providers.dart';
import '../widgets/admin_table_container.dart';
import '../widgets/doctor_form_dialog.dart';
import '../widgets/doctor_profile_detail_dialog.dart';

class AdminDoctorsTab extends ConsumerStatefulWidget {
  const AdminDoctorsTab({super.key});

  @override
  ConsumerState<AdminDoctorsTab> createState() => _AdminDoctorsTabState();
}

class _AdminDoctorsTabState extends ConsumerState<AdminDoctorsTab> {
  String _searchQuery = '';
  String _selectedDeptFilter = 'all';
  int _currentPage = 1;
  int _itemsPerPage = 10;

  @override
  Widget build(BuildContext context) {
    final doctors = ref.watch(adminDoctorsProvider);
    final departments = ref.watch(adminDepartmentsProvider);

    final filteredDoctors = doctors.where((doc) {
      final matchesSearch =
          doc.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          doc.specialist.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          doc.licenseNumber.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesDept =
          _selectedDeptFilter == 'all' ||
          doc.departmentId == _selectedDeptFilter;
      return matchesSearch && matchesDept;
    }).toList();

    final totalPages = (filteredDoctors.length / _itemsPerPage).ceil().clamp(1, 9999);
    if (_currentPage > totalPages) {
      _currentPage = totalPages;
    }
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final paginatedDoctors = filteredDoctors.skip(startIndex).take(_itemsPerPage).toList();

    final wide = MediaQuery.sizeOf(context).width > 900;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminTableContainer(
            title: 'Manajemen Tenaga Medis & Dokter',
            subtitle:
                'Kelola kredensial SIP/STR, spesialisasi, jadwal praktek, dan status aktif.',
            badgeCount: doctors.length,
            searchHint: 'Cari nama dokter, spesialisasi, atau no SIP...',
            onSearchChanged: (val) => setState(() {
              _searchQuery = val;
              _currentPage = 1;
            }),
            currentPage: _currentPage,
            totalItems: filteredDoctors.length,
            itemsPerPage: _itemsPerPage,
            onPageChanged: (page) => setState(() => _currentPage = page),
            onItemsPerPageChanged: (count) => setState(() {
              _itemsPerPage = count;
              _currentPage = 1;
            }),
            actionLabel: 'Tambah Dokter',
            actionIcon: Icons.person_add_outlined,
            onActionPressed: () => _openDoctorDialog(context),
            filterWidget: DropdownButtonFormField<String>(
              initialValue: _selectedDeptFilter,
              isExpanded: true,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: 'all',
                  child: Text(
                    'Semua Departemen / Poli',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ...departments.map(
                  (d) => DropdownMenuItem(
                    value: d.id,
                    child: Text(d.name, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedDeptFilter = val;
                    _currentPage = 1;
                  });
                }
              },
            ),
            child: filteredDoctors.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        'Tidak ada data dokter yang sesuai dengan filter.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : wide
                ? _buildDesktopTable(paginatedDoctors, departments)
                : _buildMobileList(paginatedDoctors, departments),
          ),
        ],
      ),
    );
  }

  void _openDoctorDialog(BuildContext context, [Doctor? doctor]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => DoctorFormDialog(doctor: doctor),
    );
  }

  void _openDoctorProfileDialog(
    BuildContext context,
    Doctor doctor,
    String deptName,
  ) {
    showDialog(
      context: context,
      builder: (_) => DoctorProfileDetailDialog(
        doctor: doctor,
        departmentName: deptName,
        onEditPressed: () => _openDoctorDialog(context, doctor),
      ),
    );
  }

  Widget _buildDesktopTable(
    List<Doctor> doctors,
    List<Department> departments,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStatePropertyAll(Colors.grey.shade50),
        columns: const [
          DataColumn(label: Text('Nama Dokter & Gelar')),
          DataColumn(label: Text('Nomor SIP / STR')),
          DataColumn(label: Text('Poli / Departemen')),
          DataColumn(label: Text('Rating / Exp')),
          DataColumn(label: Text('Jadwal Praktek')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Aksi')),
        ],
        rows: doctors.map((doc) {
          final dept = departments.firstWhere(
            (d) => d.id == doc.departmentId,
            orElse: () => const Department(
              id: 'none',
              name: 'Umum',
              code: 'GEN',
              doctorCount: 0,
            ),
          );

          return DataRow(
            cells: [
              DataCell(
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _openDoctorProfileDialog(context, doc, dept.name),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DoctorAvatar(
                          photoUrl: doc.photoUrl,
                          name: doc.name,
                          radius: 18,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  doc.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.navy,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.info_outline,
                                  size: 14,
                                  color: Colors.grey.shade400,
                                ),
                              ],
                            ),
                            Text(
                              doc.specialist,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              DataCell(
                Text(
                  doc.licenseNumber.isNotEmpty ? doc.licenseNumber : '-',
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    dept.name,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      '${doc.rating}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      ' • ${doc.experience} thn',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              DataCell(
                Wrap(
                  spacing: 4,
                  children: doc.scheduleDays.map((day) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(day, style: const TextStyle(fontSize: 10)),
                    );
                  }).toList(),
                ),
              ),
              DataCell(
                Switch(
                  value: doc.isActive,
                  onChanged: (_) => ref
                      .read(adminDoctorsProvider.notifier)
                      .toggleActive(doc.id),
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      tooltip: 'Lihat Profil Lengkap',
                      onPressed: () =>
                          _openDoctorProfileDialog(context, doc, dept.name),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Edit Data',
                      onPressed: () => _openDoctorDialog(context, doc),
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

  Widget _buildMobileList(List<Doctor> doctors, List<Department> departments) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: doctors.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final doc = doctors[index];
        final dept = departments.firstWhere(
          (d) => d.id == doc.departmentId,
          orElse: () => const Department(
            id: 'none',
            name: 'Umum',
            code: 'GEN',
            doctorCount: 0,
          ),
        );

        return ListTile(
          onTap: () => _openDoctorProfileDialog(context, doc, dept.name),
          leading: DoctorAvatar(
            photoUrl: doc.photoUrl,
            name: doc.name,
            radius: 20,
          ),
          title: Text(
            doc.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${doc.specialist} • ${dept.name}'),
              Text(
                'SIP: ${doc.licenseNumber} • Rating: ${doc.rating} (${doc.experience} thn)',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility_outlined, size: 20),
                tooltip: 'Lihat Profil',
                onPressed: () =>
                    _openDoctorProfileDialog(context, doc, dept.name),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Edit Data',
                onPressed: () => _openDoctorDialog(context, doc),
              ),
            ],
          ),
        );
      },
    );
  }
}
