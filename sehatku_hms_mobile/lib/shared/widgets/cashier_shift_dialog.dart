import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../features/admin/application/admin_state_providers.dart';
import '../models/health_models.dart';

class OpenCashierShiftDialog extends ConsumerStatefulWidget {
  const OpenCashierShiftDialog({super.key});

  @override
  ConsumerState<OpenCashierShiftDialog> createState() =>
      _OpenCashierShiftDialogState();
}

class _OpenCashierShiftDialogState
    extends ConsumerState<OpenCashierShiftDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cashierNameCtrl = TextEditingController(
    text: 'Siti Rahmawati (Kasir)',
  );
  final _initialCashCtrl = TextEditingController(text: '200000');
  final _notesCtrl = TextEditingController();
  String _shiftName = 'Pagi';
  bool _isLoading = false;

  @override
  void dispose() {
    _cashierNameCtrl.dispose();
    _initialCashCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.point_of_sale,
                      color: Colors.orange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Buka Shift Kasir POS',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Input modal kas awal untuk memulai transaksi',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Shift Name Selector
              DropdownButtonFormField<String>(
                initialValue: _shiftName,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Pilih Shift Operasional',
                  prefixIcon: Icon(Icons.schedule),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Pagi',
                    child: Text('Shift Pagi (08:00 - 15:00)', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: 'Siang',
                    child: Text('Shift Siang (14:00 - 21:00)', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: 'Malam',
                    child: Text('Shift Malam / Jaga (20:00 - 08:00)', overflow: TextOverflow.ellipsis),
                  ),
                ],
                onChanged: (val) => setState(() => _shiftName = val ?? 'Pagi'),
              ),
              const SizedBox(height: 14),

              // Cashier Name
              TextFormField(
                controller: _cashierNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Kasir / Petugas POS',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Nama kasir wajib diisi' : null,
              ),
              const SizedBox(height: 14),

              // Initial Cash
              TextFormField(
                controller: _initialCashCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Kas Awal / Modal Kembalian (Rp)',
                  prefixIcon: Icon(Icons.payments_outlined),
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(),
                  helperText:
                      'Uang tunai fisik yang ada di laci saat shift dimulai',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Kas awal wajib diisi';
                  if (double.tryParse(v) == null) return 'Nominal tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Notes
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Catatan Pembukaan Shift (Opsional)',
                  prefixIcon: Icon(Icons.notes),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onPressed: _isLoading
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;
                            setState(() => _isLoading = true);
                            final initialCash =
                                double.tryParse(_initialCashCtrl.text) ?? 0;
                            final success = await ref
                                .read(cashierShiftProvider.notifier)
                                .openShift(
                                  cashierId: 'c1',
                                  cashierName: _cashierNameCtrl.text.trim(),
                                  shiftName: _shiftName,
                                  initialCash: initialCash,
                                  notes: _notesCtrl.text.trim(),
                                );
                            if (mounted) {
                              setState(() => _isLoading = false);
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Shift $_shiftName berhasil dibuka dengan kas awal Rp ${NumberFormat('#,###', 'id-ID').format(initialCash)}.',
                                    ),
                                    backgroundColor: Colors.teal,
                                  ),
                                );
                                Navigator.of(context).pop();
                              }
                            }
                          },
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Buka Shift Sekarang'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CloseCashierShiftDialog extends ConsumerStatefulWidget {
  const CloseCashierShiftDialog({required this.shift, super.key});

  final CashierShiftModel shift;

  @override
  ConsumerState<CloseCashierShiftDialog> createState() =>
      _CloseCashierShiftDialogState();
}

