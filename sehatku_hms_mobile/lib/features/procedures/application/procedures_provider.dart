import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/api_client_provider.dart';
import '../../../shared/models/health_models.dart';

class ProceduresNotifier extends Notifier<List<ClinicProcedure>> {
  @override
  List<ClinicProcedure> build() {
    _fetchFromDatabase();
    return const [];
  }

  Future<void> _fetchFromDatabase() async {
    final client = ref.read(apiClientProvider);
    final list = await client.getProcedures();
    state = list;
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
