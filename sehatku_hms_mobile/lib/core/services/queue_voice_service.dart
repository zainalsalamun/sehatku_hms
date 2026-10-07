import 'package:flutter/foundation.dart';

import 'queue_voice_platform.dart'
    if (dart.library.js_interop) 'queue_voice_platform_web.dart'
    as voice_platform;

class QueueVoiceService {
  QueueVoiceService._();
  static final QueueVoiceService instance = QueueVoiceService._();

  /// Converts queue code like "A-001" to spelled out words "A, nol nol satu"
  static String spellQueueNumber(String queueNumber) {
    final buffer = StringBuffer();
    for (int i = 0; i < queueNumber.length; i++) {
      final char = queueNumber[i].toUpperCase();
      if (char == '-' || char == ' ') {
        buffer.write(', ');
      } else if (char == '0') {
        buffer.write('nol ');
      } else if (char == '1') {
        buffer.write('satu ');
      } else if (char == '2') {
        buffer.write('dua ');
      } else if (char == '3') {
        buffer.write('tiga ');
      } else if (char == '4') {
        buffer.write('empat ');
      } else if (char == '5') {
        buffer.write('lima ');
      } else if (char == '6') {
        buffer.write('enam ');
      } else if (char == '7') {
        buffer.write('tujuh ');
      } else if (char == '8') {
        buffer.write('delapan ');
      } else if (char == '9') {
        buffer.write('sembilan ');
      } else {
        buffer.write('$char, ');
      }
    }
    return buffer.toString().replaceAll(' ,', ',').replaceAll(', ,', ',').trim();
  }

  /// Formats raw invoice number (e.g. "INV-2026-103") into clean queue code (e.g. "K-103")
  static String formatKasirQueueNumber(String invoiceNumber) {
    if (invoiceNumber.isEmpty) return 'K-01';
    final parts = invoiceNumber.split('-');
    if (parts.isNotEmpty) {
      final last = parts.last;
      return 'K-$last';
    }
    return 'K-01';
  }

  /// Formats raw prescription number (e.g. "RX-2026-001") into clean queue code (e.g. "F-001")
  static String formatFarmasiQueueNumber(String rxNumber) {
    if (rxNumber.isEmpty) return 'F-001';
    final parts = rxNumber.split('-');
    if (parts.isNotEmpty) {
      final last = parts.last;
      return 'F-$last';
    }
    return 'F-001';
  }

  /// Cleans destination room string for natural speech synthesis
  static String cleanDestination(String raw) {
    return raw
        .replaceAll('(', ', ')
        .replaceAll(')', '')
        .replaceAll('-', ' ')
        .replaceAll('  ', ' ')
        .trim();
  }

  /// Announces queue calling with bell chime & Indonesian speech synthesis
  Future<void> announce({
    required String queueNumber,
    required String patientName,
    required String destination,
  }) async {
    final spelledQueue = spellQueueNumber(queueNumber);
    final targetDestination = cleanDestination(destination);
    final spokenText =
        'Panggilan nomor antrean, $spelledQueue. Atas nama, $patientName, silakan menuju ke $targetDestination. Terima kasih.';

    debugPrint('[QueueVoiceService] Announcing: "$spokenText"');

    try {
      voice_platform.playHospitalChimeAndSpeak(spokenText);
    } catch (e) {
      debugPrint('[QueueVoiceService] Voice call failed: $e');
    }
  }

  /// Sound test helper
  Future<void> playTestAnnouncement() async {
    await announce(
      queueNumber: 'A-001',
      patientName: 'Nadia Putri',
      destination: 'Poli Kardiologi, Ruang Satu',
    );
  }
}
