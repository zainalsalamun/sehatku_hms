import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/models/health_models.dart';
import '../../application/inpatient_state_providers.dart';
import 'inpatient_discharge_summary_dialog.dart';

class InpatientDischargeDialog extends ConsumerStatefulWidget {
  const InpatientDischargeDialog({super.key, required this.admission});

  final InpatientAdmissionModel admission;

  @override
  ConsumerState<InpatientDischargeDialog> createState() =>
      _InpatientDischargeDialogState();
}

class _InpatientDischargeDialogState
    extends ConsumerState<InpatientDischargeDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _dischargeDiagnosisCtrl;
  String _dischargeCondition = 'Sembuh';
  final _notesCtrl = TextEditingController(
    text:
        'Pasien telah melewati fase kritis dan diijinkan rawat jalan. Kontrol poli dalam 3 hari.',
  );
  bool _isLoading = false;

  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _dischargeDiagnosisCtrl = TextEditingController(
      text: widget.admission.initialDiagnosis != null
          ? '${widget.admission.initialDiagnosis} - Klinis Membaik'
          : 'Kondisi Klinis Membaik',
    );
  }

  @override
  void dispose() {
    _dischargeDiagnosisCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admission = widget.admission;
    final admissionDate = admission.admissionDate;
    final now = DateTime.now();
    final diff = now.difference(admissionDate);
    final days = (diff.inDays <= 0) ? 1 : diff.inDays + 1;
    final totalRoomCost = days * admission.dailyRate;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 650,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
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
                      child: const Icon(
                        Icons.output_outlined,
                        color: Colors.green,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pemulangan Pasien Rawat Inap (Discharge & Resume)',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Selesaikan rawat inap, bebaskan bed untuk sterilisasi, dan kirim tagihan ke Kasir.',
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
                const SizedBox(height: 18),

                // Patient & Bed Info Card
                Container(
                  padding: const EdgeInsets.all(16),
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
                            admission.patientName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.tealAccent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.tealAccent),
                            ),
                            child: Text(
                              admission.admissionNumber,
                              style: const TextStyle(
                                color: Colors.tealAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'No. RM: ${admission.patientMrn} • Penjamin: ${admission.patientInsurance} • DPJP: ${admission.doctorName}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const Divider(color: Colors.white24, height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Kamar / Kelas',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                '${admission.roomName} (${admission.bedNumber}) - ${admission.classType}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Lama Hari Rawat',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                '$days Hari (Tarif: ${currencyFormat.format(admission.dailyRate)}/hari)',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Biaya Kamar Ranap:',
                              style: TextStyle(
                                color: Colors.tealAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              currencyFormat.format(totalRoomCost),
                              style: const TextStyle(
                                color: Colors.tealAccent,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Kondisi Keluar
                DropdownButtonFormField<String>(
                  initialValue: _dischargeCondition,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Kondisi Saat Pulang *',
                    prefixIcon: Icon(Icons.health_and_safety_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Sembuh',
                      child: Text(
                        'Sembuh (Kondisi Sehat / Pulih)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Perbaikan',
                      child: Text(
                        'Perbaikan (Boleh Rawat Jalan / Kontrol)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Rujuk RS Lain',
                      child: Text(
                        'Rujuk ke RS Tingkat Lanjutan / Subspesialis',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Pulang Paksa',
                      child: Text(
                        'Pulang Atas Permintaan Sendiri (APS / Pulang Paksa)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Meninggal',
                      child: Text(
                        'Meninggal Dunia',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  onChanged: (v) =>
                      setState(() => _dischargeCondition = v ?? 'Sembuh'),
                ),
                const SizedBox(height: 14),

                // Diagnosa Akhir / Resume Pulang
                TextFormField(
                  controller: _dischargeDiagnosisCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Diagnosa Akhir / Resume Klinis Pulang *',
                    prefixIcon: Icon(Icons.description_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.isEmpty
                      ? 'Diagnosa akhir wajib diisi'
                      : null,
                ),
                const SizedBox(height: 14),

                // Catatan & Edukasi Pasien
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText:
                        'Instruksi Pulang, Edukasi Obat & Rencana Kontrol',
                    prefixIcon: Icon(Icons.edit_note),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        showInpatientDischargeSummaryDialog(
                          context,
                          admission.copyWith(
                            dischargeDiagnosis: _dischargeDiagnosisCtrl.text.trim(),
                            dischargeCondition: _dischargeCondition,
                            notes: _notesCtrl.text.trim(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.description_outlined, size: 16),
                      label: const Text('Pratinjau Resume Medis'),
                    ),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Batal'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  final messenger = ScaffoldMessenger.of(context);
                                  final navigator = Navigator.of(context);
                                  setState(() => _isLoading = true);

                                  final res = await ref
                                      .read(inpatientAdmissionsProvider.notifier)
                                      .dischargePatient(
                                        admissionId: admission.id,
                                        dischargeDiagnosis: _dischargeDiagnosisCtrl
                                            .text
                                            .trim(),
                                        dischargeCondition: _dischargeCondition,
                                        notes: _notesCtrl.text.trim(),
                                      );

                                  if (mounted) {
                                    setState(() => _isLoading = false);
                                    navigator.pop();

                                    if (res != null) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Pemulangan ${admission.patientName} berhasil! Invoice kamar (${currencyFormat.format(totalRoomCost)}) otomatis diteruskan ke Kasir.',
                                          ),
                                          backgroundColor: Colors.green,
                                          action: SnackBarAction(
                                            label: 'Buka Resume',
                                            textColor: Colors.white,
                                            onPressed: () {
                                              showInpatientDischargeSummaryDialog(
                                                context,
                                                res,
                                              );
                                            },
                                          ),
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
                              : const Icon(Icons.check_circle_outline),
                          label: const Text('Selesaikan Pemulangan & Buat Invoice'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
