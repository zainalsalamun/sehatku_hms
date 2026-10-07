import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/api_client_provider.dart';
import '../../../../core/utils/file_download_helper.dart';
import '../../../../shared/models/health_models.dart';

class MorbiLB1TableCard extends ConsumerStatefulWidget {
  const MorbiLB1TableCard({super.key});

  @override
  ConsumerState<MorbiLB1TableCard> createState() => _MorbiLB1TableCardState();
}

class _MorbiLB1TableCardState extends ConsumerState<MorbiLB1TableCard> {
  MorbiLB1SummaryModel? _summary;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final client = ref.read(apiClientProvider);
    final data = await client.getMorbiLB1Summary();
    if (mounted) {
      setState(() {
        _summary = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _summary?.rankedDiseases ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.coronavirus_outlined, color: Colors.red.shade700, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '10 Besar Penyakit Terbanyak (Laporan LB1 Dinkes)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Berdasarkan pengelompokan kode diagnosis ICD-10 • Total: ${_summary?.totalCases ?? 0} Kasus',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final client = ref.read(apiClientProvider);
                    final csv = await client.downloadMorbiLB1Export();
                    if (csv != null) {
                      downloadFileFromText(
                        content: csv,
                        filename: 'Laporan_LB1_10_Penyakit_${DateTime.now().year}_${DateTime.now().month}.csv',
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('File Laporan LB1 Dinkes (.csv) berhasil diunduh.'),
                            backgroundColor: Colors.teal,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.download_outlined, size: 16),
                  label: const Text('Export LB1 (.csv)'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Body Table
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('Belum ada data diagnosa rekam medis.')),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = list[index];
                final isTop3 = item.rank <= 3;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: Row(
                    children: [
                      // Rank Badge
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isTop3 ? Colors.red.shade700 : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '#${item.rank}',
                          style: TextStyle(
                            color: isTop3 ? Colors.white : Colors.black87,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // ICD-10 Code Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Text(
                          item.icd10Code,
                          style: TextStyle(
                            color: Colors.blue.shade900,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Diagnosis Name
                      Expanded(
                        flex: 4,
                        child: Text(
                          item.description,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),

                      // Gender Distribution
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Text(
                              'L: ${item.maleCount}',
                              style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold),
                            ),
                            const Text(' • ', style: TextStyle(color: Colors.grey)),
                            Text(
                              'P: ${item.femaleCount}',
                              style: const TextStyle(fontSize: 11, color: Colors.pink, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),

                      // Cases & Progress Bar
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${item.totalCount} Kasus (${item.percentage}%)',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (item.percentage / 100).clamp(0.05, 1.0),
                                minHeight: 6,
                                backgroundColor: Colors.grey.shade100,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isTop3 ? Colors.red.shade600 : Colors.teal.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
