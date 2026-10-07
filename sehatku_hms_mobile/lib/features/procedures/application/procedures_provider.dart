import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/api_client_provider.dart';
import '../../../shared/models/health_models.dart';

class ProceduresNotifier extends Notifier<List<ClinicProcedure>> {
  @override
  List<ClinicProcedure> build() {
    _fetchFromDatabase();
    return _getDefaultProcedures();
  }

  List<ClinicProcedure> _getDefaultProcedures() {
    return const [
      ClinicProcedure(
        id: '25000000-0000-4000-8000-000000000001',
        code: 'PROC-001',
        name: 'Konsultasi Dokter & Pemeriksaan Fisik',
        category: 'Umum',
        description: 'Pemeriksaan tanda vital, konsultasi keluhan, dan diagnosa dokter.',
        price: 50000,
      ),
      ClinicProcedure(
        id: '25000000-0000-4000-8000-000000000002',
        code: 'PROC-002',
        name: 'Scaling Gigi (Pembersihan Karang)',
        category: 'Gigi',
        description: 'Pembersihan plak dan kalkulus supragingival.',
        price: 150000,
      ),
      ClinicProcedure(
        id: '25000000-0000-4000-8000-000000000003',
        code: 'PROC-003',
        name: 'Injeksi Obat / Vitamin Booster',
        category: 'Tindakan Medis',
        description: 'Pemberian injeksi multivitamin atau pereda nyeri.',
        price: 45000,
      ),
      ClinicProcedure(
        id: '25000000-0000-4000-8000-000000000004',
        code: 'PROC-004',
        name: 'Nebulizer Inhalasi Saluran Nafas',
        category: 'Tindakan Medis',
        description: 'Terapi uap bronkodilator untuk asma / batuk sesak.',
        price: 75000,
      ),
      ClinicProcedure(
        id: '25000000-0000-4000-8000-000000000005',
        code: 'PROC-005',
        name: 'Rawat Luka & Ganti Verban',
        category: 'Keperawatan',
        description: 'Pembersihan luka dan balutan kasa steril.',
        price: 35000,
      ),
      ClinicProcedure(
        id: '25000000-0000-4000-8000-000000000006',
        code: 'PROC-006',
        name: 'Penjahitan Luka (Hecting)',
        category: 'Tindakan Medis',
        description: 'Anestesi lokal & penjahitan 1-3 jahitan.',
        price: 120000,
      ),
      ClinicProcedure(
        id: '25000000-0000-4000-8000-000000000007',
        code: 'PROC-007',
        name: 'Cek Gula Darah Sewaktu (Strip)',
        category: 'Laboratorium Rapid',
        description: 'Tes glukosa darah kapiler cepat.',
        price: 25000,
      ),
      ClinicProcedure(
        id: '25000000-0000-4000-8000-000000000008',
        code: 'PROC-008',
        name: 'Cek Asam Urat (Strip)',
        category: 'Laboratorium Rapid',
        description: 'Tes asam urat kapiler cepat.',
        price: 25000,
      ),
      ClinicProcedure(
        id: '25000000-0000-4000-8000-000000000009',
        code: 'PROC-009',
        name: 'Cek Kolesterol Total (Strip)',
        category: 'Laboratorium Rapid',
        description: 'Skrining kolesterol darah kapiler.',
        price: 35000,
      ),
      ClinicProcedure(
        id: '25000000-0000-4000-8000-000000000010',
        code: 'PROC-010',
        name: 'Pemeriksaan Rekam Jantung (EKG)',
        category: 'Tindakan Medis',
        description: 'Rekam EKG 12-lead lengkap dengan interpretasi.',
        price: 100000,
      ),
    ];
  }

  Future<void> _fetchFromDatabase() async {
    final client = ref.read(apiClientProvider);
    final list = await client.getProcedures();
    if (list.isNotEmpty) {
      state = list;
    }
  }

  Future<void> refresh() async => _fetchFromDatabase();

  void addProcedure(ClinicProcedure proc) {
    state = [...state, proc];
    ref.read(apiClientProvider).createProcedure({
      'code': proc.code,
      'name': proc.name,
      'category': proc.category,
      'description': proc.description,
      'price': proc.price,
      'status': proc.status,
    });
  }

  void updateProcedure(ClinicProcedure updated) {
    state = [
      for (final p in state) if (p.id == updated.id) updated else p,
    ];
    ref.read(apiClientProvider).updateProcedure(updated.id, {
      'name': updated.name,
      'category': updated.category,
      'description': updated.description,
      'price': updated.price,
      'status': updated.status,
    });
  }

  void toggleStatus(String id) {
    state = [
      for (final p in state)
        if (p.id == id)
          p.copyWith(status: p.status == 'active' ? 'inactive' : 'active')
        else
          p,
    ];
    final target = state.firstWhere((p) => p.id == id);
    ref.read(apiClientProvider).updateProcedure(id, {'status': target.status});
  }
}

final clinicProceduresProvider =
    NotifierProvider<ProceduresNotifier, List<ClinicProcedure>>(
  ProceduresNotifier.new,
);
