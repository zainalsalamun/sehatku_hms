import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../shared/models/health_models.dart';
import 'dio_client.dart';

class HmsApiClient {
  const HmsApiClient();

  Dio get _dio => DioClient.instance.dio;

  // --- AUTHENTICATION ---

  Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final token = data['accessToken'] as String?;
        if (token != null) {
          DioClient.instance.setAuthToken(token);
        }
        return data;
      }
    } catch (e) {
      debugPrint('[HmsApiClient] Login error: $e');
      rethrow;
    }
    return null;
  }

  // --- DOCTORS ---

  Future<List<Doctor>> getDoctors({String? query, String? departmentId}) async {
    try {
      final response = await _dio.get(
        '/doctors',
        queryParameters: {
          if (query != null && query.isNotEmpty) 'query': query,
          if (departmentId != null && departmentId != 'all')
            'departmentId': departmentId,
        },
      );
      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        return list.map((json) => _doctorFromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('[HmsApiClient] getDoctors error: $e');
    }
    return [];
  }

  Future<Doctor?> createDoctor(Doctor doctor) async {
    try {
      final response = await _dio.post(
        '/doctors',
        data: {
          'name': doctor.name,
          'licenseNumber': doctor.licenseNumber,
          'departmentId': doctor.departmentId,
          'specialist': doctor.specialist,
          'experienceYears': doctor.experience,
          'phone': doctor.phone,
          'email': doctor.email,
          'scheduleDays': doctor.scheduleDays,
          'avatarUrl': doctor.photoUrl,
        },
      );
      if (response.statusCode == 201 && response.data != null) {
        return _doctorFromJson(response.data);
      }
    } catch (e) {
      debugPrint('[HmsApiClient] createDoctor error: $e');
    }
    return null;
  }

  Future<Doctor?> updateDoctor(Doctor doctor) async {
    try {
      final response = await _dio.put(
        '/doctors/${doctor.id}',
        data: {
          'name': doctor.name,
          'licenseNumber': doctor.licenseNumber,
          'departmentId': doctor.departmentId,
          'specialist': doctor.specialist,
          'experienceYears': doctor.experience,
          'phone': doctor.phone,
          'email': doctor.email,
          'scheduleDays': doctor.scheduleDays,
          'avatarUrl': doctor.photoUrl,
          'status': doctor.isActive ? 'active' : 'inactive',
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        return _doctorFromJson(response.data);
      }
    } catch (e) {
      debugPrint('[HmsApiClient] updateDoctor error: $e');
    }
    return null;
  }

  Future<bool> toggleDoctorActive(String id) async {
    try {
      final response = await _dio.patch('/doctors/$id/toggle-active');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[HmsApiClient] toggleDoctorActive error: $e');
      return false;
    }
  }

  // --- PATIENTS ---

  Future<List<Patient>> getPatients({String? query, String? insurance}) async {
    try {
      final response = await _dio.get(
        '/patients',
        queryParameters: {
          if (query != null && query.isNotEmpty) 'query': query,
          if (insurance != null && insurance != 'all') 'insurance': insurance,
        },
      );
      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        return list.map((json) => _patientFromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('[HmsApiClient] getPatients error: $e');
    }
    return [];
  }

  Future<Patient?> createPatient(Patient patient) async {
    try {
      final response = await _dio.post(
        '/patients',
        data: {
          'medicalRecordNumber': patient.medicalRecordNumber,
          'name': patient.name,
          'nik': patient.nik,
          'birthDate': patient.birthDate.toIso8601String().split('T').first,
          'gender': patient.gender,
          'bloodType': patient.bloodType,
          'insuranceProvider': patient.insuranceProvider,
          'phone': patient.phone,
          'email': patient.email,
          'address': patient.address,
          'emergencyContact': patient.emergencyContact,
        },
      );
      if (response.statusCode == 201 && response.data != null) {
        return _patientFromJson(response.data);
      }
    } catch (e) {
      debugPrint('[HmsApiClient] createPatient error: $e');
    }
    return null;
  }

  Future<Patient?> updatePatient(Patient patient) async {
    try {
      final response = await _dio.put(
        '/patients/${patient.id}',
        data: {
          'medicalRecordNumber': patient.medicalRecordNumber,
          'name': patient.name,
          'nik': patient.nik,
          'birthDate': patient.birthDate.toIso8601String().split('T').first,
          'gender': patient.gender,
          'bloodType': patient.bloodType,
          'insuranceProvider': patient.insuranceProvider,
          'phone': patient.phone,
          'email': patient.email,
          'address': patient.address,
          'emergencyContact': patient.emergencyContact,
          'status': patient.status,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        return _patientFromJson(response.data);
      }
    } catch (e) {
      debugPrint('[HmsApiClient] updatePatient error: $e');
    }
    return null;
  }

  Future<bool> togglePatientStatus(String id) async {
    try {
      final response = await _dio.patch('/patients/$id/toggle-status');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[HmsApiClient] togglePatientStatus error: $e');
      return false;
    }
  }

  // --- APPOINTMENTS ---

  Future<List<Appointment>> getAppointments({
    String? query,
    String? status,
    String? patientId,
  }) async {
    try {
      final response = await _dio.get(
        '/appointments',
        queryParameters: {
          if (query != null && query.isNotEmpty) 'query': query,
          if (status != null && status != 'all') 'status': status,
          if (patientId != null && patientId.isNotEmpty) 'patientId': patientId,
        },
      );
      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        return list.map((json) => _appointmentFromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('[HmsApiClient] getAppointments error: $e');
    }
    return [];
  }

  Future<Appointment?> createAppointment({
    String? id,
    required String doctorId,
    required String patientId,
    required String dateLabel,
    required String appointmentTime,
    required String departmentName,
    String? reason,
  }) async {
    try {
      final response = await _dio.post(
        '/appointments',
        data: {
          'id': ?id,
          'doctorId': doctorId,
          'patientId': patientId,
          'dateLabel': dateLabel,
          'appointmentTime': appointmentTime,
          'departmentName': departmentName,
          'reason': reason,
        },
      );
      if (response.statusCode == 201 && response.data != null) {
        return _appointmentFromJson(response.data);
      }
    } catch (e) {
      debugPrint('[HmsApiClient] createAppointment error: $e');
    }
    return null;
  }

  Future<bool> checkInAppointment(String id) async {
    try {
      final response = await _dio.patch('/appointments/$id/check-in');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[HmsApiClient] checkInAppointment error: $e');
      return false;
    }
  }

  Future<bool> completeAppointment(String id) async {
    try {
      final response = await _dio.patch('/appointments/$id/complete');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[HmsApiClient] completeAppointment error: $e');
      return false;
    }
  }

  Future<bool> cancelAppointment(String id, String reason) async {
    try {
      final response = await _dio.patch(
        '/appointments/$id/cancel',
        data: {'cancellationReason': reason},
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[HmsApiClient] cancelAppointment error: $e');
      return false;
    }
  }

  // --- BILLING & INVOICES ---

  Future<List<Invoice>> getInvoices({
    String? query,
    String? status,
    String? patientId,
  }) async {
    try {
      final response = await _dio.get(
        '/billing/invoices',
        queryParameters: {
          if (query != null && query.isNotEmpty) 'query': query,
          if (status != null && status != 'all') 'status': status,
          if (patientId != null && patientId.isNotEmpty) 'patientId': patientId,
        },
      );
      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        return list.map((json) => _invoiceFromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('[HmsApiClient] getInvoices error: $e');
    }
    return [];
  }

  Future<Invoice?> getInvoiceById(String id) async {
    try {
      final response = await _dio.get('/billing/invoices/$id');
      if (response.statusCode == 200 && response.data != null) {
        return _invoiceFromJson(response.data);
      }
    } catch (e) {
      debugPrint('[HmsApiClient] getInvoiceById error: $e');
    }
    return null;
  }

  Future<bool> payInvoice(
    String id, {
    String? paymentMethod,
    double? amountPaid,
    String? cashierName,
  }) async {
    try {
      final response = await _dio.patch(
        '/billing/invoices/$id/pay',
        data: {
          'paymentMethod': ?paymentMethod,
          'amountPaid': ?amountPaid,
          'cashierName': ?cashierName,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[HmsApiClient] payInvoice error: $e');
      return false;
    }
  }

  Future<bool> markInvoicePaid(String id) async {
    return payInvoice(id);
  }

  // --- CASHIER SHIFTS ---

  Future<CashierShiftModel?> openCashierShift({
    required String cashierId,
    required String cashierName,
    String shiftName = 'Pagi',
    double initialCash = 0.0,
    String? notes,
  }) async {
    try {
      final response = await _dio.post(
        '/billing/shifts/open',
        data: {
          'cashierId': cashierId,
          'cashierName': cashierName,
          'shiftName': shiftName,
          'initialCash': initialCash,
          'notes': ?notes,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['shift'] ?? response.data;
        return CashierShiftModel.fromJson(data);
      }
    } catch (e) {
      debugPrint('[HmsApiClient] openCashierShift error: $e');
    }
    return null;
  }

  Future<CashierShiftModel?> getCurrentCashierShift({String? cashierId}) async {
    try {
      final response = await _dio.get(
        '/billing/shifts/current',
        queryParameters: {if (cashierId != null && cashierId.isNotEmpty) 'cashierId': cashierId},
      );
      if (response.statusCode == 200 && response.data != null && response.data is Map) {
        return CashierShiftModel.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('[HmsApiClient] getCurrentCashierShift error: $e');
    }
    return null;
  }

  Future<CashierShiftModel?> closeCashierShift(
    String shiftId, {
    required double actualCashCounted,
    String? notes,
  }) async {
    try {
      final response = await _dio.post(
        '/billing/shifts/$shiftId/close',
        data: {'actualCashCounted': actualCashCounted, 'notes': ?notes},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['shift'] ?? response.data;
        return CashierShiftModel.fromJson(data);
      }
    } catch (e) {
      debugPrint('[HmsApiClient] closeCashierShift error: $e');
    }
    return null;
  }

  Future<List<CashierShiftModel>> getCashierShifts() async {
    try {
      final response = await _dio.get('/billing/shifts');
      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        return list.map((json) => CashierShiftModel.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('[HmsApiClient] getCashierShifts error: $e');
    }
    return [];
  }

  // ===================== INPATIENT (RAWAT INAP & BEDS) =====================

  Future<List<RoomBedModel>> getInpatientBeds({
    String? classType,
    String? status,
  }) async {
    try {
      final response = await _dio.get(
        '/inpatient/beds',
        queryParameters: {
          if (classType != null && classType != 'all') 'classType': classType,
          if (status != null && status != 'all') 'status': status,
        },
      );
      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        return list.map((json) => RoomBedModel.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('[HmsApiClient] getInpatientBeds error: $e');
    }
    return [];
  }

  Future<RoomBedModel?> updateBedStatus(
    String bedId,
    String status, {
    String? notes,
  }) async {
    try {
      final response = await _dio.patch(
        '/inpatient/beds/$bedId/status',
        data: {'status': status, 'notes': ?notes},
      );
      if (response.statusCode == 200 && response.data != null) {
        return RoomBedModel.fromJson(response.data);
      }
    } catch (e) {
      debugPrint('[HmsApiClient] updateBedStatus error: $e');
    }
    return null;
  }

  Future<List<InpatientAdmissionModel>> getInpatientAdmissions({
    String? status,
    String? query,
  }) async {
    try {
      final response = await _dio.get(
        '/inpatient/admissions',
        queryParameters: {
          if (status != null && status != 'all') 'status': status,
          if (query != null && query.isNotEmpty) 'query': query,
        },
      );
      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        return list
            .map((json) => InpatientAdmissionModel.fromJson(json))
            .toList();
      }
    } catch (e) {
      debugPrint('[HmsApiClient] getInpatientAdmissions error: $e');
    }
    return [];
  }

  Future<InpatientAdmissionModel?> getInpatientAdmissionDetail(
    String id,
  ) async {
    try {
      final response = await _dio.get('/inpatient/admissions/$id');
      if (response.statusCode == 200 && response.data != null) {
        return InpatientAdmissionModel.fromJson(response.data);
      }
    } catch (e) {
      debugPrint('[HmsApiClient] getInpatientAdmissionDetail error: $e');
    }
    return null;
  }

  Future<InpatientAdmissionModel?> createInpatientAdmission({
    required String patientId,
    required String doctorId,
    required String bedId,
    String? admissionType,
    String? initialDiagnosis,
    String? notes,
  }) async {
    try {
      final response = await _dio.post(
        '/inpatient/admissions',
        data: {
          'patientId': patientId,
          'doctorId': doctorId,
          'bedId': bedId,
          'admissionType': ?admissionType,
          'initialDiagnosis': ?initialDiagnosis,
          'notes': ?notes,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return InpatientAdmissionModel.fromJson(response.data);
      }
    } catch (e) {
      debugPrint('[HmsApiClient] createInpatientAdmission error: $e');
    }
    return null;
  }

  Future<InpatientAdmissionModel?> transferInpatientBed(
    String admissionId,
    String newBedId, {
    String? reason,
  }) async {
    try {
      final response = await _dio.post(
        '/inpatient/admissions/$admissionId/transfer-bed',
        data: {'newBedId': newBedId, 'reason': ?reason},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return InpatientAdmissionModel.fromJson(response.data);
      }
    } catch (e) {
      debugPrint('[HmsApiClient] transferInpatientBed error: $e');
    }
    return null;
  }

  Future<InpatientAdmissionModel?> dischargeInpatient(
    String admissionId, {
    required String dischargeDiagnosis,
    required String dischargeCondition,
    String? notes,
  }) async {
    try {
      final response = await _dio.post(
        '/inpatient/admissions/$admissionId/discharge',
        data: {
          'dischargeDiagnosis': dischargeDiagnosis,
          'dischargeCondition': dischargeCondition,
          'notes': ?notes,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return InpatientAdmissionModel.fromJson(response.data);
      }
    } catch (e) {
      debugPrint('[HmsApiClient] dischargeInpatient error: $e');
    }
    return null;
  }

  Future<List<InpatientCPPTModel>> getInpatientCPPT(String admissionId) async {
    try {
      final response = await _dio.get(
        '/inpatient/admissions/$admissionId/cppt',
      );
      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        return list.map((json) => InpatientCPPTModel.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('[HmsApiClient] getInpatientCPPT error: $e');
    }
    return [];
  }

  Future<InpatientCPPTModel?> createInpatientCPPT(
    String admissionId, {
    required String recorderRole,
    required String recorderName,
    String? subjective,
    String? objective,
    String? assessment,
    String? plan,
    String? instruction,
    String? bloodPressure,
    int? heartRate,
    double? temperature,
    int? respiratoryRate,
    int? oxygenSaturation,
  }) async {
    try {
      final response = await _dio.post(
        '/inpatient/admissions/$admissionId/cppt',
        data: {
          'recorderRole': recorderRole,
          'recorderName': recorderName,
          'subjective': ?subjective,
          'objective': ?objective,
          'assessment': ?assessment,
          'plan': ?plan,
          'instruction': ?instruction,
          'bloodPressure': ?bloodPressure,
          'heartRate': ?heartRate,
          'temperature': ?temperature,
          'respiratoryRate': ?respiratoryRate,
          'oxygenSaturation': ?oxygenSaturation,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return InpatientCPPTModel.fromJson(response.data);
      }
    } catch (e) {
      debugPrint('[HmsApiClient] createInpatientCPPT error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getReceiptData(String id) async {
    try {
      final response = await _dio.get('/billing/invoices/$id/receipt-data');
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[HmsApiClient] getReceiptData error: $e');
    }
    return null;
  }

  // ===================== LABORATORY & DIAGNOSTICS (LIS) =====================

  Future<List<LabTestCatalogModel>> getLabCatalog({
    String? category,
    String? query,
  }) async {
    try {
      final response = await _dio.get(
        '/laboratory/catalog',
        queryParameters: {
          if (category != null && category != 'all') 'category': category,
          if (query != null && query.isNotEmpty) 'query': query,
        },
      );
      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        return list.map((json) => LabTestCatalogModel.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('[HmsApiClient] getLabCatalog error: $e');
    }
    return [];
  }

  Future<LabTestCatalogModel?> createLabCatalog(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post('/laboratory/catalog', data: data);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return LabTestCatalogModel.fromJson(response.data);
      }
    } catch (e) {
      debugPrint('[HmsApiClient] createLabCatalog error: $e');
    }
    return null;
  }

  Future<List<LabOrderModel>> getLabOrders({
    String? status,
    String? priority,
    String? query,
  }) async {
    try {
      final response = await _dio.get(
        '/laboratory/orders',
        queryParameters: {
          if (status != null && status != 'all') 'status': status,
          if (priority != null && priority != 'all') 'priority': priority,
          if (query != null && query.isNotEmpty) 'query': query,
        },
      );
      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        return list.map((json) => LabOrderModel.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('[HmsApiClient] getLabOrders error: $e');
    }
    return [];
  }

  Future<LabOrderModel?> getLabOrderDetail(String id) async {
    try {
      final response = await _dio.get('/laboratory/orders/$id');
      if (response.statusCode == 200 && response.data != null) {
        return LabOrderModel.fromJson(response.data);
      }
    } catch (e) {
      debugPrint('[HmsApiClient] getLabOrderDetail error: $e');
    }
    return null;
  }

  Future<LabOrderModel?> createLabOrder({
    required String patientId,
    required String doctorId,
    String? appointmentId,
    String? admissionId,
    String? priority,
    String? clinicalDiagnosis,
    String? clinicalNotes,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final response = await _dio.post(
        '/laboratory/orders',
        data: {
          'patientId': patientId,
          'doctorId': doctorId,
          'appointmentId': ?appointmentId,
          'admissionId': ?admissionId,
          'priority': ?priority,
          'clinicalDiagnosis': ?clinicalDiagnosis,
          'clinicalNotes': ?clinicalNotes,
          'items': items,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return LabOrderModel.fromJson(response.data);
      }
    } catch (e) {
      debugPrint('[HmsApiClient] createLabOrder error: $e');
    }
    return null;
  }

  Future<LabOrderModel?> collectLabSample(
    String orderId,
    String collectorName,
  ) async {
    try {
      final response = await _dio.patch(
        '/laboratory/orders/$orderId/sample',
        data: {'collectorName': collectorName},
      );
      if (response.statusCode == 200 && response.data != null) {
        return LabOrderModel.fromJson(response.data);
      }
    } catch (e) {
      debugPrint('[HmsApiClient] collectLabSample error: $e');
    }
    return null;
  }

  Future<LabOrderModel?> submitLabResults(
    String orderId,
    List<Map<String, dynamic>> results,
  ) async {
    try {
      final response = await _dio.post(
        '/laboratory/orders/$orderId/results',
        data: {'results': results},
      );
      if (response.statusCode == 200 && response.data != null) {
        return LabOrderModel.fromJson(response.data);
      }
    } catch (e) {
      debugPrint('[HmsApiClient] submitLabResults error: $e');
    }
    return null;
  }

  Future<LabOrderModel?> verifyLabOrder(
    String orderId,
    String verifiedBy,
  ) async {
    try {
      final response = await _dio.post(
        '/laboratory/orders/$orderId/verify',
        data: {'verifiedBy': verifiedBy},
      );
      if (response.statusCode == 200 && response.data != null) {
        return LabOrderModel.fromJson(response.data);
      }
    } catch (e) {
      debugPrint('[HmsApiClient] verifyLabOrder error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getLabPdfData(String orderId) async {
    try {
      final response = await _dio.get('/laboratory/orders/$orderId/pdf-data');
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[HmsApiClient] getLabPdfData error: $e');
    }
    return null;
  }

  // --- AUDIT LOGS ---

  Future<List<AuditLog>> getAuditLogs({String? query, String? action}) async {
    try {
      final response = await _dio.get(
        '/audit-logs',
        queryParameters: {
          if (query != null && query.isNotEmpty) 'query': query,
          if (action != null && action != 'all') 'action': action,
        },
      );
      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        return list.map((json) => _auditLogFromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('[HmsApiClient] getAuditLogs error: $e');
    }
    return [];
  }

  // --- NOTIFICATIONS ---

  Future<List<AppNotification>> getNotifications({
    String? role,
    String? userId,
    bool? isRead,
    int limit = 50,
  }) async {
    try {
      final response = await _dio.get(
        '/notifications',
        queryParameters: {
          if (role != null && role != 'all') 'role': role,
          if (userId != null && userId.isNotEmpty) 'userId': userId,
          if (isRead != null) 'isRead': isRead.toString(),
          'limit': limit,
        },
      );
      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        return list.map((json) => _notificationFromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('[HmsApiClient] getNotifications error: $e');
    }
    return [];
  }

  Future<int> getUnreadNotificationCount({String? role, String? userId}) async {
    try {
      final response = await _dio.get(
        '/notifications/unread-count',
        queryParameters: {
          if (role != null && role != 'all') 'role': role,
          if (userId != null && userId.isNotEmpty) 'userId': userId,
        },
      );
      if (response.statusCode == 200 && response.data is Map) {
        return (response.data['unreadCount'] as num?)?.toInt() ?? 0;
      }
    } catch (e) {
      debugPrint('[HmsApiClient] getUnreadNotificationCount error: $e');
    }
    return 0;
  }

  Future<bool> markNotificationRead(String id) async {
    try {
      final response = await _dio.patch('/notifications/$id/read');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[HmsApiClient] markNotificationRead error: $e');
      return false;
    }
  }

  Future<bool> markAllNotificationsRead({String? role, String? userId}) async {
    try {
      final response = await _dio.patch(
        '/notifications/mark-all-read',
        queryParameters: {
          if (role != null && role != 'all') 'role': role,
          if (userId != null && userId.isNotEmpty) 'userId': userId,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[HmsApiClient] markAllNotificationsRead error: $e');
      return false;
    }
  }

  // --- DEPARTMENTS ---

  Future<List<Department>> getDepartments() async {
    try {
      final response = await _dio.get('/departments');
      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        return list.map((json) => _departmentFromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('[HmsApiClient] getDepartments error: $e');
    }
    return [];
  }

  // --- MEDICAL RECORDS & CLINICAL ENCOUNTERS ---

  Future<List<MedicalRecord>> getMedicalRecords({String? patientId}) async {
    try {
      final response = await _dio.get(
        '/medical-records',
        queryParameters: {
          if (patientId != null && patientId.isNotEmpty) 'patientId': patientId,
        },
      );
      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        return list.map((json) => _medicalRecordFromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('[HmsApiClient] getMedicalRecords error: $e');
    }
    return [];
  }

  Future<bool> createMedicalRecord(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/medical-records', data: data);
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      debugPrint('[HmsApiClient] createMedicalRecord error: $e');
      return false;
    }
  }

  Future<List<Map<String, String>>> getIcd10Catalog({String? query}) async {
    try {
      final response = await _dio.get(
        '/medical-records/icd10',
        queryParameters: {
          if (query != null && query.isNotEmpty) 'query': query,
        },
      );
      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        return list
            .map(
              (item) => {
                'code': item['code']?.toString() ?? '',
                'name': item['name']?.toString() ?? '',
                'category': item['category']?.toString() ?? '',
              },
            )
            .toList();
      }
    } catch (e) {
      debugPrint('[HmsApiClient] getIcd10Catalog error: $e');
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getFormularyCatalog({
    String? query,
  }) async {
    try {
      final response = await _dio.get(
        '/medical-records/formulary',
        queryParameters: {
          if (query != null && query.isNotEmpty) 'query': query,
        },
      );
      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        return list
            .map(
              (item) => {
                'name': item['name']?.toString() ?? '',
                'category': item['category']?.toString() ?? '',
                'defaultDose': item['defaultDose']?.toString() ?? '',
                'defaultFrequency': item['defaultFrequency']?.toString() ?? '',
              },
            )
            .toList();
      }
    } catch (e) {
      debugPrint('[HmsApiClient] getFormularyCatalog error: $e');
    }
    return [];
  }

  // --- PHARMACY & MEDICATION DISPENSING ---

  Future<List<PharmacyPrescription>> getPharmacyPrescriptions({
    String? status,
  }) async {
    try {
      final response = await _dio.get(
        '/pharmacy/prescriptions',
        queryParameters: {
          if (status != null && status != 'all') 'status': status,
        },
      );
      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        return list.map((json) => _pharmacyPrescriptionFromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('[HmsApiClient] getPharmacyPrescriptions error: $e');
    }
    return [];
  }

  Future<bool> updatePrescriptionStatus(String id, String status) async {
    try {
      final response = await _dio.patch(
        '/pharmacy/prescriptions/$id/status',
        data: {'status': status},
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[HmsApiClient] updatePrescriptionStatus error: $e');
      return false;
    }
  }

  Future<List<MedicineStock>> getPharmacyInventory({String? query}) async {
    try {
      final response = await _dio.get(
        '/pharmacy/inventory',
        queryParameters: {
          if (query != null && query.isNotEmpty) 'query': query,
        },
      );
      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        return list.map((json) => _medicineStockFromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('[HmsApiClient] getPharmacyInventory error: $e');
    }
    return [];
  }

  Future<bool> updateMedicineStock(String id, int quantity) async {
    try {
      final response = await _dio.patch(
        '/pharmacy/inventory/$id/stock',
        data: {'quantity': quantity},
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[HmsApiClient] updateMedicineStock error: $e');
      return false;
    }
  }

  // --- CLINIC PROCEDURES ---

  Future<List<ClinicProcedure>> getProcedures({
    String? category,
    String? status,
  }) async {
    try {
      final response = await _dio.get(
        '/procedures',
        queryParameters: {
          if (category != null && category != 'all') 'category': category,
          if (status != null && status != 'all') 'status': status,
        },
      );
      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        return list.map((json) => _clinicProcedureFromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('[HmsApiClient] getProcedures error: $e');
    }
    return [];
  }

  Future<bool> createProcedure(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/procedures', data: data);
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      debugPrint('[HmsApiClient] createProcedure error: $e');
      return false;
    }
  }

  Future<bool> updateProcedure(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch('/procedures/$id', data: data);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[HmsApiClient] updateProcedure error: $e');
      return false;
    }
  }

  Future<bool> deleteProcedure(String id) async {
    try {
      final response = await _dio.delete('/procedures/$id');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[HmsApiClient] deleteProcedure error: $e');
      return false;
    }
  }

  // --- MEDICAL CERTIFICATES (SKD & Surat Sehat) ---

  Future<List<MedicalCertificate>> getMedicalCertificates({
    String? patientId,
    String? doctorId,
  }) async {
    try {
      final response = await _dio.get(
        '/medical-records/certificates',
        queryParameters: {
          if (patientId != null && patientId.isNotEmpty) 'patientId': patientId,
          if (doctorId != null && doctorId.isNotEmpty) 'doctorId': doctorId,
        },
      );
      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        return list.map((json) => _medicalCertificateFromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('[HmsApiClient] getMedicalCertificates error: $e');
    }
    return [];
  }

  Future<bool> createMedicalCertificate(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(
        '/medical-records/certificates',
        data: data,
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      debugPrint('[HmsApiClient] createMedicalCertificate error: $e');
      return false;
    }
  }

  // --- CLINIC DAILY ANALYTICS & EXCEL EXPORTS ---

  Future<DailyClinicSummary?> getDailyAnalytics() async {
    try {
      final response = await _dio.get('/analytics/daily-report');
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return _dailyClinicSummaryFromJson(response.data);
      }
    } catch (e) {
      debugPrint('[HmsApiClient] getDailyAnalytics error: $e');
    }
    return null;
  }

  Future<MorbiLB1SummaryModel?> getMorbiLB1Summary({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final response = await _dio.get(
        '/analytics/morbi-lb1-summary',
        queryParameters: {
          if (startDate != null && startDate.isNotEmpty) 'startDate': startDate,
          if (endDate != null && endDate.isNotEmpty) 'endDate': endDate,
        },
      );
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return MorbiLB1SummaryModel.fromJson(response.data);
      }
    } catch (e) {
      debugPrint('[HmsApiClient] getMorbiLB1Summary error: $e');
    }
    return null;
  }

  Future<String?> downloadFinancialExport({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final response = await _dio.get(
        '/analytics/export/financial',
        queryParameters: {
          if (startDate != null && startDate.isNotEmpty) 'startDate': startDate,
          if (endDate != null && endDate.isNotEmpty) 'endDate': endDate,
        },
      );
      if (response.statusCode == 200) {
        return response.data?.toString();
      }
    } catch (e) {
      debugPrint('[HmsApiClient] downloadFinancialExport error: $e');
    }
    return null;
  }

  Future<String?> downloadMorbiLB1Export({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final response = await _dio.get(
        '/analytics/export/morbi-lb1',
        queryParameters: {
          if (startDate != null && startDate.isNotEmpty) 'startDate': startDate,
          if (endDate != null && endDate.isNotEmpty) 'endDate': endDate,
        },
      );
      if (response.statusCode == 200) {
        return response.data?.toString();
      }
    } catch (e) {
      debugPrint('[HmsApiClient] downloadMorbiLB1Export error: $e');
    }
    return null;
  }

  Future<String?> downloadPharmacyStockExport() async {
    try {
      final response = await _dio.get('/analytics/export/pharmacy-stock');
      if (response.statusCode == 200) {
        return response.data?.toString();
      }
    } catch (e) {
      debugPrint('[HmsApiClient] downloadPharmacyStockExport error: $e');
    }
    return null;
  }

  Future<String?> downloadPatientVisitsExport({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final response = await _dio.get(
        '/analytics/export/patient-visits',
        queryParameters: {
          if (startDate != null && startDate.isNotEmpty) 'startDate': startDate,
          if (endDate != null && endDate.isNotEmpty) 'endDate': endDate,
        },
      );
      if (response.statusCode == 200) {
        return response.data?.toString();
      }
    } catch (e) {
      debugPrint('[HmsApiClient] downloadPatientVisitsExport error: $e');
    }
    return null;
  }

  // --- JSON DESERIALIZERS ---

  ClinicProcedure _clinicProcedureFromJson(dynamic json) {
    final map = json as Map<String, dynamic>;
    return ClinicProcedure(
      id: map['id']?.toString() ?? '',
      code: map['code']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      category: map['category']?.toString() ?? 'Umum',
      description: map['description']?.toString() ?? '',
      price: double.tryParse(map['price']?.toString() ?? '0') ?? 0.0,
      status: map['status']?.toString() ?? 'active',
    );
  }

  MedicalCertificate _medicalCertificateFromJson(dynamic json) {
    final map = json as Map<String, dynamic>;
    final patientMap = map['patient'] as Map<String, dynamic>?;
    final doctorMap = map['doctor'] as Map<String, dynamic>?;

    return MedicalCertificate(
      id: map['id']?.toString() ?? '',
      certificateNumber:
          map['certificateNumber']?.toString() ?? 'SKD/2026/08/001',
      type: map['type']?.toString() ?? 'sick_leave',
      patientName:
          patientMap?['name']?.toString() ??
          map['patientName']?.toString() ??
          'Nadia Putri',
      patientMrn:
          patientMap?['medicalRecordNumber']?.toString() ??
          map['patientMrn']?.toString() ??
          'MRN-2026-001',
      doctorName:
          doctorMap?['name']?.toString() ??
          map['doctorName']?.toString() ??
          'dr. Maya Pratama, Sp.JP',
      doctorSpecialist:
          doctorMap?['specialist']?.toString() ??
          map['doctorSpecialist']?.toString() ??
          'Poli Umum',
      diagnosis: map['diagnosis']?.toString() ?? 'Pemeriksaan Rutin',
      startDate: map['startDate'] != null
          ? DateTime.tryParse(map['startDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      endDate: map['endDate'] != null
          ? DateTime.tryParse(map['endDate'].toString()) ??
                DateTime.now().add(const Duration(days: 2))
          : DateTime.now().add(const Duration(days: 2)),
      durationDays: (map['durationDays'] as num?)?.toInt() ?? 1,
      notes: map['notes']?.toString() ?? '',
      status: map['status']?.toString() ?? 'issued',
    );
  }

  DailyClinicSummary _dailyClinicSummaryFromJson(dynamic json) {
    final map = json as Map<String, dynamic>;
    final fin = map['financials'] as Map<String, dynamic>? ?? {};
    final ops = map['operations'] as Map<String, dynamic>? ?? {};
    final pMethods = (fin['paymentMethods'] as List?) ?? [];
    final topMeds = (map['topMedicines'] as List?) ?? [];

    return DailyClinicSummary(
      reportDate: map['reportDate'] != null
          ? DateTime.tryParse(map['reportDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      totalRevenue:
          double.tryParse(fin['totalRevenue']?.toString() ?? '0') ?? 0.0,
      pendingRevenue:
          double.tryParse(fin['pendingRevenue']?.toString() ?? '0') ?? 0.0,
      paidCount: (fin['paidTransactionsCount'] as num?)?.toInt() ?? 0,
      pendingCount: (fin['pendingTransactionsCount'] as num?)?.toInt() ?? 0,
      averageTicket:
          double.tryParse(fin['averageTicketSize']?.toString() ?? '0') ?? 0.0,
      totalAppointments: (ops['totalAppointments'] as num?)?.toInt() ?? 0,
      completedVisits: (ops['completedVisits'] as num?)?.toInt() ?? 0,
      paymentMethods: pMethods
          .map(
            (item) => PaymentMethodSummary(
              method: item['method']?.toString() ?? 'Tunai',
              totalAmount:
                  double.tryParse(item['totalAmount']?.toString() ?? '0') ??
                  0.0,
              percentage: (item['percentage'] as num?)?.toInt() ?? 0,
            ),
          )
          .toList(),
      topMedicines: topMeds
          .map(
            (item) => TopMedicineSummary(
              name: item['name']?.toString() ?? '',
              dosage: item['dosage']?.toString() ?? '',
              prescribedCount: (item['prescribedCount'] as num?)?.toInt() ?? 0,
            ),
          )
          .toList(),
    );
  }

  PharmacyPrescription _pharmacyPrescriptionFromJson(dynamic json) {
    final map = json as Map<String, dynamic>;
    final itemsList = (map['items'] as List?) ?? [];

    return PharmacyPrescription(
      id: map['id']?.toString() ?? '',
      prescriptionNumber: map['prescriptionNumber']?.toString() ?? 'RX-001',
      patientId: map['patientId']?.toString() ?? '',
      patientName: map['patientName']?.toString() ?? '',
      patientMrn: map['patientMrn']?.toString() ?? '',
      insurance: map['insurance']?.toString() ?? 'Umum',
      doctorId: map['doctorId']?.toString() ?? '',
      doctorName: map['doctorName']?.toString() ?? '',
      doctorSpecialist: map['doctorSpecialist']?.toString() ?? '',
      status: map['status']?.toString() ?? 'issued',
      statusLabel: map['statusLabel']?.toString() ?? 'Menunggu Diracik',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      notes: map['notes']?.toString() ?? '',
      items: itemsList.map((item) {
        final iMap = item as Map<String, dynamic>;
        return PharmacyPrescriptionItem(
          id: iMap['id']?.toString() ?? '',
          medicineName: iMap['medicineName']?.toString() ?? '',
          dosage: iMap['dosage']?.toString() ?? '',
          frequency: iMap['frequency']?.toString() ?? '',
          route: iMap['route']?.toString() ?? 'oral',
          durationDays: (iMap['durationDays'] as num?)?.toInt() ?? 3,
          instruction: iMap['instruction']?.toString() ?? '',
        );
      }).toList(),
    );
  }

  MedicineStock _medicineStockFromJson(dynamic json) {
    final map = json as Map<String, dynamic>;
    return MedicineStock(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      form: map['form']?.toString() ?? '',
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      minStock: (map['minStock'] as num?)?.toInt() ?? 0,
      unit: map['unit']?.toString() ?? '',
      batchNumber: map['batchNumber']?.toString() ?? '',
      expirationDate: map['expirationDate']?.toString() ?? '',
      price: double.tryParse(map['price']?.toString() ?? '0') ?? 0.0,
      status: map['status']?.toString() ?? 'normal',
    );
  }

  Department _departmentFromJson(dynamic json) {
    final map = json as Map<String, dynamic>;
    return Department(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      code: map['code']?.toString() ?? '',
      doctorCount: (map['doctorCount'] as num?)?.toInt() ?? 0,
      isActive: map['status'] == 'active',
    );
  }

  MedicalRecord _medicalRecordFromJson(dynamic json) {
    final map = json as Map<String, dynamic>;
    final diagnoses =
        (map['diagnoses'] as List?)
            ?.map((d) => d['name']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .join(', ') ??
        (map['diagnosisSummary']?.toString() ?? 'Pemeriksaan Rutin');

    final prescriptions =
        (map['prescriptions'] as List?)
            ?.map((p) => '${p['medicineName']} (${p['dosage']})')
            .where((s) => s.isNotEmpty)
            .join(', ') ??
        'Resep obat standar';

    final dateStr = map['date'] != null
        ? map['date'].toString().split('T').first
        : '2026-08-15';

    return MedicalRecord(
      id: map['id']?.toString() ?? '',
      date: dateStr,
      doctor: map['doctorName']?.toString() ?? 'dr. Maya Pratama, Sp.JP',
      specialist: map['specialist']?.toString() ?? 'Kardiologi',
      diagnosis: diagnoses.isNotEmpty ? diagnoses : 'Pemeriksaan Rutin',
      medicine: prescriptions.isNotEmpty ? prescriptions : 'Amlodipine 5mg',
      anamnesis: map['anamnesis']?.toString() ?? '',
      physicalExam: map['physicalExam']?.toString() ?? '',
      status: map['status']?.toString() ?? 'signed',
    );
  }

  Doctor _doctorFromJson(dynamic json) {
    final map = json as Map<String, dynamic>;
    return Doctor(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      specialist: map['specialist']?.toString() ?? '',
      hospital: 'SehatKu Medical Center',
      experience: (map['experienceYears'] as num?)?.toInt() ?? 0,
      rating: double.tryParse(map['rating']?.toString() ?? '5.0') ?? 5.0,
      availableToday: map['availableToday'] == true,
      licenseNumber: map['licenseNumber']?.toString() ?? '',
      departmentId: map['departmentId']?.toString() ?? 'dept-1',
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      scheduleDays:
          (map['scheduleDays'] as List?)?.map((e) => e.toString()).toList() ??
          ['Senin', 'Rabu', 'Jumat'],
      isActive: map['status'] == 'active',
      photoUrl: map['photoUrl']?.toString() ?? map['avatarUrl']?.toString() ?? '',
    );
  }

  Patient _patientFromJson(dynamic json) {
    final map = json as Map<String, dynamic>;
    return Patient(
      id: map['id']?.toString() ?? '',
      medicalRecordNumber: map['medicalRecordNumber']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      birthDate: map['birthDate'] != null
          ? DateTime.tryParse(map['birthDate'].toString()) ?? DateTime(1990)
          : DateTime(1990),
      gender: map['gender']?.toString() ?? 'Perempuan',
      status: map['status']?.toString() ?? 'Aktif',
      bloodType: map['bloodType']?.toString(),
      insuranceProvider: map['insuranceProvider']?.toString(),
      nik: map['nik']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      emergencyContact: map['emergencyContact']?.toString() ?? '',
    );
  }

  Appointment _appointmentFromJson(dynamic json) {
    final map = json as Map<String, dynamic>;
    final docName = map['doctor'] != null && map['doctor'] is Map
        ? (map['doctor']['name']?.toString() ?? '')
        : (map['doctorName']?.toString() ?? 'dr. Maya Pratama, Sp.JP');
    final patName = map['patient'] != null && map['patient'] is Map
        ? (map['patient']['name']?.toString() ?? '')
        : (map['patientName']?.toString() ?? 'Nadia Putri');

    final docAvatar = map['doctor'] != null && map['doctor'] is Map
        ? (map['doctor']['avatarUrl']?.toString() ?? map['doctor']['photoUrl']?.toString() ?? '')
        : (map['doctorPhotoUrl']?.toString() ?? map['avatarUrl']?.toString() ?? '');

    return Appointment(
      id: map['id']?.toString() ?? '',
      doctorName: docName,
      patientName: patName,
      dateLabel: map['dateLabel']?.toString() ?? 'Hari ini',
      time: map['appointmentTime']?.toString() ?? '09:30 WIB',
      status: map['status']?.toString() ?? 'Menunggu',
      queueNumber: map['queueNumber']?.toString() ?? 'A-001',
      department: map['departmentName']?.toString() ?? 'Poli Umum',
      reason: map['reason']?.toString() ?? 'Konsultasi Rutin',
      cancellationReason: map['cancellationReason']?.toString(),
      reservationNumber: map['reservationNumber']?.toString() ?? map['appointmentNumber']?.toString(),
      doctorPhotoUrl: docAvatar,
    );
  }

  Invoice _invoiceFromJson(dynamic json) {
    final map = json as Map<String, dynamic>;
    final itemsRaw = (map['items'] as List?) ?? [];
    return Invoice(
      id: map['id']?.toString() ?? '',
      invoiceNumber: map['invoiceNumber']?.toString() ?? '',
      patientName: map['patientName']?.toString() ?? '',
      patientMrn: map['patientMrn']?.toString() ?? 'MRN-2026-001',
      insuranceProvider:
          map['insuranceProvider']?.toString() ?? 'Umum / Mandiri',
      doctorName: map['doctorName']?.toString() ?? '',
      serviceName: map['serviceName']?.toString() ?? '',
      amount: double.tryParse(map['amount']?.toString() ?? '0') ?? 0.0,
      status: map['status']?.toString() ?? 'Menunggu',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      paymentMethod: map['paymentMethod']?.toString() ?? 'Tunai',
      paidAt: map['paidAt'] != null
          ? DateTime.tryParse(map['paidAt'].toString())
          : null,
      items: itemsRaw.map((item) {
        final iMap = item as Map<String, dynamic>;
        return InvoiceItem(
          name: iMap['name']?.toString() ?? '',
          category: iMap['category']?.toString() ?? 'Umum',
          quantity: (iMap['quantity'] as num?)?.toInt() ?? 1,
          unitPrice:
              double.tryParse(iMap['unitPrice']?.toString() ?? '0') ?? 0.0,
          subtotal: double.tryParse(iMap['subtotal']?.toString() ?? '0') ?? 0.0,
        );
      }).toList(),
      terbilang: map['terbilang']?.toString() ?? '',
    );
  }

  AuditLog _auditLogFromJson(dynamic json) {
    final map = json as Map<String, dynamic>;
    return AuditLog(
      id: map['id']?.toString() ?? '',
      actorName: map['actorName']?.toString() ?? '',
      actorRole: map['actorRole']?.toString() ?? '',
      action: map['action']?.toString() ?? 'UPDATE',
      resourceType: map['resourceType']?.toString() ?? '',
      resourceId: map['resourceId']?.toString() ?? '',
      details: map['details']?.toString() ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      ipAddress: map['ipAddress']?.toString() ?? '127.0.0.1',
    );
  }

  AppNotification _notificationFromJson(dynamic json) {
    final map = json as Map<String, dynamic>;
    return AppNotification(
      id: map['id']?.toString() ?? '',
      role: map['role']?.toString() ?? 'all',
      title: map['title']?.toString() ?? 'Notifikasi',
      message: map['message']?.toString() ?? '',
      type: map['type']?.toString() ?? 'info',
      isRead: map['isRead'] == true,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      targetId: map['targetId']?.toString(),
    );
  }
}
