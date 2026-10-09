import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/health_models.dart';
import '../../application/pharmacy_state_providers.dart';

class MedicineFormDialog extends ConsumerStatefulWidget {
  const MedicineFormDialog({super.key});

  @override
  ConsumerState<MedicineFormDialog> createState() => _MedicineFormDialogState();
}

class _MedicineFormDialogState extends ConsumerState<MedicineFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _batchCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _minStockCtrl;
  late final TextEditingController _priceCtrl;

  String? _category;
  String? _form;
  String? _unit;
  DateTime _expirationDate = DateTime.now().add(const Duration(days: 730));

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _batchCtrl = TextEditingController(
      text: 'BATCH-${(100 + (DateTime.now().millisecondsSinceEpoch % 900))}-2026',
    );
    _stockCtrl = TextEditingController(text: '100');
    _minStockCtrl = TextEditingController(text: '30');
    _priceCtrl = TextEditingController(text: '25000');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _batchCtrl.dispose();
    _stockCtrl.dispose();
    _minStockCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickExpirationDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expirationDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _expirationDate = picked);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final stock = int.tryParse(_stockCtrl.text.trim()) ?? 0;
    final minStock = int.tryParse(_minStockCtrl.text.trim()) ?? 30;
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0.0;
    final expStr = DateFormat('yyyy-MM-dd').format(_expirationDate);

    String status = 'normal';
    if (stock <= (minStock / 2)) {
      status = 'critical';
    } else if (stock <= minStock) {
      status = 'low';
    }

    final pharmacyConfig = ref.read(pharmacyConfigProvider);
    final categories = pharmacyConfig.categories.isNotEmpty
        ? pharmacyConfig.categories
        : ['Analgesik & Antipiretik'];
    final forms = pharmacyConfig.forms.isNotEmpty
        ? pharmacyConfig.forms
        : ['Tablet'];
    final units = pharmacyConfig.units.isNotEmpty
        ? pharmacyConfig.units
        : ['strip (10 tab)'];

    final effectiveCategory = (_category != null && categories.contains(_category))
        ? _category!
        : categories.first;
    final effectiveForm = (_form != null && forms.contains(_form))
        ? _form!
        : forms.first;
    final effectiveUnit = (_unit != null && units.contains(_unit))
        ? _unit!
        : units.first;

    final newMedicine = MedicineStock(
      id: 'med-${DateTime.now().millisecondsSinceEpoch}',
      name: _nameCtrl.text.trim(),
      category: effectiveCategory,
      form: effectiveForm,
      stock: stock,
      minStock: minStock,
      unit: effectiveUnit,
      batchNumber: _batchCtrl.text.trim(),
      expirationDate: expStr,
      status: status,
      price: price,
    );

    ref.read(pharmacyInventoryProvider.notifier).addMedicine(newMedicine);

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Obat ${newMedicine.name} (${newMedicine.stock} ${newMedicine.unit}) berhasil didaftarkan ke apotek.',
        ),
        backgroundColor: Colors.green.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pharmacyConfig = ref.watch(pharmacyConfigProvider);
    final categories = pharmacyConfig.categories.isNotEmpty
        ? pharmacyConfig.categories
        : ['Analgesik & Antipiretik'];
    final forms = pharmacyConfig.forms.isNotEmpty
        ? pharmacyConfig.forms
        : ['Tablet'];
    final units = pharmacyConfig.units.isNotEmpty
        ? pharmacyConfig.units
        : ['strip (10 tab)'];

    final effectiveCategory = (_category != null && categories.contains(_category))
        ? _category!
        : categories.first;
    final effectiveForm = (_form != null && forms.contains(_form))
        ? _form!
        : forms.first;
    final effectiveUnit = (_unit != null && units.contains(_unit))
        ? _unit!
        : units.first;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.teal.shade50,
                      child: const Icon(
                        Icons.medication_outlined,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tambah Obat Baru ke Apotek',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            'Registrasi nama obat, sediaan, stok awal, dan harga jual',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(height: 28),

                // Nama Obat
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Obat & Dosis *',
                    hintText: 'Contoh: Paracetamol 500mg / Amoxicillin Sirup 125mg/5ml',
                    prefixIcon: Icon(Icons.vaccines_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Nama obat wajib diisi' : null,
                ),
                const SizedBox(height: 16),

                // Kategori & Bentuk Sediaan Row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: effectiveCategory,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Kategori Obat *',
                          prefixIcon: Icon(Icons.category_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: categories
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(c, overflow: TextOverflow.ellipsis),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _category = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: effectiveForm,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Bentuk Sediaan *',
                          prefixIcon: Icon(Icons.healing_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: forms
                            .map(
                              (f) => DropdownMenuItem(
                                value: f,
                                child: Text(f, overflow: TextOverflow.ellipsis),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _form = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Satuan Kemasan & No Batch Row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: effectiveUnit,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Satuan Kemasan *',
                          prefixIcon: Icon(Icons.inventory_2_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: units
                            .map(
                              (u) => DropdownMenuItem(
                                value: u,
                                child: Text(u, overflow: TextOverflow.ellipsis),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _unit = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _batchCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nomor Batch *',
                          prefixIcon: Icon(Icons.tag_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'No. Batch wajib diisi'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Tanggal Kadaluarsa (ED) & Harga
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _pickExpirationDate,
                        borderRadius: BorderRadius.circular(4),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Tanggal Kadaluarsa (ED) *',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            DateFormat('dd MMM yyyy').format(_expirationDate),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Harga Jual Satuan (IDR) *',
                          prefixText: 'Rp ',
                          prefixIcon: Icon(Icons.payments_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Harga wajib diisi'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Stok Awal & Min Stok Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _stockCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Stok Awal Fisik *',
                          prefixIcon: Icon(Icons.add_box_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Stok awal wajib diisi'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _minStockCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Batas Minimum Stok *',
                          helperText: 'Alert jika stok di bawah angka ini',
                          prefixIcon: Icon(Icons.warning_amber_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Batas minimum wajib diisi'
                            : null,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      icon: const Icon(Icons.save_outlined, size: 18),
                      label: const Text('Daftarkan Obat'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
