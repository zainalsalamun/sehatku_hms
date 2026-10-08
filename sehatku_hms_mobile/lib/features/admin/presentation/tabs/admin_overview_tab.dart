import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/queue_voice_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/health_models.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../inpatient/application/inpatient_state_providers.dart';
import '../../../laboratory/application/laboratory_state_providers.dart';
import '../../../pharmacy/application/pharmacy_state_providers.dart';
import '../../../queue/application/queue_display_provider.dart';
import '../../../queue/presentation/queue_tv_display_screen.dart';
import '../../application/admin_state_providers.dart';

class AdminOverviewTab extends ConsumerStatefulWidget {
  const AdminOverviewTab({super.key});

  @override
  ConsumerState<AdminOverviewTab> createState() => _AdminOverviewTabState();
}

class _AdminOverviewTabState extends ConsumerState<AdminOverviewTab> {
  String _selectedDeptFilter = 'all';
  String _selectedStatusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // Watch all operational state providers
    final doctors = ref.watch(adminDoctorsProvider);
    final patients = ref.watch(adminPatientsProvider);
    final appointments = ref.watch(adminAppointmentsProvider);
    final billing = ref.watch(adminBillingProvider);
    final departments = ref.watch(adminDepartmentsProvider);
    final beds = ref.watch(inpatientBedsProvider);
    final prescriptions = ref.watch(pharmacyPrescriptionsProvider);
    final labOrders = ref.watch(labOrdersProvider);
    final currentShift = ref.watch(cashierShiftProvider);
    final auditLogs = ref.watch(adminAuditLogsProvider);

    // Inpatient & BOR Calculations
    final totalBeds = beds.length;
    final occupiedBeds = beds.where((b) => !b.isAvailable).length;
    final availableBeds = totalBeds - occupiedBeds;
    final borPercentage = totalBeds > 0
        ? ((occupiedBeds / totalBeds) * 100).round()
        : 0;

    // Financial Metrics
    final totalIncome = billing
        .where((b) => b.status == 'Lunas')
        .fold<double>(0, (sum, b) => sum + b.amount);
    final pendingIncome = billing
        .where((b) => b.status == 'Menunggu')
        .fold<double>(0, (sum, b) => sum + b.amount);

    // Queue Metrics
    final waitingAppointments =
        appointments.where((a) => a.status == 'Menunggu').toList();
    final checkedInAppointments =
        appointments.where((a) => a.status == 'Checked-in').toList();
    final completedAppointments =
        appointments.where((a) => a.status == 'Selesai').toList();

    // Pharmacy & Lab Metrics
    final pendingRx =
        prescriptions.where((p) => p.status == 'issued' || p.status == 'dispensing').length;
    final readyRx = prescriptions.where((p) => p.status == 'ready').length;
    final pendingLab = labOrders.where((l) => l.status != 'completed').length;

    // Filtered Appointments for Live Queue Monitoring
    final filteredAppointments = appointments.where((a) {
      final matchDept = _selectedDeptFilter == 'all' ||
          a.department.toLowerCase().contains(_selectedDeptFilter.toLowerCase());
      final matchStatus =
          _selectedStatusFilter == 'all' || a.status == _selectedStatusFilter;
      return matchDept && matchStatus;
    }).toList();

