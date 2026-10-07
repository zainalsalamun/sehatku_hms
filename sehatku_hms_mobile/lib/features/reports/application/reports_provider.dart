import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/api_client_provider.dart';
import '../../../shared/models/health_models.dart';

class ClinicReportsNotifier extends Notifier<DailyClinicSummary?> {
  @override
  DailyClinicSummary? build() {
    _fetch();
    return _getDefaultSummary();
  }

  DailyClinicSummary _getDefaultSummary() {
    return DailyClinicSummary(
      reportDate: DateTime.now(),
      totalRevenue: 670000,
      pendingRevenue: 700000,
      paidCount: 2,
      pendingCount: 2,
      averageTicket: 335000,
      totalAppointments: 5,
      completedVisits: 2,
      paymentMethods: const [
        PaymentMethodSummary(method: 'QRIS Dinamis', totalAmount: 350000, percentage: 52),
        PaymentMethodSummary(method: 'Transfer Bank Mandiri', totalAmount: 320000, percentage: 48),
      ],
      topMedicines: const [
        TopMedicineSummary(name: 'Amlodipine Besylate', dosage: '5 mg', prescribedCount: 8),
        TopMedicineSummary(name: 'Paracetamol', dosage: '500 mg', prescribedCount: 6),
        TopMedicineSummary(name: 'Candesartan', dosage: '8 mg', prescribedCount: 5),
        TopMedicineSummary(name: 'Omeprazole', dosage: '20 mg', prescribedCount: 3),
        TopMedicineSummary(name: 'Cetirizine HCl', dosage: '10 mg', prescribedCount: 2),
      ],
    );
  }

  Future<void> _fetch() async {
    final client = ref.read(apiClientProvider);
    final report = await client.getDailyAnalytics();
    if (report != null) {
      state = report;
    }
  }

  Future<void> refresh() async => _fetch();
}

final clinicReportsProvider =
    NotifierProvider<ClinicReportsNotifier, DailyClinicSummary?>(
  ClinicReportsNotifier.new,
);
