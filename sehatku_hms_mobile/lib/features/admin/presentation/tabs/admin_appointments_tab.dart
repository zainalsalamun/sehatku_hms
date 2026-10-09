import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/health_models.dart';
import '../../application/admin_state_providers.dart';
import '../../../notification/application/notifications_provider.dart';
import '../../../queue/application/queue_display_provider.dart';
import '../screens/admin_create_appointment_screen.dart';
import '../widgets/admin_table_container.dart';
import '../widgets/cancel_appointment_dialog.dart';

class AdminAppointmentsTab extends ConsumerStatefulWidget {
  const AdminAppointmentsTab({super.key});

  @override
  ConsumerState<AdminAppointmentsTab> createState() =>
      _AdminAppointmentsTabState();
}

class _AdminAppointmentsTabState extends ConsumerState<AdminAppointmentsTab> {
  String _searchQuery = '';
  String _statusFilter = 'all';
  int _currentPage = 1;
  int _itemsPerPage = 10;

  final List<String> _statusOptions = [
    'all',
    'Checked-in',
    'Menunggu',
    'Terkonfirmasi',
    'Selesai',
    'Tidak Berlaku',
    'Dibatalkan',
  ];

  @override
  Widget build(BuildContext context) {
    final appointments = ref.watch(adminAppointmentsProvider);

    final filteredAppointments = appointments.where((a) {
      final matchesSearch =
          a.patientName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          a.doctorName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          a.queueNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          a.department.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _statusFilter == 'all'
          ? true
          : (_statusFilter == 'Tidak Berlaku'
              ? (a.isExpired || a.displayStatus == 'Tidak Berlaku')
              : (!a.isExpired && a.status == _statusFilter));
      return matchesSearch && matchesStatus;
    }).toList();

    final totalPages = (filteredAppointments.length / _itemsPerPage).ceil().clamp(1, 9999);
    if (_currentPage > totalPages) {
      _currentPage = totalPages;
    }
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final paginatedAppointments = filteredAppointments.skip(startIndex).take(_itemsPerPage).toList();

    final wide = MediaQuery.sizeOf(context).width > 900;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminTableContainer(
            title: 'Monitoring Reservasi & Antrean Poli',
            subtitle:
                'Pantau status kedatangan pasien, nomor antrean aktif, dan daftarkan pasien reservasi / walk-in loket.',
            badgeCount: appointments.length,
            currentPage: _currentPage,
            totalItems: filteredAppointments.length,
            itemsPerPage: _itemsPerPage,
            onPageChanged: (page) => setState(() => _currentPage = page),
            onItemsPerPageChanged: (count) => setState(() {
              _itemsPerPage = count;
              _currentPage = 1;
            }),
            actionLabel: 'Daftar Reservasi / Walk-in',
            actionIcon: Icons.person_add_alt_1,
            onActionPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AdminCreateAppointmentScreen(),
                ),
              );
            },
            searchHint: 'Cari nomor antrean, nama pasien, atau dokter...',
            onSearchChanged: (val) => setState(() {
              _searchQuery = val;
              _currentPage = 1;
            }),
            filterWidget: DropdownButtonFormField<String>(
              initialValue: _statusFilter,
              isExpanded: true,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(),
              ),
              items: _statusOptions.map((st) {
                return DropdownMenuItem(
                  value: st,
                  child: Text(
                    st == 'all' ? 'Semua Status' : st,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _statusFilter = val;
                    _currentPage = 1;
                  });
                }
              },
            ),
            child: filteredAppointments.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        'Tidak ada reservasi yang sesuai filter.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : wide
                ? _buildDesktopTable(paginatedAppointments)
                : _buildMobileList(paginatedAppointments),
          ),
        ],
      ),
    );
  }

  void _openCancelDialog(BuildContext context, Appointment a) {
    showDialog(
      context: context,
      builder: (_) => CancelAppointmentDialog(
        patientName: a.patientName,
        queueNumber: a.queueNumber,
        onConfirm: (reason) {
          ref
              .read(adminAppointmentsProvider.notifier)
              .cancelAppointment(a.id, reason);
          ref.read(notificationsProvider.notifier).refresh();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Reservasi ${a.queueNumber} (${a.patientName}) telah dibatalkan',
              ),
              backgroundColor: Colors.red.shade700,
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Checked-in':
        return Colors.green;
      case 'Menunggu':
        return Colors.orange;
      case 'Terkonfirmasi':
        return Colors.blue;
      case 'Selesai':
        return Colors.indigo;
      case 'Tidak Berlaku':
      case 'Kadaluarsa':
      case 'Kedaluwarsa':
        return Colors.blueGrey;
      case 'Dibatalkan':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildDesktopTable(List<Appointment> list) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStatePropertyAll(Colors.grey.shade50),
        columns: const [
          DataColumn(label: Text('Antrean / Jam')),
          DataColumn(label: Text('Pasien')),
          DataColumn(label: Text('Dokter & Poli')),
          DataColumn(label: Text('Keluhan / Layanan')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Aksi Operasional')),
        ],
        rows: list.map((a) {
          final color = _getStatusColor(a.displayStatus);

          return DataRow(
            cells: [
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.navy.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            a.queueNumber,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.navy,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          a.displayReservationNumber,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blueGrey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${a.dateLabel} • ${a.time}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              DataCell(
                Text(
                  a.patientName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      a.doctorName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      a.department,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              DataCell(Text(a.reason, style: const TextStyle(fontSize: 12))),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    a.displayStatus,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color,
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
                        Icons.volume_up_outlined,
                        size: 18,
                        color: Colors.teal,
                      ),
                      tooltip: 'Panggil Suara Antrean',
                      onPressed: () {
                        final deptName = a.department.startsWith('Poli')
                            ? a.department
                            : 'Poli ${a.department}';
                        ref
                            .read(queueDisplayProvider.notifier)
                            .callPatient(
                              queueNumber: a.queueNumber,
                              patientName: a.patientName,
                              destination: '$deptName, Ruang Periksa Dokter',
                            );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Memanggil suara antrean ${a.queueNumber} (${a.patientName}) ke ${a.department}...',
                            ),
                            backgroundColor: Colors.teal,
                          ),
                        );
                      },
                    ),
                    if (a.status == 'Terkonfirmasi' || a.status == 'Menunggu')
                      IconButton(
                        icon: const Icon(
                          Icons.how_to_reg_outlined,
                          size: 18,
                          color: Colors.green,
                        ),
                        tooltip: 'Check-in Pasien',
                        onPressed: () {
                          ref
                              .read(adminAppointmentsProvider.notifier)
                              .checkInAppointment(a.id);
                        },
                      ),
                    if (a.status == 'Checked-in')
                      IconButton(
                        icon: const Icon(
                          Icons.task_alt,
                          size: 18,
                          color: Colors.indigo,
                        ),
                        tooltip: 'Selesai Konsultasi',
                        onPressed: () {
                          ref
                              .read(adminAppointmentsProvider.notifier)
                              .completeAppointment(a.id);
                        },
                      ),
                    if (a.status != 'Selesai' && a.status != 'Dibatalkan')
                      IconButton(
                        icon: const Icon(
                          Icons.cancel_outlined,
                          size: 18,
                          color: Colors.red,
                        ),
                        tooltip: 'Batalkan Reservasi',
                        onPressed: () => _openCancelDialog(context, a),
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

  Widget _buildMobileList(List<Appointment> list) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final a = list[index];
        final color = _getStatusColor(a.displayStatus);

        return ListTile(
          leading: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.navy.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              a.queueNumber,
              style: const TextStyle(
                 fontWeight: FontWeight.bold,
                color: AppTheme.navy,
              ),
            ),
          ),
          title: Text(
            a.patientName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${a.doctorName} (${a.department})\n${a.dateLabel} • ${a.time}',
            style: const TextStyle(fontSize: 12),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              a.displayStatus,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        );
      },
    );
  }
}
