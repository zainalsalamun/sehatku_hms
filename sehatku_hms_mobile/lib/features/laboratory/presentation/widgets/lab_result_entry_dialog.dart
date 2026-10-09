import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/models/health_models.dart';
import '../../application/laboratory_state_providers.dart';

class LabResultEntryDialog extends ConsumerStatefulWidget {
  const LabResultEntryDialog({super.key, required this.order});

  final LabOrderModel order;

  @override
  ConsumerState<LabResultEntryDialog> createState() =>
      _LabResultEntryDialogState();
}

class _LabResultEntryDialogState extends ConsumerState<LabResultEntryDialog> {
  late Map<String, TextEditingController> _resultControllers;
  late Map<String, String> _flags;
  late Map<String, TextEditingController> _notesControllers;

  final _analystNameCtrl =
      TextEditingController(text: 'Wahyu Hidayat, A.Md.AK');
  final _collectorNameCtrl =
      TextEditingController(text: 'Ns. Siti Rahma, S.Kep');
  final _verifierNameCtrl =
      TextEditingController(text: 'dr. Hendra Gunawan, Sp.PK');
  bool _isLoading = false;

  final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

  @override
  void initState() {
    super.initState();
    _resultControllers = {};
    _flags = {};
    _notesControllers = {};

    for (final item in widget.order.items) {
      _resultControllers[item.id] =
          TextEditingController(text: item.resultValue ?? '');
      _flags[item.id] = item.flag ?? 'normal';
      _notesControllers[item.id] =
          TextEditingController(text: item.analystNotes ?? '');
    }
  }

  @override
  void dispose() {
    for (final c in _resultControllers.values) {
      c.dispose();
    }
    for (final c in _notesControllers.values) {
      c.dispose();
    }
    _analystNameCtrl.dispose();
    _collectorNameCtrl.dispose();
    _verifierNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final isCito = order.priority.toUpperCase().contains('CITO');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 860,
        height: 740,
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
                    color: isCito ? Colors.red.shade50 : Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.biotech_outlined,
                    color: isCito ? Colors.red.shade700 : Colors.teal.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Lembar Kerja Analis Laboratorium (${order.orderNumber})',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(width: 8),
                          if (isCito)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.shade600,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'CITO / DARURAT',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        'Entri nilai hasil pengujian parameter darah, urin, atau radiologi dan tentukan flag evaluasi klinis.',
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
            const SizedBox(height: 14),

            // Patient & Clinical Banner Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${order.patientName} (${order.patientMrn})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'DPJP: ${order.doctorName}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Dx Pengantar: ${order.clinicalDiagnosis ?? "-"}',
                        style: const TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'Tgl Order: ${dateFormat.format(order.createdAt)}',
                        style: const TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                    ],
                  ),
                  if (order.clinicalNotes != null && order.clinicalNotes!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Catatan Dokter: ${order.clinicalNotes}',
                        style: const TextStyle(color: Colors.amberAccent, fontSize: 11),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Sample Collection Action Bar if not collected yet
            if (order.status == 'ordered')
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.vaccines_outlined, color: Colors.orange, size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Sampel belum ditandai diambil. Harap konfirmasi pengambilan sampel sebelum memasukkan hasil.',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.orange.shade800,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () async {
                        await ref
                            .read(labOrdersProvider.notifier)
                            .collectSample(order.id, _collectorNameCtrl.text.trim());
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sampel berhasil ditandai telah diambil.')),
                          );
                        }
                      },
                      icon: const Icon(Icons.check, size: 14),
                      label: const Text('Tandai Sampel Diambil', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ),

            // Table of Lab Order Items
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SingleChildScrollView(
                  child: DataTable(
                    columnSpacing: 16,
                    columns: const [
                      DataColumn(label: Text('Parameter Tes')),
                      DataColumn(label: Text('Nilai Hasil *')),
                      DataColumn(label: Text('Satuan')),
                      DataColumn(label: Text('Nilai Rujukan')),
                      DataColumn(label: Text('Flagging')),
                    ],
                    rows: order.items.map((item) {
                      final ctrl = _resultControllers[item.id]!;
                      final flag = _flags[item.id] ?? 'normal';

                      return DataRow(
                        cells: [
                          DataCell(
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.testName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                Text('${item.testCode} • ${item.category}', style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
                              ],
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 120,
                              child: TextField(
                                controller: ctrl,
                                decoration: const InputDecoration(
                                  hintText: 'Nilai...',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(item.unit ?? '-', style: const TextStyle(fontSize: 12)),
                          ),
                          DataCell(
                            Text(item.normalRangeText ?? '-', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ),
                          DataCell(
                            DropdownButton<String>(
                              value: flag,
                              isDense: true,
                              underline: const SizedBox(),
                              items: [
                                DropdownMenuItem(
                                  value: 'normal',
                                  child: Text('Normal', style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 11)),
                                ),
                                DropdownMenuItem(
                                  value: 'low',
                                  child: Text('Low (Rendah)', style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold, fontSize: 11)),
                                ),
                                DropdownMenuItem(
                                  value: 'high',
                                  child: Text('High (Tinggi)', style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold, fontSize: 11)),
                                ),
                                DropdownMenuItem(
                                  value: 'critical',
                                  child: Text('Critical (Kritis)', style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.w900, fontSize: 11)),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _flags[item.id] = val);
                                }
                              },
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Analyst and Verifier Names
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _analystNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nama Analis Pemeriksa *',
                      prefixIcon: Icon(Icons.person),
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _verifierNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Dokter Penanggung Jawab Lab (Sp.PK) *',
                      prefixIcon: Icon(Icons.medical_services),
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : () => _saveResults(isFinalVerify: false),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Simpan Sementara'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: Colors.teal.shade800),
                  onPressed: _isLoading ? null : () => _saveResults(isFinalVerify: true),
                  icon: const Icon(Icons.verified_outlined),
                  label: const Text('Verifikasi & Selesaikan Hasil'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveResults({required bool isFinalVerify}) async {
    setState(() => _isLoading = true);

    final results = widget.order.items.map((i) {
      return {
        'itemId': i.id,
        'resultValue': _resultControllers[i.id]?.text.trim() ?? '',
        'flag': _flags[i.id] ?? 'normal',
        'analystNotes': _notesControllers[i.id]?.text.trim(),
        'analyzedBy': _analystNameCtrl.text.trim(),
      };
    }).toList();

    await ref
        .read(labOrdersProvider.notifier)
        .submitResults(widget.order.id, results);

    if (isFinalVerify) {
      await ref
          .read(labOrdersProvider.notifier)
          .verifyOrder(widget.order.id, _verifierNameCtrl.text.trim());
    }

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isFinalVerify
              ? 'Hasil Lab ${widget.order.orderNumber} telah diverifikasi resmi oleh ${_verifierNameCtrl.text}.'
              : 'Hasil Lab ${widget.order.orderNumber} berhasil disimpan sementara.'),
          backgroundColor: isFinalVerify ? Colors.teal.shade800 : Colors.blue.shade800,
        ),
      );
    }
  }
}
