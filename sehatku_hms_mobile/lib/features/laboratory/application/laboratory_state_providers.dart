import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/api_client_provider.dart';
import '../../../shared/models/health_models.dart';
import '../../admin/application/admin_state_providers.dart';

// ===================== LAB CATALOG NOTIFIER =====================

class LabCatalogNotifier extends Notifier<List<LabTestCatalogModel>> {
  @override
  List<LabTestCatalogModel> build() {
    _fetchFromApi();
    return const [];
  }

  Future<void> _fetchFromApi({String? category, String? query}) async {
    final client = ref.read(apiClientProvider);
    final list = await client.getLabCatalog(category: category, query: query);
    if (list.isNotEmpty) {
      state = list;
    }
  }

  Future<void> refresh({String? category, String? query}) async =>
      _fetchFromApi(category: category, query: query);

  Future<LabTestCatalogModel?> createCatalog(Map<String, dynamic> data) async {
    final client = ref.read(apiClientProvider);
    final created = await client.createLabCatalog(data);
    if (created != null) {
      state = [created, ...state];
    }
    return created;
  }
}

final labCatalogProvider =
    NotifierProvider<LabCatalogNotifier, List<LabTestCatalogModel>>(
  LabCatalogNotifier.new,
);

// ===================== LAB ORDERS NOTIFIER =====================

class LabOrdersNotifier extends Notifier<List<LabOrderModel>> {
  @override
  List<LabOrderModel> build() {
    _fetchFromApi();
    return const [];
  }

  Future<void> _fetchFromApi({
    String? status,
    String? priority,
    String? query,
  }) async {
    final client = ref.read(apiClientProvider);
    final list = await client.getLabOrders(
      status: status,
      priority: priority,
      query: query,
    );
    state = list;
  }

  Future<void> refresh({
    String? status,
    String? priority,
    String? query,
  }) async =>
      _fetchFromApi(status: status, priority: priority, query: query);

  Future<LabOrderModel?> createOrder({
    required String patientId,
    required String doctorId,
    String? appointmentId,
    String? admissionId,
    String? priority,
    String? clinicalDiagnosis,
    String? clinicalNotes,
    required List<Map<String, dynamic>> items,
  }) async {
    final client = ref.read(apiClientProvider);
    final order = await client.createLabOrder(
      patientId: patientId,
      doctorId: doctorId,
      appointmentId: appointmentId,
      admissionId: admissionId,
      priority: priority,
      clinicalDiagnosis: clinicalDiagnosis,
      clinicalNotes: clinicalNotes,
      items: items,
    );

    if (order != null) {
      state = [order, ...state];
      ref.read(adminBillingProvider.notifier).refresh();
      ref.read(adminAuditLogsProvider.notifier).log(
            action: 'LAB_ORDER',
            resourceType: 'LabOrder',
            resourceId: order.id,
            details:
                'Order Lab Baru: ${order.orderNumber} untuk ${order.patientName} (${order.items.length} parameter, Prioritas: ${order.priority})',
          );
    }
    return order;
  }

  Future<LabOrderModel?> collectSample(
    String orderId,
    String collectorName,
  ) async {
    final client = ref.read(apiClientProvider);
    final updated = await client.collectLabSample(orderId, collectorName);
    if (updated != null) {
      await _fetchFromApi();
      ref.read(adminAuditLogsProvider.notifier).log(
            action: 'LAB_SAMPLE_COLLECTED',
            resourceType: 'LabOrder',
            resourceId: orderId,
            details:
                'Sampel Laboratorium Diambil: ${updated.orderNumber} (${updated.patientName}) oleh $collectorName',
          );
    }
    return updated;
  }

  Future<LabOrderModel?> submitResults(
    String orderId,
    List<Map<String, dynamic>> results,
  ) async {
    final client = ref.read(apiClientProvider);
    final updated = await client.submitLabResults(orderId, results);
    if (updated != null) {
      await _fetchFromApi();
    }
    return updated;
  }

  Future<LabOrderModel?> verifyOrder(
    String orderId,
    String verifiedBy,
  ) async {
    final client = ref.read(apiClientProvider);
    final updated = await client.verifyLabOrder(orderId, verifiedBy);
    if (updated != null) {
      await _fetchFromApi();
      ref.read(adminAuditLogsProvider.notifier).log(
            action: 'LAB_VERIFIED',
            resourceType: 'LabOrder',
            resourceId: orderId,
            details:
                'Hasil Lab Diverifikasi Resmi: ${updated.orderNumber} (${updated.patientName}) oleh $verifiedBy',
          );
    }
    return updated;
  }
}

final labOrdersProvider =
    NotifierProvider<LabOrdersNotifier, List<LabOrderModel>>(
  LabOrdersNotifier.new,
);
