import '../../core/config/app_env.dart';

enum UserRole {
  patient('Pasien'),
  doctor('Dokter'),
  admin('Admin');

  const UserRole(this.label);
  final String label;
}


class Doctor {
  const Doctor({
    required this.id,
    required this.name,
    required this.specialist,
    required this.hospital,
    required this.experience,
    required this.rating,
    required this.availableToday,
    this.licenseNumber = '',
    this.departmentId = 'dept-1',
    this.email = '',
    this.phone = '',
    this.scheduleDays = const ['Senin', 'Rabu', 'Jumat'],
    this.isActive = true,
    this.photoUrl = '',
  });

  final String id;
  final String name;
  final String specialist;
  final String hospital;
  final int experience;
  final double rating;
  final bool availableToday;
  final String licenseNumber;
  final String departmentId;
  final String email;
  final String phone;
  final List<String> scheduleDays;
  final bool isActive;
  final String photoUrl;

  String get displayPhotoUrl => AppEnv.resolveMediaUrl(photoUrl);

  Doctor copyWith({
    String? id,
    String? name,
    String? specialist,
    String? hospital,
    int? experience,
    double? rating,
    bool? availableToday,
    String? licenseNumber,
    String? departmentId,
    String? email,
    String? phone,
    List<String>? scheduleDays,
    bool? isActive,
    String? photoUrl,
  }) {
    return Doctor(
      id: id ?? this.id,
      name: name ?? this.name,
      specialist: specialist ?? this.specialist,
      hospital: hospital ?? this.hospital,
      experience: experience ?? this.experience,
      rating: rating ?? this.rating,
      availableToday: availableToday ?? this.availableToday,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      departmentId: departmentId ?? this.departmentId,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      scheduleDays: scheduleDays ?? this.scheduleDays,
      isActive: isActive ?? this.isActive,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}

class Patient {
  const Patient({
    required this.id,
    required this.medicalRecordNumber,
    required this.name,
    required this.birthDate,
    required this.gender,
    this.status = 'Aktif',
    this.bloodType,
    this.insuranceProvider,
    this.nik = '',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.emergencyContact = '',
  });

  final String id;
  final String medicalRecordNumber;
  final String name;
  final DateTime birthDate;
  final String gender;
  final String status;
  final String? bloodType;
  final String? insuranceProvider;
  final String nik;
  final String phone;
  final String email;
  final String address;
  final String emergencyContact;

  String get insurance => insuranceProvider ?? 'Umum / Mandiri';

  Patient copyWith({
    String? id,
    String? medicalRecordNumber,
    String? name,
    DateTime? birthDate,
    String? gender,
    String? status,
    String? bloodType,
    String? insuranceProvider,
    String? nik,
    String? phone,
    String? email,
    String? address,
    String? emergencyContact,
  }) {
    return Patient(
      id: id ?? this.id,
      medicalRecordNumber: medicalRecordNumber ?? this.medicalRecordNumber,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      status: status ?? this.status,
      bloodType: bloodType ?? this.bloodType,
      insuranceProvider: insuranceProvider ?? this.insuranceProvider,
      nik: nik ?? this.nik,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      emergencyContact: emergencyContact ?? this.emergencyContact,
    );
  }
}

class Appointment {
  const Appointment({
    required this.id,
    required this.doctorName,
    required this.patientName,
    required this.dateLabel,
    required this.time,
    required this.status,
    required this.queueNumber,
    this.department = 'Poli Umum',
    this.reason = 'Konsultasi Rutin',
    this.cancellationReason,
    this.reservationNumber,
    this.doctorPhotoUrl = '',
  });

  final String id;
  final String doctorName;
  final String patientName;
  final String dateLabel;
  final String time;
  final String status;
  final String queueNumber;
  final String department;
  final String reason;
  final String? cancellationReason;
  final String? reservationNumber;
  final String doctorPhotoUrl;

  String get displayReservationNumber {
    if (reservationNumber != null && reservationNumber!.isNotEmpty) {
      return reservationNumber!;
    }
    if (id.startsWith('RSV-') || id.startsWith('APT-')) {
      return id;
    }
    final cleanId = id.replaceAll('-', '').toUpperCase();
    final short = cleanId.length >= 8 ? cleanId.substring(0, 8) : cleanId;
    return 'RSV-2026-$short';
  }

  String get displayDoctorPhotoUrl => AppEnv.resolveMediaUrl(doctorPhotoUrl);

  Appointment copyWith({
    String? id,
    String? doctorName,
    String? patientName,
    String? dateLabel,
    String? time,
    String? status,
    String? queueNumber,
    String? department,
    String? reason,
    String? cancellationReason,
    String? reservationNumber,
    String? doctorPhotoUrl,
  }) {
    return Appointment(
      id: id ?? this.id,
      doctorName: doctorName ?? this.doctorName,
      patientName: patientName ?? this.patientName,
      dateLabel: dateLabel ?? this.dateLabel,
      time: time ?? this.time,
      status: status ?? this.status,
      queueNumber: queueNumber ?? this.queueNumber,
      department: department ?? this.department,
      reason: reason ?? this.reason,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      reservationNumber: reservationNumber ?? this.reservationNumber,
      doctorPhotoUrl: doctorPhotoUrl ?? this.doctorPhotoUrl,
    );
  }
}

class MedicalRecord {
  const MedicalRecord({
    this.id = '',
    required this.date,
    required this.doctor,
    this.specialist = 'Spesialis',
    required this.diagnosis,
    required this.medicine,
    this.anamnesis = '',
    this.physicalExam = '',
    this.status = 'signed',
  });

  final String id;
  final String date;
  final String doctor;
  final String specialist;
  final String diagnosis;
  final String medicine;
  final String anamnesis;
  final String physicalExam;
  final String status;
}

class Department {
  const Department({
    required this.id,
    required this.name,
    required this.code,
    required this.doctorCount,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String code;
  final int doctorCount;
  final bool isActive;
}

class InvoiceItem {
  const InvoiceItem({
    required this.name,
    required this.category,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  final String name;
  final String category; // 'Konsultasi Medis', 'Farmasi & Obat', 'Tindakan', 'Administrasi'
  final int quantity;
  final double unitPrice;
  final double subtotal;
}

class Invoice {
  const Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.patientName,
    this.patientMrn = 'MRN-2026-001',
    this.insuranceProvider = 'Umum / Mandiri',
    required this.doctorName,
    required this.serviceName,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.paymentMethod,
    this.paidAt,
    this.items = const [],
    this.terbilang = '',
  });

  final String id;
  final String invoiceNumber;
  final String patientName;
  final String patientMrn;
  final String insuranceProvider;
  final String doctorName;
  final String serviceName;
  final double amount;
  final String status; // 'Lunas', 'Menunggu', 'Dibatalkan', 'Refund'
  final DateTime createdAt;
  final String paymentMethod; // 'QRIS Dinamis', 'Tunai', 'Kartu Debit', 'Transfer Bank', 'BPJS Kesehatan'
  final DateTime? paidAt;
  final List<InvoiceItem> items;
  final String terbilang;

  Invoice copyWith({
    String? id,
    String? invoiceNumber,
    String? patientName,
    String? patientMrn,
    String? insuranceProvider,
    String? doctorName,
    String? serviceName,
    double? amount,
    String? status,
    DateTime? createdAt,
    String? paymentMethod,
    DateTime? paidAt,
    List<InvoiceItem>? items,
    String? terbilang,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      patientName: patientName ?? this.patientName,
      patientMrn: patientMrn ?? this.patientMrn,
      insuranceProvider: insuranceProvider ?? this.insuranceProvider,
      doctorName: doctorName ?? this.doctorName,
      serviceName: serviceName ?? this.serviceName,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paidAt: paidAt ?? this.paidAt,
      items: items ?? this.items,
      terbilang: terbilang ?? this.terbilang,
    );
  }
}

class AuditLog {
  const AuditLog({
    required this.id,
    required this.actorName,
    required this.actorRole,
    required this.action,
    required this.resourceType,
    required this.resourceId,
    required this.details,
    required this.timestamp,
    this.ipAddress = '192.168.1.100',
  });

  final String id;
  final String actorName;
  final String actorRole;
  final String action; // 'CREATE', 'UPDATE', 'DEACTIVATE', 'CANCEL', 'LOGIN'
  final String resourceType; // 'Doctor', 'Patient', 'Appointment', 'Invoice'
  final String resourceId;
  final String details;
  final DateTime timestamp;
  final String ipAddress;
}

class PharmacyPrescriptionItem {
  const PharmacyPrescriptionItem({
    required this.id,
    required this.medicineName,
    required this.dosage,
    required this.frequency,
    this.route = 'oral',
    this.durationDays = 3,
    this.instruction = '',
  });

  final String id;
  final String medicineName;
  final String dosage;
  final String frequency;
  final String route;
  final int durationDays;
  final String instruction;
}

class PharmacyPrescription {
  const PharmacyPrescription({
    required this.id,
    required this.prescriptionNumber,
    required this.patientId,
    required this.patientName,
    required this.patientMrn,
    required this.insurance,
    required this.doctorId,
    required this.doctorName,
    required this.doctorSpecialist,
    required this.status, // 'issued', 'dispensing', 'ready', 'completed'
    required this.statusLabel,
    required this.createdAt,
    required this.items,
    this.notes = '',
  });

  final String id;
  final String prescriptionNumber;
  final String patientId;
  final String patientName;
  final String patientMrn;
  final String insurance;
  final String doctorId;
  final String doctorName;
  final String doctorSpecialist;
  final String status;
  final String statusLabel;
  final DateTime createdAt;
  final List<PharmacyPrescriptionItem> items;
  final String notes;

  PharmacyPrescription copyWith({
    String? status,
    String? statusLabel,
  }) {
    return PharmacyPrescription(
      id: id,
      prescriptionNumber: prescriptionNumber,
      patientId: patientId,
      patientName: patientName,
      patientMrn: patientMrn,
      insurance: insurance,
      doctorId: doctorId,
      doctorName: doctorName,
      doctorSpecialist: doctorSpecialist,
      status: status ?? this.status,
      statusLabel: statusLabel ?? this.statusLabel,
      createdAt: createdAt,
      items: items,
      notes: notes,
    );
  }
}

class MedicineStock {
  const MedicineStock({
    required this.id,
    required this.name,
    required this.category,
    required this.form,
    required this.stock,
    required this.minStock,
    required this.unit,
    required this.batchNumber,
    required this.expirationDate,
    required this.price,
    required this.status, // 'normal', 'low', 'critical'
  });

  final String id;
  final String name;
  final String category;
  final String form;
  final int stock;
  final int minStock;
  final String unit;
  final String batchNumber;
  final String expirationDate;
  final double price;
  final String status;

  MedicineStock copyWith({
    int? stock,
    String? status,
  }) {
    return MedicineStock(
      id: id,
      name: name,
      category: category,
      form: form,
      stock: stock ?? this.stock,
      minStock: minStock,
      unit: unit,
      batchNumber: batchNumber,
      expirationDate: expirationDate,
      price: price,
      status: status ?? this.status,
    );
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.role,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.targetId,
  });

  final String id;
  final String role; // 'patient', 'doctor', 'admin', 'all'
  final String title;
  final String message;
  final String type; // 'appointment', 'prescription', 'billing', 'clinical', 'system', 'emergency'
  final bool isRead;
  final DateTime createdAt;
  final String? targetId;

  AppNotification copyWith({
    String? id,
    String? role,
    String? title,
    String? message,
    String? type,
    bool? isRead,
    DateTime? createdAt,
    String? targetId,
  }) {
    return AppNotification(
      id: id ?? this.id,
      role: role ?? this.role,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      targetId: targetId ?? this.targetId,
    );
  }
}

class ClinicProcedure {
  const ClinicProcedure({
    required this.id,
    required this.code,
    required this.name,
    this.category = 'Umum',
    this.description = '',
    required this.price,
    this.status = 'active',
  });

  final String id;
  final String code;
  final String name;
  final String category;
  final String description;
  final double price;
  final String status;

  ClinicProcedure copyWith({
    String? id,
    String? code,
    String? name,
    String? category,
    String? description,
    double? price,
    String? status,
  }) {
    return ClinicProcedure(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      price: price ?? this.price,
      status: status ?? this.status,
    );
  }
}

class MedicalCertificate {
  const MedicalCertificate({
    required this.id,
    required this.certificateNumber,
    this.type = 'sick_leave', // 'sick_leave' (SKD) or 'healthy' (Surat Sehat)
    required this.patientName,
    required this.patientMrn,
    required this.doctorName,
    required this.doctorSpecialist,
    this.diagnosis = 'Pemeriksaan Klinis Rutin',
    required this.startDate,
    required this.endDate,
    this.durationDays = 1,
    this.notes = '',
    this.status = 'issued',
  });

  final String id;
  final String certificateNumber;
  final String type;
  final String patientName;
  final String patientMrn;
  final String doctorName;
  final String doctorSpecialist;
  final String diagnosis;
  final DateTime startDate;
  final DateTime endDate;
  final int durationDays;
  final String notes;
  final String status;
}

class PaymentMethodSummary {
  const PaymentMethodSummary({
    required this.method,
    required this.totalAmount,
    required this.percentage,
  });

  final String method;
  final double totalAmount;
  final int percentage;
}

class TopMedicineSummary {
  const TopMedicineSummary({
    required this.name,
    required this.dosage,
    required this.prescribedCount,
  });

  final String name;
  final String dosage;
  final int prescribedCount;
}

class DailyClinicSummary {
  const DailyClinicSummary({
    required this.reportDate,
    required this.totalRevenue,
    required this.pendingRevenue,
    required this.paidCount,
    required this.pendingCount,
    required this.averageTicket,
    required this.totalAppointments,
    required this.completedVisits,
    required this.paymentMethods,
    required this.topMedicines,
  });

  final DateTime reportDate;
  final double totalRevenue;
  final double pendingRevenue;
  final int paidCount;
  final int pendingCount;
  final double averageTicket;
  final int totalAppointments;
  final int completedVisits;
  final List<PaymentMethodSummary> paymentMethods;
  final List<TopMedicineSummary> topMedicines;
}

class MorbiLB1ItemModel {
  const MorbiLB1ItemModel({
    required this.rank,
    required this.icd10Code,
    required this.description,
    required this.maleCount,
    required this.femaleCount,
    required this.totalCount,
    required this.percentage,
  });

  final int rank;
  final String icd10Code;
  final String description;
  final int maleCount;
  final int femaleCount;
  final int totalCount;
  final double percentage;

  factory MorbiLB1ItemModel.fromJson(Map<String, dynamic> json) {
    return MorbiLB1ItemModel(
      rank: (json['rank'] as num?)?.toInt() ?? 1,
      icd10Code: json['icd10Code']?.toString() ?? '-',
      description: json['description']?.toString() ?? '-',
      maleCount: (json['maleCount'] as num?)?.toInt() ?? 0,
      femaleCount: (json['femaleCount'] as num?)?.toInt() ?? 0,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class MorbiLB1SummaryModel {
  const MorbiLB1SummaryModel({
    required this.totalCases,
    required this.rankedDiseases,
  });

  final int totalCases;
  final List<MorbiLB1ItemModel> rankedDiseases;

  factory MorbiLB1SummaryModel.fromJson(Map<String, dynamic> json) {
    return MorbiLB1SummaryModel(
      totalCases: (json['totalCases'] as num?)?.toInt() ?? 0,
      rankedDiseases: json['rankedDiseases'] != null && json['rankedDiseases'] is List
          ? (json['rankedDiseases'] as List)
              .map((i) => MorbiLB1ItemModel.fromJson(i as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}

class CashierShiftModel {
  const CashierShiftModel({
    required this.id,
    required this.cashierId,
    required this.cashierName,
    required this.shiftName,
    required this.startTime,
    this.endTime,
    required this.initialCash,
    this.totalCashReceived = 0.0,
    this.totalQrisReceived = 0.0,
    this.totalTransferReceived = 0.0,
    this.totalDebitReceived = 0.0,
    this.totalTransactions = 0,
    this.expectedCashEnd = 0.0,
    this.actualCashCounted,
    this.discrepancy,
    required this.status, // 'OPEN', 'CLOSED'
    this.notes = '',
  });

  final String id;
  final String cashierId;
  final String cashierName;
  final String shiftName;
  final DateTime startTime;
  final DateTime? endTime;
  final double initialCash;
  final double totalCashReceived;
  final double totalQrisReceived;
  final double totalTransferReceived;
  final double totalDebitReceived;
  final int totalTransactions;
  final double expectedCashEnd;
  final double? actualCashCounted;
  final double? discrepancy;
  final String status;
  final String notes;

  double get grandTotalSales =>
      totalCashReceived +
      totalQrisReceived +
      totalTransferReceived +
      totalDebitReceived;

  bool get isOpen => status == 'OPEN';

  factory CashierShiftModel.fromJson(Map<String, dynamic> json) {
    return CashierShiftModel(
      id: json['id']?.toString() ?? '',
      cashierId: json['cashierId']?.toString() ?? '',
      cashierName: json['cashierName']?.toString() ?? '',
      shiftName: json['shiftName']?.toString() ?? 'Pagi',
      startTime: json['startTime'] != null
          ? DateTime.tryParse(json['startTime'].toString()) ?? DateTime.now()
          : DateTime.now(),
      endTime: json['endTime'] != null
          ? DateTime.tryParse(json['endTime'].toString())
          : null,
      initialCash: (json['initialCash'] as num?)?.toDouble() ??
          (json['liveSummary']?['initialCash'] as num?)?.toDouble() ??
          0.0,
      totalCashReceived: (json['totalCashReceived'] as num?)?.toDouble() ??
          (json['liveSummary']?['totalCashReceived'] as num?)?.toDouble() ??
          0.0,
      totalQrisReceived: (json['totalQrisReceived'] as num?)?.toDouble() ??
          (json['liveSummary']?['totalQrisReceived'] as num?)?.toDouble() ??
          0.0,
      totalTransferReceived:
          (json['totalTransferReceived'] as num?)?.toDouble() ??
              (json['liveSummary']?['totalTransferReceived'] as num?)
                  ?.toDouble() ??
              0.0,
      totalDebitReceived: (json['totalDebitReceived'] as num?)?.toDouble() ??
          (json['liveSummary']?['totalDebitReceived'] as num?)?.toDouble() ??
          0.0,
      totalTransactions: (json['totalTransactions'] as num?)?.toInt() ??
          (json['liveSummary']?['totalTransactions'] as num?)?.toInt() ??
          0,
      expectedCashEnd: (json['expectedCashEnd'] as num?)?.toDouble() ??
          (json['liveSummary']?['expectedCashEnd'] as num?)?.toDouble() ??
          0.0,
      actualCashCounted: (json['actualCashCounted'] as num?)?.toDouble(),
      discrepancy: (json['discrepancy'] as num?)?.toDouble(),
      status: json['status']?.toString() ?? 'OPEN',
      notes: json['notes']?.toString() ?? '',
    );
  }
}

class RoomBedModel {
  const RoomBedModel({
    required this.id,
    required this.roomNumber,
    required this.roomName,
    required this.bedNumber,
    required this.classType,
    required this.dailyRate,
    required this.status,
    this.notes,
    this.activePatient,
  });

  final String id;
  final String roomNumber;
  final String roomName;
  final String bedNumber;
  final String classType;
  final double dailyRate;
  final String status;
  final String? notes;
  final ActiveInpatientPatient? activePatient;

  factory RoomBedModel.fromJson(Map<String, dynamic> json) {
    return RoomBedModel(
      id: json['id']?.toString() ?? '',
      roomNumber: json['roomNumber']?.toString() ?? '',
      roomName: json['roomName']?.toString() ?? '',
      bedNumber: json['bedNumber']?.toString() ?? '',
      classType: json['classType']?.toString() ?? 'Kelas 1',
      dailyRate: (json['dailyRate'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'available',
      notes: json['notes']?.toString(),
      activePatient: json['activePatient'] != null
          ? ActiveInpatientPatient.fromJson(json['activePatient'])
          : null,
    );
  }

  RoomBedModel copyWith({
    String? id,
    String? roomNumber,
    String? roomName,
    String? bedNumber,
    String? classType,
    double? dailyRate,
    String? status,
    String? notes,
    ActiveInpatientPatient? activePatient,
  }) {
    return RoomBedModel(
      id: id ?? this.id,
      roomNumber: roomNumber ?? this.roomNumber,
      roomName: roomName ?? this.roomName,
      bedNumber: bedNumber ?? this.bedNumber,
      classType: classType ?? this.classType,
      dailyRate: dailyRate ?? this.dailyRate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      activePatient: activePatient ?? this.activePatient,
    );
  }
}

class ActiveInpatientPatient {
  const ActiveInpatientPatient({
    required this.admissionId,
    required this.admissionNumber,
    required this.patientId,
    required this.patientName,
    required this.patientMrn,
    required this.patientGender,
    required this.insurance,
    required this.doctorId,
    required this.doctorName,
    required this.admissionDate,
    required this.daysAdmitted,
    this.initialDiagnosis,
  });

  final String admissionId;
  final String admissionNumber;
  final String patientId;
  final String patientName;
  final String patientMrn;
  final String patientGender;
  final String insurance;
  final String doctorId;
  final String doctorName;
  final DateTime admissionDate;
  final int daysAdmitted;
  final String? initialDiagnosis;

  factory ActiveInpatientPatient.fromJson(Map<String, dynamic> json) {
    return ActiveInpatientPatient(
      admissionId: json['admissionId']?.toString() ?? '',
      admissionNumber: json['admissionNumber']?.toString() ?? '',
      patientId: json['patientId']?.toString() ?? '',
      patientName: json['patientName']?.toString() ?? '',
      patientMrn: json['patientMrn']?.toString() ?? '',
      patientGender: json['patientGender']?.toString() ?? '',
      insurance: json['insurance']?.toString() ?? 'Umum',
      doctorId: json['doctorId']?.toString() ?? '',
      doctorName: json['doctorName']?.toString() ?? '',
      admissionDate: json['admissionDate'] != null
          ? DateTime.tryParse(json['admissionDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      daysAdmitted: (json['daysAdmitted'] as num?)?.toInt() ?? 1,
      initialDiagnosis: json['initialDiagnosis']?.toString(),
    );
  }
}

class InpatientAdmissionModel {
  const InpatientAdmissionModel({
    required this.id,
    required this.admissionNumber,
    required this.patientId,
    required this.patientName,
    required this.patientMrn,
    required this.patientPhone,
    required this.patientGender,
    required this.patientInsurance,
    required this.doctorId,
    required this.doctorName,
    required this.doctorSpecialist,
    required this.bedId,
    required this.roomNumber,
    required this.roomName,
    required this.bedNumber,
    required this.classType,
    required this.dailyRate,
    required this.admissionDate,
    this.dischargeDate,
    required this.admissionType,
    this.initialDiagnosis,
    this.dischargeDiagnosis,
    this.dischargeCondition,
    required this.status,
    required this.totalDays,
    required this.totalBedCost,
    this.notes,
    this.latestCPPT,
  });

  final String id;
  final String admissionNumber;
  final String patientId;
  final String patientName;
  final String patientMrn;
  final String patientPhone;
  final String patientGender;
  final String patientInsurance;
  final String doctorId;
  final String doctorName;
  final String doctorSpecialist;
  final String bedId;
  final String roomNumber;
  final String roomName;
  final String bedNumber;
  final String classType;
  final double dailyRate;
  final DateTime admissionDate;
  final DateTime? dischargeDate;
  final String admissionType;
  final String? initialDiagnosis;
  final String? dischargeDiagnosis;
  final String? dischargeCondition;
  final String status;
  final int totalDays;
  final double totalBedCost;
  final String? notes;
  final InpatientCPPTModel? latestCPPT;

  factory InpatientAdmissionModel.fromJson(Map<String, dynamic> json) {
    return InpatientAdmissionModel(
      id: json['id']?.toString() ?? '',
      admissionNumber: json['admissionNumber']?.toString() ?? '',
      patientId: json['patientId']?.toString() ?? '',
      patientName: json['patientName']?.toString() ?? '',
      patientMrn: json['patientMrn']?.toString() ?? '',
      patientPhone: json['patientPhone']?.toString() ?? '-',
      patientGender: json['patientGender']?.toString() ?? '',
      patientInsurance: json['patientInsurance']?.toString() ?? 'Umum',
      doctorId: json['doctorId']?.toString() ?? '',
      doctorName: json['doctorName']?.toString() ?? '',
      doctorSpecialist: json['doctorSpecialist']?.toString() ?? 'Dokter DPJP',
      bedId: json['bedId']?.toString() ?? '',
      roomNumber: json['roomNumber']?.toString() ?? '',
      roomName: json['roomName']?.toString() ?? '',
      bedNumber: json['bedNumber']?.toString() ?? '',
      classType: json['classType']?.toString() ?? 'Kelas 1',
      dailyRate: (json['dailyRate'] as num?)?.toDouble() ?? 0.0,
      admissionDate: json['admissionDate'] != null
          ? DateTime.tryParse(json['admissionDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      dischargeDate: json['dischargeDate'] != null
          ? DateTime.tryParse(json['dischargeDate'].toString())
          : null,
      admissionType: json['admissionType']?.toString() ?? 'Poliklinik',
      initialDiagnosis: json['initialDiagnosis']?.toString(),
      dischargeDiagnosis: json['dischargeDiagnosis']?.toString(),
      dischargeCondition: json['dischargeCondition']?.toString(),
      status: json['status']?.toString() ?? 'active',
      totalDays: (json['totalDays'] as num?)?.toInt() ?? 1,
      totalBedCost: (json['totalBedCost'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes']?.toString(),
      latestCPPT: json['latestCPPT'] != null
          ? InpatientCPPTModel.fromJson(json['latestCPPT'])
          : null,
    );
  }
}

class InpatientCPPTModel {
  const InpatientCPPTModel({
    required this.id,
    required this.recorderRole,
    required this.recorderName,
    required this.recordedAt,
    this.subjective,
    this.objective,
    this.assessment,
    this.plan,
    this.instruction,
    this.bloodPressure,
    this.heartRate,
    this.temperature,
    this.respiratoryRate,
    this.oxygenSaturation,
  });

  final String id;
  final String recorderRole;
  final String recorderName;
  final DateTime recordedAt;
  final String? subjective;
  final String? objective;
  final String? assessment;
  final String? plan;
  final String? instruction;
  final String? bloodPressure;
  final int? heartRate;
  final double? temperature;
  final int? respiratoryRate;
  final int? oxygenSaturation;

  factory InpatientCPPTModel.fromJson(Map<String, dynamic> json) {
    return InpatientCPPTModel(
      id: json['id']?.toString() ?? '',
      recorderRole: json['recorderRole']?.toString() ?? 'Dokter DPJP',
      recorderName: json['recorderName']?.toString() ?? '',
      recordedAt: json['recordedAt'] != null
          ? DateTime.tryParse(json['recordedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      subjective: json['subjective']?.toString(),
      objective: json['objective']?.toString(),
      assessment: json['assessment']?.toString(),
      plan: json['plan']?.toString(),
      instruction: json['instruction']?.toString(),
      bloodPressure: json['bloodPressure']?.toString(),
      heartRate: (json['heartRate'] as num?)?.toInt(),
      temperature: (json['temperature'] as num?)?.toDouble(),
      respiratoryRate: (json['respiratoryRate'] as num?)?.toInt(),
      oxygenSaturation: (json['oxygenSaturation'] as num?)?.toInt(),
    );
  }
}

class LabTestCatalogModel {
  const LabTestCatalogModel({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.sampleType,
    this.unit,
    this.normalRangeMin,
    this.normalRangeMax,
    this.normalRangeText,
    required this.price,
    this.description,
    required this.status,
  });

  final String id;
  final String code;
  final String name;
  final String category;
  final String sampleType;
  final String? unit;
  final double? normalRangeMin;
  final double? normalRangeMax;
  final String? normalRangeText;
  final double price;
  final String? description;
  final String status;

  factory LabTestCatalogModel.fromJson(Map<String, dynamic> json) {
    return LabTestCatalogModel(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Hematologi',
      sampleType: json['sampleType']?.toString() ?? 'Darah Vena',
      unit: json['unit']?.toString(),
      normalRangeMin: json['normalRangeMin'] != null
          ? double.tryParse(json['normalRangeMin'].toString())
          : null,
      normalRangeMax: json['normalRangeMax'] != null
          ? double.tryParse(json['normalRangeMax'].toString())
          : null,
      normalRangeText: json['normalRangeText']?.toString(),
      price: json['price'] != null
          ? (double.tryParse(json['price'].toString()) ?? 0.0)
          : 0.0,
      description: json['description']?.toString(),
      status: json['status']?.toString() ?? 'active',
    );
  }
}

class LabOrderModel {
  const LabOrderModel({
    required this.id,
    required this.orderNumber,
    required this.patientId,
    required this.patientName,
    required this.patientMrn,
    required this.patientGender,
    required this.patientInsurance,
    required this.doctorId,
    required this.doctorName,
    required this.doctorSpecialist,
    this.appointmentId,
    this.admissionId,
    required this.priority,
    this.clinicalDiagnosis,
    this.clinicalNotes,
    required this.status,
    this.sampleCollectedAt,
    this.sampleCollectorName,
    this.completedAt,
    this.verifiedBy,
    required this.totalCost,
    required this.createdAt,
    required this.items,
  });

  final String id;
  final String orderNumber;
  final String patientId;
  final String patientName;
  final String patientMrn;
  final String patientGender;
  final String patientInsurance;
  final String doctorId;
  final String doctorName;
  final String doctorSpecialist;
  final String? appointmentId;
  final String? admissionId;
  final String priority;
  final String? clinicalDiagnosis;
  final String? clinicalNotes;
  final String status;
  final DateTime? sampleCollectedAt;
  final String? sampleCollectorName;
  final DateTime? completedAt;
  final String? verifiedBy;
  final double totalCost;
  final DateTime createdAt;
  final List<LabOrderItemModel> items;

  factory LabOrderModel.fromJson(Map<String, dynamic> json) {
    return LabOrderModel(
      id: json['id']?.toString() ?? '',
      orderNumber: json['orderNumber']?.toString() ?? '',
      patientId: json['patientId']?.toString() ?? '',
      patientName: json['patientName']?.toString() ?? '-',
      patientMrn: json['patientMrn']?.toString() ?? '-',
      patientGender: json['patientGender']?.toString() ?? '-',
      patientInsurance: json['patientInsurance']?.toString() ?? 'Umum',
      doctorId: json['doctorId']?.toString() ?? '',
      doctorName: json['doctorName']?.toString() ?? '-',
      doctorSpecialist: json['doctorSpecialist']?.toString() ?? 'Dokter Spesialis',
      appointmentId: json['appointmentId']?.toString(),
      admissionId: json['admissionId']?.toString(),
      priority: json['priority']?.toString() ?? 'Normal',
      clinicalDiagnosis: json['clinicalDiagnosis']?.toString(),
      clinicalNotes: json['clinicalNotes']?.toString(),
      status: json['status']?.toString() ?? 'ordered',
      sampleCollectedAt: json['sampleCollectedAt'] != null
          ? DateTime.tryParse(json['sampleCollectedAt'].toString())
          : null,
      sampleCollectorName: json['sampleCollectorName']?.toString(),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'].toString())
          : null,
      verifiedBy: json['verifiedBy']?.toString(),
      totalCost: (json['totalCost'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      items: json['items'] != null && json['items'] is List
          ? (json['items'] as List)
              .map((i) => LabOrderItemModel.fromJson(i))
              .toList()
          : [],
    );
  }
}

class LabOrderItemModel {
  const LabOrderItemModel({
    required this.id,
    this.testCatalogId,
    required this.testCode,
    required this.testName,
    required this.category,
    required this.price,
    this.resultValue,
    this.unit,
    this.normalRangeText,
    this.flag,
    required this.status,
    this.analystNotes,
    this.analyzedAt,
    this.analyzedBy,
  });

  final String id;
  final String? testCatalogId;
  final String testCode;
  final String testName;
  final String category;
  final double price;
  final String? resultValue;
  final String? unit;
  final String? normalRangeText;
  final String? flag;
  final String status;
  final String? analystNotes;
  final DateTime? analyzedAt;
  final String? analyzedBy;

  factory LabOrderItemModel.fromJson(Map<String, dynamic> json) {
    return LabOrderItemModel(
      id: json['id']?.toString() ?? '',
      testCatalogId: json['testCatalogId']?.toString(),
      testCode: json['testCode']?.toString() ?? '',
      testName: json['testName']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Hematologi',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      resultValue: json['resultValue']?.toString(),
      unit: json['unit']?.toString(),
      normalRangeText: json['normalRangeText']?.toString(),
      flag: json['flag']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      analystNotes: json['analystNotes']?.toString(),
      analyzedAt: json['analyzedAt'] != null
          ? DateTime.tryParse(json['analyzedAt'].toString())
          : null,
      analyzedBy: json['analyzedBy']?.toString(),
    );
  }
}





