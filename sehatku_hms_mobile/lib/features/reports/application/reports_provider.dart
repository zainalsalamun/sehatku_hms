import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/api_client_provider.dart';
import '../../../shared/models/health_models.dart';

class ClinicReportsNotifier extends Notifier<DailyClinicSummary?> {
  @override
  DailyClinicSummary? build() {
    _fetch();
    return null;
  }

  DailyClinicSummary _getEmptySummary() {
    return DailyClinicSummary(
      reportDate: DateTime.now(),
      totalRevenue: 0,
      pendingRevenue: 0,
      paidCount: 0,
      pendingCount: 0,
      averageTicket: 0,
      totalAppointments: 0,
      completedVisits: 0,
      paymentMethods: const [],
      topMedicines: const [],
    );
  }

  Future<void> _fetch() async {
    final client = ref.read(apiClientProvider);
    final report = await client.getDailyAnalytics();
    if (report != null) {
      state = report;
    } else {
      state = _getEmptySummary();
    }
  }

  Future<void> refresh() async => _fetch();
}

final clinicReportsProvider =
    NotifierProvider<ClinicReportsNotifier, DailyClinicSummary?>(
  ClinicReportsNotifier.new,
);
