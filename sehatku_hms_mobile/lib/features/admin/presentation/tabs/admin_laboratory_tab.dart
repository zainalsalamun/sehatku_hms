import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/health_models.dart';
import '../../../laboratory/application/laboratory_state_providers.dart';
import '../../../laboratory/presentation/widgets/lab_order_create_dialog.dart';
import '../../../laboratory/presentation/widgets/lab_result_entry_dialog.dart';
import '../../../laboratory/presentation/widgets/lab_result_print_dialog.dart';
import '../widgets/admin_table_container.dart';

class AdminLaboratoryTab extends ConsumerStatefulWidget {
  const AdminLaboratoryTab({super.key});

  @override
  ConsumerState<AdminLaboratoryTab> createState() => _AdminLaboratoryTabState();
}

class _AdminLaboratoryTabState extends ConsumerState<AdminLaboratoryTab> {
  int _viewMode = 0; // 0 = Antrean Order Lab, 1 = Katalog Parameter & Tarif Tes

  String _statusFilter = 'all';
  String _priorityFilter = 'all';
  String _categoryFilter = 'all';
  String _searchQuery = '';

  int _ordersCurrentPage = 1;
  int _ordersRowsPerPage = 10;
  int _catalogCurrentPage = 1;
  int _catalogRowsPerPage = 10;

  final List<int> _rowsPerPageOptions = [5, 10, 20, 50];

  final currencyFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(labOrdersProvider);
    final catalog = ref.watch(labCatalogProvider);

    // KPI Metrics
    final totalOrders = orders.length;
    final citoOrders = orders.where((o) => o.priority.toUpperCase().contains('CITO')).length;
    final inProgressOrders = orders.where((o) => o.status == 'ordered' || o.status == 'sample_collected' || o.status == 'in_progress').length;
    final completedOrders = orders.where((o) => o.status == 'completed').length;

