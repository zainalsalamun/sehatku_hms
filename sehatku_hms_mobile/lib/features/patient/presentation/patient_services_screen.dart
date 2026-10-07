import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../admin/application/admin_state_providers.dart';
import '../../appointment/presentation/interactive_booking_sheet.dart';
import 'doctor_patient_chat_screen.dart';

class DepartmentStyle {
  const DepartmentStyle({
    required this.icon,
    required this.color,
    required this.gradientColors,
    required this.shortDescription,
  });

  final IconData icon;
  final Color color;
  final List<Color> gradientColors;
  final String shortDescription;
}

class PatientServicesScreen extends ConsumerStatefulWidget {
  const PatientServicesScreen({super.key});

  @override
  ConsumerState<PatientServicesScreen> createState() =>
      _PatientServicesScreenState();
}

class _PatientServicesScreenState extends ConsumerState<PatientServicesScreen> {
  String _searchQuery = '';

  DepartmentStyle _getDepartmentStyle(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('kardio') || lower.contains('jantung')) {
      return const DepartmentStyle(
        icon: Icons.favorite_rounded,
        color: Color(0xFFE11D48),
        gradientColors: [Color(0xFFFFF1F2), Color(0xFFFFE4E6)],
        shortDescription: 'Spesialis Jantung & Pembuluh Darah',
      );
    }
    if (lower.contains('gigi') || lower.contains('mulut')) {
      return const DepartmentStyle(
        icon: Icons.medical_services_rounded,
        color: Color(0xFF0284C7),
        gradientColors: [Color(0xFFF0F9FF), Color(0xFFE0F2FE)],
        shortDescription: 'Konservasi Gigi & Bedah Mulut',
      );
    }
    if (lower.contains('mata') || lower.contains('oftalmo')) {
      return const DepartmentStyle(
        icon: Icons.visibility_rounded,
        color: Color(0xFF6366F1),
        gradientColors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
        shortDescription: 'Pemeriksaan Visus & Retina',
      );
    }
    if (lower.contains('saraf') || lower.contains('neuro')) {
      return const DepartmentStyle(
        icon: Icons.psychology_rounded,
        color: Color(0xFFEA580C),
        gradientColors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
        shortDescription: 'Diagnosis Otak & Sistem Saraf',
      );
    }
    if (lower.contains('anak') || lower.contains('pediatri')) {
      return const DepartmentStyle(
        icon: Icons.child_care_rounded,
        color: Color(0xFF10B981),
        gradientColors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
        shortDescription: 'Tumbuh Kembang & Imunisasi Anak',
      );
    }
    if (lower.contains('penyakit dalam') || lower.contains('internis')) {
      return const DepartmentStyle(
        icon: Icons.health_and_safety_rounded,
        color: Color(0xFF0D9488),
        gradientColors: [Color(0xFFF0FDFA), Color(0xFFCCFBF1)],
        shortDescription: 'Organ Dalam, Metabolik & Diabetes',
      );
    }
    if (lower.contains('tht') || lower.contains('telinga')) {
      return const DepartmentStyle(
        icon: Icons.hearing_rounded,
        color: Color(0xFFD97706),
        gradientColors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
        shortDescription: 'Telinga, Hidung & Tenggorokan',
      );
    }
    if (lower.contains('kulit') || lower.contains('dermato')) {
      return const DepartmentStyle(
        icon: Icons.spa_rounded,
        color: Color(0xFFDB2777),
        gradientColors: [Color(0xFFFDF2F8), Color(0xFFFCE7F3)],
        shortDescription: 'Kesehatan Kulit & Estetika Medis',
      );
    }
    if (lower.contains('kandungan') || lower.contains('obgyn')) {
      return const DepartmentStyle(
        icon: Icons.pregnant_woman_rounded,
        color: Color(0xFFBE185D),
        gradientColors: [Color(0xFFFFF1F2), Color(0xFFFFE4E6)],
        shortDescription: 'Kebidanan & Kehamilan USG 4D',
      );
    }
    if (lower.contains('orthopedi') || lower.contains('tulang')) {
      return const DepartmentStyle(
        icon: Icons.accessibility_new_rounded,
        color: Color(0xFF4F46E5),
        gradientColors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
        shortDescription: 'Bedah Tulang & Sendi',
      );
    }
    if (lower.contains('lab') || lower.contains('radiologi')) {
      return const DepartmentStyle(
        icon: Icons.biotech_rounded,
        color: Color(0xFF7C3AED),
        gradientColors: [Color(0xFFF5F3FF), Color(0xFFEDE9FE)],
        shortDescription: 'Tes Darah, Rontgen & CT Scan',
      );
    }

    return const DepartmentStyle(
      icon: Icons.local_hospital_rounded,
      color: AppTheme.primary,
      gradientColors: [Color(0xFFF0FDFA), Color(0xFFCCFBF1)],
      shortDescription: 'Pelayanan Medis Spesialis Terpadu',
    );
  }

  @override
  Widget build(BuildContext context) {
    final departments = ref.watch(adminDepartmentsProvider);

    final filtered = departments.where((d) {
      return d.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          d.code.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    final isWide = MediaQuery.sizeOf(context).width > 760;

    return Scaffold(
      appBar: const DashboardAppBar(
        title: 'Layanan & Poliklinik',
        subtitle: 'Poli spesialisasi klinis terakreditasi & fasilitas modern RS',
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(adminDepartmentsProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Cari poliklinik atau spesialisasi dokter...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
            const SizedBox(height: 20),

            // Section Header
            SectionHeader(
              'Poliklinik Spesialisasi Terdaftar',
              action: '${filtered.length} Poliklinik',
            ),
            const SizedBox(height: 14),

            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'Poliklinik "$_searchQuery" tidak ditemukan',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWide ? 3 : 2,
                  childAspectRatio: isWide ? 1.35 : 0.98,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final dept = filtered[index];
                  final style = _getDepartmentStyle(dept.name);

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: style.color.withValues(alpha: 0.18),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: style.color.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => showInteractiveBookingSheet(context),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: style.gradientColors,
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: style.color.withValues(alpha: 0.2),
                                      ),
                                    ),
                                    child: Icon(
                                      style.icon,
                                      color: style.color,
                                      size: 26,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: dept.doctorCount > 0
                                          ? Colors.green.shade50
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: dept.doctorCount > 0
                                            ? Colors.green.shade300
                                            : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircleAvatar(
                                          radius: 3,
                                          backgroundColor: dept.doctorCount > 0
                                              ? Colors.green
                                              : Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${dept.doctorCount} Dokter',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: dept.doctorCount > 0
                                                ? Colors.green.shade800
                                                : Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                dept.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                style.shortDescription,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Text(
                                    'Reservasi',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: style.color,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 14,
                                    color: style.color,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 28),
            const SectionHeader('Fasilitas & Telemedisin Siaga'),
            const SizedBox(height: 12),

            // Emergency Card
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.error, AppColors.maroonDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.error.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Menghubungi Hotline IGD SehatKu Medical Center: 1500-911 (Ambulans Siaga 24 Jam)',
                        ),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.emergency_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Instalasi Gawat Darurat (IGD 24 Jam)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Call Center: 1500-911 • Siaga Trauma & Ambulans',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.phone_in_talk_rounded,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Telemedicine Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Colors.teal,
                    size: 24,
                  ),
                ),
                title: const Text(
                  'Konsultasi Dokter Online (Chat)',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                subtitle: const Text(
                  'Percakapan langsung & telekonsultasi dokter spesialis',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.primary,
                  ),
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const DoctorPatientChatScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
