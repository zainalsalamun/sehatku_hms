import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/health_models.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../application/admin_state_providers.dart';

class AdminOverviewTab extends ConsumerWidget {
  const AdminOverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctors = ref.watch(adminDoctorsProvider);
    final patients = ref.watch(adminPatientsProvider);
    final appointments = ref.watch(adminAppointmentsProvider);
    final billing = ref.watch(adminBillingProvider);

    final totalIncome = billing
        .where((b) => b.status == 'Lunas')
        .fold<double>(0, (sum, b) => sum + b.amount);

    final compact = MediaQuery.sizeOf(context).width < 600;

    return SingleChildScrollView(
      padding: EdgeInsets.all(compact ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Hospital Overview',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ringkasan operasional harian terintegrasi, real-time metrics, dan log audit.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 22),

          // KPI Cards Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 1000
                  ? 4
                  : constraints.maxWidth > 560
                  ? 2
                  : 1;
              return GridView.count(
                crossAxisCount: columns,
                childAspectRatio: columns == 1 ? 3.8 : 2.35,
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
                    label: 'Dokter Aktif',
                    value: '${doctors.where((d) => d.isActive).length}',
                    icon: Icons.medical_services_outlined,
                    color: Colors.indigo,
                  ),
                  MetricCard(
                    label: 'Reservasi Hari Ini',
                    value: '${appointments.length}',
                    icon: Icons.calendar_month,
                    color: Colors.orange,
                  ),
                  MetricCard(
                    label: 'Pendapatan Lunas',
                    value:
                        'Rp ${(totalIncome / 1000000).toStringAsFixed(1)} jt',
                    icon: Icons.trending_up,
                    color: AppTheme.success,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Visitor Analytics & Today's Appointments Row
          LayoutBuilder(
            builder: (context, constraints) {
              final cards = [
                _analyticsCard(context),
                _recentAppointmentsCard(context, appointments),
              ];
              return constraints.maxWidth > 850
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: cards[0]),
                        const SizedBox(width: 16),
                        Expanded(flex: 2, child: cards[1]),
                      ],
                    )
                  : Column(
                      children: [
                        cards[0],
                        const SizedBox(height: 16),
                        cards[1],
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }

  Widget _analyticsCard(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kunjungan Pasien',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Text(
            'Tren 7 hari terakhir (Poli Umum vs Spesialis)',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                _Bar(label: 'Sen', value: 0.72),
                _Bar(label: 'Sel', value: 0.88),
                _Bar(label: 'Rab', value: 0.65),
                _Bar(label: 'Kam', value: 0.94),
                _Bar(label: 'Jum', value: 0.82),
                _Bar(label: 'Sab', value: 0.58),
                _Bar(label: 'Min', value: 0.35),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _recentAppointmentsCard(
    BuildContext context,
    List<Appointment> appointments,
  ) => Card(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Antrean Berjalan',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const Icon(Icons.sync, size: 20, color: Colors.grey),
            ],
          ),
          const Text(
            'Status antrean poli aktif',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          if (appointments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Belum ada antrean aktif.',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            ),
          ...appointments.take(3).map((a) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.patientName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${a.doctorName} • ${a.time}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: a.status == 'Checked-in'
                            ? Colors.green.shade50
                            : Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        a.status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: a.status == 'Checked-in'
                              ? Colors.green.shade800
                              : Colors.amber.shade900,
                        ),
                      ),
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

class _Bar extends StatelessWidget {
  const _Bar({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: value.clamp(0.05, 1.0),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.navy,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
