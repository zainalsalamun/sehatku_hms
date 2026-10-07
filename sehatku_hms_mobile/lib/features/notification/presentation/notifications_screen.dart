import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/health_models.dart';
import '../../../shared/widgets/official_receipt_dialog.dart';
import '../../admin/application/admin_state_providers.dart';
import '../../medical_record/application/medical_records_provider.dart';
import '../../patient/presentation/widgets/queue_ticket_dialog.dart';
import '../../pharmacy/application/pharmacy_state_providers.dart';
import '../application/notifications_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _selectedFilter = 'all';

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(dt);
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'appointment':
        return Icons.calendar_month_rounded;
      case 'prescription':
        return Icons.medication_liquid_rounded;
      case 'billing':
        return Icons.receipt_long_rounded;
      case 'clinical':
        return Icons.assignment_turned_in_rounded;
      case 'emergency':
        return Icons.emergency_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'appointment':
        return Colors.blue;
      case 'prescription':
        return Colors.purple;
      case 'billing':
        return Colors.green;
      case 'clinical':
        return AppTheme.primary;
      case 'emergency':
        return Colors.red;
      default:
        return Colors.amber.shade800;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'appointment':
        return 'Reservasi Dokter';
      case 'prescription':
        return 'Instalasi Farmasi';
      case 'billing':
        return 'Kasir & Pembayaran';
      case 'clinical':
        return 'Rekam Medis EMR';
      case 'emergency':
        return 'Peringatan Darurat';
      default:
        return 'Informasi Rumah Sakit';
    }
  }

  void _handleNotificationTap(BuildContext context, AppNotification item) {
    // 1. Mark as read
    if (!item.isRead) {
      ref.read(notificationsProvider.notifier).markAsRead(item.id);
    }

    // 2. Open specific detail modal according to type
    switch (item.type) {
      case 'appointment':
        _openAppointmentDetail(context, item);
        break;
      case 'billing':
        _openBillingDetail(context, item);
        break;
      case 'clinical':
        _openClinicalDetail(context, item);
        break;
      case 'prescription':
        _openPrescriptionDetail(context, item);
        break;
      default:
        _showSystemNoticeDialog(context, item);
        break;
    }
  }

  void _openAppointmentDetail(BuildContext context, AppNotification item) {
    final appointments = ref.read(adminAppointmentsProvider);
    final appt = appointments.firstWhere(
      (a) => a.id == item.targetId || a.queueNumber == item.targetId,
      orElse: () => appointments.isNotEmpty
          ? appointments.first
          : Appointment(
              id: item.targetId ?? 'a1',
              patientName: 'Nadia Putri',
              doctorName: 'dr. Maya Pratama, Sp.JP',
              department: 'Kardiologi & Vaskular',
              queueNumber: 'A-001',
              dateLabel: 'Hari Ini',
              time: '09:30 WIB',
              status: 'Terkonfirmasi',
              reason: 'Pemeriksaan Rutin Jantung',
            ),
    );

    showDialog(
      context: context,
      builder: (_) => QueueTicketDialog(appointment: appt),
    );
  }

  void _openBillingDetail(BuildContext context, AppNotification item) {
    final billing = ref.read(adminBillingProvider);
    final inv = billing.firstWhere(
      (b) => b.id == item.targetId || b.invoiceNumber == item.targetId,
      orElse: () => billing.isNotEmpty
          ? billing.first
          : Invoice(
              id: item.targetId ?? 'inv-1',
              invoiceNumber: 'INV-2026-001',
              patientName: 'Nadia Putri',
              patientMrn: 'MRN-2026-001',
              doctorName: 'dr. Maya Pratama, Sp.JP',
              serviceName: 'Konsultasi Poli Kardiologi & Vaskular',
              amount: 350000,
              status: 'Lunas',
              createdAt: DateTime.now(),
              paymentMethod: 'QRIS Dinamis',
              paidAt: DateTime.now(),
            ),
    );

    showOfficialReceiptDialog(context, inv);
  }

  void _openClinicalDetail(BuildContext context, AppNotification item) {
    final records = ref.read(medicalRecordsProvider);
    final record = records.firstWhere(
      (r) => r.id == item.targetId,
      orElse: () => records.isNotEmpty
          ? records.first
          : MedicalRecord(
              id: item.targetId ?? 'mr-1',
              date: DateFormat('d MMMM yyyy', 'id_ID').format(DateTime.now()),
              doctor: 'dr. Maya Pratama, Sp.JP',
              specialist: 'Kardiologi & Vaskular',
              diagnosis: 'Hipertensi Primer Esensial (ICD-10: I10)',
              medicine: 'Candesartan 8mg (1x1), Amlodipine 5mg (1x1)',
              anamnesis:
                  'Pasien kontrol rutin tensi darah, mengeluhkan pusing ringan di area tengkuk saat beraktivitas berat.',
              physicalExam:
                  'Tekanan Darah: 135/85 mmHg, Nadi: 78x/mnt, RR: 18x/mnt, Suhu: 36.6 C, SpO2: 99%',
              status: 'signed',
            ),
    );

    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: 520,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.assignment_turned_in_rounded,
                        color: AppTheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Lembar Rekam Medis (EMR)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${record.specialist} • ${record.doctor}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(dialogCtx),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildInfoSection(
                  'Tanggal Pemeriksaan',
                  record.date,
                  Icons.calendar_today_outlined,
                ),
                const SizedBox(height: 12),
                _buildInfoSection(
                  'Diagnosa Utama',
                  record.diagnosis,
                  Icons.health_and_safety_outlined,
                  highlight: true,
                ),
                const SizedBox(height: 12),
                _buildInfoSection(
                  'Anamnesis (Keluhan Subjektif)',
                  record.anamnesis.isNotEmpty
                      ? record.anamnesis
                      : 'Pemeriksaan rutin berkala.',
                  Icons.chat_bubble_outline,
                ),
                const SizedBox(height: 12),
                _buildInfoSection(
                  'Pemeriksaan Fisik & Tanda Vital',
                  record.physicalExam.isNotEmpty
                      ? record.physicalExam
                      : 'Dalam batas normal.',
                  Icons.monitor_heart_outlined,
                ),
                const SizedBox(height: 12),
                _buildInfoSection(
                  'Resep & Terapi Medis',
                  record.medicine,
                  Icons.medication_outlined,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(dialogCtx),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Tutup Lembar Medis'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openPrescriptionDetail(BuildContext context, AppNotification item) {
    final prescriptions = ref.read(pharmacyPrescriptionsProvider);
    final rx = prescriptions.firstWhere(
      (p) => p.id == item.targetId || p.prescriptionNumber == item.targetId,
      orElse: () => prescriptions.isNotEmpty
          ? prescriptions.first
          : PharmacyPrescription(
              id: item.targetId ?? '70000000-0000-4000-8000-000000000001',
              prescriptionNumber: 'RX-2026-001',
              patientId: '40000000-0000-4000-8000-000000000001',
              patientName: 'Nadia Putri',
              patientMrn: 'MRN-2026-001',
              insurance: 'BPJS Kesehatan Mandiri',
              doctorId: '30000000-0000-4000-8000-000000000001',
              doctorName: 'dr. Maya Pratama, Sp.JP',
              doctorSpecialist: 'Kardiologi & Vaskular',
              status: 'ready',
              statusLabel: 'Siap Diambil di Loket Farmasi',
              createdAt: DateTime.now(),
              notes: 'Diminum teratur sesudah makan.',
              items: const [
                PharmacyPrescriptionItem(
                  id: '75000000-0000-4000-8000-000000000001',
                  medicineName: 'Amlodipine Besylate',
                  dosage: '5mg',
                  frequency: '1x sehari pagi',
                  route: 'oral',
                  durationDays: 30,
                  instruction: 'Sesudah makan pagi',
                ),
                PharmacyPrescriptionItem(
                  id: '75000000-0000-4000-8000-000000000002',
                  medicineName: 'Candesartan',
                  dosage: '8mg',
                  frequency: '1x sehari malam',
                  route: 'oral',
                  durationDays: 30,
                  instruction: 'Sebelum tidur malam',
                ),
              ],
            ),
    );

    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.medication_liquid_rounded,
                        color: Colors.purple,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Resep ${rx.prescriptionNumber}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Pasien: ${rx.patientName} (${rx.patientMrn})',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(dialogCtx),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: Colors.green.shade800,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rx.statusLabel,
                          style: TextStyle(
                            color: Colors.green.shade900,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Daftar Obat & Aturan Pakai:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                ...rx.items.map(
                  (m) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.medication,
                            color: AppTheme.primary, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${m.medicineName} (${m.dosage})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                'Aturan: ${m.frequency} • ${m.instruction}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${m.durationDays} hari',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (rx.notes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Catatan Dokter: ${rx.notes}',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: const Text('Tutup'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSystemNoticeDialog(BuildContext context, AppNotification item) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              _getIconForType(item.type),
              color: _getColorForType(item.type),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.message,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getTypeLabel(item.type),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _getColorForType(item.type),
                  ),
                ),
                Text(
                  _formatTime(item.createdAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ],
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String label, String value, IconData icon,
      {bool highlight = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight
            ? AppTheme.primary.withValues(alpha: 0.08)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight
              ? AppTheme.primary.withValues(alpha: 0.3)
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: highlight ? AppTheme.primary : Colors.grey.shade700,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
                    color: highlight ? AppTheme.navy : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifState = ref.watch(notificationsProvider);
    final allItems = notifState.items;

    final filtered = allItems.where((n) {
      if (_selectedFilter == 'unread') return !n.isRead;
      if (_selectedFilter == 'appointment') return n.type == 'appointment';
      if (_selectedFilter == 'prescription') return n.type == 'prescription';
      if (_selectedFilter == 'billing') return n.type == 'billing';
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pusat Notifikasi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          if (notifState.unreadCount > 0)
            TextButton.icon(
              onPressed: () {
                ref.read(notificationsProvider.notifier).markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Semua notifikasi ditandai telah dibaca.'),
                    backgroundColor: AppTheme.primary,
                  ),
                );
              },
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('Tandai Dibaca'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(notificationsProvider.notifier).refresh(),
        child: Column(
          children: [
            // Filter Tabs Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildFilterChip('all', 'Semua (${allItems.length})'),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'unread',
                    'Belum Dibaca (${notifState.unreadCount})',
                    highlight: notifState.unreadCount > 0,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip('appointment', 'Reservasi'),
                  const SizedBox(width: 8),
                  _buildFilterChip('prescription', 'Farmasi & Resep'),
                  const SizedBox(width: 8),
                  _buildFilterChip('billing', 'Tagihan'),
                ],
              ),
            ),
            const Divider(height: 1),

            // Notification List
            Expanded(
              child: notifState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.notifications_off_outlined,
                                size: 56,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Tidak ada notifikasi',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Seluruh pembaruan dan aktivitas terkini akan muncul di sini.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            return _buildNotificationTile(context, item);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, {bool highlight = false}) {
    final isSelected = _selectedFilter == key;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      selectedColor: highlight
          ? Colors.red.shade50
          : AppTheme.primary.withValues(alpha: 0.15),
      checkmarkColor: highlight ? Colors.red : AppTheme.primary,
      labelStyle: TextStyle(
        fontSize: 12,
        color: isSelected
            ? (highlight ? Colors.red.shade900 : AppTheme.primary)
            : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) => setState(() => _selectedFilter = key),
    );
  }

  Widget _buildNotificationTile(BuildContext context, AppNotification item) {
    final typeColor = _getColorForType(item.type);
    final typeIcon = _getIconForType(item.type);

    return InkWell(
      onTap: () => _handleNotificationTap(context, item),
      child: Container(
        color: item.isRead
            ? Colors.transparent
            : AppTheme.primary.withValues(alpha: 0.04),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(typeIcon, color: typeColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontWeight: item.isRead
                                ? FontWeight.w600
                                : FontWeight.w800,
                            fontSize: 13,
                            color: item.isRead ? Colors.black87 : AppTheme.navy,
                          ),
                        ),
                      ),
                      Text(
                        _formatTime(item.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.message,
                    style: TextStyle(
                      fontSize: 12,
                      color: item.isRead
                          ? Colors.grey.shade700
                          : Colors.grey.shade900,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getTypeLabel(item.type),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: typeColor,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Text(
                            'Buka Detail',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: typeColor,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 10,
                            color: typeColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!item.isRead) ...[
              const SizedBox(width: 8),
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