    final isNarrow = MediaQuery.sizeOf(context).width < 800;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isNarrow ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header & Quick Action Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hospital Command Center & Overview',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: isNarrow ? 20 : 26,
                          ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Monitoring operasional terintegrasi: antrean poli, kapasitas rawat inap, farmasi, kasir, dan audit trail.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.navy,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const QueueTvDisplayScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.tv, size: 18),
                label: const Text('Layar TV Antrean'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 1. TOP EXECUTIVE KPI CARDS (6 Metrics Grid)
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 1100
                  ? 6
                  : constraints.maxWidth > 700
                      ? 3
                      : 2;
              return GridView.count(
                crossAxisCount: columns,
                childAspectRatio: columns >= 3 ? 1.9 : 1.6,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  MetricCard(
                    label: 'Pasien Terdaftar',
                    value: '${patients.length}',
                    icon: Icons.people_outline,
                  ),
                  MetricCard(
                    label: 'Dokter DPJP Aktif',
                    value: '${doctors.where((d) => d.isActive).length}',
                    icon: Icons.medical_services_outlined,
                    color: Colors.indigo,
                  ),
                  MetricCard(
                    label: 'Antrean Hari Ini',
                    value: '${appointments.length}',
                    icon: Icons.confirmation_number_outlined,
                    color: Colors.orange,
                  ),
                  MetricCard(
                    label: 'Kapasitas BOR Ranap',
                    value: '$borPercentage%',
                    icon: Icons.single_bed_outlined,
                    color: borPercentage > 85 ? Colors.red : Colors.teal,
                  ),
                  MetricCard(
                    label: 'Resep Farmasi Aktif',
                    value: '$pendingRx',
                    icon: Icons.medication_outlined,
                    color: Colors.purple,
                  ),
                  MetricCard(
                    label: 'Pendapatan Lunas',
                    value: 'Rp ${(totalIncome / 1000000).toStringAsFixed(1)} jt',
                    icon: Icons.trending_up,
                    color: AppTheme.success,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // 2. LIVE QUEUE & POLYCLINIC MONITORING SECTION
          _buildLiveQueueMonitorSection(
            context: context,
            departments: departments,
            filteredAppointments: filteredAppointments,
            waitingCount: waitingAppointments.length,
            checkedInCount: checkedInAppointments.length,
            completedCount: completedAppointments.length,
            totalCount: appointments.length,
          ),
          const SizedBox(height: 24),

          // 3. INPATIENT / BOR & PHARMACY/LAB MONITORING ROW
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              final borCard = _buildInpatientBORCard(
                context: context,
                totalBeds: totalBeds,
                occupiedBeds: occupiedBeds,
                availableBeds: availableBeds,
                borPercentage: borPercentage,
                beds: beds,
              );
              final pharmacyLabCard = _buildPharmacyAndLabCard(
                context: context,
                pendingRx: pendingRx,
                readyRx: readyRx,
                pendingLab: pendingLab,
                currencyFormat: currencyFormat,
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: borCard),
                    const SizedBox(width: 16),
                    Expanded(flex: 3, child: pharmacyLabCard),
                  ],
                );
              }
              return Column(
                children: [
                  borCard,
                  const SizedBox(height: 16),
                  pharmacyLabCard,
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // 4. CASHIER SHIFT & REAL-TIME AUDIT LOGS ROW
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              final cashierCard = _buildCashierShiftOverviewCard(
                context: context,
                currentShift: currentShift,
                totalIncome: totalIncome,
                pendingIncome: pendingIncome,
                billing: billing,
                currencyFormat: currencyFormat,
              );
              final auditCard = _buildRecentAuditLogsCard(
                context: context,
                auditLogs: auditLogs,
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: cashierCard),
                    const SizedBox(width: 16),
                    Expanded(flex: 3, child: auditCard),
                  ],
                );
              }
              return Column(
                children: [
                  cashierCard,
                  const SizedBox(height: 16),
                  auditCard,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ===================== WIDGET: LIVE QUEUE MONITORING SECTION =====================

  Widget _buildLiveQueueMonitorSection({
    required BuildContext context,
    required List<Department> departments,
    required List<Appointment> filteredAppointments,
    required int waitingCount,
    required int checkedInCount,
    required int completedCount,
    required int totalCount,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title & Status Summary Badges
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.hub_outlined, color: Colors.orange, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monitoring Antrean Poliklinik & Pasien Real-Time',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'Pantau status antrean aktif, panggil suara pasien, dan kelola alur poliklinik.',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => ref.read(adminAppointmentsProvider.notifier).refresh(),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Queue Status Summary Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _statusFilterChip('Semua Antrean ($totalCount)', 'all', Colors.grey),
                  const SizedBox(width: 8),
                  _statusFilterChip('Menunggu ($waitingCount)', 'Menunggu', Colors.amber.shade800),
                  const SizedBox(width: 8),
                  _statusFilterChip('Checked-in ($checkedInCount)', 'Checked-in', Colors.indigo),
                  const SizedBox(width: 8),
                  _statusFilterChip('Selesai ($completedCount)', 'Selesai', Colors.green),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Department Filters Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.all_inclusive, size: 14),
                    label: const Text('Semua Poli', style: TextStyle(fontSize: 12)),
                    backgroundColor: _selectedDeptFilter == 'all'
                        ? AppTheme.navy.withValues(alpha: 0.15)
                        : null,
                    side: BorderSide(
                      color: _selectedDeptFilter == 'all' ? AppTheme.navy : Colors.grey.shade300,
                    ),
                    onPressed: () => setState(() => _selectedDeptFilter = 'all'),
                  ),
                  const SizedBox(width: 6),
                  ...departments.map((dept) {
                    final isSelected = _selectedDeptFilter == dept.name;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        label: Text(dept.name, style: const TextStyle(fontSize: 12)),
                        backgroundColor:
                            isSelected ? Colors.indigo.withValues(alpha: 0.15) : null,
                        side: BorderSide(
                          color: isSelected ? Colors.indigo : Colors.grey.shade300,
                        ),
                        onPressed: () => setState(() => _selectedDeptFilter = dept.name),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const Divider(height: 24),

            // Live Queue Table / List
            if (filteredAppointments.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: const [
                      Icon(Icons.event_available_outlined, size: 44, color: Colors.grey),
                      SizedBox(height: 10),
                      Text(
                        'Tidak ada antrean yang sesuai filter saat ini.',
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredAppointments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final appt = filteredAppointments[index];
                  Color statusColor = Colors.amber.shade800;
                  if (appt.status == 'Checked-in') statusColor = Colors.indigo;
                  if (appt.status == 'Selesai') statusColor = Colors.green;
                  if (appt.status == 'Dibatalkan') statusColor = Colors.red;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        // Queue Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.navy,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            appt.queueNumber,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Patient & Doctor Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appt.patientName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${appt.department} • ${appt.doctorName} • ${appt.time}',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            appt.status,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Quick Call Audio Button
                        IconButton(
                          tooltip: 'Panggil Suara Pasien',
                          icon: const Icon(Icons.volume_up, color: Colors.teal),
                          onPressed: () {
                            QueueVoiceService.callPatient(
                              queueNumber: appt.queueNumber,
                              destination: appt.department,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Memanggil suara antrean ${appt.queueNumber} (${appt.patientName}) ke ${appt.department}...',
                                ),
                                backgroundColor: Colors.teal,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusFilterChip(String label, String status, Color color) {
    final isSelected = _selectedStatusFilter == status;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      selectedColor: color.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) => setState(() => _selectedStatusFilter = status),
    );
  }

  // ===================== WIDGET: INPATIENT & BOR MONITORING =====================

  Widget _buildInpatientBORCard({
    required BuildContext context,
    required int totalBeds,
    required int occupiedBeds,
    required int availableBeds,
    required int borPercentage,
    required List<RoomBedModel> beds,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.hotel_outlined, color: Colors.teal, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kapasitas Rawat Inap & BOR',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'Bed Occupancy Rate & Ketersediaan Tempat Tidur',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (borPercentage > 85 ? Colors.red : Colors.teal).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'BOR: $borPercentage%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: borPercentage > 85 ? Colors.red : Colors.teal,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Progress Bar BOR
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: totalBeds > 0 ? (occupiedBeds / totalBeds).clamp(0.0, 1.0) : 0,
                minHeight: 12,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  borPercentage > 85 ? Colors.red : Colors.teal,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Summary Stats (Total, Terisi, Kosong)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _miniStat('Total Bed', '$totalBeds Bed', Colors.black87),
                _miniStat('Terisi (Occupied)', '$occupiedBeds Bed', Colors.indigo),
                _miniStat('Tersedia (Ready)', '$availableBeds Bed', Colors.green),
              ],
            ),
            const Divider(height: 24),

            // Class Breakdown Chips
            const Text(
              'Ketersediaan Kamar per Kelas:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: ['VVIP', 'VIP', 'Kelas 1', 'Kelas 2', 'Kelas 3', 'ICU'].map((cls) {
                final classBeds = beds.where((b) => b.classType == cls).toList();
                final ready = classBeds.where((b) => b.isAvailable).length;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    '$cls: $ready/${classBeds.length} Kosong',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== WIDGET: PHARMACY & LAB STATUS =====================

  Widget _buildPharmacyAndLabCard({
    required BuildContext context,
    required int pendingRx,
    required int readyRx,
    required int pendingLab,
    required NumberFormat currencyFormat,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.science_outlined, color: Colors.purple, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Instalasi Farmasi & Laboratorium',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'Monitoring peracikan e-resep & uji sampel diagnostik',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Pharmacy Status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.purple.shade100),
              ),
              child: Row(
                children: [
                  const Icon(Icons.medication, color: Colors.purple, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Antrean Resep Obat Apotek',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          '$pendingRx resep dalam proses racik • $readyRx resep siap diambil',
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    backgroundColor: Colors.purple.shade100,
                    label: Text(
                      '$pendingRx Aktif',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade900,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Laboratory Status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.shade50.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.teal.shade100),
              ),
              child: Row(
                children: [
                  const Icon(Icons.biotech, color: Colors.teal, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order Laboratorium & Diagnostik',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          '$pendingLab order pemeriksaan sedang berjalan',
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    backgroundColor: Colors.teal.shade100,
                    label: Text(
                      '$pendingLab Order',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade900,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== WIDGET: CASHIER SHIFT OVERVIEW =====================

  Widget _buildCashierShiftOverviewCard({
    required BuildContext context,
    required CashierShiftModel? currentShift,
    required double totalIncome,
    required double pendingIncome,
    required List<Invoice> billing,
    required NumberFormat currencyFormat,
  }) {
    final isShiftOpen = currentShift != null;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.point_of_sale_outlined, color: Colors.green, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shift Kasir POS & Penerimaan',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        isShiftOpen
                            ? 'Shift ${currentShift.shiftName} aktif (${currentShift.cashierName})'
                            : 'Belum ada shift kasir yang dibuka',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isShiftOpen ? Colors.green : Colors.grey).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isShiftOpen ? 'Shift Buka' : 'Shift Tutup',
                    style: TextStyle(
                      color: isShiftOpen ? Colors.green.shade800 : Colors.grey.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Financial Summary Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _miniStat('Penerimaan Lunas', currencyFormat.format(totalIncome), Colors.green),
                _miniStat('Tagihan Tertunda', currencyFormat.format(pendingIncome), Colors.orange.shade800),
                _miniStat('Total Transaksi', '${billing.length} Invoice', Colors.black87),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===================== WIDGET: RECENT AUDIT LOGS =====================

  Widget _buildRecentAuditLogsCard({
    required BuildContext context,
    required List<AuditLog> auditLogs,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.history_toggle_off, color: Colors.indigo, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aktivitas Sistem & Audit Trail',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'Log transaksi dan rekam medis real-time',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (auditLogs.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: Text('Belum ada log audit tercatat.', style: TextStyle(color: Colors.grey))),
              )
            else
              ...auditLogs.take(3).map((log) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_outline, size: 16, color: Colors.indigo.shade400),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          log.details,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}
