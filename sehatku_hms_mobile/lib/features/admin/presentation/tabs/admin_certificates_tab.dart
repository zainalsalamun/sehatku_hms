import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/admin_pagination_footer.dart';
import '../../../medical_record/application/certificates_provider.dart';
import '../../../medical_record/presentation/widgets/create_medical_certificate_dialog.dart';
import '../../../medical_record/presentation/widgets/medical_certificate_dialog.dart';

class AdminCertificatesTab extends ConsumerStatefulWidget {
  const AdminCertificatesTab({super.key});

  @override
  ConsumerState<AdminCertificatesTab> createState() => _AdminCertificatesTabState();
}

class _AdminCertificatesTabState extends ConsumerState<AdminCertificatesTab> {
  final _searchController = TextEditingController();
  int _currentPage = 1;
  int _itemsPerPage = 10;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final certificates = ref.watch(medicalCertificatesProvider);
    final dateFormat = DateFormat('d MMM yyyy', 'id_ID');

    final filtered = certificates.where((c) {
      final q = _searchController.text.trim().toLowerCase();
      return q.isEmpty ||
          c.patientName.toLowerCase().contains(q) ||
          c.certificateNumber.toLowerCase().contains(q) ||
          c.doctorName.toLowerCase().contains(q) ||
          c.diagnosis.toLowerCase().contains(q);
    }).toList();

    final totalPages = (filtered.length / _itemsPerPage).ceil().clamp(1, 9999);
    if (_currentPage > totalPages) {
      _currentPage = totalPages;
    }
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final paginatedCerts = filtered.skip(startIndex).take(_itemsPerPage).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Arsip Surat Keterangan Medis (SKD & Surat Sehat)',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Daftar surat resmi yang diterbitkan oleh dokter pemeriksa dengan QR Code verifikasi.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () =>
                        ref.read(medicalCertificatesProvider.notifier).refresh(),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Refresh Data'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const CreateMedicalCertificateDialog(),
                      );
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Terbitkan Surat Medis'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari nomor surat, nama pasien, atau dokter...',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (_) => setState(() => _currentPage = 1),
          ),
          const SizedBox(height: 18),

          // List of Certificates
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: filtered.isEmpty
                  ? const Center(
                      child: Text('Belum ada surat keterangan medis yang diterbitkan.'),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: paginatedCerts.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, idx) {
                              final cert = paginatedCerts[idx];
                              final isSickLeave = cert.type == 'sick_leave';

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: isSickLeave ? Colors.deepOrange.shade100 : Colors.teal.shade100,
                                  child: Icon(
                                    isSickLeave ? Icons.sick_outlined : Icons.health_and_safety_outlined,
                                    color: isSickLeave ? Colors.deepOrange.shade800 : Colors.teal.shade800,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Text(
                                      cert.patientName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.grey.shade300),
                                      ),
                                      child: Text(
                                        cert.certificateNumber,
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isSickLeave ? Colors.deepOrange.shade50 : Colors.teal.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isSickLeave ? 'Surat Sakit (${cert.durationDays} Hari)' : 'Surat Sehat',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isSickLeave ? Colors.deepOrange.shade800 : Colors.teal.shade800,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 2),
                                    Text(
                                      'Diagnosa: ${cert.diagnosis} • Dokter: ${cert.doctorName}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                    ),
                                    Text(
                                      'Masa Istirahat: ${dateFormat.format(cert.startDate)} s/d ${dateFormat.format(cert.endDate)}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                                trailing: FilledButton.tonalIcon(
                                  onPressed: () => showMedicalCertificateDialog(context, cert),
                                  icon: const Icon(Icons.print_outlined, size: 16),
                                  label: const Text('Buka & Cetak'),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        AdminPaginationFooter(
                          currentPage: _currentPage,
                          totalItems: filtered.length,
                          itemsPerPage: _itemsPerPage,
                          onPageChanged: (page) => setState(() => _currentPage = page),
                          onItemsPerPageChanged: (count) => setState(() {
                            _itemsPerPage = count;
                            _currentPage = 1;
                          }),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
