import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/health_models.dart';
import '../../../../shared/widgets/doctor_avatar.dart';

class DoctorProfileDetailDialog extends StatelessWidget {
  const DoctorProfileDetailDialog({
    super.key,
    required this.doctor,
    required this.departmentName,
    required this.onEditPressed,
  });

  final Doctor doctor;
  final String departmentName;
  final VoidCallback onEditPressed;

  @override
  Widget build(BuildContext context) {
    final schedule = doctor.scheduleDays.isNotEmpty
        ? doctor.scheduleDays.join(', ')
        : 'Belum diatur';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: 520,
        color: Colors.white,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Banner
              Container(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.navy, AppColors.navyLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: doctor.isActive
                                      ? AppColors.greenAccent
                                      : Colors.grey.shade400,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                doctor.isActive
                                    ? 'Dokter Aktif'
                                    : 'Dokter Nonaktif',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Doctor Avatar
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.6),
                            width: 3,
                          ),
                        ),
                        child: DoctorAvatar(
                          photoUrl: doctor.photoUrl,
                          name: doctor.name,
                          radius: 44,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Doctor Name & Specialty
                    Text(
                      doctor.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor.specialist,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Department Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        departmentName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Details Body
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Row
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.grey50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            icon: Icons.star_rounded,
                            iconColor: AppColors.warning,
                            value: '${doctor.rating}',
                            label: 'Rating Pasien',
                          ),
                          Container(
                            height: 30,
                            width: 1,
                            color: AppColors.cardBorder,
                          ),
                          _buildStatItem(
                            icon: Icons.workspace_premium_outlined,
                            iconColor: AppColors.primary,
                            value: '${doctor.experience} Tahun',
                            label: 'Pengalaman',
                          ),
                          Container(
                            height: 30,
                            width: 1,
                            color: AppColors.cardBorder,
                          ),
                          _buildStatItem(
                            icon: Icons.verified_outlined,
                            iconColor: AppColors.success,
                            value: 'Terverifikasi',
                            label: 'Kredensial RS',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Info List
                    const Text(
                      'Informasi Kredensial & Praktek',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildInfoTile(
                      icon: Icons.badge_outlined,
                      label: 'Nomor SIP / STR',
                      value: doctor.licenseNumber.isNotEmpty
                          ? doctor.licenseNumber
                          : '-',
                    ),
                    _buildInfoTile(
                      icon: Icons.calendar_month_outlined,
                      label: 'Jadwal Praktek',
                      value: schedule,
                    ),
                    _buildInfoTile(
                      icon: Icons.phone_outlined,
                      label: 'Nomor Telepon',
                      value: doctor.phone.isNotEmpty ? doctor.phone : '-',
                    ),
                    _buildInfoTile(
                      icon: Icons.email_outlined,
                      label: 'Alamat Email',
                      value: doctor.email.isNotEmpty ? doctor.email : '-',
                    ),
                    const SizedBox(height: 24),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Tutup'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            onEditPressed();
                          },
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Edit Data Dokter'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
