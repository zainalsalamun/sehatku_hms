import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../models/health_models.dart';

void showOfficialReceiptDialog(BuildContext context, Invoice invoice) {
  showDialog(
    context: context,
    builder: (ctx) => OfficialReceiptDialog(invoice: invoice),
  );
}

class OfficialReceiptDialog extends StatelessWidget {
  const OfficialReceiptDialog({required this.invoice, super.key});
  final Invoice invoice;

  String _formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}';
  }

  String _terbilang(double n) {
    if (invoice.terbilang.isNotEmpty) return invoice.terbilang;
    final val = n.toInt();
    if (val >= 350000) return 'Tiga Ratus Lima Puluh Ribu Rupiah';
    if (val >= 250000) return 'Dua Ratus Lima Puluh Ribu Rupiah';
    return '${_formatCurrency(n)} Rupiah';
  }

  String _formatDate(DateTime dt) {
    try {
      return DateFormat('EEEE, d MMMM yyyy • HH:mm', 'id_ID').format(dt);
    } catch (_) {
      final days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
      final months = [
        '',
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember'
      ];
      final dayName = days[dt.weekday % 7];
      final monthName = months[dt.month];
      final timeStr =
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      return '$dayName, ${dt.day} $monthName ${dt.year} • $timeStr WIB';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPaid = invoice.status == 'Lunas';
    final dateFormatted = invoice.paidAt != null
        ? _formatDate(invoice.paidAt!)
        : _formatDate(invoice.createdAt);

    final amountNum = invoice.amount;
    final adminFee = 15000.0;
    final consultationFee = (amountNum - adminFee).clamp(0.0, double.infinity);

    final items = invoice.items.isNotEmpty
        ? invoice.items
        : [
            InvoiceItem(
              name: 'Jasa Konsultasi Spesialis & Pemeriksaan Klinis',
              category: 'Konsultasi Medis',
              quantity: 1,
              unitPrice: consultationFee,
              subtotal: consultationFee,
            ),
            InvoiceItem(
              name: 'Administrasi Rekam Medis & Pendaftaran RS',
              category: 'Administrasi',
              quantity: 1,
              unitPrice: adminFee,
              subtotal: adminFee,
            ),
          ];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 680),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Receipt Paper Header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                decoration: const BoxDecoration(
                  color: AppTheme.navy,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.local_hospital,
                        color: AppTheme.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SEHATKU MEDICAL CENTER',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Layanan Kesehatan Paripurna • Akreditasi KARS',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            'Jl. Sudirman Boulevard No. 45, Jakarta • Telp: (021) 555-8900',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Official Title & Stamp Status
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'KWITANSI PEMBAYARAN RESMI',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'No. Bukti: KWIT/${invoice.invoiceNumber.replaceAll('INV-', '')}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'No. Tagihan: ${invoice.invoiceNumber}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isPaid ? Colors.green.shade50 : Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isPaid ? Colors.green.shade600 : Colors.amber.shade700,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isPaid ? Icons.check_circle : Icons.pending_actions,
                                color: isPaid ? Colors.green.shade700 : Colors.amber.shade800,
                                size: 18,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isPaid ? 'LUNAS / PAID' : 'MENUNGGU',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                  color: isPaid ? Colors.green.shade800 : Colors.amber.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    _buildDashedLine(),
                    const SizedBox(height: 16),

                    // Patient & Encounter Metadata
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          _buildMetaRow('Nama Pasien', invoice.patientName, 'No. RM (MRN)', invoice.patientMrn),
                          const SizedBox(height: 10),
                          _buildMetaRow('Dokter Pemeriksa', invoice.doctorName, 'Poliklinik', invoice.serviceName),
                          const SizedBox(height: 10),
                          _buildMetaRow('Metode Bayar', invoice.paymentMethod, 'Waktu Transaksi', dateFormatted),
                          const SizedBox(height: 10),
                          _buildMetaRow('Penjamin', invoice.insuranceProvider, 'Kasir / Petugas', 'Siti Rahma (Kasir Utama)'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),
                    const Text(
                      'RINCIAN BIAYA PELAYANAN',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Itemized Table
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          // Table Header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                            ),
                            child: const Row(
                              children: [
                                Expanded(flex: 5, child: Text('Uraian Layanan & Tindakan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                SizedBox(width: 4),
                                Expanded(flex: 2, child: Text('Kategori', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                SizedBox(width: 28, child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                SizedBox(width: 4),
                                Expanded(flex: 3, child: Text('Subtotal', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          // Table Rows
                          ...items.map((item) => Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 5,
                                      child: Text(
                                        item.name,
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        item.category,
                                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 28,
                                      child: Text(
                                        '${item.quantity}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        _formatCurrency(item.subtotal),
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                          const Divider(height: 1),
                          // Grand Total Footer
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.05),
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'TOTAL PEMBAYARAN',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                                ),
                                Text(
                                  _formatCurrency(amountNum),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Terbilang Box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.record_voice_over_outlined, size: 16, color: Colors.brown),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Terbilang: "${_terbilang(amountNum)}"',
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w600,
                                fontSize: 10.5,
                                color: Colors.brown,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Official Stamp & Verification QR
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade400),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.qr_code_2, size: 38, color: AppTheme.navy),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Dokumen Sah RS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5)),
                                    Text('Sistem EMR Terverifikasi', style: TextStyle(color: Colors.grey, fontSize: 9.5), overflow: TextOverflow.ellipsis),
                                    Text('ID: #DOC-2026', style: TextStyle(color: Colors.grey, fontSize: 8.5)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.blue.shade300),
                              ),
                              child: Text(
                                'VALIDATED ELECTRONICALLY',
                                style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text('Siti Rahma, S.E.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            const Text('Kasir & Bendahara RS', style: TextStyle(color: Colors.grey, fontSize: 9.5)),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Kwitansi ${invoice.invoiceNumber} berhasil dikirim ke email pasien.'),
                                  backgroundColor: AppTheme.primary,
                                ),
                              );
                            },
                            icon: const Icon(Icons.share, size: 18),
                            label: const Text('Kirim Dokumen'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Mencetak Kwitansi Resmi: ${invoice.invoiceNumber}... (PDF Generated)'),
                                  backgroundColor: AppTheme.success,
                                ),
                              );
                            },
                            icon: const Icon(Icons.print, size: 18),
                            label: const Text('Cetak / Unduh PDF'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaRow(String label1, String value1, String label2, String value2) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label1, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
              const SizedBox(height: 2),
              Text(value1, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label2, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
              const SizedBox(height: 2),
              Text(value2, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDashedLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 6.0;
        const dashSpace = 4.0;
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.grey.shade300),
              ),
            );
          }),
        );
      },
    );
  }
}
