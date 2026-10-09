import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/document_template_helper.dart';
import '../../../../core/utils/print_helper.dart';
import '../../../../shared/models/health_models.dart';

void showMedicalCertificateDialog(
  BuildContext context,
  MedicalCertificate cert,
) {
  showDialog(
    context: context,
    builder: (_) => MedicalCertificateDialog(certificate: cert),
  );
}

class MedicalCertificateDialog extends StatelessWidget {
  const MedicalCertificateDialog({super.key, required this.certificate});

  final MedicalCertificate certificate;

  String _numberToWords(int n) {
    const words = [
      'Nol',
      'Satu',
      'Dua',
      'Tiga',
      'Empat',
      'Lima',
      'Enam',
      'Tujuh',
      'Delapan',
      'Sembilan',
      'Sepuluh',
      'Sebelas',
      'Dua Belas',
      'Tiga Belas',
      'Empat Belas',
    ];
    if (n < words.length) return words[n];
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isSickLeave = certificate.type == 'sick_leave';
    final dateFormat = DateFormat('d MMMM yyyy', 'id_ID');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: 580,
        padding: const EdgeInsets.all(28),
        color: Colors.white,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Letterhead Kop Surat Klinik
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_hospital_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'KLINIK PRATAMA SEHATKU MEDIKA',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 0.5,
                            color: AppTheme.navy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Izin Operasional No: 445/092/DINKES/2023',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          'Jl. Jenderal Sudirman Kav. 52-53, Jakarta Selatan • Telp: (021) 555-8900',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(height: 2, color: AppTheme.navy),
              const SizedBox(height: 2),
              Container(height: 0.8, color: AppTheme.navy),
              const SizedBox(height: 20),

              // Title Document
              Center(
                child: Column(
                  children: [
                    Text(
                      isSickLeave
                          ? 'SURAT KETERANGAN SAKIT'
                          : 'SURAT KETERANGAN KESEHATAN',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        letterSpacing: 1.1,
                        decoration: TextDecoration.underline,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nomor: ${certificate.certificateNumber}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Body Letter
              const Text(
                'Yang bertanda tangan di bawah ini, Dokter Pemeriksa Klinik Pratama SehatKu Medika menerangkan dengan sebenarnya bahwa:',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 14),

              // Patient Info Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    _infoRow('Nama Pasien', certificate.patientName, bold: true),
                    const SizedBox(height: 8),
                    _infoRow('No. Rekam Medis (MRN)', certificate.patientMrn),
                    const SizedBox(height: 8),
                    _infoRow(
                      'Diagnosa Medis',
                      certificate.diagnosis.isNotEmpty
                          ? certificate.diagnosis
                          : 'Kelelahan Fisik & Observasi Klinis',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Statement
              if (isSickLeave)
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                    children: [
                      const TextSpan(
                        text: 'Berhubung sedang dalam keadaan sakit, pasien memerlukan istirahat tirah baring selama ',
                      ),
                      TextSpan(
                        text: '${certificate.durationDays} (${_numberToWords(certificate.durationDays)}) hari',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: ', terhitung mulai tanggal '),
                      TextSpan(
                        text: dateFormat.format(certificate.startDate),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: ' sampai dengan '),
                      TextSpan(
                        text: dateFormat.format(certificate.endDate),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                )
              else
                const Text(
                  'Telah diperiksa kesehatan jasmaninya dan dinyatakan SEHAT pada hari ini untuk keperluan administratif / kegiatan.',
                  style: TextStyle(fontSize: 13, height: 1.5),
                ),

              if (certificate.notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Catatan Medis: ${certificate.notes}',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],

              const SizedBox(height: 16),
              const Text(
                'Demikian surat keterangan ini diberikan untuk dapat dipergunakan sebagaimana mestinya.',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 24),

              // Signature & Stamp Block
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // QR Verification & Stamp
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: const Icon(
                              Icons.qr_code_2_rounded,
                              size: 56,
                              color: AppTheme.navy,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Transform.rotate(
                            angle: -0.15,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.red.shade700,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'TERVERIFIKASI\nKLINIK SEHATKU',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.red.shade700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Scan QR untuk validasi keaslian dokumen',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),

                  // Doctor Signature
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Jakarta, ${dateFormat.format(certificate.startDate)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Dokter Pemeriksa,',
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 38),
                      Text(
                        certificate.doctorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      Text(
                        'SIP. 449.1/023/DINKES/2021',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Tutup'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        final htmlContent =
                            DocumentTemplateHelper.generateMedicalCertificateHtml(
                          certificate,
                        );
                        final safeNumber = certificate.certificateNumber
                            .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
                        printHtmlDocument(
                          title: '${certificate.type == "sick_leave" ? "Surat_Sakit" : "Surat_Kesehatan"}_$safeNumber',
                          htmlContent: htmlContent,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Membuka dokumen ${certificate.certificateNumber} untuk dicetak / diunduh sebagai PDF.',
                            ),
                            backgroundColor: AppTheme.primary,
                          ),
                        );
                      },
                      icon: const Icon(Icons.print_rounded, size: 18),
                      label: const Text('Cetak / Unduh PDF'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool bold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 160,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Text(': ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
