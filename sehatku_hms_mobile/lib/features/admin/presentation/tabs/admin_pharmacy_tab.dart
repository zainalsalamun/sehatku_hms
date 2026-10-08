import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/queue_voice_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/health_models.dart';
import '../../../../shared/widgets/admin_pagination_footer.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../../shared/widgets/medicine_label_print_dialog.dart';
import '../../../notification/application/notifications_provider.dart';
import '../../../pharmacy/application/pharmacy_state_providers.dart';
import '../../../queue/application/queue_display_provider.dart';
import '../../../reports/presentation/widgets/export_report_dialog.dart';

class AdminPharmacyTab extends ConsumerStatefulWidget {
  const AdminPharmacyTab({super.key});

  @override
  ConsumerState<AdminPharmacyTab> createState() => _AdminPharmacyTabState();
}

class _AdminPharmacyTabState extends ConsumerState<AdminPharmacyTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _statusFilter = 'all';
  int _currentPagePrescriptions = 1;
  int _itemsPerPagePrescriptions = 10;
  int _currentPageInventory = 1;
  int _itemsPerPageInventory = 10;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showRestockDialog(MedicineStock item) {
    final qtyCtrl = TextEditingController(text: '50');
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            'Restock ${item.name}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kategori: ${item.category} • Satuan: ${item.unit}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(
                'Stok saat ini: ${item.stock} ${item.unit}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah Penambahan Stok *',
                  suffixText: 'unit',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
                if (qty > 0) {
                  ref
                      .read(pharmacyInventoryProvider.notifier)
                      .restock(item.id, qty);
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Berhasil menambahkan $qty ${item.unit} ke stok ${item.name}.',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final prescriptions = ref.watch(pharmacyPrescriptionsProvider);
    final inventory = ref.watch(pharmacyInventoryProvider);

    final waitingCount = prescriptions
        .where((p) => p.status == 'issued')
        .length;
    final dispensingCount = prescriptions
        .where((p) => p.status == 'dispensing')
        .length;
    final readyCount = prescriptions.where((p) => p.status == 'ready').length;
    final lowStockCount = inventory.where((m) => m.status != 'normal').length;

    final filteredPrescriptions = prescriptions.where((p) {
      final q = _searchQuery.toLowerCase();
      final matchesQuery =
          p.patientName.toLowerCase().contains(q) ||
          p.patientMrn.toLowerCase().contains(q) ||
          p.prescriptionNumber.toLowerCase().contains(q) ||
          p.doctorName.toLowerCase().contains(q);
      final matchesStatus = _statusFilter == 'all' || p.status == _statusFilter;
      return matchesQuery && matchesStatus;
    }).toList();

    final filteredInventory = inventory.where((m) {
      final q = _searchQuery.toLowerCase();
      return m.name.toLowerCase().contains(q) ||
          m.category.toLowerCase().contains(q) ||
          m.batchNumber.toLowerCase().contains(q);
    }).toList();

    final totalPrescriptionPages =
        (filteredPrescriptions.length / _itemsPerPagePrescriptions).ceil().clamp(1, 9999);
    if (_currentPagePrescriptions > totalPrescriptionPages) {
      _currentPagePrescriptions = totalPrescriptionPages;
    }
    final startRxIndex =
        (_currentPagePrescriptions - 1) * _itemsPerPagePrescriptions;
    final paginatedPrescriptions = filteredPrescriptions
        .skip(startRxIndex)
        .take(_itemsPerPagePrescriptions)
        .toList();

    final totalInventoryPages =
        (filteredInventory.length / _itemsPerPageInventory).ceil().clamp(1, 9999);
    if (_currentPageInventory > totalInventoryPages) {
      _currentPageInventory = totalInventoryPages;
    }
    final startInvIndex =
        (_currentPageInventory - 1) * _itemsPerPageInventory;
    final paginatedInventory = filteredInventory
        .skip(startInvIndex)
        .take(_itemsPerPageInventory)
        .toList();

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(pharmacyPrescriptionsProvider.notifier).refresh();
        await ref.read(pharmacyInventoryProvider.notifier).refresh();
      },
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Farmasi & Instalasi Obat',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Kelola antrean peracikan resep dokter, dispensing obat, dan inventori apotek real-time.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const ExportReportDialog(initialType: ReportExportType.pharmacyStock),
                  );
                },
                icon: const Icon(Icons.download_outlined, size: 18),
                label: const Text('Export Valuasi Stok (.csv)'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
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
                childAspectRatio: 2.35,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  MetricCard(
                    label: 'Menunggu Diracik',
                    value: '$waitingCount',
                    icon: Icons.hourglass_top_outlined,
                    color: Colors.orange,
                  ),
                  MetricCard(
                    label: 'Sedang Diracik',
                    value: '$dispensingCount',
                    icon: Icons.science_outlined,
                    color: Colors.indigo,
                  ),
                  MetricCard(
                    label: 'Siap Diambil di Loket',
                    value: '$readyCount',
                    icon: Icons.task_alt_outlined,
                    color: AppTheme.success,
                  ),
                  MetricCard(
                    label: 'Peringatan Stok Obat',
                    value: '$lowStockCount',
                    icon: Icons.warning_amber_rounded,
                    color: Colors.red,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Tab Bar Selector
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: AppTheme.navy,
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade700,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(
                  icon: Icon(Icons.receipt_long_outlined, size: 18),
                  text: 'Antrean Resep & Dispensing Tracker',
                ),
                Tab(
                  icon: Icon(Icons.inventory_2_outlined, size: 18),
                  text: 'Manajemen Stok Obat & Kedaluwarsa',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Search & Filter
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  decoration: const InputDecoration(
                    hintText:
                        'Cari nomor resep, nama pasien, obat, atau dokter...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => setState(() {
                    _searchQuery = val;
                    _currentPagePrescriptions = 1;
                    _currentPageInventory = 1;
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
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
                  items: const [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text(
                        'Semua Status Resep',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'issued',
                      child: Text(
                        'Menunggu Diracik',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'dispensing',
                      child: Text(
                        'Sedang Diracik',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'ready',
                      child: Text(
                        'Siap Diambil',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'completed',
                      child: Text(
                        'Selesai Diserahkan',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _statusFilter = val;
                        _currentPagePrescriptions = 1;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tab Content Area
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              return _tabController.index == 0
                  ? _buildPrescriptionsList(
                      context,
                      paginatedPrescriptions,
                      filteredPrescriptions.length,
                    )
                  : _buildInventoryList(
                      context,
                      paginatedInventory,
                      filteredInventory.length,
                    );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionsList(
    BuildContext context,
    List<PharmacyPrescription> prescriptions,
    int totalPrescriptions,
  ) {
    if (prescriptions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: const [
              Icon(Icons.medication_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'Tidak ada resep obat dalam antrean.',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: prescriptions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final p = prescriptions[idx];

        Color badgeColor = Colors.orange;
        IconData badgeIcon = Icons.hourglass_empty;
        if (p.status == 'dispensing') {
          badgeColor = Colors.indigo;
          badgeIcon = Icons.science_outlined;
        } else if (p.status == 'ready') {
          badgeColor = Colors.teal;
          badgeIcon = Icons.task_alt;
        } else if (p.status == 'completed' || p.status == 'dispensed') {
          badgeColor = Colors.green;
          badgeIcon = Icons.check_circle;
        }

        return Card(
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: badgeColor.withValues(alpha: 0.12),
              child: Icon(badgeIcon, color: badgeColor),
            ),
            title: Row(
              children: [
                Text(
                  p.patientName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    p.patientMrn,
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: badgeColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    p.statusLabel,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Text(
              '${p.prescriptionNumber} • Penulis: ${p.doctorName} (${p.doctorSpecialist})',
            ),
            childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            children: [
              const Divider(),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Rincian Resep Obat (E-Prescription):',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(height: 8),
              ...p.items.map(
                (item) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.medication,
                        size: 16,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item.medicineName} (${item.dosage})',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'Aturan: ${item.frequency} • Durasi: ${item.durationDays} hari',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (item.instruction.isNotEmpty)
                        Text(
                          item.instruction,
                          style: const TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: Colors.teal,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.indigo.shade700,
                      side: BorderSide(color: Colors.indigo.shade200),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) =>
                            MedicineLabelPrintDialog(prescription: p),
                      );
                    },
                    icon: const Icon(Icons.print_outlined, size: 16),
                    label: const Text('Cetak Etiket Obat & Label RM'),
                  ),
                  Row(
                    children: [
                      if (p.status == 'issued')
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.indigo,
                          ),
                          onPressed: () {
                            ref
                                .read(pharmacyPrescriptionsProvider.notifier)
                                .updateStatus(p.id, 'dispensing');
                            ref.read(notificationsProvider.notifier).refresh();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Resep ${p.prescriptionNumber} mulai diracik oleh apoteker.',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.science_outlined, size: 16),
                          label: const Text('Mulai Racik Obat'),
                        )
                      else if (p.status == 'dispensing')
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.teal,
                          ),
                          onPressed: () {
                            ref
                                .read(pharmacyPrescriptionsProvider.notifier)
                                .updateStatus(p.id, 'ready');
                            ref.read(notificationsProvider.notifier).refresh();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Resep ${p.prescriptionNumber} siap diambil di loket apotek.',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.notifications_active_outlined,
                            size: 16,
                          ),
                          label: const Text('Tandai Siap di Loket'),
                        )
                      else if (p.status == 'ready') ...[
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.teal,
                            side: const BorderSide(color: Colors.teal),
                          ),
                          onPressed: () {
                            final farmasiQueue =
                                QueueVoiceService.formatFarmasiQueueNumber(
                                  p.prescriptionNumber,
                                );
                            ref
                                .read(queueDisplayProvider.notifier)
                                .callPatient(
                                  queueNumber: farmasiQueue,
                                  patientName: p.patientName,
                                  destination: 'Loket Farmasi Pengambilan Obat',
                                );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Memanggil antrean $farmasiQueue (${p.patientName}) ke Loket Farmasi...',
                                ),
                                backgroundColor: Colors.teal,
                              ),
                            );
                          },
                          icon: const Icon(Icons.volume_up_outlined, size: 16),
                          label: const Text('Panggil Suara'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          onPressed: () {
                            ref
                                .read(pharmacyPrescriptionsProvider.notifier)
                                .updateStatus(p.id, 'completed');
                            ref.read(notificationsProvider.notifier).refresh();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Resep ${p.prescriptionNumber} telah diserahkan ke ${p.patientName}. Stok obat terpotong otomatis!',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.check_circle_outline,
                            size: 16,
                          ),
                          label: const Text('Serahkan ke Pasien (Selesai)'),
                        ),
                      ] else
                        const Chip(
                          avatar: Icon(
                            Icons.check,
                            size: 14,
                            color: Colors.green,
                          ),
                          label: Text(
                            'Obat Sudah Diserahkan',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
    const SizedBox(height: 12),
    AdminPaginationFooter(
      currentPage: _currentPagePrescriptions,
      totalItems: totalPrescriptions,
      itemsPerPage: _itemsPerPagePrescriptions,
      onPageChanged: (page) =>
          setState(() => _currentPagePrescriptions = page),
      onItemsPerPageChanged: (count) => setState(() {
        _itemsPerPagePrescriptions = count;
        _currentPagePrescriptions = 1;
      }),
    ),
  ],
);
  }

  Widget _buildInventoryList(
    BuildContext context,
    List<MedicineStock> inventory,
    int totalInventory,
  ) {
    if (inventory.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: const [
              Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'Tidak ada stok obat yang sesuai filter.',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: inventory.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, idx) {
            final m = inventory[idx];
            Color statusColor = Colors.green;
            String statusLabel = 'Stok Aman';

            if (m.status == 'low') {
              statusColor = Colors.orange;
              statusLabel = 'Stok Menipis';
            } else if (m.status == 'critical') {
              statusColor = Colors.red;
              statusLabel = 'Stok Kritis';
            }

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: statusColor.withValues(alpha: 0.12),
                      child: Icon(Icons.inventory_2_outlined, color: statusColor),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                m.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: statusColor.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${m.category} • Sediaan: ${m.form} • Batch: ${m.batchNumber}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Kadaluwarsa (ED): ${m.expirationDate} • Min. Stok: ${m.minStock} ${m.unit}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${m.stock} ${m.unit}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        OutlinedButton.icon(
                          onPressed: () => _showRestockDialog(m),
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text(
                            'Restock',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        AdminPaginationFooter(
          currentPage: _currentPageInventory,
          totalItems: totalInventory,
          itemsPerPage: _itemsPerPageInventory,
          onPageChanged: (page) =>
              setState(() => _currentPageInventory = page),
          onItemsPerPageChanged: (count) => setState(() {
            _itemsPerPageInventory = count;
            _currentPageInventory = 1;
          }),
        ),
      ],
    );
  }
}
