import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/api_client_provider.dart';
import '../../../../core/utils/file_download_helper.dart';

enum ReportExportType {
  financial,
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
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
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.table_view_outlined, color: Colors.green.shade700, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Export Laporan Spreadsheet (Excel / .csv)',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Unduh data terstruktur untuk pembukuan akuntansi, audit, farmasi, atau pelaporan Dinas Kesehatan.',
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
            const SizedBox(height: 14),

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
              const SizedBox(height: 16),
            ],

            const Divider(height: 20),

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
                    backgroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: _isLoading ? null : _handleDownload,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.download),
                  label: Text(_isLoading ? 'Mengunduh...' : 'Unduh File Excel (.csv)'),
                ),
              ],
            ),
          ],
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
          color: isSelected ? Colors.green.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.green.shade400 : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<ReportExportType>(
              value: type,
              groupValue: _selectedType,
              onChanged: (v) {
                if (v != null) setState(() => _selectedType = v);
              },
            ),
            Icon(icon, color: isSelected ? Colors.green.shade700 : Colors.grey.shade600, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isSelected ? Colors.green.shade900 : Colors.black87,
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
      onSelected: (sel) {
        if (sel) setState(() => _dateRangePreset = value);
      },
    );
  }

  Future<void> _handleDownload() async {
    setState(() => _isLoading = true);

    final client = ref.read(apiClientProvider);
    final (start, end) = _calculateDateRange();
    final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());

    String? csvContent;
    String filename = 'Laporan_SehatKu_$dateStr.csv';

    switch (_selectedType) {
      case ReportExportType.financial:
        csvContent = await client.downloadFinancialExport(startDate: start, endDate: end);
        filename = 'Laporan_Rekap_Keuangan_Kasir_$dateStr.csv';
        break;
      case ReportExportType.morbiLB1:
        csvContent = await client.downloadMorbiLB1Export(startDate: start, endDate: end);
        filename = 'Laporan_10_Penyakit_LB1_Dinkes_$dateStr.csv';
        break;
      case ReportExportType.pharmacyStock:
        csvContent = await client.downloadPharmacyStockExport();
        filename = 'Laporan_Valuasi_Stok_Farmasi_$dateStr.csv';
        break;
      case ReportExportType.patientVisits:
        csvContent = await client.downloadPatientVisitsExport(startDate: start, endDate: end);
        filename = 'Laporan_Kunjungan_Pasien_$dateStr.csv';
        break;
    }

    if (mounted) {
      setState(() => _isLoading = false);

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
            content: Text('Gagal mengunduh file laporan.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
