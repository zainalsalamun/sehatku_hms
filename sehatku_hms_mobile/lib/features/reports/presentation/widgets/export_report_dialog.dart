import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/api_client_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/document_template_helper.dart';
import '../../../../core/utils/file_download_helper.dart';
import '../../../../core/utils/print_helper.dart';

enum ReportExportType {
  financial,
  inpatientCensus,
  morbiLB1,
  pharmacyStock,
  patientVisits,
}

class ExportReportDialog extends ConsumerStatefulWidget {
  const ExportReportDialog({
    super.key,
    this.initialType = ReportExportType.financial,
  });

  final ReportExportType initialType;

  @override
  ConsumerState<ExportReportDialog> createState() => _ExportReportDialogState();
}

class _ExportReportDialogState extends ConsumerState<ExportReportDialog> {
  late ReportExportType _selectedType;
  String _dateRangePreset = 'month'; // 'today', 'week', 'month', 'all'
  bool _isLoading = false;
  String? _loadingAction;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  (String?, String?) _calculateDateRange() {
    final now = DateTime.now();
    final format = DateFormat('yyyy-MM-dd');

    if (_dateRangePreset == 'today') {
      final todayStr = format.format(now);
      return (todayStr, todayStr);
    } else if (_dateRangePreset == 'week') {
      final start = now.subtract(const Duration(days: 7));
      return (format.format(start), format.format(now));
    } else if (_dateRangePreset == 'month') {
      final start = DateTime(now.year, now.month, 1);
      return (format.format(start), format.format(now));
    }
    return (null, null); // 'all'
  }

  String _getPeriodLabel() {
    if (_selectedType == ReportExportType.pharmacyStock) {
      return 'Stok Real-time Saat Ini';
    }
    switch (_dateRangePreset) {
      case 'today':
        return 'Hari Ini (${DateFormat('d MMM yyyy', 'id_ID').format(DateTime.now())})';
      case 'week':
        return '7 Hari Terakhir';
      case 'month':
        return 'Bulan Ini (${DateFormat('MMMM yyyy', 'id_ID').format(DateTime.now())})';
      default:
        return 'Semua Periode';
    }
  }

  Future<String?> _fetchReportCsv() async {
    final client = ref.read(apiClientProvider);
    final (start, end) = _calculateDateRange();

    switch (_selectedType) {
      case ReportExportType.financial:
        return client.downloadFinancialExport(startDate: start, endDate: end);
      case ReportExportType.inpatientCensus:
        return client.downloadInpatientCensusExport(startDate: start, endDate: end);
      case ReportExportType.morbiLB1:
        return client.downloadMorbiLB1Export(startDate: start, endDate: end);
      case ReportExportType.pharmacyStock:
        return client.downloadPharmacyStockExport();
      case ReportExportType.patientVisits:
        return client.downloadPatientVisitsExport(startDate: start, endDate: end);
    }
  }

  (String, String, String) _getReportMetadata() {
    final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
    switch (_selectedType) {
      case ReportExportType.financial:
        return (
          'LAPORAN REKAPITULASI KASIR & KEUANGAN',
          'Rekapitulasi Transaksi Pembayaran, Omzet, dan Metode Bayar',
          'Laporan_Keuangan_Kasir_$dateStr',
        );
      case ReportExportType.inpatientCensus:
        return (
          'LAPORAN SENSUS HARIAN RAWAT INAP & INDIKATOR BOR (KARS)',
          'Sensus Pasien Rawat Inap, Utilisasi Tempat Tidur & Akumulasi Hari Rawat',
          'Laporan_Sensus_Rawat_Inap_$dateStr',
        );
      case ReportExportType.morbiLB1:
        return (
          'LAPORAN 10 BESAR PENYAKIT (MORBIDITAS LB1)',
          'Rekapitulasi Diagnosa ICD-10 Pasien Standar Dinas Kesehatan',
          'Laporan_LB1_Dinkes_$dateStr',
        );
      case ReportExportType.pharmacyStock:
        return (
          'LAPORAN MUTASI & VALUASI STOK FARMASI',
          'Inventori Obat, Nilai Aset Farmasi, dan Batas Minimum Stok',
          'Laporan_Valuasi_Stok_Farmasi_$dateStr',
        );
      case ReportExportType.patientVisits:
        return (
          'LAPORAN REKAPITULASI KUNJUNGAN PASIEN',
          'Daftar Kunjungan Poliklinik per DPJP, Keluhan & Penjamin',
          'Laporan_Kunjungan_Pasien_$dateStr',
        );
    }
  }

