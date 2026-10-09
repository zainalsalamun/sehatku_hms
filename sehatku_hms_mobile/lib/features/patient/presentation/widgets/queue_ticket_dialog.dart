import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/document_template_helper.dart';
import '../../../../core/utils/print_helper.dart';
import '../../../../shared/models/health_models.dart';
import '../../../admin/application/admin_state_providers.dart';

class QueueTicketDialog extends ConsumerStatefulWidget {
  const QueueTicketDialog({
    super.key,
    required this.appointment,
    this.currentServingNumber = 'A-029',
  });

  final Appointment appointment;
  final String currentServingNumber;

  @override
  ConsumerState<QueueTicketDialog> createState() => _QueueTicketDialogState();
}

class _QueueTicketDialogState extends ConsumerState<QueueTicketDialog> {
  late String _status;
  bool _isCheckingIn = false;

  @override
  void initState() {
    super.initState();
    _status = widget.appointment.status;
  }

  bool get _isExpired =>
      widget.appointment.isExpired ||
      _status == 'Kadaluarsa' ||
      _status == 'Kedaluwarsa' ||
      _status == 'Tidak Berlaku' ||
      _status == 'Hangus';

  bool get _isSelesai => _status == 'Selesai';
  bool get _isDibatalkan => _status == 'Dibatalkan';
  bool get _isCheckedIn => _status == 'Checked-in';

  bool get _canCheckIn =>
      !_isCheckedIn && !_isSelesai && !_isDibatalkan && !_isExpired;

