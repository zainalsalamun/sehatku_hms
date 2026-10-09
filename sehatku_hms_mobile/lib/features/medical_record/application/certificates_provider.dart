import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/api_client_provider.dart';
import '../../../shared/models/health_models.dart';

class CertificatesNotifier extends Notifier<List<MedicalCertificate>> {
  @override
  List<MedicalCertificate> build() {
    _fetch();
    return const [];
  }

  Future<void> _fetch() async {
    final client = ref.read(apiClientProvider);
    final list = await client.getMedicalCertificates();
    state = list;
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
