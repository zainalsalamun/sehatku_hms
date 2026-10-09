import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/api_client_provider.dart';
import '../../../core/utils/uuid_helper.dart';
import '../../../shared/models/health_models.dart';

// --- AUDIT LOGS PROVIDER ---

class AdminAuditLogsNotifier extends Notifier<List<AuditLog>> {
  @override
  List<AuditLog> build() {
    _fetchFromApi();
    return const [];
  }

  Future<void> _fetchFromApi() async {
    final client = ref.read(apiClientProvider);
    final logs = await client.getAuditLogs();
    if (logs.isNotEmpty) {
      state = logs;
    }
  }

  Future<void> refresh() async => _fetchFromApi();

  void log({
    required String action,
    required String resourceType,
    required String resourceId,
    required String details,
    String actorName = 'Budi Santoso (Admin)',
    String actorRole = 'hospital_admin',
  }) {
    final newLog = AuditLog(
      id: UuidHelper.generate(),
      actorName: actorName,
      actorRole: actorRole,
      action: action,
      resourceType: resourceType,
      resourceId: resourceId,
      details: details,
      timestamp: DateTime.now(),
    );
    state = [newLog, ...state];
  }
}

final adminAuditLogsProvider =
    NotifierProvider<AdminAuditLogsNotifier, List<AuditLog>>(
  AdminAuditLogsNotifier.new,
);

// --- DEPARTMENTS PROVIDER ---

class AdminDepartmentsNotifier extends Notifier<List<Department>> {
  @override
  List<Department> build() {
    _fetchFromApi();
    return const [];
  }

  Future<void> _fetchFromApi() async {
    final client = ref.read(apiClientProvider);
    final depts = await client.getDepartments();
    state = depts;
  }

  Future<void> refresh() async => _fetchFromApi();
}

final adminDepartmentsProvider =
    NotifierProvider<AdminDepartmentsNotifier, List<Department>>(
  AdminDepartmentsNotifier.new,
);

// --- DOCTORS PROVIDER ---

class AdminDoctorsNotifier extends Notifier<List<Doctor>> {
  @override
  List<Doctor> build() {
    _fetchFromApi();
    return const [];
  }

  Future<void> _fetchFromApi() async {
    final client = ref.read(apiClientProvider);
    final docs = await client.getDoctors();
    if (docs.isNotEmpty) {
      state = docs;
    }
  }

  Future<void> refresh() async => _fetchFromApi();

  Future<void> addDoctor(Doctor doctor) async {
    state = [...state, doctor];
    final created = await ref.read(apiClientProvider).createDoctor(doctor);
    if (created != null) {
      state = [
        for (final doc in state)
          if (doc.id == doctor.id) created else doc,
      ];
    }
    ref.read(adminAuditLogsProvider.notifier).log(
          action: 'CREATE',
          resourceType: 'Doctor',
          resourceId: created?.id ?? doctor.id,
          details: 'Menambahkan dokter baru: ${doctor.name} (${doctor.specialist})',
        );
  }

  void updateDoctor(Doctor updatedDoctor) {
    state = [
      for (final doc in state)
        if (doc.id == updatedDoctor.id) updatedDoctor else doc,
    ];
    ref.read(apiClientProvider).updateDoctor(updatedDoctor);
    ref.read(adminAuditLogsProvider.notifier).log(
          action: 'UPDATE',
          resourceType: 'Doctor',
          resourceId: updatedDoctor.id,
          details: 'Memperbarui profil dokter: ${updatedDoctor.name}',
        );
  }

  void toggleActive(String id) {
    state = [
      for (final doc in state)
        if (doc.id == id)
          doc.copyWith(isActive: !doc.isActive)
        else
          doc,
    ];
    ref.read(apiClientProvider).toggleDoctorActive(id);
    final doc = state.firstWhere((d) => d.id == id);
    ref.read(adminAuditLogsProvider.notifier).log(
          action: doc.isActive ? 'ACTIVATE' : 'DEACTIVATE',
          resourceType: 'Doctor',
          resourceId: id,
          details:
              'Mengubah status dokter ${doc.name} menjadi ${doc.isActive ? "Aktif" : "Nonaktif"}',
        );
  }
}

final adminDoctorsProvider =
    NotifierProvider<AdminDoctorsNotifier, List<Doctor>>(
  AdminDoctorsNotifier.new,
);

// --- PATIENTS PROVIDER ---

