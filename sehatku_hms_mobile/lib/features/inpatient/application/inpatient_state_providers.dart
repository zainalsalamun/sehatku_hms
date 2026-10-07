import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/api_client_provider.dart';
import '../../../shared/models/health_models.dart';
import '../../admin/application/admin_state_providers.dart';

// ===================== BEDS NOTIFIER =====================

class InpatientBedsNotifier extends Notifier<List<RoomBedModel>> {
  @override
  List<RoomBedModel> build() {
    _fetchFromApi();
    return const [];
  }

  Future<void> _fetchFromApi({String? classType, String? status}) async {
    final client = ref.read(apiClientProvider);
    final beds = await client.getInpatientBeds(
      classType: classType,
      status: status,
    );
    if (beds.isNotEmpty) {
      state = beds;
    }
  }

  Future<void> refresh({String? classType, String? status}) async =>
      _fetchFromApi(classType: classType, status: status);

  Future<void> updateBedStatus(String id, String newStatus, {String? notes}) async {
    state = [
      for (final b in state)
        if (b.id == id) b.copyWith(status: newStatus, notes: notes) else b,
    ];
    await ref.read(apiClientProvider).updateBedStatus(id, newStatus, notes: notes);
    _fetchFromApi();
  }
}

final inpatientBedsProvider =
    NotifierProvider<InpatientBedsNotifier, List<RoomBedModel>>(
  InpatientBedsNotifier.new,
);

// ===================== ADMISSIONS NOTIFIER =====================

class InpatientAdmissionsNotifier
    extends Notifier<List<InpatientAdmissionModel>> {
  @override
  List<InpatientAdmissionModel> build() {
    _fetchFromApi();
    return const [];
  }

  Future<void> _fetchFromApi({String? status, String? query}) async {
    final client = ref.read(apiClientProvider);
    final admissions = await client.getInpatientAdmissions(
      status: status,
      query: query,
    );
    state = admissions;
  }

  Future<void> refresh({String? status, String? query}) async =>
      _fetchFromApi(status: status, query: query);

  Future<InpatientAdmissionModel?> createAdmission({
    required String patientId,
    required String doctorId,
    required String bedId,
    String? admissionType,
    String? initialDiagnosis,
    String? notes,
  }) async {
    final client = ref.read(apiClientProvider);
    final newAdmission = await client.createInpatientAdmission(
      patientId: patientId,
      doctorId: doctorId,
      bedId: bedId,
      admissionType: admissionType,
      initialDiagnosis: initialDiagnosis,
      notes: notes,
    );

    if (newAdmission != null) {
      state = [newAdmission, ...state];
      // Refresh beds & audit
      ref.read(inpatientBedsProvider.notifier).refresh();
      ref.read(adminAuditLogsProvider.notifier).log(
            action: 'ADMISSION',
            resourceType: 'InpatientAdmission',
            resourceId: newAdmission.id,
            details:
                'Admisi Rawat Inap Baru: ${newAdmission.patientName} (${newAdmission.admissionNumber}) di ${newAdmission.roomName} (${newAdmission.bedNumber})',
          );
    }
    return newAdmission;
  }

  Future<InpatientAdmissionModel?> transferBed({
    required String admissionId,
    required String newBedId,
    String? reason,
  }) async {
    final client = ref.read(apiClientProvider);
    final updated = await client.transferInpatientBed(
      admissionId,
      newBedId,
      reason: reason,
    );

    if (updated != null) {
      await _fetchFromApi();
      ref.read(inpatientBedsProvider.notifier).refresh();
      ref.read(adminAuditLogsProvider.notifier).log(
            action: 'TRANSFER_BED',
            resourceType: 'InpatientAdmission',
            resourceId: admissionId,
            details:
                'Transfer Bed Pasien ${updated.patientName}: Pindah ke ${updated.roomName} (${updated.bedNumber}). Alasan: ${reason ?? "-"}',
          );
    }
    return updated;
  }

  Future<InpatientAdmissionModel?> dischargePatient({
    required String admissionId,
    required String dischargeDiagnosis,
    required String dischargeCondition,
    String? notes,
  }) async {
    final client = ref.read(apiClientProvider);
    final discharged = await client.dischargeInpatient(
      admissionId,
      dischargeDiagnosis: dischargeDiagnosis,
      dischargeCondition: dischargeCondition,
      notes: notes,
    );

    if (discharged != null) {
      await _fetchFromApi();
      ref.read(inpatientBedsProvider.notifier).refresh();
      ref.read(adminBillingProvider.notifier).refresh();
      ref.read(adminAuditLogsProvider.notifier).log(
            action: 'DISCHARGE',
            resourceType: 'InpatientAdmission',
            resourceId: admissionId,
            details:
                'Pemulangan Pasien Ranap: ${discharged.patientName} (${discharged.admissionNumber}). Kondisi: $dischargeCondition. Tagihan dibuat otomatis.',
          );
    }
    return discharged;
  }
}

final inpatientAdmissionsProvider = NotifierProvider<
    InpatientAdmissionsNotifier, List<InpatientAdmissionModel>>(
  InpatientAdmissionsNotifier.new,
);
