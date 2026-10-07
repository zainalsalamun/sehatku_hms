import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/models/health_models.dart';
import '../../application/inpatient_state_providers.dart';

class InpatientTransferBedDialog extends ConsumerStatefulWidget {
  const InpatientTransferBedDialog({super.key, required this.admission});

  final InpatientAdmissionModel admission;

  @override
  ConsumerState<InpatientTransferBedDialog> createState() =>
      _InpatientTransferBedDialogState();
}

class _InpatientTransferBedDialogState
    extends ConsumerState<InpatientTransferBedDialog> {
  final _formKey = GlobalKey<FormState>();

  RoomBedModel? _selectedNewBed;
  final _reasonCtrl = TextEditingController(
    text: 'Permintaan upgrade kelas kamar oleh keluarga pasien',
  );
  bool _isLoading = false;

  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admission = widget.admission;
    final beds = ref.watch(inpatientBedsProvider);
    final availableBeds = beds.where((b) => b.status == 'available').toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 620,
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
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.swap_horiz,
                        color: Colors.orange,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pindah Kamar & Bed Pasien (Transfer Bed)',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Pindahkan pasien ke kamar atau kelas lain. Bed lama akan otomatis berstatus cleaning.',
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

                // Current Bed Info
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.meeting_room_outlined,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pasien: ${admission.patientName} (${admission.patientMrn})',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'Kamar Saat Ini: ${admission.roomName} (${admission.bedNumber}) - ${admission.classType}',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Select New Bed
                DropdownButtonFormField<RoomBedModel>(
                  initialValue: _selectedNewBed,
                  decoration: const InputDecoration(
                    labelText: 'Pilih Kamar & Bed Tujuan (Tersedia) *',
                    prefixIcon: Icon(Icons.single_bed_outlined),
                    border: OutlineInputBorder(),
                  ),
                  isExpanded: true,
                  items: availableBeds.map((b) {
                    return DropdownMenuItem(
                      value: b,
                      child: Text(
                        '${b.roomName} (${b.roomNumber}) - ${b.bedNumber} [${b.classType}] • ${currencyFormat.format(b.dailyRate)}/malam',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (b) => setState(() => _selectedNewBed = b),
                  validator: (v) =>
                      v == null ? 'Pilih kamar & bed tujuan' : null,
                ),
                const SizedBox(height: 14),

                // Reason for Transfer
                TextFormField(
                  controller: _reasonCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Alasan Pemindahan Kamar *',
                    prefixIcon: Icon(Icons.notes),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.isEmpty
                      ? 'Alasan pemindahan wajib diisi'
                      : null,
                ),
                const SizedBox(height: 24),

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
                        backgroundColor: Colors.orange.shade800,
                      ),
                      onPressed: _isLoading
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) return;
                              setState(() => _isLoading = true);

                              final res = await ref
                                  .read(inpatientAdmissionsProvider.notifier)
                                  .transferBed(
                                    admissionId: admission.id,
                                    newBedId: _selectedNewBed!.id,
                                    reason: _reasonCtrl.text.trim(),
                                  );

                              if (mounted) {
                                setState(() => _isLoading = false);
                                Navigator.of(context).pop();

                                if (res != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Pasien ${admission.patientName} berhasil dipindahkan ke ${_selectedNewBed!.roomName} (${_selectedNewBed!.bedNumber}).',
                                      ),
                                      backgroundColor: Colors.orange.shade800,
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
                          : const Icon(Icons.swap_horiz),
                      label: const Text('Konfirmasi Pindah Kamar'),
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