class AdminPatientsNotifier extends Notifier<List<Patient>> {
  @override
  List<Patient> build() {
    _fetchFromApi();
    return const [];
  }

  Future<void> _fetchFromApi() async {
    final client = ref.read(apiClientProvider);
    final pats = await client.getPatients();
    if (pats.isNotEmpty) {
      state = pats;
    }
  }

  Future<void> refresh() async => _fetchFromApi();

  Future<void> registerPatient(Patient patient) async {
    state = [patient, ...state];
    final created = await ref.read(apiClientProvider).createPatient(patient);
    if (created != null) {
      state = [
        for (final p in state)
          if (p.id == patient.id) created else p,
      ];
    }
    ref.read(adminAuditLogsProvider.notifier).log(
          action: 'CREATE',
          resourceType: 'Patient',
          resourceId: created?.id ?? patient.id,
          details:
              'Pendaftaran pasien baru: ${patient.name} (${patient.medicalRecordNumber})',
        );
  }

  void togglePatientStatus(String id) {
    state = [
      for (final p in state)
        if (p.id == id)
          p.copyWith(status: p.status == 'Aktif' ? 'Nonaktif' : 'Aktif')
        else
          p,
    ];
    ref.read(apiClientProvider).togglePatientStatus(id);
    final p = state.firstWhere((item) => item.id == id);
    ref.read(adminAuditLogsProvider.notifier).log(
          action: p.status == 'Aktif' ? 'ACTIVATE' : 'DEACTIVATE',
          resourceType: 'Patient',
          resourceId: id,
          details: 'Mengubah status pasien ${p.name} menjadi ${p.status}',
        );
  }

  void toggleStatus(String id) => togglePatientStatus(id);

  void updatePatient(Patient updated) {
    state = [
      for (final p in state) if (p.id == updated.id) updated else p,
    ];
    ref.read(apiClientProvider).updatePatient(updated);
    ref.read(adminAuditLogsProvider.notifier).log(
          action: 'UPDATE',
          resourceType: 'Patient',
          resourceId: updated.id,
          details: 'Memperbarui data demografis pasien: ${updated.name}',
        );
  }
}

final adminPatientsProvider =
    NotifierProvider<AdminPatientsNotifier, List<Patient>>(
  AdminPatientsNotifier.new,
);

// --- APPOINTMENTS PROVIDER ---

class AdminAppointmentsNotifier extends Notifier<List<Appointment>> {
  @override
  List<Appointment> build() {
    _fetchFromApi();
    return const [];
  }

  Future<void> _fetchFromApi() async {
    final client = ref.read(apiClientProvider);
    final appts = await client.getAppointments();
    if (appts.isNotEmpty) {
      final docs = ref.read(adminDoctorsProvider);
      state = appts.map((a) {
        if (a.doctorPhotoUrl.isNotEmpty) return a;
        final match = docs.cast<Doctor?>().firstWhere(
              (d) =>
                  d?.name.trim().toLowerCase() == a.doctorName.trim().toLowerCase(),
              orElse: () => null,
            );
        if (match != null && match.photoUrl.isNotEmpty) {
          return a.copyWith(doctorPhotoUrl: match.photoUrl);
        }
        return a;
      }).toList();
    }
  }

  Future<void> refresh() async => _fetchFromApi();

  void addAppointment(
    Appointment appointment, {
    String? patientId,
    String? doctorId,
  }) async {
    var finalAppt = appointment;
    if (finalAppt.doctorPhotoUrl.isEmpty) {
      final docs = ref.read(adminDoctorsProvider);
      final match = docs.cast<Doctor?>().firstWhere(
            (d) =>
                d?.id == doctorId ||
                d?.name.trim().toLowerCase() ==
                    appointment.doctorName.trim().toLowerCase(),
            orElse: () => null,
          );
      if (match != null && match.photoUrl.isNotEmpty) {
        finalAppt = finalAppt.copyWith(doctorPhotoUrl: match.photoUrl);
      }
    }
    state = [finalAppt, ...state];
    final created = await ref.read(apiClientProvider).createAppointment(
          id: finalAppt.id,
          patientId: patientId ?? '40000000-0000-4000-8000-000000000001',
          doctorId: doctorId ?? '30000000-0000-4000-8000-000000000001',
          dateLabel: finalAppt.dateLabel,
          appointmentTime: finalAppt.time,
          departmentName: finalAppt.department,
          reason: finalAppt.reason,
          appointmentDate: finalAppt.appointmentDate != null
              ? DateFormat('yyyy-MM-dd').format(finalAppt.appointmentDate!)
              : null,
        );
    if (created != null) {
      state = [
        for (final a in state)
          if (a.id == finalAppt.id)
            created.copyWith(
              doctorPhotoUrl: created.doctorPhotoUrl.isNotEmpty
                  ? created.doctorPhotoUrl
                  : finalAppt.doctorPhotoUrl,
            )
          else
            a,
      ];
    }
    ref.read(adminAuditLogsProvider.notifier).log(
          action: 'CREATE',
          resourceType: 'Appointment',
          resourceId: finalAppt.id,
          details:
              'Pendaftaran antrean baru: ${finalAppt.patientName} (${finalAppt.queueNumber}) ke ${finalAppt.doctorName}',
        );
  }

