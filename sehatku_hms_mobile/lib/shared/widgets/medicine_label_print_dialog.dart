import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/health_models.dart';

class MedicineLabelPrintDialog extends StatefulWidget {
  const MedicineLabelPrintDialog({
    required this.prescription,
    this.patient,
    super.key,
  });

  final PharmacyPrescription prescription;
  final Patient? patient;

  @override
  State<MedicineLabelPrintDialog> createState() =>
      _MedicineLabelPrintDialogState();
}

class _MedicineLabelPrintDialogState extends State<MedicineLabelPrintDialog> {
  int _selectedTabIndex = 0; // 0: Etiket Obat, 1: Label Rekam Medis
  int _selectedItemIndex = 0;
  String _labelType = 'putih'; // 'putih' (Obat Minum) or 'biru' (Obat Luar)
  String _mealTiming =
      'Sesudah Makan'; // 'Sebelum Makan', 'Sesudah Makan', 'Bersama Makan'
  bool _morning = true;
  bool _afternoon = true;
  bool _night = true;
  bool _mustFinish = false;
  bool _shakeWell = false;
  String _expiryDate = '';

  @override
  void initState() {
    super.initState();
    final exp = DateTime.now().add(const Duration(days: 180));
    _expiryDate = DateFormat('dd/MM/yyyy').format(exp);
    _updateFormForSelectedItem();
  }

