import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/queue_voice_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/health_models.dart';
import '../../../../shared/widgets/cashier_shift_dialog.dart';
import '../../../../shared/widgets/official_receipt_dialog.dart';
import '../../application/admin_state_providers.dart';
import '../../../notification/application/notifications_provider.dart';
import '../../../queue/application/queue_display_provider.dart';
import '../../../reports/presentation/widgets/export_report_dialog.dart';
import '../widgets/admin_table_container.dart';

class AdminBillingTab extends ConsumerStatefulWidget {
  const AdminBillingTab({super.key});

  @override
  ConsumerState<AdminBillingTab> createState() => _AdminBillingTabState();
}

class _AdminBillingTabState extends ConsumerState<AdminBillingTab> {
  String _searchQuery = '';
  String _statusFilter = 'all';

  static const _statusOptions = ['all', 'Menunggu', 'Lunas', 'Dibatalkan'];

  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

  String _formatCurrency(double amount) {
    return currencyFormat.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final billing = ref.watch(adminBillingProvider);
    final activeShift = ref.watch(cashierShiftProvider);

    final filteredInvoices = billing.where((inv) {
      final matchStatus = _statusFilter == 'all' || inv.status == _statusFilter;
      final matchSearch =
          _searchQuery.isEmpty ||
          inv.invoiceNumber.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          inv.patientName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          inv.paymentMethod.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchStatus && matchSearch;
    }).toList();

    final wide = MediaQuery.sizeOf(context).width > 900;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCashierShiftBanner(context, activeShift),
          const SizedBox(height: 18),
          AdminTableContainer(
            title: 'Kasir POS, Invoice & Rekonsiliasi Tagihan RS',
            subtitle:
                'Pencatatan tagihan terpadu tindakan poli + farmasi, proses kasir POS multi-kanal, dan cetak kwitansi resmi PDF.',
            badgeCount: billing.length,
            actionLabel: 'Export Rekap Kasir (.csv)',
            actionIcon: Icons.download_outlined,
            onActionPressed: () {
              showDialog(
                context: context,
                builder: (_) => const ExportReportDialog(
                  initialType: ReportExportType.financial,
                ),
              );
            },
            searchHint: 'Cari No. Invoice, nama pasien, atau metode bayar...',
            onSearchChanged: (val) => setState(() => _searchQuery = val),
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
                    st == 'all' ? 'Semua Status Bayar' : st,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _statusFilter = val);
              },
            ),
            child: filteredInvoices.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        'Tidak ada invoice yang sesuai kriteria.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : wide
                ? _buildDesktopTable(filteredInvoices)
                : _buildMobileList(filteredInvoices),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Lunas':
        return Colors.green;
      case 'Menunggu':
        return Colors.orange;
      case 'Refund':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildDesktopTable(List<Invoice> invoices) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStatePropertyAll(Colors.grey.shade50),
        columns: const [
          DataColumn(label: Text('Nomor Invoice / Waktu')),
          DataColumn(label: Text('Pasien & Dokter')),
          DataColumn(label: Text('Layanan / Tindakan')),
          DataColumn(label: Text('Total Tagihan')),
          DataColumn(label: Text('Metode Pembayaran')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Aksi & Kwitansi')),
        ],
        rows: invoices.map((inv) {
          final color = _getStatusColor(inv.status);

          return DataRow(
            cells: [
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      inv.invoiceNumber,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${inv.createdAt.day}/${inv.createdAt.month}/${inv.createdAt.year} ${inv.createdAt.hour}:${inv.createdAt.minute.toString().padLeft(2, "0")}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      inv.patientName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      inv.doctorName,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              DataCell(
                Text(inv.serviceName, style: const TextStyle(fontSize: 12)),
              ),
              DataCell(
                Text(
                  _formatCurrency(inv.amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.navy,
                  ),
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    inv.paymentMethod,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.blueGrey.shade900,
                    ),
                  ),
                ),
              ),
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
                    inv.status,
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
                    if (inv.status == 'Menunggu') ...[
                      IconButton(
                        icon: const Icon(
                          Icons.volume_up_outlined,
                          size: 18,
                          color: Colors.teal,
                        ),
                        tooltip: 'Panggil Suara ke Kasir',
                        onPressed: () {
                          final kasirQueue =
                              QueueVoiceService.formatKasirQueueNumber(
                                inv.invoiceNumber,
                              );
                          ref
                              .read(queueDisplayProvider.notifier)
                              .callPatient(
                                queueNumber: kasirQueue,
                                patientName: inv.patientName,
                                destination: 'Loket Pembayaran dan Kasir',
                              );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Memanggil antrean $kasirQueue (${inv.patientName}) ke Loket Kasir...',
                              ),
                              backgroundColor: Colors.teal,
                            ),
                          );
                        },
                      ),
                      FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => _showCashierPOSDialog(context, inv),
                        icon: const Icon(Icons.point_of_sale, size: 14),
                        label: const Text(
                          'Kasir POS',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(
                        Icons.receipt_long,
                        size: 20,
                        color: AppTheme.primary,
                      ),
                      tooltip: 'Cetak Kwitansi Resmi PDF',
                      onPressed: () => showOfficialReceiptDialog(context, inv),
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

  Widget _buildMobileList(List<Invoice> invoices) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: invoices.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final inv = invoices[index];
        final color = _getStatusColor(inv.status);

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          title: Text(
            '${inv.invoiceNumber} • ${inv.patientName}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${inv.serviceName} • ${_formatCurrency(inv.amount)}\n${inv.paymentMethod}',
            style: const TextStyle(fontSize: 12),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  inv.status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.receipt_long, color: AppTheme.primary),
                tooltip: 'Cetak Kwitansi',
                onPressed: () => showOfficialReceiptDialog(context, inv),
              ),
            ],
          ),
          onTap: inv.status == 'Menunggu'
              ? () => _showCashierPOSDialog(context, inv)
              : () => showOfficialReceiptDialog(context, inv),
        );
      },
    );
  }

  void _showCashierPOSDialog(BuildContext context, Invoice invoice) {
    String selectedMethod = 'QRIS Dinamis';
    final cashController = TextEditingController();
    double changeAmount = 0;

    final methods = [
      {'key': 'QRIS Dinamis', 'icon': Icons.qr_code},
      {'key': 'Tunai', 'icon': Icons.money},
      {'key': 'Kartu Debit', 'icon': Icons.credit_card},
      {'key': 'Transfer Bank', 'icon': Icons.account_balance},
      {'key': 'BPJS Kesehatan', 'icon': Icons.shield},
    ];

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                const Icon(Icons.point_of_sale, color: AppTheme.primary),
                const SizedBox(width: 10),
                const Text('Pelunasan Kasir POS'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.navy.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No. Invoice: ${invoice.invoiceNumber}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Pasien: ${invoice.patientName} (${invoice.doctorName})',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Tagihan:',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              _formatCurrency(invoice.amount),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: AppTheme.navy,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pilih Metode Pembayaran:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: methods.map((m) {
                      final isSelected = selectedMethod == m['key'];
                      return ChoiceChip(
                        avatar: Icon(
                          m['icon'] as IconData,
                          size: 16,
                          color: isSelected ? Colors.white : AppTheme.primary,
                        ),
                        label: Text(m['key'] as String),
                        selected: isSelected,
                        selectedColor: AppTheme.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 11,
                        ),
                        onSelected: (_) {
                          setDialogState(
                            () => selectedMethod = m['key'] as String,
                          );
                        },
                      );
                    }).toList(),
                  ),
                  if (selectedMethod == 'Tunai') ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: cashController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Uang Diterima Kasir (Rp)',
                        hintText: 'Misal: 400000',
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) {
                        final received = double.tryParse(val) ?? 0;
                        setDialogState(() {
                          changeAmount = (received - invoice.amount).clamp(
                            0,
                            double.infinity,
                          );
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Kembalian Pasien:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _formatCurrency(changeAmount),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade900,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Batal'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.success,
                ),
                onPressed: () async {
                  await ref
                      .read(adminBillingProvider.notifier)
                      .payInvoice(
                        invoice.id,
                        paymentMethod: selectedMethod,
                        cashierName: 'Kasir Utama - Siti Rahma',
                      );
                  ref.read(notificationsProvider.notifier).refresh();
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Pembayaran ${invoice.invoiceNumber} berhasil diselesaikan via $selectedMethod.',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                icon: const Icon(Icons.check),
                label: const Text('Selesaikan Pelunasan'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCashierShiftBanner(
    BuildContext context,
    CashierShiftModel? shift,
  ) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    if (shift == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.orange.shade300, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.point_of_sale,
                color: Colors.orangeAccent,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Shift Kasir Saat Ini: BELUM DIBUKA',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Buka shift kasir terlebih dahulu untuk mencatat uang modal kembalian & rekonsiliasi kas harian.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const OpenCashierShiftDialog(),
                );
              },
              icon: const Icon(Icons.lock_open, size: 18),
              label: const Text(
                'Buka Shift Kasir POS',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    final startTimeStr = DateFormat('HH:mm').format(shift.startTime);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF064E3B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.tealAccent.shade400, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.tealAccent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: Colors.tealAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.tealAccent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'SHIFT ${shift.shiftName.toUpperCase()} AKTIF',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Kasir: ${shift.cashierName}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Mulai: $startTimeStr WIB • Kas Awal: ${currencyFormat.format(shift.initialCash)} • Transaksi: ${shift.totalTransactions} • Total Penjualan: ${currencyFormat.format(shift.grandTotalSales)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => CloseCashierShiftDialog(shift: shift),
              );
            },
            icon: const Icon(Icons.lock_clock, size: 18),
            label: const Text(
              'Tutup Shift & Rekap Kas',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
