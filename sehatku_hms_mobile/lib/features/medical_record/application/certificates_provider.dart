import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/api_client_provider.dart';
import '../../../shared/models/health_models.dart';

class CertificatesNotifier extends Notifier<List<MedicalCertificate>> {
  @override
  List<MedicalCertificate> build() {
    _fetch();
    return [
      MedicalCertificate(
        id: '68000000-0000-4000-8000-000000000001',
        certificateNumber: 'SKD/2026/08/001',
        type: 'sick_leave',
        patientName: 'Nadia Putri',
        patientMrn: 'MRN-2026-001',
        doctorName: 'dr. Maya Pratama, Sp.JP',
        doctorSpecialist: 'Kardiologi & Vaskular',
        diagnosis: 'Hipertensi Primer & Kelelahan Fisik Akut',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 2)),
        durationDays: 2,
        notes: 'Pasien memerlukan istirahat tirah baring selama 2 hari.',
        status: 'issued',
      ),
    ];
  }

  Future<void> _fetch() async {
    final client = ref.read(apiClientProvider);
    final list = await client.getMedicalCertificates();
    if (list.isNotEmpty) {
      state = list;
    }
  }

  Future<void> refresh() async => _fetch();

  void addCertificate(MedicalCertificate cert) {
    state = [cert, ...state];
  }
}

final medicalCertificatesProvider =
    NotifierProvider<CertificatesNotifier, List<MedicalCertificate>>(
  CertificatesNotifier.new,
);