  void cancelAppointment(String id, String reason) {
    state = [
      for (final a in state)
        if (a.id == id)
          a.copyWith(status: 'Dibatalkan', cancellationReason: reason)
        else
          a,
    ];
    ref.read(apiClientProvider).cancelAppointment(id, reason);
    final a = state.firstWhere((item) => item.id == id);
    ref.read(adminAuditLogsProvider.notifier).log(
          action: 'CANCEL',
          resourceType: 'Appointment',
          resourceId: id,
          details:
              'Membatalkan appointment ${a.patientName} (${a.queueNumber}). Alasan: $reason',
        );
  }

  void checkInAppointment(String id) {
    state = [
      for (final a in state)
        if (a.id == id) a.copyWith(status: 'Checked-in') else a,
    ];
    ref.read(apiClientProvider).checkInAppointment(id);
    final a = state.firstWhere((item) => item.id == id);
    ref.read(adminAuditLogsProvider.notifier).log(
          action: 'CHECK_IN',
          resourceType: 'Appointment',
          resourceId: id,
          details:
              'Check-in manual staf untuk ${a.patientName} (${a.queueNumber})',
        );
  }

  void completeAppointment(String id) {
    state = [
      for (final a in state)
        if (a.id == id) a.copyWith(status: 'Selesai') else a,
    ];
    ref.read(apiClientProvider).completeAppointment(id);
    final a = state.firstWhere((item) => item.id == id);
    ref.read(adminAuditLogsProvider.notifier).log(
          action: 'COMPLETE',
          resourceType: 'Appointment',
          resourceId: id,
          details:
              'Menandai selesai appointment ${a.patientName} (${a.queueNumber})',
        );
  }
}

final adminAppointmentsProvider =
    NotifierProvider<AdminAppointmentsNotifier, List<Appointment>>(
  AdminAppointmentsNotifier.new,
);

// --- APPOINTMENT SLOT & REASON CONFIG PROVIDER ---

class AppointmentSlotConfigNotifier extends Notifier<AppointmentSlotConfig> {
  @override
  AppointmentSlotConfig build() {
    _fetchFromApi();
    return const AppointmentSlotConfig(
      timeSlots: [
        '08:00', '08:30', '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
        '13:00', '13:30', '14:00', '14:30', '15:00', '15:30', '16:00', '16:30',
        '18:30', '19:00', '19:30', '20:00',
      ],
      quickReasons: [
        'Konsultasi Rutin',
        'Demam & Flu',
        'Nyeri Dada & Sesak',
        'Pemeriksaan Gigi',
        'Kontrol Pasca Obat',
        'Pusing / Sakit Kepala',
        'Medical Checkup',
      ],
    );
  }

  Future<void> _fetchFromApi() async {
    final client = ref.read(apiClientProvider);
    final config = await client.getAppointmentConfig();
    if (config != null) {
      state = config;
    }
  }

  Future<void> refresh() async => _fetchFromApi();

  Future<void> updateConfig({
    List<String>? timeSlots,
    List<String>? quickReasons,
  }) async {
    final client = ref.read(apiClientProvider);
    final updated = await client.updateAppointmentConfig(
      timeSlots: timeSlots,
      quickReasons: quickReasons,
    );
    if (updated != null) {
      state = updated;
    }
  }
}

final appointmentSlotConfigProvider =
    NotifierProvider<AppointmentSlotConfigNotifier, AppointmentSlotConfig>(
  AppointmentSlotConfigNotifier.new,
);

// --- BILLING / INVOICES PROVIDER ---

