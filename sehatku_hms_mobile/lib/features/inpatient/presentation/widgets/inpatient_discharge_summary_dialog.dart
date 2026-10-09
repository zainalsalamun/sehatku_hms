import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/document_template_helper.dart';
import '../../../../core/utils/print_helper.dart';
import '../../../../shared/models/health_models.dart';

void showInpatientDischargeSummaryDialog(
  BuildContext context,
  InpatientAdmissionModel admission,
) {
  showDialog(
    context: context,
    builder: (_) => InpatientDischargeSummaryDialog(admission: admission),
  );
}

class InpatientDischargeSummaryDialog extends StatefulWidget {
  const InpatientDischargeSummaryDialog({
    super.key,
    required this.admission,
  });

  final InpatientAdmissionModel admission;

  @override
  State<InpatientDischargeSummaryDialog> createState() =>
      _InpatientDischargeSummaryDialogState();
}

class _InpatientDischargeSummaryDialogState
    extends State<InpatientDischargeSummaryDialog> {
  late final List<Map<String, String>> _medications;
  late final String _controlDate;

  final dateFormat = DateFormat('d MMMM yyyy', 'id_ID');

  @override
  void initState() {
    super.initState();
    final dischargeDt = widget.admission.dischargeDate ?? DateTime.now();
    _controlDate = dateFormat.format(dischargeDt.add(const Duration(days: 4)));

    _medications = [
      {
        'name': 'Cefixime 100 mg Tablet',
        'dosage': '2 x 1 Tablet',
        'timing': 'Sesudah makan',
        'duration': '5 Hari (Harus Dihabiskan)',
      },
      {
        'name': 'Paracetamol 500 mg Tablet',
        'dosage': '3 x 1 Tablet',
        'timing': 'Sesudah makan (Bila demam / nyeri)',
        'duration': '3 Hari',
      },
      {
        'name': 'Omeprazole 20 mg Kapsul',
        'dosage': '1 x 1 Kapsul',
        'timing': '30 menit sebelum makan pagi',
        'duration': '5 Hari',
      },
    ];
  }

  void _printOrExportPdf() {
    final htmlContent =
        DocumentTemplateHelper.generateInpatientDischargeSummaryHtml(
      admission: widget.admission,
      homeMedications: _medications,
      controlDate: _controlDate,
      controlClinic: 'Poli ${widget.admission.doctorSpecialist}',
    );

    final safeAdm = widget.admission.admissionNumber
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

    printHtmlDocument(
      title: 'Resume_Medis_Rawat_Inap_$safeAdm',
      htmlContent: htmlContent,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Membuka Lembar Resume Medis ${widget.admission.admissionNumber} untuk cetak / ekspor PDF.',
        ),
        backgroundColor: AppTheme.navy,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admission = widget.admission;
    final dischargeDt = admission.dischargeDate ?? DateTime.now();
    final days = admission.totalDays > 0
        ? admission.totalDays
        : (dischargeDt.difference(admission.admissionDate).inDays <= 0
            ? 1
            : dischargeDt.difference(admission.admissionDate).inDays + 1);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 850),
        child: Column(
          children: [
            // Header Dialog
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              color: AppTheme.navy,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Resume Medis Rawat Inap & Surat Kontrol',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'No. Admisi: ${admission.admissionNumber} • Standar Akreditasi KARS / RME',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Scrollable Document Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Letterhead Klinik
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.local_hospital_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                DocumentTemplateHelper.clinicName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  color: AppTheme.navy,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                '${DocumentTemplateHelper.clinicLicense} • Terakreditasi Paripurna KARS',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              Text(
                                DocumentTemplateHelper.clinicAddress,
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
                    const Divider(thickness: 2, height: 2, color: AppTheme.navy),
                    const SizedBox(height: 2),
                    const Divider(thickness: 0.8, height: 1, color: AppTheme.navy),
                    const SizedBox(height: 16),

                    // Document Title
                    Center(
                      child: Column(
                        children: [
                          const Text(
                            'RINGKASAN PULANG PASIEN RAWAT INAP (DISCHARGE SUMMARY)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.navy,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Nomor Dokumen: DS-${admission.admissionNumber}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Demographic Metadata Box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          _buildDocRow('Nama Pasien', admission.patientName, 'Dokter DPJP', admission.doctorName),
                          const SizedBox(height: 6),
                          _buildDocRow('No. Rekam Medis (MRN)', admission.patientMrn, 'Spesialisasi DPJP', admission.doctorSpecialist),
                          const SizedBox(height: 6),
                          _buildDocRow('Jenis Kelamin', admission.patientGender, 'Ruang / Kelas', '${admission.roomName} (${admission.bedNumber}) - ${admission.classType}'),
                          const SizedBox(height: 6),
                          _buildDocRow('Tanggal Masuk (MRS)', dateFormat.format(admission.admissionDate), 'Tanggal Keluar (KRS)', '${dateFormat.format(dischargeDt)} ($days Hari)'),
                          const SizedBox(height: 6),
                          _buildDocRow('Penjamin Biaya', admission.patientInsurance, 'Kondisi Saat Pulang', admission.dischargeCondition ?? 'Sembuh (Klinis Membaik)'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Section Diagnosa
                    _buildSectionHeader('RINGKASAN DIAGNOSA & OBSERVASI KLINIS'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSingleRow('Diagnosa Masuk', admission.initialDiagnosis ?? 'Observasi Klinis Lanjutan'),
                          const Divider(height: 14),
                          _buildSingleRow(
                            'Diagnosa Akhir / Utama',
                            admission.dischargeDiagnosis ??
                                (admission.initialDiagnosis != null
                                    ? '${admission.initialDiagnosis} - Klinis Stabil'
                                    : 'Kondisi Klinis Membaik'),
                            isHighlight: true,
                          ),
                          const Divider(height: 14),
                          _buildSingleRow(
                            'Instruksi Klinis & Terapi Terakhir',
                            admission.latestCPPT?.instruction?.isNotEmpty == true
                                ? admission.latestCPPT!.instruction!
                                : (admission.notes ??
                                    'Pasien diijinkan pulang rawat jalan, lanjutkan terapi obat rumah.'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Section Obat Pulang (Home Medications)
                    _buildSectionHeader('TERAPI OBAT PULANG (HOME MEDICATIONS)'),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(4),
                          1: FlexColumnWidth(2.5),
                          2: FlexColumnWidth(3),
                          3: FlexColumnWidth(3),
                        },
                        border: TableBorder(
                          horizontalInside: BorderSide(color: Colors.grey.shade200),
                        ),
                        children: [
                          TableRow(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                            ),
                            children: const [
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Text('Nama Obat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Text('Dosis / Aturan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Text('Waktu Konsumsi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Text('Durasi Terapi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                              ),
                            ],
                          ),
                          ..._medications.map((m) => TableRow(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(m['name'] ?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(m['dosage'] ?? '', style: const TextStyle(fontSize: 11)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(m['timing'] ?? '', style: const TextStyle(fontSize: 11)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(m['duration'] ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.navy, fontWeight: FontWeight.w500)),
                                  ),
                                ],
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Section Jadwal Kontrol
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_month_outlined, size: 16, color: Colors.blue.shade900),
                              const SizedBox(width: 8),
                              Text(
                                'JADWAL KONTROL POLIKLINIK RAWAT JALAN',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('Tanggal Kontrol Ulang: ', style: TextStyle(fontSize: 11.5, color: Colors.black87)),
                              Text(_controlDate, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Text('Poliklinik Tujuan: ', style: TextStyle(fontSize: 11.5, color: Colors.black87)),
                              Text('Poli ${admission.doctorSpecialist} (DPJP: ${admission.doctorName})', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.red),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Peringatan Kegawatdaruratan: Segera ke IGD jika demam tinggi > 38.5 C, sesak napas berat, nyeri dada, atau perdarahan.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Digital DPJP Signature & QR
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Left: QR Code Verification
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: const Icon(Icons.qr_code_2_rounded, size: 48, color: AppTheme.navy),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: Colors.green.shade300),
                                      ),
                                      child: Text(
                                        'TERVERIFIKASI DIGITAL RME',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Dokumen resmi tervalidasi Sistem Kemenkes SatuSehat & KARS.',
                                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),

                        // Right: Doctor DPJP Name
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Jakarta, ${dateFormat.format(DateTime.now())}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Dokter Penanggung Jawab Pelayanan (DPJP),',
                              style: TextStyle(fontSize: 11),
                            ),
                            const SizedBox(height: 36),
                            Text(
                              admission.doctorName,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                                color: AppTheme.navy,
                              ),
                            ),
                            Text(
                              admission.doctorSpecialist,
                              style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Dialog Footer Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Tutup'),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.navy,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                    onPressed: _printOrExportPdf,
                    icon: const Icon(Icons.print_outlined, size: 18),
                    label: const Text('Cetak / Unduh PDF Resume Medis'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 3.5,
          height: 14,
          decoration: BoxDecoration(
            color: AppTheme.navy,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppTheme.navy,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildDocRow(String label1, String val1, String label2, String val2) {
    return Row(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 130,
                child: Text(label1, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
              ),
              const Text(': ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              Expanded(
                child: Text(val1, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 130,
                child: Text(label2, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
              ),
              const Text(': ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              Expanded(
                child: Text(val2, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSingleRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 160,
          child: Text(label, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700)),
        ),
        const Text(': ', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
              color: isHighlight ? AppTheme.navy : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