  void _handleCheckIn() {
    if (!_canCheckIn) return;

    setState(() => _isCheckingIn = true);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      ref
          .read(adminAppointmentsProvider.notifier)
          .checkInAppointment(widget.appointment.id);
      setState(() {
        _isCheckingIn = false;
        _status = 'Checked-in';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Berhasil check-in untuk antrean ${widget.appointment.queueNumber}! Silakan menuju ruang tunggu.',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppTheme.primary.withValues(
                            alpha: 0.15,
                          ),
                          child: const Icon(
                            Icons.confirmation_number_outlined,
                            color: AppTheme.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Tiket Antrean Digital',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
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
              const Divider(height: 24),

              // Live Queue Monitor Box (or Status Box if completed/expired)
              if (!_isSelesai && !_isDibatalkan && !_isExpired)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.navy,
                        AppTheme.navy.withValues(alpha: 0.85),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.navy.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'SEDANG DILAYANI',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.currentServingNumber,
                                  style: const TextStyle(
                                    color: Colors.amberAccent,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 38,
                            width: 1,
                            color: Colors.white24,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'NOMOR ANTREAN ANDA',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.appointment.queueNumber,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.hourglass_top,
                              size: 14,
                              color: Colors.white70,
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Sisa antrean di depan Anda (Est. 15 mnt)',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                _buildStatusBanner(),

              const SizedBox(height: 20),

              // QR Code Card
              Center(
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isExpired || _isDibatalkan
                              ? AppColors.errorBorder
                              : (_isSelesai
                                    ? AppColors.infoBorder
                                    : AppColors.grey300),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Dual Identifier Header Badges
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.navy.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.navy.withValues(alpha: 0.25)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.bookmark_border, size: 14, color: AppTheme.navy),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.appointment.displayReservationNumber,
                                      style: const TextStyle(
                                        color: AppTheme.navy,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green.shade300),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.confirmation_number_outlined, size: 14, color: Colors.green.shade800),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Antrean ${widget.appointment.queueNumber}',
                                      style: TextStyle(
                                        color: Colors.green.shade800,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isExpired
                                    ? AppColors.grey300
                                    : (_isDibatalkan
                                        ? AppColors.errorBorder
                                        : AppColors.grey200),
                              ),
                            ),
                            child: _isExpired
                                ? Opacity(
                                    opacity: 0.35,
                                    child: QrImageView(
                                      data: widget.appointment.displayReservationNumber,
                                      version: QrVersions.auto,
                                      size: 140.0,
                                      gapless: false,
                                      eyeStyle: const QrEyeStyle(
                                        eyeShape: QrEyeShape.square,
                                        color: AppColors.grey400,
                                      ),
                                      dataModuleStyle: const QrDataModuleStyle(
                                        dataModuleShape: QrDataModuleShape.square,
                                        color: AppColors.grey400,
                                      ),
                                    ),
                                  )
                                : _isDibatalkan
                                    ? Opacity(
                                        opacity: 0.35,
                                        child: QrImageView(
                                          data: widget.appointment.displayReservationNumber,
                                          version: QrVersions.auto,
                                          size: 140.0,
                                          gapless: false,
                                          eyeStyle: const QrEyeStyle(
                                            eyeShape: QrEyeShape.square,
                                            color: AppColors.error,
                                          ),
                                          dataModuleStyle: const QrDataModuleStyle(
                                            dataModuleShape: QrDataModuleShape.square,
                                            color: AppColors.error,
                                          ),
                                        ),
                                      )
                                    : QrImageView(
                                        data: widget.appointment.displayReservationNumber,
                                        version: QrVersions.auto,
                                        size: 140.0,
                                        gapless: false,
                                        eyeStyle: const QrEyeStyle(
                                          eyeShape: QrEyeShape.square,
                                          color: Colors.black87,
                                        ),
                                        dataModuleStyle: const QrDataModuleStyle(
                                          dataModuleShape: QrDataModuleShape.square,
                                          color: Colors.black87,
                                        ),
                                      ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Scan QR Code / Masukkan No. Reservasi di APM Kiosk',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildQrStatusSubtitle(),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Detail List
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _itemRow('No. Reservasi', widget.appointment.displayReservationNumber),
                    const Divider(height: 14),
                    _itemRow('No. Antrean', widget.appointment.queueNumber),
                    const Divider(height: 14),
                    _itemRow('Dokter', widget.appointment.doctorName),
                    const Divider(height: 14),
                    _itemRow('Poli / Spesialis', widget.appointment.department),
                    const Divider(height: 14),
                    _itemRow(
                      'Waktu Jadwal',
                      '${widget.appointment.dateLabel} • ${widget.appointment.time}',
                    ),
                    const Divider(height: 14),
                    _itemRow(
                      'Status Reservasi',
                      _getStatusDisplay(),
                      isBadge: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              OutlinedButton.icon(
                onPressed: () {
                  final html = DocumentTemplateHelper.generateQueueTicketHtml(
                    queueNumber: widget.appointment.queueNumber,
                    patientName: widget.appointment.patientName,
                    doctorName: widget.appointment.doctorName,
                    department: widget.appointment.department,
                    dateLabel: widget.appointment.dateLabel,
                    time: widget.appointment.time,
                    status: _status,
                  );
                  printHtmlDocument(
                    title: 'Karcis Antrean ${widget.appointment.queueNumber} - ${widget.appointment.patientName}',
                    htmlContent: html,
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.print_outlined, size: 18),
                label: const Text('Cetak Karcis Antrean (Thermal / PDF)'),
              ),
              const SizedBox(height: 10),

              // Action Check-in Button or Close Button
              if (_canCheckIn)
                FilledButton.icon(
                  onPressed: _isCheckingIn ? null : _handleCheckIn,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isCheckingIn
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.qr_code_scanner, size: 18),
                  label: Text(
                    _isCheckingIn
                        ? 'Memproses Check-In...'
                        : 'Simulasikan Check-In Kiosk',
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    _isExpired || _isDibatalkan ? Icons.close : Icons.check,
                    size: 18,
                    color: _isExpired || _isDibatalkan
                        ? Colors.grey.shade700
                        : (_isSelesai ? Colors.blue : Colors.green),
                  ),
                  label: Text(
                    _isExpired
                        ? 'Tutup (Jadwal Terlewat)'
                        : (_isDibatalkan
                              ? 'Tutup (Dibatalkan)'
                              : (_isSelesai
                                    ? 'Tutup (Pemeriksaan Selesai)'
                                    : 'Tutup Tiket Antrean')),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    Color bg;
    Color border;
    Color text;
    IconData icon;
    String title;
    String subtitle;

    if (_isSelesai) {
      bg = Colors.blue.shade50;
      border = Colors.blue.shade200;
      text = Colors.blue.shade900;
      icon = Icons.check_circle_rounded;
      title = 'Pemeriksaan Telah Selesai';
      subtitle =
          'Sesi konsultasi medis telah tuntas dan rekam medis telah ditandatangani.';
    } else if (_isDibatalkan) {
      bg = Colors.red.shade50;
      border = Colors.red.shade200;
      text = Colors.red.shade900;
      icon = Icons.cancel_rounded;
      title = 'Reservasi Dibatalkan';
      subtitle =
          'Reservasi ini telah dibatalkan sehingga tidak dapat check-in.';
    } else {
      // Expired / Terlewat / Tidak Berlaku
      bg = Colors.red.shade50;
      border = Colors.red.shade200;
      text = Colors.red.shade900;
      icon = Icons.event_busy;
      title = 'Reservasi Tidak Berlaku (Lewat Hari H)';
      subtitle =
          'Jadwal reservasi ini telah melewati hari H pelaksanaan dan sudah tidak dapat digunakan lagi. Silakan buat reservasi baru.';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: text, size: 24),
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
                    color: text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: text, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrStatusSubtitle() {
    IconData icon;
    String text;
    Color color;

    if (_isSelesai) {
      icon = Icons.check_circle_outline;
      text = 'Pemeriksaan Medis Selesai';
      color = Colors.blue.shade800;
    } else if (_isDibatalkan) {
      icon = Icons.cancel_outlined;
      text = 'Reservasi Dibatalkan (Tidak Berlaku)';
      color = Colors.red.shade700;
    } else if (_isExpired) {
      icon = Icons.warning_amber_rounded;
      text = 'Tiket Tidak Berlaku (Jadwal Terlewat)';
      color = Colors.red.shade700;
    } else if (_isCheckedIn) {
      icon = Icons.check_circle_outline;
      text = 'Pasien Telah Check-In di Poli';
      color = Colors.green.shade800;
    } else {
      icon = Icons.qr_code_scanner;
      text = 'Scan barcode ini di mesin Kiosk Rumah Sakit';
      color = Colors.grey.shade700;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: _isCheckedIn || _isSelesai
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  String _getStatusDisplay() {
    if (_isExpired) return 'Tidak Berlaku (Lewat Hari H)';
    return _status;
  }

  Widget _itemRow(String label, String value, {bool isBadge = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        const SizedBox(width: 12),
        if (isBadge)
          Flexible(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _isSelesai
                    ? Colors.blue.shade50
                    : (_isDibatalkan
                          ? Colors.red.shade50
                          : (_isExpired
                                ? Colors.amber.shade50
                                : (_isCheckedIn
                                      ? Colors.green.shade50
                                      : Colors.orange.shade50))),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _isSelesai
                      ? Colors.blue.shade800
                      : (_isDibatalkan
                            ? Colors.red.shade800
                            : (_isExpired
                                  ? Colors.amber.shade900
                                  : (_isCheckedIn
                                        ? Colors.green.shade800
                                        : Colors.orange.shade900))),
                ),
              ),
            ),
          )
        else
          Expanded(
            flex: 3,
            child: Text(
              value,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}
