import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/api_client_provider.dart';
import '../../../../shared/models/health_models.dart';

class InpatientCPPTDialog extends ConsumerStatefulWidget {
  const InpatientCPPTDialog({super.key, required this.admissionId});

  final String admissionId;

  @override
  ConsumerState<InpatientCPPTDialog> createState() =>
      _InpatientCPPTDialogState();
}

class _InpatientCPPTDialogState extends ConsumerState<InpatientCPPTDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isAdding = false;
  bool _isLoading = false;

  InpatientAdmissionModel? _admissionDetail;
  List<InpatientCPPTModel> _cpptList = [];

  // Form Fields
  String _recorderRole = 'Dokter DPJP';
  final _recorderNameCtrl = TextEditingController(
    text: 'dr. Maya Pratama, Sp.JP',
  );
  final _subjectiveCtrl = TextEditingController();
  final _objectiveCtrl = TextEditingController();
  final _assessmentCtrl = TextEditingController();
  final _planCtrl = TextEditingController();
  final _instructionCtrl = TextEditingController();

  final _tdCtrl = TextEditingController(text: '120/80');
  final _hrCtrl = TextEditingController(text: '80');
  final _tempCtrl = TextEditingController(text: '36.6');
  final _rrCtrl = TextEditingController(text: '18');
  final _spo2Ctrl = TextEditingController(text: '99');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final client = ref.read(apiClientProvider);
    final detail = await client.getInpatientAdmissionDetail(widget.admissionId);
    final list = await client.getInpatientCPPT(widget.admissionId);

    if (mounted) {
      setState(() {
        _admissionDetail = detail;
        _cpptList = list;
        _isLoading = false;
        if (detail != null) {
          _recorderNameCtrl.text = detail.doctorName;
        }
      });
    }
  }

  @override
  void dispose() {
    _recorderNameCtrl.dispose();
    _subjectiveCtrl.dispose();
    _objectiveCtrl.dispose();
    _assessmentCtrl.dispose();
    _planCtrl.dispose();
    _instructionCtrl.dispose();
    _tdCtrl.dispose();
    _hrCtrl.dispose();
    _tempCtrl.dispose();
    _rrCtrl.dispose();
    _spo2Ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 820,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.history_edu_outlined,
                    color: Colors.teal,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Catatan Perkembangan Pasien Terintegrasi (CPPT Ranap)',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (_admissionDetail != null)
                        Text(
                          '${_admissionDetail!.patientName} (${_admissionDetail!.patientMrn}) • ${_admissionDetail!.roomName} (${_admissionDetail!.bedNumber}) • DPJP: ${_admissionDetail!.doctorName}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                if (!_isAdding)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                    ),
                    onPressed: () => setState(() => _isAdding = true),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Tambah Catatan CPPT'),
                  ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 24),

            // Content Area
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _isAdding
                  ? _buildNewCPPTForm()
                  : _buildCPPTTimeline(dateFormat),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCPPTTimeline(DateFormat dateFormat) {
    if (_cpptList.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notes, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'Belum ada catatan CPPT.',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => setState(() => _isAdding = true),
              icon: const Icon(Icons.add),
              label: const Text('Tulis Catatan Visite / Asuhan Pertama'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _cpptList.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, idx) {
        final c = _cpptList[idx];
        final isDoctor = c.recorderRole.contains('Dokter');

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDoctor
                          ? Colors.blue.shade50
                          : Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isDoctor
                            ? Colors.blue.shade200
                            : Colors.teal.shade200,
                      ),
                    ),
                    child: Text(
                      c.recorderRole.toUpperCase(),
                      style: TextStyle(
                        color: isDoctor
                            ? Colors.blue.shade900
                            : Colors.teal.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    c.recorderName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    dateFormat.format(c.recordedAt),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // TTV Chips if available
              if (c.bloodPressure != null ||
                  c.temperature != null ||
                  c.heartRate != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Wrap(
                    spacing: 12,
                    children: [
                      if (c.bloodPressure != null)
                        Text(
                          'TD: ${c.bloodPressure} mmHg',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (c.heartRate != null)
                        Text(
                          'HR: ${c.heartRate} x/m',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (c.temperature != null)
                        Text(
                          'T: ${c.temperature} °C',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (c.respiratoryRate != null)
                        Text(
                          'RR: ${c.respiratoryRate} x/m',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (c.oxygenSaturation != null)
                        Text(
                          'SpO2: ${c.oxygenSaturation}%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),

              // SOAP Details
              if (c.subjective != null && c.subjective!.isNotEmpty)
                _buildSoapRow(
                  'S (Subjective)',
                  c.subjective!,
                  Colors.blue.shade800,
                ),
              if (c.objective != null && c.objective!.isNotEmpty)
                _buildSoapRow(
                  'O (Objective)',
                  c.objective!,
                  Colors.teal.shade800,
                ),
              if (c.assessment != null && c.assessment!.isNotEmpty)
                _buildSoapRow(
                  'A (Assessment)',
                  c.assessment!,
                  Colors.orange.shade900,
                ),
              if (c.plan != null && c.plan!.isNotEmpty)
                _buildSoapRow(
                  'P (Plan / Terapi)',
                  c.plan!,
                  Colors.purple.shade800,
                ),
              if (c.instruction != null && c.instruction!.isNotEmpty)
                _buildSoapRow(
                  'Instruksi PPA',
                  c.instruction!,
                  Colors.red.shade800,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSoapRow(String label, String content, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(color: Colors.grey, fontSize: 11)),
          Expanded(child: Text(content, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildNewCPPTForm() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _recorderRole,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Profesi PPA *',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Dokter DPJP',
                        child: Text(
                          'Dokter DPJP (Visite Utama)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Dokter Jaga',
                        child: Text(
                          'Dokter Jaga Ruangan / Bangsal',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Perawat Ranap',
                        child: Text(
                          'Perawat Rawat Inap',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Bidan',
                        child: Text('Bidan', overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: 'Ahli Gizi',
                        child: Text(
                          'Ahli Gizi (Diet & Nutrisi)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Farmasi Klinis',
                        child: Text(
                          'Farmasi Klinis (Rekonsiliasi Obat)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    onChanged: (v) =>
                        setState(() => _recorderRole = v ?? 'Dokter DPJP'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _recorderNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nama Tenaga Medis (PPA) *',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Nama wajib diisi' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // TTV Grid
            const Text(
              'TANDA VITAL PASIEN (TTV)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _tdCtrl,
                    decoration: const InputDecoration(
                      labelText: 'TD (mmHg)',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _hrCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'HR (x/m)',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _tempCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Suhu (°C)',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _rrCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'RR (x/m)',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _spo2Ctrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'SpO2 (%)',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // SOAP Fields
            TextFormField(
              controller: _subjectiveCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'S (Subjective) - Keluhan & Anamnesis Pasien',
                border: OutlineInputBorder(),
                hintText:
                    'Contoh: Pasien merasa demam sudah turun, nyeri ulu hati berkurang, makan habis 1/2 porsi.',
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _objectiveCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText:
                    'O (Objective) - Pemeriksaan Fisik & Hasil Penunjang',
                border: OutlineInputBorder(),
                hintText:
                    'Contoh: KU: Sedang, CM. Abdomen supel, NT (-). Trombosit hari ini 115.000.',
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _assessmentCtrl,
              decoration: const InputDecoration(
                labelText:
                    'A (Assessment) - Evaluasi Diagnosa & Progres Klinis',
                border: OutlineInputBorder(),
                hintText: 'Contoh: DHF Grade II fase pemulihan.',
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _planCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText:
                    'P (Plan) - Rencana Terapi, Medikasi Injeksi & Cairan Infus',
                border: OutlineInputBorder(),
                hintText:
                    'Contoh: IVFD Asering 1500cc/24 jam, Paracetamol PO 500mg prn, Ondansetron 4mg IV k/p mual.',
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _instructionCtrl,
              decoration: const InputDecoration(
                labelText: 'Instruksi Khusus Tenaga Medis / Observasi Lanjutan',
                border: OutlineInputBorder(),
                hintText:
                    'Contoh: Pantau balance cairan tiap 8 jam, cek DL ulang besok pagi.',
              ),
            ),
            const SizedBox(height: 18),

            // Submit Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => setState(() => _isAdding = false),
                  child: const Text('Batal'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                  ),
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    setState(() => _isLoading = true);

                    final client = ref.read(apiClientProvider);
                    await client.createInpatientCPPT(
                      widget.admissionId,
                      recorderRole: _recorderRole,
                      recorderName: _recorderNameCtrl.text.trim(),
                      subjective: _subjectiveCtrl.text.trim(),
                      objective: _objectiveCtrl.text.trim(),
                      assessment: _assessmentCtrl.text.trim(),
                      plan: _planCtrl.text.trim(),
                      instruction: _instructionCtrl.text.trim(),
                      bloodPressure: _tdCtrl.text.trim(),
                      heartRate: int.tryParse(_hrCtrl.text),
                      temperature: double.tryParse(_tempCtrl.text),
                      respiratoryRate: int.tryParse(_rrCtrl.text),
                      oxygenSaturation: int.tryParse(_spo2Ctrl.text),
                    );

                    await _loadData();
                    setState(() => _isAdding = false);

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Catatan CPPT berhasil ditambahkan ke rekam medis ranap.',
                          ),
                          backgroundColor: Colors.teal,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Simpan Catatan CPPT'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
