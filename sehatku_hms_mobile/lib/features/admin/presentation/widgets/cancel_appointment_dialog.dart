import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class CancelAppointmentDialog extends StatefulWidget {
  const CancelAppointmentDialog({
    super.key,
    required this.patientName,
    required this.queueNumber,
    required this.onConfirm,
  });

  final String patientName;
  final String queueNumber;
  final ValueChanged<String> onConfirm;

  @override
  State<CancelAppointmentDialog> createState() =>
      _CancelAppointmentDialogState();
}

class _CancelAppointmentDialogState extends State<CancelAppointmentDialog> {
  final _reasonController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() => _errorText = 'Alasan pembatalan wajib diisi');
      return;
    }
    widget.onConfirm(reason);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.error),
          const SizedBox(width: 10),
          const Text('Batalkan Reservasi Dokter'),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apakah Anda yakin ingin membatalkan antrean ${widget.queueNumber} atas nama pasien ${widget.patientName}?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Alasan Pembatalan *',
                hintText: 'Misal: Dokter berhalangan hadir / Pasien reschedule via telepon',
                border: const OutlineInputBorder(),
                errorText: _errorText,
              ),
              onChanged: (_) {
                if (_errorText != null) {
                  setState(() => _errorText = null);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Kembali'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: _submit,
          child: const Text('Konfirmasi Batalkan'),
        ),
      ],
    );
  }
}