class AdminBillingNotifier extends Notifier<List<Invoice>> {
  @override
  List<Invoice> build() {
    _fetchFromApi();
    return const [];
  }

  Future<void> _fetchFromApi() async {
    final client = ref.read(apiClientProvider);
    final invs = await client.getInvoices();
    state = invs;
  }

  Future<void> refresh() async => _fetchFromApi();

  void addInvoice(Invoice invoice) {
    state = [invoice, ...state];
    ref.read(adminAuditLogsProvider.notifier).log(
          action: 'CREATE',
          resourceType: 'Invoice',
          resourceId: invoice.id,
          details:
              'Terbit tagihan lunas ${invoice.invoiceNumber} untuk ${invoice.patientName} (${invoice.serviceName}) sebesar Rp ${invoice.amount}',
        );
  }

  Future<void> payInvoice(
    String invoiceId, {
    String paymentMethod = 'Tunai',
    double? amountPaid,
    String? cashierName,
  }) async {
    state = [
      for (final inv in state)
        if (inv.id == invoiceId)
          inv.copyWith(
            status: 'Lunas',
            paymentMethod: paymentMethod,
            paidAt: DateTime.now(),
          )
        else
          inv,
    ];
    await ref.read(apiClientProvider).payInvoice(
          invoiceId,
          paymentMethod: paymentMethod,
          amountPaid: amountPaid,
          cashierName: cashierName,
        );
    final inv = state.firstWhere((item) => item.id == invoiceId);
    ref.read(adminAuditLogsProvider.notifier).log(
          action: 'PAYMENT_SETTLE',
          resourceType: 'Invoice',
          resourceId: invoiceId,
          details:
              'Pelunasan kasir POS invoice ${inv.invoiceNumber} (${inv.patientName}) via $paymentMethod sebesar Rp ${inv.amount.toStringAsFixed(0)}',
        );
  }

  void markAsPaid(String invoiceId) {
    payInvoice(invoiceId);
  }
}

final adminBillingProvider =
    NotifierProvider<AdminBillingNotifier, List<Invoice>>(
  AdminBillingNotifier.new,
);

// --- CASHIER SHIFTS PROVIDER ---

class CashierShiftNotifier extends Notifier<CashierShiftModel?> {
  @override
  CashierShiftModel? build() {
    _fetchCurrentShift();
    return null;
  }

  Future<void> _fetchCurrentShift() async {
    final client = ref.read(apiClientProvider);
    final shift = await client.getCurrentCashierShift();
    state = shift;
  }

  Future<void> refresh() async => _fetchCurrentShift();

  Future<bool> openShift({
    required String cashierId,
    required String cashierName,
    String shiftName = 'Pagi',
    double initialCash = 0.0,
    String? notes,
  }) async {
    final client = ref.read(apiClientProvider);
    final shift = await client.openCashierShift(
      cashierId: cashierId,
      cashierName: cashierName,
      shiftName: shiftName,
      initialCash: initialCash,
      notes: notes,
    );
    if (shift != null) {
      state = shift;
      ref.read(adminAuditLogsProvider.notifier).log(
            action: 'SHIFT_OPEN',
            resourceType: 'CashierShift',
            resourceId: shift.id,
            details:
                'Buka shift ${shift.shiftName} kasir $cashierName dengan kas awal Rp ${initialCash.toStringAsFixed(0)}',
            actorName: cashierName,
          );
      return true;
    }
    return false;
  }

  Future<CashierShiftModel?> closeShift({
    required double actualCashCounted,
    String? notes,
  }) async {
    if (state == null) return null;
    final client = ref.read(apiClientProvider);
    final closed = await client.closeCashierShift(
      state!.id,
      actualCashCounted: actualCashCounted,
      notes: notes,
    );
    if (closed != null) {
      ref.read(adminAuditLogsProvider.notifier).log(
            action: 'SHIFT_CLOSE',
            resourceType: 'CashierShift',
            resourceId: closed.id,
            details:
                'Tutup shift ${closed.shiftName} kasir ${closed.cashierName}. Total kas fisik: Rp ${actualCashCounted.toStringAsFixed(0)}, Selisih: Rp ${(closed.discrepancy ?? 0).toStringAsFixed(0)}',
            actorName: closed.cashierName,
          );
      state = null; // Shift is now closed
      return closed;
    }
    return null;
  }
}

final cashierShiftProvider =
    NotifierProvider<CashierShiftNotifier, CashierShiftModel?>(
  CashierShiftNotifier.new,
);
