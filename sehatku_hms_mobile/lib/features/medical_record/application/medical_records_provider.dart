import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/api_client_provider.dart';
import '../../../shared/models/health_models.dart';

class MedicalRecordsNotifier extends Notifier<List<MedicalRecord>> {
  @override
  List<MedicalRecord> build() {
    _fetchFromDatabase();
    return const [];
  }

  Future<void> _fetchFromDatabase() async {
    final client = ref.read(apiClientProvider);
    final records = await client.getMedicalRecords();
    state = records;
  }

  Future<void> refresh() async {
    await _fetchFromDatabase();
  }

  void addRecord(MedicalRecord record) {
    state = [record, ...state];
  }
}

final medicalRecordsProvider =
    NotifierProvider<MedicalRecordsNotifier, List<MedicalRecord>>(
  MedicalRecordsNotifier.new,
);
