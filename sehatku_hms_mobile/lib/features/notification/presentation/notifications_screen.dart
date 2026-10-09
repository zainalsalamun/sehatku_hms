import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/health_models.dart';
import '../../../shared/widgets/official_receipt_dialog.dart';
import '../../admin/application/admin_state_providers.dart';
import '../../authentication/application/auth_controller.dart';
import '../../doctor/presentation/clinical_encounter_screen.dart';
import '../../inpatient/application/inpatient_state_providers.dart';
import '../../inpatient/presentation/widgets/inpatient_cppt_dialog.dart';
import '../../laboratory/application/laboratory_state_providers.dart';
import '../../laboratory/presentation/widgets/lab_result_print_dialog.dart';
import '../../medical_record/application/certificates_provider.dart';
import '../../medical_record/application/medical_records_provider.dart';
import '../../medical_record/presentation/widgets/medical_certificate_dialog.dart';
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
      case 'lab':
        return Icons.biotech_rounded;
      case 'certificate':
      case 'skd':
        return Icons.description_rounded;
      case 'inpatient':
        return Icons.hotel_rounded;
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
      case 'lab':
        return Colors.indigo;
      case 'certificate':
      case 'skd':
        return Colors.teal;
      case 'inpatient':
        return Colors.deepPurple;
      case 'emergency':
        return Colors.red;
      default:
        return Colors.amber.shade800;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'appointment':
        return 'Reservasi & Antrean Poli';
      case 'prescription':
        return 'Instalasi Farmasi & Obat';
      case 'billing':
        return 'Kasir & Pembayaran';
      case 'clinical':
        return 'Rekam Medis (EMR)';
      case 'lab':
        return 'Hasil Laboratorium';
      case 'certificate':
      case 'skd':
        return 'Surat Keterangan Sakit';
      case 'inpatient':
        return 'Rawat Inap & DPJP';
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
      case 'lab':
        _openLabDetail(context, item);
        break;
      case 'certificate':
      case 'skd':
        _openCertificateDetail(context, item);
        break;
      case 'inpatient':
        _openInpatientDetail(context, item);
        break;
      default:
        _showSystemNoticeDialog(context, item);
        break;
    }
  }

  void _openAppointmentDetail(BuildContext context, AppNotification item) {
    final appointments = ref.read(adminAppointmentsProvider);
    var matches = appointments.where(
      (a) => a.id == item.targetId || a.queueNumber == item.targetId,
    ).toList();

    if (matches.isEmpty) {
      matches = appointments.where((a) {
        return item.message.contains(a.queueNumber) ||
            item.title.contains(a.queueNumber) ||
            item.message.toLowerCase().contains(a.patientName.toLowerCase());
      }).toList();
    }

    if (matches.isEmpty) {
      _showSystemNoticeDialog(
        context,
        item,
        fallbackNotice: 'Data reservasi/antrean pasien terkait tidak ditemukan atau telah diarsipkan.',
      );
      return;
    }

    final appt = matches.first;
    final auth = ref.read(authControllerProvider);

    // If logged in as Doctor and appointment is active/waiting, provide direct EMR SOAP option
    if (auth.role == UserRole.doctor) {
      final patients = ref.read(adminPatientsProvider);
      final patient = patients.where((p) => p.name == appt.patientName).firstOrNull;

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (sheetCtx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_pin_circle_outlined, color: Colors.blue),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appt.patientName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            'Antrean ${appt.queueNumber} • ${appt.time} • Status: ${appt.status}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Text('Keluhan Pasien: ${appt.reason}', style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.confirmation_number_outlined),
                        label: const Text('Lihat Antrean'),
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          showDialog(
                            context: context,
                            builder: (_) => QueueTicketDialog(appointment: appt),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
                        icon: const Icon(Icons.assignment_turned_in_outlined),
                        label: const Text('Buka SOAP (EMR)'),
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ClinicalEncounterScreen(
                                appointment: appt,
                                patient: patient,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    // Default for Patient and Admin
    showDialog(
      context: context,
      builder: (_) => QueueTicketDialog(appointment: appt),
    );
  }

  void _openBillingDetail(BuildContext context, AppNotification item) {
    final billings = ref.read(adminBillingProvider);
    final matchInvoice = billings.where(
      (inv) => inv.id == item.targetId || inv.invoiceNumber == item.targetId,
    ).firstOrNull;

    if (matchInvoice != null) {
      showOfficialReceiptDialog(context, matchInvoice);
      return;
    }

    if (billings.isNotEmpty) {
      showOfficialReceiptDialog(context, billings.first);
      return;
    }

    _showSystemNoticeDialog(
      context,
      item,
      fallbackNotice: 'Lembar rincian tagihan atau kuitansi sedang disinkronkan.',
    );
  }

  void _openClinicalDetail(BuildContext context, AppNotification item) {
    // 1. Check if targetId matches an EMR record
    final records = ref.read(medicalRecordsProvider);
    final matchRecord = records.where((r) => r.id == item.targetId).firstOrNull;
    if (matchRecord != null) {
      _showEMRDialog(context, matchRecord);
      return;
    }

    // 2. Check if targetId matches a Medical Certificate (SKD)
    final certs = ref.read(medicalCertificatesProvider);
    final matchCert = certs.where(
      (c) => c.id == item.targetId || c.certificateNumber == item.targetId,
    ).firstOrNull;
    if (matchCert != null) {
      showMedicalCertificateDialog(context, matchCert);
      return;
    }

    // 3. Check if targetId matches a Lab Order
    final labs = ref.read(labOrdersProvider);
    final matchLab = labs.where(
      (l) => l.id == item.targetId || l.orderNumber == item.targetId,
    ).firstOrNull;
    if (matchLab != null) {
      showDialog(
        context: context,
        builder: (_) => LabResultPrintDialog(order: matchLab),
      );
      return;
    }

    // 4. Check if targetId matches an appointment for clinical consultation
    final appts = ref.read(adminAppointmentsProvider);
    final matchAppt = appts.where(
      (a) => a.id == item.targetId || a.queueNumber == item.targetId,
    ).firstOrNull;
    if (matchAppt != null) {
      final patients = ref.read(adminPatientsProvider);
      final patient = patients.where((p) => p.name == matchAppt.patientName).firstOrNull;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ClinicalEncounterScreen(
            appointment: matchAppt,
            patient: patient,
          ),
        ),
      );
      return;
    }

    _showSystemNoticeDialog(
      context,
      item,
      fallbackNotice: 'Lembar medis terkait sedang dalam sinkronisasi atau diarsipkan.',
    );
  }

  void _showEMRDialog(BuildContext context, MedicalRecord record) {
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
    // 1. Check in pharmacyPrescriptionsProvider
    final prescriptions = ref.read(pharmacyPrescriptionsProvider);
    final matchRx = prescriptions.where(
      (p) => p.id == item.targetId || p.prescriptionNumber == item.targetId,
    ).firstOrNull;
    if (matchRx != null) {
      _showPrescriptionDialog(context, matchRx);
      return;
    }

    // 2. Check in pharmacyInventoryProvider (e.g. stock warning targetId: 'med-4')
    final medicines = ref.read(pharmacyInventoryProvider);
    final matchMed = medicines.where((m) {
      return m.id == item.targetId ||
          m.name.toLowerCase() == item.targetId?.toLowerCase() ||
          item.message.toLowerCase().contains(m.name.toLowerCase());
    }).firstOrNull;
    if (matchMed != null) {
      _showMedicineStockDialog(context, matchMed, item);
      return;
    }

    _showSystemNoticeDialog(
      context,
      item,
      fallbackNotice: 'Data resep atau stok obat tidak ditemukan di modul farmasi.',
    );
  }

  void _showPrescriptionDialog(BuildContext context, PharmacyPrescription rx) {
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

  void _showMedicineStockDialog(
    BuildContext context,
    MedicineStock med,
    AppNotification item,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      Icons.inventory_2_outlined,
                      color: Colors.purple,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Peringatan Inventaris Obat',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          med.name,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (med.stock <= med.minStock)
                      ? Colors.red.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (med.stock <= med.minStock)
                        ? Colors.red.shade200
                        : Colors.green.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      (med.stock <= med.minStock)
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_outline,
                      color: (med.stock <= med.minStock)
                          ? Colors.red.shade800
                          : Colors.green.shade800,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        (med.stock <= med.minStock)
                            ? 'Stok Kritis: ${med.stock} ${med.unit} (Batas Min: ${med.minStock} ${med.unit})'
                            : 'Stok Aman: ${med.stock} ${med.unit}',
                        style: TextStyle(
                          color: (med.stock <= med.minStock)
                              ? Colors.red.shade900
                              : Colors.green.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _buildInfoSection('Kategori Obat', med.category, Icons.category_outlined),
              const SizedBox(height: 10),
              _buildInfoSection(
                'Nomor Batch & Sediaan',
                '${med.batchNumber} • ${med.form}',
                Icons.medical_services_outlined,
              ),
              const SizedBox(height: 10),
              _buildInfoSection(
                'Estimasi Kadaluarsa',
                DateTime.tryParse(med.expirationDate) != null
                    ? DateFormat('d MMMM yyyy', 'id_ID')
                        .format(DateTime.parse(med.expirationDate))
                    : med.expirationDate,
                Icons.event_outlined,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(dialogCtx),
                      child: const Text('Tutup'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        ref
                            .read(pharmacyInventoryProvider.notifier)
                            .restock(med.id, 50);
                        Navigator.pop(dialogCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Berhasil restock +50 ${med.unit} untuk ${med.name}.',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_shopping_cart, size: 16),
                      label: const Text('Restock +50'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openLabDetail(BuildContext context, AppNotification item) {
    final labs = ref.read(labOrdersProvider);
    var matchLab = labs.where(
      (l) => l.id == item.targetId || l.orderNumber == item.targetId,
    ).firstOrNull;

    if (matchLab == null) {
      matchLab = labs.where((l) {
        return item.message.contains(l.orderNumber) ||
            item.message.toLowerCase().contains(l.patientName.toLowerCase());
      }).firstOrNull;
    }

    if (matchLab != null) {
      showDialog(
        context: context,
        builder: (_) => LabResultPrintDialog(order: matchLab!),
      );
      return;
    }

    _showSystemNoticeDialog(
      context,
      item,
      fallbackNotice: 'Lembar hasil laboratorium belum tersedia atau sedang dianalisis analis.',
    );
  }

  void _openCertificateDetail(BuildContext context, AppNotification item) {
    final certs = ref.read(medicalCertificatesProvider);
    var matchCert = certs.where(
      (c) => c.id == item.targetId || c.certificateNumber == item.targetId,
    ).firstOrNull;

    if (matchCert == null) {
      matchCert = certs.where((c) {
        return item.message.contains(c.certificateNumber) ||
            item.message.toLowerCase().contains(c.patientName.toLowerCase());
      }).firstOrNull;
    }

    if (matchCert != null) {
      showMedicalCertificateDialog(context, matchCert!);
      return;
    }

    _showSystemNoticeDialog(
      context,
      item,
      fallbackNotice: 'Surat Keterangan Sakit (SKD) tidak ditemukan atau nomor surat telah kadaluarsa.',
    );
  }

  void _openInpatientDetail(BuildContext context, AppNotification item) {
    final admissions = ref.read(inpatientAdmissionsProvider);
    var matchAdm = admissions.where(
      (a) => a.id == item.targetId || a.admissionNumber == item.targetId,
    ).firstOrNull;

    if (matchAdm == null) {
      matchAdm = admissions.where((a) {
        return item.message.contains(a.admissionNumber) ||
            item.title.contains(a.admissionNumber) ||
            item.message.toLowerCase().contains(a.patientName.toLowerCase());
      }).firstOrNull;
    }

    if (matchAdm != null) {
      showDialog(
        context: context,
        builder: (_) => InpatientCPPTDialog(admissionId: matchAdm!.id),
      );
      return;
    }

    _showSystemNoticeDialog(
      context,
      item,
      fallbackNotice: 'Data rawat inap pasien tidak ditemukan atau telah dipulangkan.',
    );
  }

  void _showSystemNoticeDialog(
    BuildContext context,
    AppNotification item, {
    String? fallbackNotice,
  }) {
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
            if (fallbackNotice != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Text(
                  fallbackNotice,
                  style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                ),
              ),
            ],
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
      if (_selectedFilter == 'clinical') {
        return n.type == 'clinical' ||
            n.type == 'lab' ||
            n.type == 'certificate' ||
            n.type == 'skd';
      }
      if (_selectedFilter == 'prescription') return n.type == 'prescription';
      if (_selectedFilter == 'billing') return n.type == 'billing';
      if (_selectedFilter == 'inpatient') return n.type == 'inpatient';
      return true;
    }).toList();

    final readCount = allItems.length - notifState.unreadCount;

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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Opsi Notifikasi',
            onSelected: (value) {
              if (value == 'mark_all_read') {
                ref.read(notificationsProvider.notifier).markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Semua notifikasi ditandai telah dibaca.'),
                    backgroundColor: AppTheme.primary,
                  ),
                );
              } else if (value == 'clear_read') {
                ref.read(notificationsProvider.notifier).clearAllRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notifikasi yang sudah dibaca telah dibersihkan.'),
                    backgroundColor: AppTheme.navy,
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'mark_all_read',
                enabled: notifState.unreadCount > 0,
                child: const Row(
                  children: [
                    Icon(Icons.done_all, size: 18, color: AppTheme.primary),
                    SizedBox(width: 8),
                    Text('Tandai Semua Dibaca'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear_read',
                enabled: readCount > 0,
                child: const Row(
                  children: [
                    Icon(Icons.cleaning_services_outlined, size: 18, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Hapus yang Sudah Dibaca'),
                  ],
                ),
              ),
            ],
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
                  _buildFilterChip('appointment', 'Poli & Antrean'),
                  const SizedBox(width: 8),
                  _buildFilterChip('clinical', 'Rekam Medis & Lab'),
                  const SizedBox(width: 8),
                  _buildFilterChip('prescription', 'Farmasi & Obat'),
                  const SizedBox(width: 8),
                  _buildFilterChip('billing', 'Tagihan & Kasir'),
                  const SizedBox(width: 8),
                  _buildFilterChip('inpatient', 'Rawat Inap'),
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
                            return Dismissible(
                              key: Key(item.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                color: Colors.red.shade600,
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Icon(Icons.delete_outline, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text(
                                      'Hapus',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              onDismissed: (direction) {
                                ref.read(notificationsProvider.notifier).deleteNotification(item.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Notifikasi "${item.title}" dihapus.'),
                                    action: SnackBarAction(
                                      label: 'OK',
                                      textColor: Colors.white,
                                      onPressed: () {},
                                    ),
                                  ),
                                );
                              },
                              child: _buildNotificationTile(context, item),
                            );
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