  Future<void> _handleDownloadCsv() async {
    setState(() {
      _isLoading = true;
      _loadingAction = 'csv';
    });

    final csvContent = await _fetchReportCsv();
    final (_, _, baseFilename) = _getReportMetadata();
    final filename = '$baseFilename.csv';

    if (mounted) {
      setState(() {
        _isLoading = false;
        _loadingAction = null;
      });

      if (csvContent != null) {
        downloadFileFromText(
          content: csvContent,
          filename: filename,
        );

        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Laporan spreadsheet ($filename) berhasil diunduh.'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengunduh file laporan spreadsheet.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handlePrintPdf() async {
    setState(() {
      _isLoading = true;
      _loadingAction = 'pdf';
    });

    final csvContent = await _fetchReportCsv();
    final (title, subtitle, baseFilename) = _getReportMetadata();

    if (mounted) {
      setState(() {
        _isLoading = false;
        _loadingAction = null;
      });

      if (csvContent != null) {
        final htmlContent = DocumentTemplateHelper.generateExecutiveReportHtml(
          reportTitle: title,
          reportSubtitle: subtitle,
          period: _getPeriodLabel(),
          csvContent: csvContent,
        );

        printHtmlDocument(
          title: baseFilename,
          htmlContent: htmlContent,
        );

        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Membuka pratinjau dokumen resmi $title untuk cetak / unduh PDF.'),
            backgroundColor: AppTheme.navy,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memproses dokumen laporan resmi PDF.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.navy.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.analytics_outlined,
                      color: AppTheme.navy,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ekspor Laporan Eksekutif Rumah Sakit',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          'Unduh data terstruktur untuk akuntansi, audit KARS, farmasi, atau pelaporan Dinas Kesehatan.',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
              const Divider(height: 24),

              // Select Report Type
              const Text(
                'PILIH JENIS LAPORAN',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 8),

              _typeRadioTile(
                type: ReportExportType.financial,
                title: 'Laporan Rekapitulasi Kasir & Keuangan',
                subtitle: 'Rekap seluruh transaksi invoice, metode bayar (Tunai/QRIS/Debit), dan status tagihan.',
                icon: Icons.payments_outlined,
              ),
              _typeRadioTile(
                type: ReportExportType.inpatientCensus,
                title: 'Laporan Sensus Harian Rawat Inap & BOR (KARS)',
                subtitle: 'Sensus pasien masuk, keluar, hari rawat, occupancy bed, dan rekapitulasi BOR/ALOS.',
                icon: Icons.hotel_outlined,
              ),
              _typeRadioTile(
                type: ReportExportType.morbiLB1,
                title: 'Laporan 10 Besar Penyakit (LB1 Dinkes)',
                subtitle: 'Rekapitulasi agregasi diagnosa ICD-10 dan demografi gender pasien standar Dinas Kesehatan.',
                icon: Icons.coronavirus_outlined,
              ),
              _typeRadioTile(
                type: ReportExportType.pharmacyStock,
                title: 'Laporan Mutasi & Valuasi Stok Farmasi',
                subtitle: 'Daftar stok obat, batch, min. stok, harga pokok, harga jual, dan total nilai aset obat.',
                icon: Icons.medication_liquid_outlined,
              ),
              _typeRadioTile(
                type: ReportExportType.patientVisits,
                title: 'Laporan Rekapitulasi Kunjungan Pasien',
                subtitle: 'Daftar kunjungan poliklinik per dokter DPJP, keluhan, dan penjamin pasien (BPJS/Umum).',
                icon: Icons.people_outline,
              ),
              const SizedBox(height: 12),

              // Date Range Selection (only if applicable)
              if (_selectedType != ReportExportType.pharmacyStock) ...[
                const Text(
                  'RENTANG PERIODE LAPORAN',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _presetChip('Hari Ini', 'today'),
                    _presetChip('7 Hari Terakhir', 'week'),
                    _presetChip('Bulan Ini', 'month'),
                    _presetChip('Semua Periode', 'all'),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              const Divider(height: 16),

              // Action Buttons: PDF & CSV
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Batal'),
                  ),
                  Row(
                    children: [
                      // Button 1: PDF Export
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.navy,
                          side: const BorderSide(color: AppTheme.navy),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        onPressed: _isLoading ? null : _handlePrintPdf,
                        icon: _isLoading && _loadingAction == 'pdf'
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.navy),
                              )
                            : const Icon(Icons.print_outlined, size: 18),
                        label: Text(_isLoading && _loadingAction == 'pdf' ? 'Memuat PDF...' : 'Cetak / Unduh PDF'),
                      ),
                      const SizedBox(width: 8),
                      // Button 2: CSV Export
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onPressed: _isLoading ? null : _handleDownloadCsv,
                        icon: _isLoading && _loadingAction == 'csv'
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.table_chart_outlined, size: 18),
                        label: Text(_isLoading && _loadingAction == 'csv' ? 'Mengunduh...' : 'Unduh Excel (.csv)'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeRadioTile({
    required ReportExportType type,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedType == type;

    return InkWell(
      onTap: () => setState(() => _selectedType = type),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.navy.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.navy : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<ReportExportType>(
              value: type,
              groupValue: _selectedType,
              activeColor: AppTheme.navy,
              onChanged: (v) {
                if (v != null) setState(() => _selectedType = v);
              },
            ),
            Icon(icon, color: isSelected ? AppTheme.navy : Colors.grey.shade600, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                      color: isSelected ? AppTheme.navy : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _presetChip(String label, String value) {
    final isSelected = _dateRangePreset == value;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      selectedColor: AppTheme.navy,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey.shade800,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (sel) {
        if (sel) setState(() => _dateRangePreset = value);
      },
    );
  }
}