  void _updateFormForSelectedItem() {
    if (widget.prescription.items.isEmpty) return;
    final item = widget.prescription.items[_selectedItemIndex];
    final isLuar =
        item.route.toLowerCase().contains('topikal') ||
        item.route.toLowerCase().contains('oles') ||
        item.medicineName.toLowerCase().contains('salep') ||
        item.medicineName.toLowerCase().contains('tetes') ||
        item.medicineName.toLowerCase().contains('gel') ||
        item.medicineName.toLowerCase().contains('cream');

    _labelType = isLuar ? 'biru' : 'putih';
    _mustFinish =
        item.medicineName.toLowerCase().contains('amoxicillin') ||
        item.medicineName.toLowerCase().contains('ciprofloxacin') ||
        item.medicineName.toLowerCase().contains('azithromycin') ||
        item.medicineName.toLowerCase().contains('cef') ||
        item.medicineName.toLowerCase().contains('antibiotik');
    _shakeWell =
        item.dosage.toLowerCase().contains('sirup') ||
        item.dosage.toLowerCase().contains('suspensi') ||
        item.dosage.toLowerCase().contains('tetes');
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.prescription;
    final currentItem = p.items.isNotEmpty ? p.items[_selectedItemIndex] : null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 820,
        height: 640,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.local_pharmacy,
                    color: Colors.teal,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cetak Etiket Obat & Label Pasien',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Resep: ${p.prescriptionNumber} • Pasien: ${p.patientName} (${p.patientMrn})',
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

            // Tab Selector
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  icon: Icon(Icons.medication),
                  label: Text('Etiket Stiker Obat Farmasi'),
                ),
                ButtonSegment(
                  value: 1,
                  icon: Icon(Icons.badge_outlined),
                  label: Text('Label Berkas Rekam Medis (MRN)'),
                ),
              ],
              selected: {_selectedTabIndex},
              onSelectionChanged: (val) {
                setState(() => _selectedTabIndex = val.first);
              },
            ),
            const SizedBox(height: 16),

            // Main Body Content
            Expanded(
              child: _selectedTabIndex == 0
                  ? _buildMedicineLabelView(p, currentItem)
                  : _buildPatientMrnLabelView(p),
            ),

            const SizedBox(height: 16),

            // Actions Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Kembali'),
                ),
                Row(
                  children: [
                    if (_selectedTabIndex == 0) ...[
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.teal,
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Mencetak seluruh ${p.items.length} etiket obat ke printer thermal...',
                              ),
                              backgroundColor: Colors.teal,
                            ),
                          );
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.print_outlined),
                        label: Text('Cetak Semua (${p.items.length} Etiket)'),
                      ),
                      const SizedBox(width: 10),
                    ],
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _selectedTabIndex == 0
                                  ? 'Mencetak etiket: ${currentItem?.medicineName}...'
                                  : 'Mencetak stiker label rekam medis ${p.patientName}...',
                            ),
                            backgroundColor: Colors.teal,
                          ),
                        );
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.print),
                      label: Text(
                        _selectedTabIndex == 0
                            ? 'Cetak Etiket Ini'
                            : 'Cetak Label RM',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineLabelView(
    PharmacyPrescription p,
    PharmacyPrescriptionItem? currentItem,
  ) {
    if (currentItem == null) {
      return const Center(child: Text('Tidak ada item obat dalam resep.'));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Item Selector & Edit Controls
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PILIH OBAT (${_selectedItemIndex + 1}/${p.items.length})',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(p.items.length, (idx) {
                    final isSel = idx == _selectedItemIndex;
                    return ChoiceChip(
                      label: Text(p.items[idx].medicineName),
                      selected: isSel,
                      onSelected: (sel) {
                        if (sel) {
                          setState(() {
                            _selectedItemIndex = idx;
                            _updateFormForSelectedItem();
                          });
                        }
                      },
                    );
                  }),
                ),
                const SizedBox(height: 14),

                // Label Type (Putih / Biru)
                const Text(
                  'Tipe Etiket Standar:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text(
                          'Obat Minum (Putih)',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: 'putih',
                        groupValue: _labelType,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) => setState(() => _labelType = val!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text(
                          'Obat Luar (Biru)',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: 'biru',
                        groupValue: _labelType,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) => setState(() => _labelType = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Timing & Meal
                const Text(
                  'Petunjuk Konsumsi:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _mealTiming,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Sesudah Makan',
                      child: Text('Sesudah Makan (P.C.)', overflow: TextOverflow.ellipsis),
                    ),
                    DropdownMenuItem(
                      value: 'Sebelum Makan',
                      child: Text('Sebelum Makan (A.C.)', overflow: TextOverflow.ellipsis),
                    ),
                    DropdownMenuItem(
                      value: 'Bersama Makan',
                      child: Text('Bersama Makan / Saat Makan (D.C.)', overflow: TextOverflow.ellipsis),
                    ),
                    DropdownMenuItem(
                      value: 'Sesuai Kebutuhan (P.R.N)',
                      child: Text('Bila Perlu / Nyeri (P.R.N)', overflow: TextOverflow.ellipsis),
                    ),
                  ],
                  onChanged: (val) => setState(() => _mealTiming = val!),
                ),
                const SizedBox(height: 10),

                // Times of Day Checkboxes
                Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text(
                          'Pagi',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: _morning,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (v) => setState(() => _morning = v ?? true),
                      ),
                    ),
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text(
                          'Siang',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: _afternoon,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (v) =>
                            setState(() => _afternoon = v ?? true),
                      ),
                    ),
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text(
                          'Malam',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: _night,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (v) => setState(() => _night = v ?? true),
                      ),
                    ),
                  ],
                ),

                // Warning Flags
                CheckboxListTile(
                  title: const Text(
                    'Harus dihabiskan (Antibiotik)',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _mustFinish,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setState(() => _mustFinish = v ?? false),
                ),
                CheckboxListTile(
                  title: const Text(
                    'Kocok dahulu sebelum diminum/dipakai',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _shakeWell,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setState(() => _shakeWell = v ?? false),
                ),
              ],
            ),
          ),
        ),

        const VerticalDivider(width: 24),

        // Right Column: Thermal Sticker Preview (Etiket Standar Farmasi)
        Expanded(
          flex: 5,
          child: Center(child: _buildEtiketStickerPreview(p, currentItem)),
        ),
      ],
    );
  }

  Widget _buildEtiketStickerPreview(
    PharmacyPrescription p,
    PharmacyPrescriptionItem item,
  ) {
    final isBiru = _labelType == 'biru';
    final headerBgColor = isBiru ? const Color(0xFF1D4ED8) : Colors.white;
    final headerTextColor = isBiru ? Colors.white : Colors.black87;
    final borderColor = isBiru ? const Color(0xFF1D4ED8) : Colors.grey.shade400;

    final dateStr = DateFormat('dd MMM yyyy').format(p.createdAt);

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Clinic Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              color: headerBgColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'KLINIK PRATAMA SEHATKU MEDIKA',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: headerTextColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'SIA: 445/SIA/089/2023 • SIPA: 1988/SIPA/2024\nJl. Sudirman Boulevard No. 45, Jakarta • Telp: (021) 555-8900',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isBiru ? Colors.white70 : Colors.grey.shade600,
                    fontSize: 8,
                    height: 1.2,
                  ),
                ),
                if (isBiru) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amberAccent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'OBAT LUAR - TIDAK BOLEH DITELAN',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1),

          // Prescription Info
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'No. Resep: ${p.prescriptionNumber}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      dateStr,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('Pasien: ', style: TextStyle(fontSize: 11)),
                    Expanded(
                      child: Text(
                        '${p.patientName} (${p.patientMrn})',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 12),

                // Medicine Name & Dosage
                Center(
                  child: Column(
                    children: [
                      Text(
                        item.medicineName.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Sediaan / Dosis: ${item.dosage}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Usage Rules Badge
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isBiru ? Colors.blue.shade50 : Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isBiru
                          ? Colors.blue.shade200
                          : Colors.teal.shade200,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        item.frequency.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isBiru
                              ? Colors.blue.shade900
                              : Colors.teal.shade900,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _mealTiming.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isBiru
                              ? Colors.blue.shade800
                              : Colors.teal.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Time Checklist (Pagi - Siang - Malam)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _timeIndicator('PAGI', _morning),
                    _timeIndicator('SIANG', _afternoon),
                    _timeIndicator('MALAM', _night),
                  ],
                ),
                const SizedBox(height: 6),

                // Warnings
                if (_mustFinish)
                  _warningBadge('HARUS DIHABISKAN (ANTIBIOTIK)', Colors.red),
                if (_shakeWell)
                  _warningBadge('KOCOK DAHULU SEBELUM DIMINUM', Colors.orange),

                const SizedBox(height: 6),
                const Divider(height: 8),

                // Footer BUD & Exp
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Exp / BUD: $_expiryDate',
                      style: const TextStyle(fontSize: 9, color: Colors.grey),
                    ),
                    Text(
                      'Dr: ${p.doctorName}',
                      style: const TextStyle(fontSize: 9, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeIndicator(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: active ? Colors.grey.shade800 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : Colors.grey.shade500,
          fontWeight: FontWeight.bold,
          fontSize: 9,
        ),
      ),
    );
  }

  Widget _warningBadge(String text, MaterialColor color) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: color.shade50,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.shade200),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color.shade800,
            fontWeight: FontWeight.bold,
            fontSize: 9,
          ),
        ),
      ),
    );
  }

  Widget _buildPatientMrnLabelView(PharmacyPrescription p) {
    final patient = widget.patient;
    final birthDateStr = patient != null
        ? DateFormat('dd MMM yyyy').format(patient.birthDate)
        : '12 Mei 1994';
    final gender = patient?.gender ?? 'Perempuan';
    final nik = patient?.nik ?? '3174025205940003';

    return Center(
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black87, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_hospital, color: Colors.teal, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'KLINIK PRATAMA SEHATKU MEDIKA',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'LABEL RM',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 14),

            // MRN Big Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NO. REKAM MEDIS (MRN):',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        p.patientMrn,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                // Mock Barcode
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.qr_code_2, size: 44),
                ),
              ],
            ),
            const SizedBox(height: 8),

            _labelRow('Nama Pasien', p.patientName, isBold: true),
            _labelRow('NIK', nik),
            _labelRow('Tanggal Lahir / JK', '$birthDateStr • $gender'),
            _labelRow('Penjamin', p.insurance),
            const Divider(height: 14),

            Text(
              'Gunakan stiker ini untuk ditempel pada Map Rekam Medis, Gelang Pasien, atau Tabung Laboratorium.',
              style: TextStyle(
                fontSize: 8,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _labelRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
            ),
          ),
          const Text(': ', style: TextStyle(fontSize: 10)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
