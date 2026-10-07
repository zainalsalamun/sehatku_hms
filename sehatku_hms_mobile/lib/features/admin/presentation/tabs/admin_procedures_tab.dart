import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/uuid_helper.dart';
import '../../../../shared/models/health_models.dart';
import '../../../procedures/application/procedures_provider.dart';

class AdminProceduresTab extends ConsumerStatefulWidget {
  const AdminProceduresTab({super.key});

  @override
  ConsumerState<AdminProceduresTab> createState() => _AdminProceduresTabState();
}

class _AdminProceduresTabState extends ConsumerState<AdminProceduresTab> {
  String _selectedCategory = 'Semua';
  final _searchController = TextEditingController();

  final List<String> _categories = [
    'Semua',
    'Umum',
    'Gigi',
    'Tindakan Medis',
    'Laboratorium Rapid',
    'Keperawatan',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditProcedureDialog([ClinicProcedure? existing]) {
    final isEdit = existing != null;
    final codeCtrl = TextEditingController(
      text: existing?.code ?? 'PROC-${DateTime.now().millisecond}',
    );
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final priceCtrl = TextEditingController(
      text: existing != null ? existing.price.toInt().toString() : '',
    );
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    String category = existing?.category ?? 'Umum';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    isEdit ? Icons.edit_outlined : Icons.add_circle_outline,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isEdit
                        ? 'Edit Tarif Tindakan Medis'
                        : 'Tambah Master Tindakan Medis',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 460,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: codeCtrl,
                        enabled: !isEdit,
                        decoration: const InputDecoration(
                          labelText: 'Kode Tindakan',
                          hintText: 'Contoh: PROC-011',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nama Tindakan Medis',
                          hintText: 'Contoh: Injeksi Neurobion 5000',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: category,
                        decoration: const InputDecoration(
                          labelText: 'Kategori Layanan',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            [
                                  'Umum',
                                  'Gigi',
                                  'Tindakan Medis',
                                  'Laboratorium Rapid',
                                  'Keperawatan',
                                ]
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) {
                          if (v != null) setModalState(() => category = v);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Tarif Layanan (Rp)',
                          hintText: 'Contoh: 65000',
                          prefixText: 'Rp ',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi / Keterangan',
                          hintText: 'Penjelasan singkat tindakan klinis...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final price = double.tryParse(priceCtrl.text.trim()) ?? 0;
                    if (name.isEmpty || price <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Nama tindakan dan tarif harus diisi dengan benar.',
                          ),
                        ),
                      );
                      return;
                    }

                    if (isEdit) {
                      final updated = existing.copyWith(
                        name: name,
                        category: category,
                        description: descCtrl.text.trim(),
                        price: price,
                      );
                      ref
                          .read(clinicProceduresProvider.notifier)
                          .updateProcedure(updated);
                    } else {
                      final newProc = ClinicProcedure(
                        id: UuidHelper.generate(),
                        code: codeCtrl.text.trim(),
                        name: name,
                        category: category,
                        description: descCtrl.text.trim(),
                        price: price,
                      );
                      ref
                          .read(clinicProceduresProvider.notifier)
                          .addProcedure(newProc);
                    }

                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEdit
                              ? 'Tarif tindakan berhasil diperbarui!'
                              : 'Tindakan medis baru berhasil ditambahkan!',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: Text(isEdit ? 'Simpan Perubahan' : 'Tambahkan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final procedures = ref.watch(clinicProceduresProvider);
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final filtered = procedures.where((p) {
      final matchCat =
          _selectedCategory == 'Semua' || p.category == _selectedCategory;
      final q = _searchController.text.trim().toLowerCase();
      final matchSearch =
          q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.code.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q);
      return matchCat && matchSearch;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Katalog Tindakan Medis & Tarif Klinik',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kelola master tarif layanan dokter, perawat, dan pemeriksaan laboratorium rapid.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: () => _showAddEditProcedureDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tambah Tindakan Medis'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Filters & Search
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari tindakan medis atau kode...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (_) =>
                              setState(() => _selectedCategory = cat),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Procedures Table / List
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'Tidak ada tindakan medis yang sesuai filter.',
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final proc = filtered[idx];
                        final isActive = proc.status == 'active';

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.navy.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              proc.code,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppTheme.navy,
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                proc.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  decoration: isActive
                                      ? null
                                      : TextDecoration.lineThrough,
                                  color: isActive
                                      ? Colors.black87
                                      : Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blueGrey.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  proc.category,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.blueGrey.shade800,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            proc.description.isNotEmpty
                                ? proc.description
                                : 'Tindakan klinis standar',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                currency.format(proc.price),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  color: Colors.teal,
                                ),
                              ),
                              const SizedBox(width: 14),
                              IconButton(
                                tooltip: 'Edit Tarif & Detail',
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: Colors.blue,
                                ),
                                onPressed: () =>
                                    _showAddEditProcedureDialog(proc),
                              ),
                              Switch(
                                value: isActive,
                                activeThumbColor: Colors.green,
                                onChanged: (_) {
                                  ref
                                      .read(clinicProceduresProvider.notifier)
                                      .toggleStatus(proc.id);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