    // Filtered Orders
    final filteredOrders = orders.where((o) {
      final matchStatus =
          _statusFilter == 'all' || o.status.toLowerCase() == _statusFilter.toLowerCase();
      final matchPriority =
          _priorityFilter == 'all' || o.priority.toLowerCase() == _priorityFilter.toLowerCase();
      final matchSearch = _searchQuery.isEmpty ||
          o.orderNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          o.patientName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          o.patientMrn.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          o.doctorName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (o.clinicalDiagnosis?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      return matchStatus && matchPriority && matchSearch;
    }).toList();

    // Paginate Orders
    final totalOrdersCount = filteredOrders.length;
    final totalOrdersPages = totalOrdersCount > 0 ? (totalOrdersCount / _ordersRowsPerPage).ceil() : 1;
    final safeOrdersPage = _ordersCurrentPage > totalOrdersPages ? totalOrdersPages : (_ordersCurrentPage < 1 ? 1 : _ordersCurrentPage);
    final startOrdersIndex = (safeOrdersPage - 1) * _ordersRowsPerPage;
    final endOrdersIndex = math.min(startOrdersIndex + _ordersRowsPerPage, totalOrdersCount);
    final paginatedOrders = totalOrdersCount > 0
        ? filteredOrders.sublist(startOrdersIndex, endOrdersIndex)
        : <LabOrderModel>[];

    // Filtered Catalog
    final filteredCatalog = catalog.where((c) {
      final matchCat =
          _categoryFilter == 'all' || c.category.toLowerCase() == _categoryFilter.toLowerCase();
      final matchSearch = _searchQuery.isEmpty ||
          c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.code.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCat && matchSearch;
    }).toList();

    // Paginate Catalog
    final totalCatalogCount = filteredCatalog.length;
    final totalCatalogPages = totalCatalogCount > 0 ? (totalCatalogCount / _catalogRowsPerPage).ceil() : 1;
    final safeCatalogPage = _catalogCurrentPage > totalCatalogPages ? totalCatalogPages : (_catalogCurrentPage < 1 ? 1 : _catalogCurrentPage);
    final startCatalogIndex = (safeCatalogPage - 1) * _catalogRowsPerPage;
    final endCatalogIndex = math.min(startCatalogIndex + _catalogRowsPerPage, totalCatalogCount);
    final paginatedCatalog = totalCatalogCount > 0
        ? filteredCatalog.sublist(startCatalogIndex, endCatalogIndex)
        : <LabTestCatalogModel>[];

    final wide = MediaQuery.sizeOf(context).width > 900;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // KPI Metric Cards
          _buildKpiMetrics(
            totalOrders: totalOrders,
            citoOrders: citoOrders,
            inProgressOrders: inProgressOrders,
            completedOrders: completedOrders,
            wide: wide,
          ),
          const SizedBox(height: 20),

          // Main Table Container
          AdminTableContainer(
            title: 'Instalasi Laboratorium & Diagnostik Klinis (LIS)',
            subtitle:
                'Penerimaan order pemeriksaan hematologi, kimia darah, urinalisis, & radiologi, pemrosesan sampel, entri hasil analis, dan validasi dokter penanggung jawab.',
            badgeCount: _viewMode == 0 ? filteredOrders.length : filteredCatalog.length,
            actionLabel: 'Buat Order Lab Baru',
            actionIcon: Icons.add_circle_outline,
            onActionPressed: () {
              showDialog(
                context: context,
                builder: (_) => const LabOrderCreateDialog(),
              );
            },
            searchHint: _viewMode == 0
                ? 'Cari nama pasien, No. RM, No. Order, DPJP...'
                : 'Cari nama tes, kode parameter...',
            onSearchChanged: (val) {
              setState(() {
                _searchQuery = val;
                _ordersCurrentPage = 1;
                _catalogCurrentPage = 1;
              });
            },
            filterWidget: Row(
              children: [
                Expanded(
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(
                        value: 0,
                        icon: Icon(Icons.biotech_outlined),
                        label: Text('Antrean Order Lab'),
                      ),
                      ButtonSegment(
                        value: 1,
                        icon: Icon(Icons.list_alt_outlined),
                        label: Text('Katalog & Tarif Uji'),
                      ),
                    ],
                    selected: {_viewMode},
                    onSelectionChanged: (val) {
                      setState(() {
                        _viewMode = val.first;
                        _ordersCurrentPage = 1;
                        _catalogCurrentPage = 1;
                      });
                    },
                  ),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_viewMode == 0) ...[
                  // Secondary Filter Bar for Orders
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        const Text('Prioritas:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Semua', style: TextStyle(fontSize: 11)),
                          selected: _priorityFilter == 'all',
                          onSelected: (s) => setState(() {
                            _priorityFilter = 'all';
                            _ordersCurrentPage = 1;
                          }),
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          label: const Text('CITO (Darurat)', style: TextStyle(fontSize: 11)),
                          selected: _priorityFilter == 'CITO',
                          selectedColor: Colors.red.shade100,
                          onSelected: (s) => setState(() {
                            _priorityFilter = s ? 'CITO' : 'all';
                            _ordersCurrentPage = 1;
                          }),
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          label: const Text('Normal (Rutin)', style: TextStyle(fontSize: 11)),
                          selected: _priorityFilter == 'Normal',
                          onSelected: (s) => setState(() {
                            _priorityFilter = s ? 'Normal' : 'all';
                            _ordersCurrentPage = 1;
                          }),
                        ),
                        const Spacer(),
                        DropdownButton<String>(
                          value: _statusFilter,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('Semua Status')),
                            DropdownMenuItem(value: 'ordered', child: Text('Menunggu Sampel')),
                            DropdownMenuItem(value: 'sample_collected', child: Text('Sampel Diterima')),
                            DropdownMenuItem(value: 'in_progress', child: Text('Sedang Diuji')),
                            DropdownMenuItem(value: 'completed', child: Text('Selesai & Valid')),
                          ],
                          onChanged: (v) => setState(() {
                            _statusFilter = v ?? 'all';
                            _ordersCurrentPage = 1;
                          }),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Orders Table
                  filteredOrders.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(
                            child: Text('Tidak ada order laboratorium yang sesuai kriteria.', style: TextStyle(color: Colors.grey)),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildOrdersTable(paginatedOrders, wide),
                            const Divider(height: 1),
                            _buildPaginationFooter(
                              totalItems: totalOrdersCount,
                              totalPages: totalOrdersPages,
                              currentPage: safeOrdersPage,
                              startIndex: startOrdersIndex,
                              endIndex: endOrdersIndex,
                              rowsPerPage: _ordersRowsPerPage,
                              onRowsPerPageChanged: (newRows) {
                                setState(() {
                                  _ordersRowsPerPage = newRows;
                                  _ordersCurrentPage = 1;
                                });
                              },
                              onPageChanged: (newPage) {
                                setState(() => _ordersCurrentPage = newPage);
                              },
                              itemLabel: 'order lab',
                              wide: wide,
                            ),
                          ],
                        ),
                ] else ...[
                  // Category Filter Bar for Catalog
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _catalogChip('Semua Kategori', 'all'),
                          _catalogChip('Hematologi', 'Hematologi'),
                          _catalogChip('Kimia Klinik', 'Kimia Klinik'),
                          _catalogChip('Urinalisis', 'Urinalisis'),
                          _catalogChip('Imunologi & Serologi', 'Imunologi & Serologi'),
                          _catalogChip('Radiologi', 'Radiologi'),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1),

                  // Catalog Table
                  filteredCatalog.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(
                            child: Text('Tidak ada parameter katalog tes yang sesuai.', style: TextStyle(color: Colors.grey)),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildCatalogTable(paginatedCatalog, wide),
                            const Divider(height: 1),
                            _buildPaginationFooter(
                              totalItems: totalCatalogCount,
                              totalPages: totalCatalogPages,
                              currentPage: safeCatalogPage,
                              startIndex: startCatalogIndex,
                              endIndex: endCatalogIndex,
                              rowsPerPage: _catalogRowsPerPage,
                              onRowsPerPageChanged: (newRows) {
                                setState(() {
                                  _catalogRowsPerPage = newRows;
                                  _catalogCurrentPage = 1;
                                });
                              },
                              onPageChanged: (newPage) {
                                setState(() => _catalogCurrentPage = newPage);
                              },
                              itemLabel: 'parameter tes',
                              wide: wide,
                            ),
                          ],
                        ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationFooter({
    required int totalItems,
    required int totalPages,
    required int currentPage,
    required int startIndex,
    required int endIndex,
    required int rowsPerPage,
    required ValueChanged<int> onRowsPerPageChanged,
    required ValueChanged<int> onPageChanged,
    required String itemLabel,
    required bool wide,
  }) {
    final startDisplay = totalItems == 0 ? 0 : startIndex + 1;

    final infoText = Text(
      'Menampilkan $startDisplay-$endIndex dari $totalItems $itemLabel',
      style: TextStyle(
        fontSize: 13,
        color: Colors.grey.shade700,
        fontWeight: FontWeight.w500,
      ),
    );

    final rowsPerPageSelector = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Baris per halaman:',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: rowsPerPage,
              isDense: true,
              items: _rowsPerPageOptions.map((opt) {
                return DropdownMenuItem<int>(
                  value: opt,
                  child: Text(
                    opt.toString(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (newVal) {
                if (newVal != null) {
                  onRowsPerPageChanged(newVal);
                }
              },
            ),
          ),
        ),
      ],
    );

    final pageControls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Halaman Pertama',
          icon: const Icon(Icons.first_page, size: 20),
          onPressed: currentPage > 1 ? () => onPageChanged(1) : null,
        ),
        IconButton(
          tooltip: 'Halaman Sebelumnya',
          icon: const Icon(Icons.chevron_left, size: 20),
          onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.navy.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'Halaman $currentPage / $totalPages',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.navy,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Halaman Selanjutnya',
          icon: const Icon(Icons.chevron_right, size: 20),
          onPressed: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
        ),
        IconButton(
          tooltip: 'Halaman Terakhir',
          icon: const Icon(Icons.last_page, size: 20),
          onPressed: currentPage < totalPages ? () => onPageChanged(totalPages) : null,
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: Colors.grey.shade50,
      child: wide
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                infoText,
                Row(
                  children: [
                    rowsPerPageSelector,
                    const SizedBox(width: 24),
                    pageControls,
                  ],
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    infoText,
                    rowsPerPageSelector,
                  ],
                ),
                const SizedBox(height: 12),
                Center(child: pageControls),
              ],
            ),
    );
  }

  Widget _catalogChip(String label, String value) {
    final isSelected = _categoryFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        selected: isSelected,
        onSelected: (sel) {
          if (sel) {
            setState(() {
              _categoryFilter = value;
              _catalogCurrentPage = 1;
            });
          }
        },
      ),
    );
  }

  // ===================== KPI METRICS =====================

  Widget _buildKpiMetrics({
    required int totalOrders,
    required int citoOrders,
    required int inProgressOrders,
    required int completedOrders,
    required bool wide,
  }) {
    final cards = [
      _metricCard(
        title: 'Total Order Lab',
        value: '$totalOrders Order',
        subtitle: 'Seluruh permohonan diagnostik',
        icon: Icons.biotech_outlined,
        color: Colors.purple.shade700,
      ),
      _metricCard(
        title: 'Prioritas CITO',
        value: '$citoOrders Pasien',
        subtitle: 'Hasil dibutuhkan segera',
        icon: Icons.priority_high_outlined,
        color: Colors.red.shade700,
      ),
      _metricCard(
        title: 'Dalam Pengujian',
        value: '$inProgressOrders Sampel',
        subtitle: 'Proses analis & alat lab',
        icon: Icons.science_outlined,
        color: Colors.orange.shade800,
      ),
      _metricCard(
        title: 'Selesai & Terverifikasi',
        value: '$completedOrders Hasil',
        subtitle: 'Tervalidasi Sp.PK / Dokter Lab',
        icon: Icons.check_circle_outline,
        color: Colors.teal.shade700,
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

  // ===================== ORDERS TABLE =====================

  Widget _buildOrdersTable(List<LabOrderModel> list, bool wide) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('No. Order Lab')),
          DataColumn(label: Text('Pasien')),
          DataColumn(label: Text('Prioritas')),
          DataColumn(label: Text('DPJP Pengirim')),
          DataColumn(label: Text('Item Pemeriksaan')),
          DataColumn(label: Text('Status & Biaya')),
          DataColumn(label: Text('Aksi LIS')),
        ],
        rows: list.map((order) {
          final isCito = order.priority.toUpperCase().contains('CITO');
          final isCompleted = order.status == 'completed';

          return DataRow(
            cells: [
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Text(dateFormat.format(order.createdAt), style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
                  ],
                ),
              ),
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.patientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('RM: ${order.patientMrn} • ${order.patientInsurance}', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                  ],
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isCito ? Colors.red.shade50 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isCito ? Colors.red.shade300 : Colors.blue.shade200),
                  ),
                  child: Text(
                    order.priority.toUpperCase(),
                    style: TextStyle(
                      color: isCito ? Colors.red.shade900 : Colors.blue.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.doctorName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    if (order.clinicalDiagnosis != null)
                      Text('Dx: ${order.clinicalDiagnosis}', style: TextStyle(color: Colors.teal.shade800, fontSize: 10)),
                  ],
                ),
              ),
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${order.items.length} Parameter Uji', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Text(
                      order.items.take(2).map((i) => i.testName).join(', ') + (order.items.length > 2 ? '...' : ''),
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                    ),
                  ],
                ),
              ),
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isCompleted ? Colors.green.shade50 : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isCompleted ? 'HASIL SELESAI' : (order.status == 'sample_collected' ? 'SAMPEL DITERIMA' : 'DALAM PROSES'),
                        style: TextStyle(
                          color: isCompleted ? Colors.green.shade900 : Colors.orange.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    Text(currencyFormat.format(order.totalCost), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  ],
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Entri Hasil Pengujian Analis',
                      icon: const Icon(Icons.edit_note, color: Colors.purple, size: 20),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => LabResultEntryDialog(order: order),
                        );
                      },
                    ),
                    IconButton(
                      tooltip: 'Cetak Lembar Hasil Lab (A4)',
                      icon: const Icon(Icons.print_outlined, color: Colors.teal, size: 20),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => LabResultPrintDialog(order: order),
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

  // ===================== CATALOG TABLE =====================

  Widget _buildCatalogTable(List<LabTestCatalogModel> list, bool wide) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Kode')),
          DataColumn(label: Text('Nama Pemeriksaan')),
          DataColumn(label: Text('Kategori')),
          DataColumn(label: Text('Jenis Sampel')),
          DataColumn(label: Text('Satuan')),
          DataColumn(label: Text('Nilai Rujukan Normal')),
          DataColumn(label: Text('Tarif')),
        ],
        rows: list.map((cat) {
          return DataRow(
            cells: [
              DataCell(Text(cat.code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    if (cat.description != null)
                      Text(cat.description!, style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
                  ],
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(cat.category, style: const TextStyle(fontSize: 11)),
                ),
              ),
              DataCell(Text(cat.sampleType, style: const TextStyle(fontSize: 11))),
              DataCell(Text(cat.unit ?? '-', style: const TextStyle(fontSize: 11))),
              DataCell(Text(cat.normalRangeText ?? '-', style: const TextStyle(fontSize: 11, color: Colors.grey))),
              DataCell(Text(currencyFormat.format(cat.price), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.teal))),
            ],
          );
        }).toList(),
      ),
    );
  }
}
