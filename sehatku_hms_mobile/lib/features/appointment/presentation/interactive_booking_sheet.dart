import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/uuid_helper.dart';
import '../../../shared/models/health_models.dart';
import '../../admin/application/admin_state_providers.dart';
import '../../authentication/application/auth_controller.dart';
import '../../notification/application/notifications_provider.dart';
import '../../patient/presentation/widgets/queue_ticket_dialog.dart';
import 'payment_checkout_sheet.dart';

void showInteractiveBookingSheet(
  BuildContext context, {
  Doctor? initialDoctor,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => InteractiveBookingSheet(
      initialDoctor: initialDoctor,
      rootContext: context,
    ),
  );
}

class InteractiveBookingSheet extends ConsumerStatefulWidget {
  const InteractiveBookingSheet({
    super.key,
    this.initialDoctor,
    this.rootContext,
  });

  final Doctor? initialDoctor;
  final BuildContext? rootContext;

  @override
  ConsumerState<InteractiveBookingSheet> createState() =>
      _InteractiveBookingSheetState();
}

class _InteractiveBookingSheetState
    extends ConsumerState<InteractiveBookingSheet> {
  Doctor? _selectedDoctor;
  int _selectedDateIndex = 0;
  String _selectedSlot = '09:30';
  final _reasonController = TextEditingController();

  late List<DateTime> _availableDates;

  @override
  void initState() {
    super.initState();
    _availableDates = List.generate(
      7,
      (index) => DateTime.now().add(Duration(days: index)),
    );
    final docs = ref.read(adminDoctorsProvider);
    _selectedDoctor =
        widget.initialDoctor ?? (docs.isNotEmpty ? docs.first : null);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _proceedToPayment() {
    final activeContext = widget.rootContext ?? context;
    final auth = ref.read(authControllerProvider);
    final appointmentsNotifier = ref.read(adminAppointmentsProvider.notifier);
    final billingNotifier = ref.read(adminBillingProvider.notifier);
    final currentAppts = ref.read(adminAppointmentsProvider);
    final doctor = _selectedDoctor;
    if (doctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih dokter terlebih dahulu.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final slot = _selectedSlot;
    final reason = _reasonController.text.trim().isNotEmpty
        ? _reasonController.text.trim()
        : 'Konsultasi Poli';

    final selectedDate = DateTime.now().add(Duration(days: _selectedDateIndex));
    final dateLabel = _selectedDateIndex == 0
        ? 'Hari ini'
        : DateFormat('EEEE, d MMM', 'id_ID').format(selectedDate);

    final fee = doctor.specialist.contains('Kardiologi') ? 350000.0 : 250000.0;

    Navigator.of(context).pop();

    showModalBottomSheet(
      context: activeContext,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (checkoutCtx) => PaymentCheckoutSheet(
        doctorName: doctor.name,
        departmentName: doctor.specialist,
        amount: fee,
        onPaymentSuccess: () {
          final count = currentAppts.length;
          final queueNum = 'A-${(count + 33).toString().padLeft(3, '0')}';
          final patientName = auth.userFullName?.trim().isNotEmpty == true
              ? auth.userFullName!
              : (auth.email != null && auth.email!.isNotEmpty
                  ? auth.email!.split('@').first
                  : 'Pasien');
          final patientId =
              auth.patientId ?? auth.userId ?? UuidHelper.generate();

          final newAppt = Appointment(
            id: UuidHelper.generate(),
            doctorName: doctor.name,
            patientName: patientName,
            dateLabel: dateLabel,
            time: '$slot WIB',
            status: 'Terkonfirmasi',
            queueNumber: queueNum,
            department: doctor.specialist,
            reason: reason,
            appointmentDate: selectedDate,
            doctorPhotoUrl: doctor.photoUrl,
          );

          appointmentsNotifier.addAppointment(
            newAppt,
            patientId: patientId,
            doctorId: doctor.id,
          );

          // Add Paid Invoice to Admin Billing
          final newInvoice = Invoice(
            id: UuidHelper.generate(),
            invoiceNumber:
                'INV-${DateTime.now().year}-${(count + 105).toString().padLeft(3, '0')}',
            patientName: patientName,
            doctorName: doctor.name,
            serviceName: 'Konsultasi Poli ${doctor.specialist}',
            amount: fee,
            status: 'Lunas',
            createdAt: DateTime.now(),
            paymentMethod: 'QRIS Dinamis',
          );
          billingNotifier.addInvoice(newInvoice);

          // Add instant notification for Patient
          ref
              .read(notificationsProvider.notifier)
              .addNotification(
                AppNotification(
                  id: UuidHelper.generate(),
                  role: 'patient',
                  title: 'Reservasi Dokter Berhasil',
                  message:
                      'Reservasi Anda di Poli ${doctor.specialist} dengan ${doctor.name} (${newAppt.dateLabel}, ${newAppt.time}) telah terdaftar dengan Nomor Antrean ${newAppt.queueNumber}.',
                  type: 'appointment',
                  targetId: newAppt.id,
                  isRead: false,
                  createdAt: DateTime.now(),
                ),
              );
          ref.read(notificationsProvider.notifier).refresh();

          // Show Ticket Dialog using root context
          showDialog(
            context: activeContext,
            barrierDismissible: false,
            builder: (_) => QueueTicketDialog(appointment: newAppt),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doctors = ref.watch(adminDoctorsProvider);
    if (_selectedDoctor == null && doctors.isNotEmpty) {
      _selectedDoctor = widget.initialDoctor ?? doctors.first;
    }
    final slotConfig = ref.watch(appointmentSlotConfigProvider);
    final timeSlots = slotConfig.timeSlots;
    final quickReasons = slotConfig.quickReasons;
    final morningSlots = timeSlots.where((s) {
      final hour = int.tryParse(s.split(':').first) ?? 9;
      return hour < 12;
    }).toList();
    final afternoonSlots = timeSlots.where((s) {
      final hour = int.tryParse(s.split(':').first) ?? 13;
      return hour >= 12;
    }).toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        8,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reservasi Dokter Spesialis',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Pilih dokter spesialis, jadwal, dan keluhan konsultasi',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 24),

            // Doctor Selector Dropdown
            const Text(
              'Pilih Dokter & Spesialisasi:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedDoctor?.id,
              isExpanded: true,
              hint: Text(doctors.isEmpty ? 'Memuat data dokter...' : 'Pilih Dokter'),
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medical_services_outlined),
              ),
              items: doctors.map((d) {
                return DropdownMenuItem(
                  value: d.id,
                  child: Text(
                    '${d.name} (${d.specialist})',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedDoctor = doctors.firstWhere((d) => d.id == val);
                  });
                }
              },
            ),

            const SizedBox(height: 18),

            // Date Picker (Next 7 Days Horizontal Chips)
            const Text(
              'Pilih Tanggal Kunjungan:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _availableDates.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final d = _availableDates[idx];
                  final isSelected = _selectedDateIndex == idx;
                  final isToday = idx == 0;

                  return InkWell(
                    onTap: () => setState(() => _selectedDateIndex = idx),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 64,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.navy
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.navy
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isToday ? 'Hari ini' : DateFormat('EEE').format(d),
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected
                                  ? Colors.white70
                                  : Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${d.day}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 18),

            // Time Slots (Morning & Afternoon)
            const Text(
              'Pilih Jam Slot Praktek:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.wb_sunny_outlined,
                  size: 16,
                  color: Colors.orange,
                ),
                const SizedBox(width: 6),
                const Text(
                  'Sesi Pagi (08:00 - 12:00)',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: morningSlots.map((slot) {
                final isSelected = _selectedSlot == slot;
                return ChoiceChip(
                  label: Text('$slot WIB'),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedSlot = slot),
                );
              }).toList(),
            ),

            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.wb_twilight, size: 16, color: Colors.indigo),
                const SizedBox(width: 6),
                const Text(
                  'Sesi Siang / Sore (13:00 - 17:00)',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: afternoonSlots.map((slot) {
                final isSelected = _selectedSlot == slot;
                return ChoiceChip(
                  label: Text('$slot WIB'),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedSlot = slot),
                );
              }).toList(),
            ),

            const SizedBox(height: 18),

            // Reason / Complaint
            TextField(
              controller: _reasonController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Keluhan / Alasan Kunjungan *',
                hintText:
                    'Contoh: Nyeri dada saat berolahraga, migrain berulang...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: quickReasons.map((r) {
                return ActionChip(
                  label: Text(r, style: const TextStyle(fontSize: 11)),
                  onPressed: () => setState(() => _reasonController.text = r),
                );
              }).toList(),
            ),

            const SizedBox(height: 22),

            // Submit Button
            FilledButton.icon(
              onPressed: _proceedToPayment,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: AppTheme.navy,
              ),
              icon: const Icon(Icons.payment, size: 18),
              label: const Text('Lanjut ke Pembayaran & Nomor Antrean'),
            ),
          ],
        ),
      ),
    );
  }
}
