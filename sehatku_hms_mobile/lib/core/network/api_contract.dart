import '../../shared/models/health_models.dart';

/// Contract for the REST/Firebase implementation used in production.
///
/// The demo ships with [MockHmsRepository]. Implement this interface using Dio,
/// attach access/refresh tokens in an interceptor, then override the Riverpod
/// provider at the app composition root.
///
/// `docs/openapi.yaml` is the complete source of truth. This interface is the
/// small hand-written boundary used by the current UI and can later be replaced
/// by an OpenAPI-generated client.
abstract interface class HmsApiContract {
  Future<String> login({required String email, required String password});
  Future<List<Doctor>> getDoctors({String? query, int page = 1});
  Future<Appointment> createAppointment(Appointment appointment);
  Future<List<Appointment>> getAppointments();
  Future<List<MedicalRecord>> getMedicalRecords(String patientId);
  Future<void> submitDiagnosis(MedicalRecord record);
  Stream<List<String>> watchQueue(String doctorId);
  Stream<List<String>> watchChat(String conversationId);

  Future<Map<String, Object?>> getAdminDashboard();

  Future<List<Map<String, Object?>>> adminListDepartments({
    String? query,
    int page = 1,
  });
  Future<Map<String, Object?>> adminCreateDepartment(
    Map<String, Object?> payload,
  );
  Future<Map<String, Object?>> adminUpdateDepartment(
    String id,
    int version,
    Map<String, Object?> payload,
  );
  Future<void> adminDeactivateDepartment(String id);

  Future<Doctor> adminCreateDoctor(Map<String, Object?> payload);
  Future<Doctor> adminUpdateDoctor(
    String id,
    int version,
    Map<String, Object?> payload,
  );
  Future<void> adminDeactivateDoctor(String id);

  Future<List<Patient>> adminListPatients({String? query, int page = 1});
  Future<Patient> adminCreatePatient(Map<String, Object?> payload);
  Future<Patient> adminUpdatePatient(
    String id,
    int version,
    Map<String, Object?> payload,
  );
  Future<void> adminDeactivatePatient(String id);

  Future<void> adminCancelAppointment(String id, String reason);
  Future<List<Map<String, Object?>>> adminListAuditLogs({int page = 1});
}
