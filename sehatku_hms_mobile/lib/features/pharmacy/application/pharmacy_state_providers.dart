import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/api_client_provider.dart';
import '../../../shared/models/health_models.dart';
import '../../admin/application/admin_state_providers.dart';

// --- PHARMACY PRESCRIPTIONS PROVIDER ---

class PharmacyPrescriptionsNotifier
    extends Notifier<List<PharmacyPrescription>> {
  @override
  List<PharmacyPrescription> build() {
    _fetchFromDatabase();
    return const [];
  }

  Future<void> _fetchFromDatabase() async {
    final client = ref.read(apiClientProvider);
    final list = await client.getPharmacyPrescriptions();
    if (list.isNotEmpty) {
      state = list;
    }
  }

  Future<void> refresh() async => _fetchFromDatabase();

  void updateStatus(String id, String newStatus) {
    String newLabel = 'Menunggu Diracik';
    if (newStatus == 'dispensing') newLabel = 'Sedang Diracik';
    if (newStatus == 'ready') newLabel = 'Siap Diambil di Loket';
    if (newStatus == 'completed') newLabel = 'Selesai Diserahkan';

    state = [
      for (final p in state)
        if (p.id == id)
          p.copyWith(status: newStatus, statusLabel: newLabel)
        else
          p,
    ];

    ref.read(apiClientProvider).updatePrescriptionStatus(id, newStatus);

    // If completed, refresh inventory to reflect deducted stock
    if (newStatus == 'completed') {
      ref.read(pharmacyInventoryProvider.notifier).refresh();
    }

    final p = state.firstWhere((item) => item.id == id);
    ref.read(adminAuditLogsProvider.notifier).log(
          actorName: 'Apoteker Farmasi',
          actorRole: 'pharmacist',
          action: 'UPDATE',
          resourceType: 'Prescription',
          resourceId: id,
          details: 'Memperbarui status resep ${p.prescriptionNumber} (${p.patientName}) menjadi $newLabel',
        );
  }
}

final pharmacyPrescriptionsProvider = NotifierProvider<
    PharmacyPrescriptionsNotifier, List<PharmacyPrescription>>(
  PharmacyPrescriptionsNotifier.new,
);

// --- PHARMACY INVENTORY PROVIDER ---

class PharmacyInventoryNotifier extends Notifier<List<MedicineStock>> {
  @override
  List<MedicineStock> build() {
    _fetchFromDatabase();
    return const [];
  }

  Future<void> _fetchFromDatabase() async {
    final client = ref.read(apiClientProvider);
    final list = await client.getPharmacyInventory();
    if (list.isNotEmpty) {
      state = list;
    }
  }

  Future<void> refresh() async => _fetchFromDatabase();

  Future<void> addMedicine(MedicineStock item) async {
    state = [item, ...state];
    final created = await ref.read(apiClientProvider).createMedicine(item);
    if (created != null) {
      state = [
        for (final m in state)
          if (m.id == item.id) created else m,
      ];
    }
    ref.read(adminAuditLogsProvider.notifier).log(
          actorName: 'Petugas Gudang Farmasi',
          actorRole: 'pharmacist',
          action: 'CREATE',
          resourceType: 'Inventory',
          resourceId: created?.id ?? item.id,
          details: 'Mendaftarkan item obat baru: ${item.name} (${item.category})',
        );
  }

  void restock(String id, int quantity) {
    state = [
      for (final m in state)
        if (m.id == id)
          m.copyWith(
            stock: m.stock + quantity,
            status: (m.stock + quantity) > m.minStock ? 'normal' : 'low',
          )
        else
          m,
    ];

    ref.read(apiClientProvider).updateMedicineStock(id, quantity);

    final m = state.firstWhere((item) => item.id == id);
    ref.read(adminAuditLogsProvider.notifier).log(
          actorName: 'Petugas Gudang Farmasi',
          actorRole: 'pharmacist',
          action: 'RESTOCK',
          resourceType: 'Inventory',
          resourceId: id,
          details: 'Restock obat ${m.name} sebanyak +$quantity ${m.unit}. Sisa stok: ${m.stock}',
        );
  }
}

final pharmacyInventoryProvider =
    NotifierProvider<PharmacyInventoryNotifier, List<MedicineStock>>(
  PharmacyInventoryNotifier.new,
);

// --- PHARMACY MASTER CONFIG PROVIDER ---

class PharmacyConfigNotifier extends Notifier<PharmacyMasterConfig> {
  @override
  PharmacyMasterConfig build() {
    _fetchFromApi();
    return const PharmacyMasterConfig(
      categories: [
        'Analgesik & Antipiretik',
        'Antibiotik',
        'Antihipertensi',
        'Antasida & Saluran Cerna',
        'Antihistamin / Alergi',
        'Suplemen & Vitamin',
        'Obat Luar / Topikal',
        'Obat Batuk & Flu',
        'Kardiologi & Jantung',
        'Lainnya',
      ],
      forms: [
        'Tablet',
        'Kaplet',
        'Kapsul',
        'Sirup / Suspensi',
        'Salep / Krim / Gel',
        'Tetes Mata / Telinga',
        'Injeksi / Ampul',
        'Larutan Infus',
      ],
      units: [
        'strip (10 tab)',
        'strip (10 kap)',
        'botol (60 ml)',
        'botol (100 ml)',
        'tube (10 gr)',
        'tube (15 gr)',
        'ampul',
        'vial',
        'sachet',
        'box',
      ],
    );
  }

  Future<void> _fetchFromApi() async {
    final client = ref.read(apiClientProvider);
    final config = await client.getPharmacyConfig();
    if (config != null) {
      state = config;
    }
  }

  Future<void> refresh() async => _fetchFromApi();

  Future<void> updateConfig({
    List<String>? categories,
    List<String>? forms,
    List<String>? units,
  }) async {
    final client = ref.read(apiClientProvider);
    final updated = await client.updatePharmacyConfig(
      categories: categories,
      forms: forms,
      units: units,
    );
    if (updated != null) {
      state = updated;
    }
  }
}

final pharmacyConfigProvider =
    NotifierProvider<PharmacyConfigNotifier, PharmacyMasterConfig>(
  PharmacyConfigNotifier.new,
);
