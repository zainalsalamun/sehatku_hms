import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../reports/application/reports_provider.dart';
import '../../../reports/presentation/widgets/export_report_dialog.dart';
import '../../../reports/presentation/widgets/morbi_lb1_table_card.dart';

class AdminReportsTab extends ConsumerWidget {
  const AdminReportsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(clinicReportsProvider);
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormat = DateFormat('EEEE, d MMMM yyyy', 'id_ID');

    if (report == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: ListView(
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Laporan Harian & Analisis Performa Klinik',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Periode: ${dateFormat.format(report.reportDate)} • Real-time database sync',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const ExportReportDialog(),
                      );
                    },
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: const Text('Export Excel / CSV'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: () {
                      ref.read(clinicReportsProvider.notifier).refresh();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Memperbarui laporan data operasional...')),
                      );
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Sinkronkan Data'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.navy,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // KPI Summary Cards
          Row(
            children: [
              Expanded(
                child: _kpiCard(
                  title: 'Total Omzet Kasir (Lunas)',
                  value: currency.format(report.totalRevenue),
                  subtitle: '${report.paidCount} transaksi berhasil',
                  icon: Icons.account_balance_wallet_outlined,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _kpiCard(
                  title: 'Tagihan Tertunda (Pending)',
                  value: currency.format(report.pendingRevenue),
                  subtitle: '${report.pendingCount} menunggu pembayaran',
                  icon: Icons.hourglass_top_outlined,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _kpiCard(
                  title: 'Rata-Rata Transaksi Pasien',
                  value: currency.format(report.averageTicket),
                  subtitle: 'Average basket size',
                  icon: Icons.receipt_long_outlined,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _kpiCard(
                  title: 'Kunjungan Pasien Selesai',
                  value: '${report.completedVisits} / ${report.totalAppointments}',
                  subtitle: 'Pemeriksaan dokter tuntas',
                  icon: Icons.people_outline,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 2 Columns: Payment Methods & Top Prescribed Medicines
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Payment Methods Breakdown
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.pie_chart_outline, color: AppTheme.primary),
                          SizedBox(width: 8),
                          Text(
                            'Distribusi Metode Pembayaran Kasir',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Pilihan channel pembayaran yang digunakan pasien di loket POS.',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                      const Divider(height: 24),
                      if (report.paymentMethods.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Belum ada data pembayaran lunas hari ini.'),
                        )
                      else
                        ...report.paymentMethods.map((pm) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      pm.method,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    Text(
                                      '${currency.format(pm.totalAmount)} (${pm.percentage}%)',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Colors.teal,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: pm.percentage / 100.0,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      pm.method.contains('QRIS')
                                          ? Colors.teal
                                          : pm.method.contains('Transfer')
                                              ? Colors.blue
                                              : Colors.orange,
                                    ),
                                    minHeight: 8,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Top Prescribed Medicines
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.medication_liquid_outlined, color: Colors.indigo),
                          SizedBox(width: 8),
                          Text(
                            'Top 5 Obat Paling Banyak Diresepkan',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Daftar item formularium farmasi klinik dengan pergerakan tercepat (fast moving).',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                      const Divider(height: 24),
                      if (report.topMedicines.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Belum ada resep obat dikeluarkan hari ini.'),
                        )
                      else
                        ...report.topMedicines.asMap().entries.map((entry) {
                          final rank = entry.key + 1;
                          final med = entry.value;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade50.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.indigo.shade100),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: rank == 1
                                      ? Colors.amber.shade700
                                      : rank == 2
                                          ? Colors.blueGrey
                                          : Colors.indigo,
                                  child: Text(
                                    '#$rank',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        med.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      Text(
                                        'Kekuatan Dosis: ${med.dosage}',
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${med.prescribedCount}x Diresepkan',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
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
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Morbi LB1 Top 10 Diseases Section
          const MorbiLB1TableCard(),
        ],
      ),
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              CircleAvatar(
                radius: 16,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