class _CloseCashierShiftDialogState
    extends ConsumerState<CloseCashierShiftDialog> {
  final _actualCashCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Default actual cash to expected cash for fast workflow
    _actualCashCtrl.text = widget.shift.expectedCashEnd.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _actualCashCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.shift;
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final actualCash = double.tryParse(_actualCashCtrl.text) ?? 0.0;
    final discrepancy = actualCash - s.expectedCashEnd;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 580,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.lock_clock,
                      color: Colors.red,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tutup Shift & Serah Terima Kasir',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Shift ${s.shiftName} • ${s.cashierName} • Dimulai ${DateFormat('HH:mm').format(s.startTime)} WIB',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Live Summary Cards
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _recapRow(
                      'Kas Awal (Modal Kembalian)',
                      currencyFormat.format(s.initialCash),
                    ),
                    _recapRow(
                      'Penerimaan Tunai (Cash)',
                      currencyFormat.format(s.totalCashReceived),
                    ),
                    _recapRow(
                      'Penerimaan QRIS Dinamis',
                      currencyFormat.format(s.totalQrisReceived),
                    ),
                    _recapRow(
                      'Penerimaan Transfer Bank',
                      currencyFormat.format(s.totalTransferReceived),
                    ),
                    _recapRow(
                      'Penerimaan Debit / EDC',
                      currencyFormat.format(s.totalDebitReceived),
                    ),
                    const Divider(height: 16),
                    _recapRow(
                      'TOTAL PENJUALAN SHIFT',
                      currencyFormat.format(s.grandTotalSales),
                      isBold: true,
                      color: Colors.teal.shade800,
                    ),
                    _recapRow(
                      'TOTAL TRANSAKSI',
                      '${s.totalTransactions} Tagihan Lunas',
                      isBold: true,
                    ),
                    const Divider(height: 16),
                    _recapRow(
                      'ESTIMASI KAS FISIK DI LACI',
                      currencyFormat.format(s.expectedCashEnd),
                      isBold: true,
                      color: Colors.blue.shade900,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Input Actual Cash Counted
              TextFormField(
                controller: _actualCashCtrl,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Hitungan Uang Tunai Fisik di Laci (Rp)',
                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                  prefixText: 'Rp ',
                  border: const OutlineInputBorder(),
                  helperText:
                      'Hitung dan masukkan uang fisik sesungguhnya di laci kasir',
                  filled: true,
                  fillColor: Colors.amber.shade50,
                ),
              ),
              const SizedBox(height: 12),

              // Discrepancy Status Card
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: discrepancy == 0
                      ? Colors.green.shade50
                      : (discrepancy > 0
                            ? Colors.blue.shade50
                            : Colors.red.shade50),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: discrepancy == 0
                        ? Colors.green.shade300
                        : (discrepancy > 0
                              ? Colors.blue.shade300
                              : Colors.red.shade300),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          discrepancy == 0
                              ? Icons.check_circle
                              : (discrepancy > 0
                                    ? Icons.arrow_upward
                                    : Icons.warning_amber),
                          color: discrepancy == 0
                              ? Colors.green
                              : (discrepancy > 0 ? Colors.blue : Colors.red),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          discrepancy == 0
                              ? 'Status Kas: BALANCE / PAS'
                              : (discrepancy > 0
                                    ? 'Status Kas: LEBIH (Surplus)'
                                    : 'Status Kas: KURANG (Defisit)'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: discrepancy == 0
                                ? Colors.green.shade900
                                : (discrepancy > 0
                                      ? Colors.blue.shade900
                                      : Colors.red.shade900),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      currencyFormat.format(discrepancy.abs()),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: discrepancy == 0
                            ? Colors.green.shade900
                            : (discrepancy > 0
                                  ? Colors.blue.shade900
                                  : Colors.red.shade900),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Notes
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Catatan Serah Terima (Opsional)',
                  prefixIcon: Icon(Icons.notes),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onPressed: _isLoading
                        ? null
                        : () async {
                            setState(() => _isLoading = true);
                            final closedShift = await ref
                                .read(cashierShiftProvider.notifier)
                                .closeShift(
                                  actualCashCounted: actualCash,
                                  notes: _notesCtrl.text.trim(),
                                );
                            if (mounted) {
                              setState(() => _isLoading = false);
                              Navigator.of(context).pop();
                              if (closedShift != null) {
                                showDialog(
                                  context: context,
                                  builder: (_) => CashierClosingReceiptDialog(
                                    shift: closedShift,
                                  ),
                                );
                              }
                            }
                          },
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.receipt_long),
                    label: const Text('Tutup Shift & Cetak Rekap'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _recapRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black87,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class CashierClosingReceiptDialog extends StatelessWidget {
  const CashierClosingReceiptDialog({required this.shift, super.key});

  final CashierShiftModel shift;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const Text(
                'KLINIK PRATAMA SEHATKU MEDIKA',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),
              const Text(
                'LEMBAR SERAH TERIMA & TUTUP KASIR (CLOSING)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Jl. Sudirman Boulevard No. 45, Jakarta • Telp: (021) 555-8900',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
              ),
              const Divider(height: 18, thickness: 1),

              // Shift Metadata
              _infoRow('ID Shift', shift.id.substring(0, 8).toUpperCase()),
              _infoRow('Shift Operasional', shift.shiftName),
              _infoRow('Nama Kasir', shift.cashierName),
              _infoRow('Waktu Buka', dateFormat.format(shift.startTime)),
              _infoRow(
                'Waktu Tutup',
                dateFormat.format(shift.endTime ?? DateTime.now()),
              ),
              const Divider(height: 18),

              // Financial Details
              _infoRow(
                'Kas Awal (Modal)',
                currencyFormat.format(shift.initialCash),
              ),
              _infoRow(
                'Penerimaan Tunai',
                currencyFormat.format(shift.totalCashReceived),
              ),
              _infoRow(
                'Penerimaan QRIS',
                currencyFormat.format(shift.totalQrisReceived),
              ),
              _infoRow(
                'Penerimaan Transfer',
                currencyFormat.format(shift.totalTransferReceived),
              ),
              _infoRow(
                'Penerimaan Kartu Debit',
                currencyFormat.format(shift.totalDebitReceived),
              ),
              const Divider(height: 18),

              _infoRow(
                'TOTAL PENJUALAN',
                currencyFormat.format(shift.grandTotalSales),
                isBold: true,
              ),
              _infoRow(
                'TOTAL TRANSAKSI',
                '${shift.totalTransactions} Tagihan',
                isBold: true,
              ),
              const Divider(height: 18),

              _infoRow(
                'Estimasi Kas di Laci',
                currencyFormat.format(shift.expectedCashEnd),
                isBold: true,
              ),
              _infoRow(
                'Hitungan Fisik Uang Kas',
                currencyFormat.format(shift.actualCashCounted ?? 0),
                isBold: true,
              ),
              _infoRow(
                'SELISIH KAS (DISCREPANCY)',
                currencyFormat.format((shift.discrepancy ?? 0)),
                isBold: true,
                color: (shift.discrepancy ?? 0) >= 0
                    ? Colors.green.shade800
                    : Colors.red.shade800,
              ),
              const Divider(height: 22),

              // Signatures
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      const Text(
                        'Diserahkan oleh (Kasir):',
                        style: TextStyle(fontSize: 9),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        '(${shift.cashierName})',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text(
                        'Diterima oleh (Supervisor):',
                        style: TextStyle(fontSize: 9),
                      ),
                      const SizedBox(height: 40),
                      const Text(
                        '(Budi Santoso, S.E.)',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Print Button
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Mencetak Lembar Serah Terima Kasir ke Printer Thermal...',
                      ),
                      backgroundColor: Colors.teal,
                    ),
                  );
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.print),
                label: const Text('Cetak Lembar Rekap Kasir'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black87,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
