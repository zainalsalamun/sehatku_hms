import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';

class PaymentCheckoutSheet extends StatefulWidget {
  const PaymentCheckoutSheet({
    super.key,
    required this.doctorName,
    required this.departmentName,
    required this.amount,
    required this.onPaymentSuccess,
  });

  final String doctorName;
  final String departmentName;
  final double amount;
  final VoidCallback onPaymentSuccess;

  @override
  State<PaymentCheckoutSheet> createState() => _PaymentCheckoutSheetState();
}

class _PaymentCheckoutSheetState extends State<PaymentCheckoutSheet> {
  String _selectedMethod = 'QRIS';
  bool _isProcessing = false;
  int _countdownSeconds = 300; // 5 minutes
  Timer? _timer;

  final List<Map<String, dynamic>> _methods = [
    {
      'id': 'QRIS',
      'name': 'QRIS (GoPay, OVO, Dana, ShopeePay)',
      'icon': Icons.qr_code_scanner,
      'badge': 'Instan',
    },
    {
      'id': 'BCA_VA',
      'name': 'BCA Virtual Account',
      'icon': Icons.account_balance,
      'vaNumber': '8801 2026 8921 001',
    },
    {
      'id': 'MANDIRI_VA',
      'name': 'Mandiri Virtual Account',
      'icon': Icons.account_balance_outlined,
      'vaNumber': '8902 2026 5512 002',
    },
    {
      'id': 'BPJS',
      'name': 'BPJS Kesehatan (Terverifikasi)',
      'icon': Icons.health_and_safety,
      'badge': 'Covered 100%',
    },
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 0) {
        setState(() => _countdownSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTimer(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _formatCurrency(double amount) {
    return CurrencyFormatter.format(amount);
  }

  void _simulatePay() {
    setState(() => _isProcessing = true);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      Navigator.of(context).pop();
      widget.onPaymentSuccess();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentMethod = _methods.firstWhere((m) => m['id'] == _selectedMethod);

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pembayaran Reservasi Dokter',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      '${widget.doctorName} • ${widget.departmentName}',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 24),

            // Summary Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.navy.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.navy.withValues(alpha: 0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Tagihan Konsultasi',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  Text(
                    _selectedMethod == 'BPJS' ? 'Gratis (Covered)' : _formatCurrency(widget.amount),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _selectedMethod == 'BPJS' ? Colors.green.shade700 : AppTheme.navy,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Method Selector
            const Text(
              'Pilih Metode Pembayaran:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 10),
            ..._methods.map((method) {
              final isSelected = _selectedMethod == method['id'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => setState(() => _selectedMethod = method['id'] as String),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(method['icon'] as IconData,
                            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            method['name'] as String,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (method['badge'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              method['badge'] as String,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 14),

            // Dynamic Content based on method
            if (_selectedMethod == 'QRIS') ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.timer_outlined, size: 16, color: Colors.orange),
                        const SizedBox(width: 6),
                        Text(
                          'Berlaku selama ${_formatTimer(_countdownSeconds)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: QrImageView(
                              data: '00020101021226680016ID.CO.SEHATKU.HMS01189360099800000000005204599953033605407${widget.amount.toInt()}5802ID5919SEHATKU_MED_CENTER6007JAKARTA6304',
                              version: QrVersions.auto,
                              size: 140,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: AppTheme.navy,
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: AppTheme.navy,
                              ),
                            ),
                          ),
                          const Text('Scan dengan Aplikasi Bank / E-Wallet Apa Saja',
                              style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_selectedMethod.contains('VA')) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nomor Virtual Account:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          currentMethod['vaNumber'] as String,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Nomor VA berhasil disalin ke clipboard')),
                            );
                          },
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Salin'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else if (_selectedMethod == 'BPJS') ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified, color: Colors.green.shade700),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Kartu BPJS Kesehatan Anda aktif dan terverifikasi untuk poli ini.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Pay Button
            FilledButton.icon(
              onPressed: _isProcessing ? null : _simulatePay,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              icon: _isProcessing
                  ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_outline, size: 20),
              label: Text(
                _isProcessing
                    ? 'Memproses Pembayaran...'
                    : _selectedMethod == 'BPJS'
                        ? 'Konfirmasi dengan BPJS'
                        : 'Simulasikan Pembayaran Sukses',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
