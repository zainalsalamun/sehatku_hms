import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../shared/models/health_models.dart';

class LabResultPrintDialog extends StatelessWidget {
  const LabResultPrintDialog({super.key, required this.order});

  final LabOrderModel order;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID');
    final dateOnly = DateFormat('dd/MM/yyyy');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 760,
        height: 780,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Top Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.print_outlined, color: Colors.teal),
                    const SizedBox(width: 8),
                    Text(
                      'Pratinjau Lembar Hasil Laboratorium (A4)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 16),

            // A4 Paper Document Preview
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Hospital Letterhead (Kop Surat)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.local_hospital, color: Colors.teal, size: 36),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'INSTALASI LABORATORIUM KLINIK & PATOLOGI',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const Text(
                                  'RUMAH SAKIT SEHATKU MEDIKA UTAMA',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal,
                                  ),
                                ),
                                Text(
                                  'Jl. Kesehatan Raya No. 128, Jakarta Selatan • Telp: (021) 7890-1234 • Izin Lab: 445/LAB/2024',
                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(thickness: 2, color: Colors.black87, height: 24),

                      // Document Title
                      Center(
                        child: Text(
                          'HASIL PEMERIKSAAN LABORATORIUM',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            letterSpacing: 1.0,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Patient & Order Meta Grid
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _metaItem('No. Rekam Medis', order.patientMrn),
                                  _metaItem('Nama Pasien', order.patientName),
                                  _metaItem('Jenis Kelamin', order.patientGender),
                                  _metaItem('Penjamin', order.patientInsurance),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _metaItem('No. Order Lab', order.orderNumber),
                                  _metaItem('Dokter Pengirim', order.doctorName),
                                  _metaItem('Tgl Permintaan', dateFormat.format(order.createdAt)),
                                  _metaItem('Prioritas', order.priority),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Diagnosis Bar
                      if (order.clinicalDiagnosis != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Diagnosa Klinis: ${order.clinicalDiagnosis}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),

                      // Results Table
                      Table(
                        border: TableBorder.all(color: Colors.grey.shade300),
                        columnWidths: const {
                          0: FlexColumnWidth(3), // Test Name
                          1: FlexColumnWidth(2), // Result Value
                          2: FlexColumnWidth(1.5), // Unit
                          3: FlexColumnWidth(3), // Reference Range
                          4: FlexColumnWidth(1.5), // Flag
                        },
                        children: [
                          TableRow(
                            decoration: BoxDecoration(color: Colors.grey.shade200),
                            children: const [
                              Padding(padding: EdgeInsets.all(8), child: Text('Pemeriksaan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                              Padding(padding: EdgeInsets.all(8), child: Text('Hasil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                              Padding(padding: EdgeInsets.all(8), child: Text('Satuan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                              Padding(padding: EdgeInsets.all(8), child: Text('Nilai Rujukan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                              Padding(padding: EdgeInsets.all(8), child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            ],
                          ),
                          ...order.items.map((item) {
                            final isAbnormal = item.flag == 'low' || item.flag == 'high' || item.flag == 'critical';

                            return TableRow(
                              decoration: BoxDecoration(
                                color: isAbnormal ? Colors.amber.shade50.withValues(alpha: 0.5) : Colors.white,
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.testName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                      Text(item.category, style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    item.resultValue ?? 'Pending',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: isAbnormal ? Colors.red.shade800 : Colors.black87,
                                    ),
                                  ),
                                ),
                                Padding(padding: const EdgeInsets.all(8), child: Text(item.unit ?? '-', style: const TextStyle(fontSize: 11))),
                                Padding(padding: const EdgeInsets.all(8), child: Text(item.normalRangeText ?? '-', style: const TextStyle(fontSize: 10, color: Colors.grey))),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    item.flag?.toUpperCase() ?? 'NORMAL',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: item.flag == 'critical'
                                          ? Colors.red.shade900
                                          : (isAbnormal ? Colors.orange.shade900 : Colors.green.shade800),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Signatures & QR Code Validation
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // QR Code Validation Box
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.qr_code_2, size: 50, color: Colors.teal),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Verifikasi Keaslian Dokumen', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                                    Text('Hash: SEHATKU-LAB-${order.orderNumber}', style: TextStyle(fontSize: 8, color: Colors.grey.shade600)),
                                    Text('Waktu: ${order.completedAt != null ? dateFormat.format(order.completedAt!) : "-"}', style: TextStyle(fontSize: 8, color: Colors.grey.shade600)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),

                          // Signature Analis & Penanggung Jawab
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Jakarta, ${order.completedAt != null ? dateOnly.format(order.completedAt!) : dateOnly.format(DateTime.now())}',
                                style: const TextStyle(fontSize: 11),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Penanggung Jawab Laboratorium',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                              const SizedBox(height: 40),
                              Text(
                                order.verifiedBy ?? 'dr. Hendra Gunawan, Sp.PK',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              Text('SIP: 446.1/1092/Sp.PK/2023', style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Tutup'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: Colors.teal.shade800),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Perintah cetak lembar hasil laboratorium dikirimkan ke printer.'),
                        backgroundColor: Colors.teal,
                      ),
                    );
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.print),
                  label: const Text('Cetak Lembar Hasil Lab'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ),
          const Text(': ', style: TextStyle(fontSize: 11, color: Colors.grey)),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
