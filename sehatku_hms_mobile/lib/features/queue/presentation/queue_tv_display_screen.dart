import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/services/queue_voice_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../admin/application/admin_state_providers.dart';
import '../../pharmacy/application/pharmacy_state_providers.dart';
import '../application/queue_display_provider.dart';

class QueueTvDisplayScreen extends ConsumerStatefulWidget {
  const QueueTvDisplayScreen({super.key});

  @override
  ConsumerState<QueueTvDisplayScreen> createState() => _QueueTvDisplayScreenState();
}

class _QueueTvDisplayScreenState extends ConsumerState<QueueTvDisplayScreen> {
  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _currentTime = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final queueState = ref.watch(queueDisplayProvider);
    final appointments = ref.watch(adminAppointmentsProvider);
    final pharmacyPrescriptions = ref.watch(pharmacyPrescriptionsProvider);
    final invoices = ref.watch(adminBillingProvider);

    final activeCall = queueState.activeCall;
    final timeFormat = DateFormat('HH:mm:ss');
    final dateFormat = DateFormat('EEEE, d MMMM yyyy', 'id_ID');

    // Filter waiting queues for side cards
    final waitingAppointments = appointments
        .where((a) => a.status == 'Menunggu' || a.status == 'Checked-in')
        .toList();

    final waitingBilling =
        invoices.where((i) => i.status == 'Menunggu').toList();

    final waitingPharmacy = pharmacyPrescriptions
        .where((p) => p.status == 'issued' || p.status == 'dispensing')
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark slate blue professional TV bg
      body: SafeArea(
        child: Column(
          children: [
            // Top TV Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                border: Border(bottom: BorderSide(color: Colors.white12)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.local_hospital_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'KLINIK PRATAMA SEHATKU MEDIKA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                      Text(
                        'Sistem Pemanggilan Antrean Terpadu (Queue Calling Display)',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Voice status & test trigger
                  OutlinedButton.icon(
                    onPressed: () {
                      ref.read(queueDisplayProvider.notifier).toggleMute();
                    },
                    icon: Icon(
                      queueState.isMuted ? Icons.volume_off : Icons.volume_up,
                      size: 18,
                      color: queueState.isMuted ? Colors.red : Colors.greenAccent,
                    ),
                    label: Text(
                      queueState.isMuted ? 'Suara Senyap' : 'Suara Aktif',
                      style: TextStyle(
                        color: queueState.isMuted ? Colors.red : Colors.greenAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: queueState.isMuted ? Colors.red : Colors.greenAccent,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () {
                      if (activeCall != null) {
                        ref.read(queueDisplayProvider.notifier).callPatient(
                              queueNumber: activeCall.queueNumber,
                              patientName: activeCall.patientName,
                              destination: activeCall.destination,
                            );
                      }
                    },
                    icon: const Icon(Icons.replay_rounded, size: 18),
                    label: const Text('Panggil Ulang'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Clock
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${timeFormat.format(_currentTime)} WIB',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Text(
                        dateFormat.format(_currentTime),
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    tooltip: 'Keluar Tampilan TV',
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
            ),

            // Main Content Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left Hero: Active Called Queue Card
                    Expanded(
                      flex: 6,
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.tealAccent.withValues(alpha: 0.6),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.tealAccent.withValues(alpha: 0.15),
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: activeCall == null
                            ? const Center(
                                child: Text(
                                  'Belum ada antrean yang dipanggil.',
                                  style: TextStyle(color: Colors.white70, fontSize: 18),
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.tealAccent.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(color: Colors.tealAccent),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.campaign, color: Colors.tealAccent, size: 22),
                                        SizedBox(width: 8),
                                        Text(
                                          'SEDANG DIPANGGIL',
                                          style: TextStyle(
                                            color: Colors.tealAccent,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 2,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),

                                  // Big Queue Number
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      activeCall.queueNumber,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 120,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 4,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // Patient Name
                                  Text(
                                    activeCall.patientName,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),

                                  // Destination Room Banner
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.teal.shade700,
                                          Colors.cyan.shade800,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      children: [
                                        const Text(
                                          'SILAKAN MENUJU KE:',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          activeCall.destination.toUpperCase(),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(width: 20),

                    // Right Side: Sub-counters Waiting Lists
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          // Poli Dokter Waiting
                          Expanded(
                            child: _counterWaitingCard(
                              title: 'Poli Dokter (Rawat Jalan)',
                              badge: '${waitingAppointments.length} Pasien',
                              icon: Icons.medical_services_outlined,
                              color: Colors.blue,
                              items: waitingAppointments
                                  .take(4)
                                  .map((a) => (a.queueNumber, a.patientName, a.department))
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Kasir Waiting
                          Expanded(
                            child: _counterWaitingCard(
                              title: 'Loket Pembayaran & Kasir',
                              badge: '${waitingBilling.length} Antrean',
                              icon: Icons.payments_outlined,
                              color: Colors.orange,
                              items: waitingBilling
                                  .take(4)
                                  .map((b) => (
                                        QueueVoiceService.formatKasirQueueNumber(b.invoiceNumber),
                                        b.patientName,
                                        'Loket Kasir 1',
                                      ))
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Farmasi Waiting
                          Expanded(
                            child: _counterWaitingCard(
                              title: 'Loket Farmasi & Obat',
                              badge: '${waitingPharmacy.length} Resep',
                              icon: Icons.medication_outlined,
                              color: Colors.green,
                              items: waitingPharmacy
                                  .take(4)
                                  .map((p) => (
                                        QueueVoiceService.formatFarmasiQueueNumber(p.prescriptionNumber),
                                        p.patientName,
                                        'Loket Obat',
                                      ))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Running Text Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: const Color(0xFF0284C7),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Selamat datang di Klinik Pratama SehatKu Medika • Mohon perhatikan nomor antrean Anda dan persiapkan kartu identitas atau buku berobat • Layanan beroperasi Senin - Sabtu pukul 08:00 s/d 21:00 WIB • Emergency Hotline: (021) 555-8900.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _counterWaitingCard({
    required String title,
    required String badge,
    required IconData icon,
    required Color color,
    required List<(String, String, String)> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.5)),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 14),
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text(
                      'Tidak ada antrean menunggu.',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  )
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, idx) {
                      final item = items[idx];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              constraints: const BoxConstraints(minWidth: 54),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.$1,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.$2,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
