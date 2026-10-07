import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/models/health_models.dart';
import '../../../inpatient/application/inpatient_state_providers.dart';
import '../../../inpatient/presentation/widgets/inpatient_admission_dialog.dart';
import '../../../inpatient/presentation/widgets/inpatient_cppt_dialog.dart';
import '../../../inpatient/presentation/widgets/inpatient_discharge_dialog.dart';
import '../../../inpatient/presentation/widgets/inpatient_transfer_bed_dialog.dart';
import '../widgets/admin_table_container.dart';

class AdminInpatientTab extends ConsumerStatefulWidget {
  const AdminInpatientTab({super.key});

  @override
  ConsumerState<AdminInpatientTab> createState() => _AdminInpatientTabState();
}

class _AdminInpatientTabState extends ConsumerState<AdminInpatientTab> {
  int _viewMode = 0; // 0 = Visual Bed Floor Plan, 1 = Pasien Ranap Aktif, 2 = Riwayat Pulang (Discharged)

  String _classFilter = 'all';
  String _statusFilter = 'all';
  String _searchQuery = '';

  final currencyFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final dateFormat = DateFormat('dd MMM yyyy');

  @override
  Widget build(BuildContext context) {
    final beds = ref.watch(inpatientBedsProvider);
    final admissions = ref.watch(inpatientAdmissionsProvider);

    // KPI Metrics
    final totalBeds = beds.length;
    final occupiedBeds = beds.where((b) => b.status == 'occupied').length;
    final availableBeds = beds.where((b) => b.status == 'available').length;
    final cleaningBeds = beds.where((b) => b.status == 'cleaning').length;
    final borPercentage = totalBeds > 0
        ? ((occupiedBeds / totalBeds) * 100).toStringAsFixed(1)
        : '0.0';

    // Filter Beds
    final filteredBeds = beds.where((b) {
      final matchClass =
          _classFilter == 'all' || b.classType.toLowerCase() == _classFilter.toLowerCase();
      final matchStatus =
          _statusFilter == 'all' || b.status.toLowerCase() == _statusFilter.toLowerCase();
      final matchSearch = _searchQuery.isEmpty ||
          b.roomName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          b.roomNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          b.bedNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (b.activePatient?.patientName.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      return matchClass && matchStatus && matchSearch;
    }).toList();

    // Filter Active Admissions
    final activeAdmissions = admissions.where((a) {
      final isAct = a.status == 'active';
      final matchQuery = _searchQuery.isEmpty ||
          a.patientName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          a.patientMrn.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          a.doctorName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          a.admissionNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          a.roomName.toLowerCase().contains(_searchQuery.toLowerCase());
      return isAct && matchQuery;
    }).toList();

    // Filter Discharged
    final dischargedAdmissions = admissions.where((a) {
      final isDis = a.status == 'discharged';
      final matchQuery = _searchQuery.isEmpty ||
          a.patientName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          a.patientMrn.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          a.doctorName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          a.admissionNumber.toLowerCase().contains(_searchQuery.toLowerCase());
      return isDis && matchQuery;
    }).toList();

    final wide = MediaQuery.sizeOf(context).width > 900;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // KPI Metric Header Cards
          _buildKpiMetrics(
            totalBeds: totalBeds,
            occupiedBeds: occupiedBeds,
            availableBeds: availableBeds,
            cleaningBeds: cleaningBeds,
            borPercentage: borPercentage,
            wide: wide,
          ),
          const SizedBox(height: 20),

          // Main Inpatient Table & Floor Plan Container
          AdminTableContainer(
            title: 'Manajemen Rawat Inap & Denah Kamar (Inpatient & Bed Management)',
            subtitle:
                'Monitoring ketersediaan bed real-time, kelola admisi pasien ranap, catatan CPPT visit DPJP, dan alur pemulangan pasien (discharge).',
            badgeCount: _viewMode == 0
                ? filteredBeds.length
                : (_viewMode == 1 ? activeAdmissions.length : dischargedAdmissions.length),
            actionLabel: 'Admisi Pasien Baru (Check-In Ranap)',
            actionIcon: Icons.add_home_outlined,
            onActionPressed: () {
              showDialog(
                context: context,
                builder: (_) => const InpatientAdmissionDialog(),
              );
            },
            searchHint: _viewMode == 0
                ? 'Cari kamar, bed, nama pasien terisi...'
                : 'Cari nama pasien, No. RM, DPJP, No. Admisi...',
            onSearchChanged: (val) => setState(() => _searchQuery = val),
            filterWidget: Row(
              children: [
                Expanded(
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(
                        value: 0,
                        icon: Icon(Icons.grid_view_outlined),
                        label: Text('Denah Bed'),
                      ),
                      ButtonSegment(
                        value: 1,
                        icon: Icon(Icons.people_outline),
                        label: Text('Pasien Ranap'),
                      ),
                      ButtonSegment(
                        value: 2,
                        icon: Icon(Icons.history_outlined),
                        label: Text('Riwayat Pulang'),
                      ),
                    ],
                    selected: {_viewMode},
                    onSelectionChanged: (val) => setState(() => _viewMode = val.first),
                  ),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_viewMode == 0) ...[
                  // Secondary Filter Toolbar for Bed Floor Plan
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        const Text('Kelas:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _classChip('Semua Kelas', 'all'),
                                _classChip('VIP', 'VIP'),
                                _classChip('Kelas 1', 'Kelas 1'),
                                _classChip('Kelas 2', 'Kelas 2'),
                                _classChip('Kelas 3', 'Kelas 3'),
                                _classChip('ICU', 'ICU'),
                                _classChip('Isolasi', 'Isolasi'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        DropdownButton<String>(
                          value: _statusFilter,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('Semua Status Bed')),
                            DropdownMenuItem(value: 'available', child: Text('Tersedia (Kosong)')),
                            DropdownMenuItem(value: 'occupied', child: Text('Terisi Pasien')),
                            DropdownMenuItem(value: 'cleaning', child: Text('Dibersihkan / Sterilisasi')),
                          ],
                          onChanged: (v) => setState(() => _statusFilter = v ?? 'all'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Bed Visual Grid
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: filteredBeds.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: Text('Tidak ada kamar & bed yang sesuai kriteria.'),
                            ),
                          )
                        : _buildBedFloorPlanGrid(filteredBeds, admissions, wide),
                  ),
                ] else if (_viewMode == 1) ...[
                  // Active Admissions Table
                  activeAdmissions.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(
                            child: Text(
                              'Tidak ada pasien yang sedang dirawat inap aktif saat ini.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      : _buildActiveAdmissionsTable(activeAdmissions, wide),
                ] else ...[
                  // Discharged History Table
                  dischargedAdmissions.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(
                            child: Text(
                              'Belum ada riwayat pasien yang dipulangkan.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      : _buildDischargedTable(dischargedAdmissions, wide),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _classChip(String label, String value) {
    final isSelected = _classFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        selected: isSelected,
        onSelected: (sel) {
          if (sel) setState(() => _classFilter = value);
        },
      ),
    );
  }

  // ===================== KPI METRICS =====================

  Widget _buildKpiMetrics({
    required int totalBeds,
    required int occupiedBeds,
    required int availableBeds,
    required int cleaningBeds,
    required String borPercentage,
    required bool wide,
  }) {
    final cards = [
      _metricCard(
        title: 'Kapasitas Total Bed',
        value: '$totalBeds Bed',
        subtitle: 'Kamar VIP s/d Kelas 3 & ICU',
        icon: Icons.hotel_outlined,
        color: Colors.indigo,
      ),
      _metricCard(
        title: 'Bed Terisi (BOR: $borPercentage%)',
        value: '$occupiedBeds Pasien',
        subtitle: 'Pasien aktif dalam perawatan',
        icon: Icons.person_pin_outlined,
        color: Colors.blue.shade800,
      ),
      _metricCard(
        title: 'Bed Kosong (Tersedia)',
        value: '$availableBeds Bed',
        subtitle: 'Siap menerima pasien baru',
        icon: Icons.check_circle_outline,
        color: Colors.green.shade700,
      ),
      _metricCard(
        title: 'Sterilisasi & Cleaning',
        value: '$cleaningBeds Bed',
        subtitle: 'Dalam proses pembersihan',
        icon: Icons.cleaning_services_outlined,
        color: Colors.orange.shade800,
      ),
    ];

    return wide
        ? Row(
            children: cards
                .map((c) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: c,
                      ),
                    ))
                .toList(),
          )
        : Column(
            children: cards
                .map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: c,
                    ))
                .toList(),
          );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================== VISUAL BED FLOOR PLAN =====================

  Widget _buildBedFloorPlanGrid(
    List<RoomBedModel> beds,
    List<InpatientAdmissionModel> admissions,
    bool wide,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1100
            ? 3
            : (constraints.maxWidth > 700 ? 2 : 1);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 220,
          ),
          itemCount: beds.length,
          itemBuilder: (context, idx) {
            final bed = beds[idx];
            return _buildBedCard(bed, admissions);
          },
        );
      },
    );
  }

  Widget _buildBedCard(RoomBedModel bed, List<InpatientAdmissionModel> admissions) {
    Color statusBg;
    Color statusBorder;
    Color statusText;
    String statusLabel;
    IconData statusIcon;

    switch (bed.status) {
      case 'occupied':
        statusBg = Colors.blue.shade50;
        statusBorder = Colors.blue.shade300;
        statusText = Colors.blue.shade900;
        statusLabel = 'TERISI PASIEN';
        statusIcon = Icons.person;
        break;
      case 'cleaning':
        statusBg = Colors.orange.shade50;
        statusBorder = Colors.orange.shade300;
        statusText = Colors.orange.shade900;
        statusLabel = 'STERILISASI / BERSIH';
        statusIcon = Icons.cleaning_services_outlined;
        break;
      case 'maintenance':
        statusBg = Colors.red.shade50;
        statusBorder = Colors.red.shade300;
        statusText = Colors.red.shade900;
        statusLabel = 'PERBAIKAN';
        statusIcon = Icons.build_circle_outlined;
        break;
      default:
        statusBg = Colors.green.shade50;
        statusBorder = Colors.green.shade300;
        statusText = Colors.green.shade900;
        statusLabel = 'TERSEDIA (KOSONG)';
        statusIcon = Icons.check_circle_outline;
    }

    final p = bed.activePatient;
    InpatientAdmissionModel? fullAdmission;
    if (p != null) {
      fullAdmission = admissions.where((a) => a.id == p.admissionId).firstOrNull;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header: Room + Class + Bed Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${bed.roomName} (${bed.bedNumber})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${bed.roomNumber} • ${bed.classType} • ${currencyFormat.format(bed.dailyRate)}/hari',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusText, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusText,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 16),

          // Card Body: Patient Info or Empty State
          Expanded(
            child: p != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.account_circle, size: 16, color: Colors.blue),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              p.patientName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${p.daysAdmitted} Hari',
                            style: const TextStyle(
                              color: Colors.indigo,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'No. RM: ${p.patientMrn} • Penjamin: ${p.insurance}',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 11),
                      ),
                      Text(
                        'DPJP: ${p.doctorName}',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (p.initialDiagnosis != null)
                        Text(
                          'Dx: ${p.initialDiagnosis}',
                          style: TextStyle(color: Colors.teal.shade800, fontSize: 11, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  )
                : bed.status == 'cleaning'
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.cleaning_services, color: Colors.orange, size: 24),
                            const SizedBox(height: 4),
                            Text(
                              'Kamar sedang dibersihkan',
                              style: TextStyle(color: Colors.orange.shade800, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )
                    : Center(
                        child: Text(
                          'Bed siap digunakan untuk admisi pasien baru.',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                        ),
                      ),
          ),

          // Card Bottom Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (p != null && fullAdmission != null) ...[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => InpatientCPPTDialog(admissionId: p.admissionId),
                    );
                  },
                  icon: const Icon(Icons.notes, size: 14),
                  label: const Text('CPPT', style: TextStyle(fontSize: 11)),
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'Pindah Kamar / Bed',
                  icon: const Icon(Icons.swap_horiz, size: 18, color: Colors.orange),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => InpatientTransferBedDialog(admission: fullAdmission!),
                    );
                  },
                ),
                IconButton(
                  tooltip: 'Pulangkan Pasien (Discharge)',
                  icon: const Icon(Icons.output, size: 18, color: Colors.green),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => InpatientDischargeDialog(admission: fullAdmission!),
                    );
                  },
                ),
              ] else if (bed.status == 'available') ...[
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => InpatientAdmissionDialog(preselectedBed: bed),
                    );
                  },
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Admisi Masuk', style: TextStyle(fontSize: 11)),
                ),
              ] else if (bed.status == 'cleaning') ...[
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () {
                    ref.read(inpatientBedsProvider.notifier).updateBedStatus(bed.id, 'available');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Bed ${bed.bedNumber} di ${bed.roomName} kini siap digunakan!')),
                    );
                  },
                  icon: const Icon(Icons.check, size: 14),
                  label: const Text('Tandai Siap', style: TextStyle(fontSize: 11)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ===================== ACTIVE ADMISSIONS TABLE =====================

  Widget _buildActiveAdmissionsTable(List<InpatientAdmissionModel> list, bool wide) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('No. Admisi')),
          DataColumn(label: Text('Pasien')),
          DataColumn(label: Text('Kamar & Bed')),
          DataColumn(label: Text('Kelas / Tarif')),
          DataColumn(label: Text('DPJP')),
          DataColumn(label: Text('Masuk & Hari Rawat')),
          DataColumn(label: Text('Diagnosa')),
          DataColumn(label: Text('Aksi Ranap')),
        ],
        rows: list.map((a) {
          return DataRow(
            cells: [
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    a.admissionNumber,
                    style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ),
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.patientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('RM: ${a.patientMrn} • ${a.patientInsurance}', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                  ],
                ),
              ),
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.roomName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(a.bedNumber, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                  ],
                ),
              ),
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.classType, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${currencyFormat.format(a.dailyRate)}/hr', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                  ],
                ),
              ),
              DataCell(
                Text(a.doctorName, style: const TextStyle(fontSize: 12)),
              ),
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dateFormat.format(a.admissionDate), style: const TextStyle(fontSize: 11)),
                    Text('${a.totalDays} Hari Rawat', style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 11)),
                  ],
                ),
              ),
              DataCell(
                Text(
                  a.initialDiagnosis ?? '-',
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Lembar CPPT (SOAP Visite & TTV)',
                      icon: const Icon(Icons.notes, color: Colors.teal, size: 18),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => InpatientCPPTDialog(admissionId: a.id),
                        );
                      },
                    ),
                    IconButton(
                      tooltip: 'Pindah Kamar / Bed',
                      icon: const Icon(Icons.swap_horiz, color: Colors.orange, size: 18),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => InpatientTransferBedDialog(admission: a),
                        );
                      },
                    ),
                    IconButton(
                      tooltip: 'Pulangkan Pasien & Buat Tagihan Kasir',
                      icon: const Icon(Icons.output, color: Colors.green, size: 18),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => InpatientDischargeDialog(admission: a),
                        );
                      },
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

  // ===================== DISCHARGED HISTORY TABLE =====================

  Widget _buildDischargedTable(List<InpatientAdmissionModel> list, bool wide) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('No. Admisi')),
          DataColumn(label: Text('Pasien')),
          DataColumn(label: Text('Kamar Terakhir')),
          DataColumn(label: Text('Tgl Masuk - Pulang')),
          DataColumn(label: Text('Hari & Biaya Kamar')),
          DataColumn(label: Text('Kondisi Keluar')),
          DataColumn(label: Text('Diagnosa Akhir')),
          DataColumn(label: Text('Aksi')),
        ],
        rows: list.map((a) {
          return DataRow(
            cells: [
              DataCell(Text(a.admissionNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.patientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(a.patientMrn, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                  ],
                ),
              ),
              DataCell(Text('${a.roomName} (${a.bedNumber})')),
              DataCell(
                Text(
                  '${dateFormat.format(a.admissionDate)} s/d ${a.dischargeDate != null ? dateFormat.format(a.dischargeDate!) : "-"}',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${a.totalDays} Hari', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(currencyFormat.format(a.totalBedCost), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
                  ],
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    a.dischargeCondition ?? 'Sembuh',
                    style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
              ),
              DataCell(Text(a.dischargeDiagnosis ?? '-', style: const TextStyle(fontSize: 12))),
              DataCell(
                IconButton(
                  tooltip: 'Lihat Catatan CPPT',
                  icon: const Icon(Icons.history_edu, size: 18),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => InpatientCPPTDialog(admissionId: a.id),
                    );
                  },
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
