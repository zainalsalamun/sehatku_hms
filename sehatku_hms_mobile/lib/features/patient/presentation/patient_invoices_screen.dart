import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/models/health_models.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/official_receipt_dialog.dart';
import '../../admin/application/admin_state_providers.dart';
import '../../appointment/presentation/payment_checkout_sheet.dart';
import '../../authentication/application/auth_controller.dart';

class PatientInvoicesScreen extends ConsumerStatefulWidget {
  const PatientInvoicesScreen({super.key});

  @override
  ConsumerState<PatientInvoicesScreen> createState() =>
      _PatientInvoicesScreenState();
}

class _PatientInvoicesScreenState extends ConsumerState<PatientInvoicesScreen> {
  String _selectedFilter = 'all'; // 'all', 'unpaid', 'paid'
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final allInvoices = ref.watch(adminBillingProvider);
    final patients = ref.watch(adminPatientsProvider);

    final patientName = auth.userFullName?.trim().isNotEmpty == true
        ? auth.userFullName!
        : (auth.email != null && auth.email!.isNotEmpty
            ? auth.email!.split('@').first
            : 'Pasien');
    final matchedPatient = patients
        .where((p) => p.name == patientName || p.id == auth.patientId)
        .firstOrNull;
    final mrn =
        matchedPatient?.medicalRecordNumber ?? auth.patientMrn ?? 'MRN-2026-001';

    // Filter invoices belonging to this patient
    final patientFirst = patientName.toLowerCase().split(' ').first;
    final patientInvoices = allInvoices.where((inv) {
      if (inv.patientMrn.isNotEmpty && inv.patientMrn == mrn) return true;
      if (inv.patientName.toLowerCase().contains(patientFirst) ||
          patientName.toLowerCase().contains(inv.patientName.toLowerCase())) {
        return true;
      }
      return false;
    }).toList();

    // In case no matches specifically for mock testing, fall back to all
    final displayInvoices =
        patientInvoices.isNotEmpty ? patientInvoices : allInvoices;

    // Filter by tab
    final filtered = displayInvoices.where((inv) {
      final matchesSearch = _searchQuery.isEmpty ||
          inv.invoiceNumber
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          inv.serviceName.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;

      if (_selectedFilter == 'unpaid') return inv.status == 'Menunggu';
      if (_selectedFilter == 'paid') return inv.status == 'Lunas';
      return true;
    }).toList();

    // Metrics calculations
    final paidInvoices =
        displayInvoices.where((i) => i.status == 'Lunas').toList();
    final unpaidInvoices =
        displayInvoices.where((i) => i.status == 'Menunggu').toList();
    final totalPaid =
        paidInvoices.fold<double>(0, (sum, i) => sum + i.amount);
    final totalUnpaid =
        unpaidInvoices.fold<double>(0, (sum, i) => sum + i.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tagihan & Pembayaran Saya',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(adminBillingProvider.notifier).refresh();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Patient Identification Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: AppTheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patientName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppTheme.navy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'No. Rekam Medis: $mrn • Pasien Terdaftar',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Summary Metrics
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: Colors.green.shade700,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Tagihan Lunas',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          CurrencyFormatter.format(totalPaid),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.green.shade900,
                          ),
                        ),
                        Text(
                          '${paidInvoices.length} transaksi selesai',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.hourglass_bottom,
                              color: Colors.orange.shade800,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Menunggu Bayar',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          CurrencyFormatter.format(totalUnpaid),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.orange.shade900,
                          ),
                        ),
                        Text(
                          '${unpaidInvoices.length} tagihan aktif',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search Bar & Filter Chips
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nomor faktur atau layanan...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
            const SizedBox(height: 12),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text('Semua (${displayInvoices.length})'),
                    selected: _selectedFilter == 'all',
                    onSelected: (_) =>
                        setState(() => _selectedFilter = 'all'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text('Menunggu Bayar (${unpaidInvoices.length})'),
                    selected: _selectedFilter == 'unpaid',
                    onSelected: (_) =>
                        setState(() => _selectedFilter = 'unpaid'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text('Lunas (${paidInvoices.length})'),
                    selected: _selectedFilter == 'paid',
                    onSelected: (_) =>
                        setState(() => _selectedFilter = 'paid'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // List of Invoices
            if (filtered.isEmpty)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Tidak Ada Tagihan Ditemukan',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.navy,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Belum ada tagihan pada filter ini. Transaksi dan pembayaran baru akan muncul di sini.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ...filtered.map((inv) => _buildInvoiceCard(context, inv)),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(BuildContext context, Invoice inv) {
    final isPaid = inv.status == 'Lunas';
    final dateStr =
        DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(inv.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isPaid ? Colors.grey.shade200 : Colors.orange.shade300,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Invoice Number, Date, Status Pill
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isPaid
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPaid ? Icons.check_circle : Icons.pending,
                    size: 18,
                    color: isPaid ? Colors.green.shade700 : Colors.orange.shade800,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inv.invoiceNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPaid
                        ? Colors.green.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isPaid
                          ? Colors.green.shade200
                          : Colors.orange.shade300,
                    ),
                  ),
                  child: Text(
                    isPaid ? 'LUNAS' : 'MENUNGGU',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isPaid
                          ? Colors.green.shade900
                          : Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // Service details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inv.serviceName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pasien: ${inv.patientName} (${inv.patientMrn.isNotEmpty ? inv.patientMrn : "-"})',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      if (inv.paymentMethod.isNotEmpty && isPaid) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Metode Pembayaran: ${inv.paymentMethod}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Total Biaya',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(inv.amount),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: isPaid ? AppTheme.navy : Colors.orange.shade900,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            if (inv.items.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rincian Komponen Tagihan:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...inv.items.take(3).map(
                          (item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.quantity}x ${item.name}',
                                    style: const TextStyle(fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.format(item.subtotal),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    if (inv.items.length > 3)
                      Text(
                        '+ ${inv.items.length - 3} item lainnya...',
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => showOfficialReceiptDialog(context, inv),
                    icon: const Icon(Icons.receipt_long, size: 18),
                    label: const Text('Kwitansi Resmi'),
                  ),
                ),
                if (!isPaid) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => PaymentCheckoutSheet(
                            doctorName: inv.serviceName,
                            departmentName: 'Kasir POS SehatKu',
                            amount: inv.amount,
                            onPaymentSuccess: () async {
                              await ref
                                  .read(adminBillingProvider.notifier)
                                  .payInvoice(
                                    inv.id,
                                    paymentMethod: 'QRIS Dinamis',
                                  );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Pembayaran tagihan ${inv.invoiceNumber} sebesar ${CurrencyFormatter.format(inv.amount)} berhasil.',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                          ),
                        );
                      },
                      icon: const Icon(Icons.qr_code_scanner, size: 18),
                      label: const Text('Bayar Sekarang'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
