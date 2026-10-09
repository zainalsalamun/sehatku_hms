import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../patient/presentation/doctor_patient_chat_screen.dart';

class PatientChatThread {
  final String id;
  final String patientName;
  final String mrn;
  final String department;
  final String lastMessage;
  final String lastTime;
  final int unreadCount;
  final bool isFollowUp;

  const PatientChatThread({
    required this.id,
    required this.patientName,
    required this.mrn,
    required this.department,
    required this.lastMessage,
    required this.lastTime,
    this.unreadCount = 0,
    this.isFollowUp = false,
  });
}

class DoctorChatInboxDialog extends StatefulWidget {
  const DoctorChatInboxDialog({
    super.key,
    required this.doctorName,
    required this.specialist,
  });

  final String doctorName;
  final String specialist;

  @override
  State<DoctorChatInboxDialog> createState() => _DoctorChatInboxDialogState();
}

class _DoctorChatInboxDialogState extends State<DoctorChatInboxDialog> {
  String _searchQuery = '';
  int _selectedFilter = 0; // 0 = Semua, 1 = Belum Dibalas, 2 = Kontrol Lanjutan

  final List<PatientChatThread> _threads = const [
    PatientChatThread(
      id: 'cht-001',
      patientName: 'Nadia Putri',
      mrn: 'RM-2026-0812',
      department: 'Poli Jantung & Pembuluh Darah',
      lastMessage:
          'Selamat siang dok, tekanan darah saya pagi ini 120/80 mmHg. Apakah obat penurun tensi tetap diminum?',
      lastTime: '10:45',
      unreadCount: 1,
      isFollowUp: true,
    ),
    PatientChatThread(
      id: 'cht-002',
      patientName: 'Budi Santoso',
      mrn: 'RM-2026-0491',
      department: 'Poli Penyakit Dalam',
      lastMessage:
          'Terima kasih dok, keluhan lemas sudah berkurang setelah 3 hari konsumsi vitamin.',
      lastTime: '09:15',
      unreadCount: 0,
      isFollowUp: false,
    ),
    PatientChatThread(
      id: 'cht-003',
      patientName: 'Siti Rahmawati',
      mrn: 'RM-2026-0155',
      department: 'Poli Jantung & Pembuluh Darah',
      lastMessage:
          'Dokter, hasil lab profil lipid dan EKG saya sudah keluar di aplikasi, mohon direview.',
      lastTime: 'Kemarin',
      unreadCount: 2,
      isFollowUp: true,
    ),
    PatientChatThread(
      id: 'cht-004',
      patientName: 'Ahmad Fauzi',
      mrn: 'RM-2026-0732',
      department: 'Poli Umum',
      lastMessage:
          'Baik dok, jadwal kontrol minggu depan sudah saya daftarkan lewat antrean online.',
      lastTime: '2 hari lalu',
      unreadCount: 0,
      isFollowUp: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _threads.where((t) {
      if (_selectedFilter == 1 && t.unreadCount == 0) return false;
      if (_selectedFilter == 2 && !t.isFollowUp) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = t.patientName.toLowerCase().contains(q);
        final matchMrn = t.mrn.toLowerCase().contains(q);
        return matchName || matchMrn;
      }
      return true;
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.navy,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.forum_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kotak Pesan & Telekonsultasi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.doctorName} • ${widget.specialist}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
            ),

            // Search Bar & Filter Chips
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                children: [
                  TextField(
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    decoration: InputDecoration(
                      hintText: 'Cari nama pasien atau No. RM...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.navy, width: 1.5),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(0, 'Semua Pesan', _threads.length),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          1,
                          'Perlu Dibalas',
                          _threads.where((t) => t.unreadCount > 0).length,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          2,
                          'Konsultasi Lanjutan',
                          _threads.where((t) => t.isFollowUp).length,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Message list
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.mark_chat_read_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tidak ada percakapan telekonsultasi',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Semua pesan pasien telah terjawab.',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                      itemBuilder: (context, index) {
                        final thread = filtered[index];
                        final hasUnread = thread.unreadCount > 0;

                        return InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => DoctorPatientChatScreen(
                                  doctorName: widget.doctorName,
                                  specialist: widget.specialist,
                                  patientName: thread.patientName,
                                  isDoctorView: true,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: hasUnread
                                      ? AppTheme.navy.withValues(alpha: 0.12)
                                      : Colors.grey.shade200,
                                  child: Text(
                                    thread.patientName.isNotEmpty
                                        ? thread.patientName[0].toUpperCase()
                                        : 'P',
                                    style: TextStyle(
                                      color: hasUnread ? AppTheme.navy : Colors.grey.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    thread.patientName,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: hasUnread
                                                          ? FontWeight.bold
                                                          : FontWeight.w600,
                                                      color: AppTheme.navy,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade100,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    thread.mrn,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.grey.shade700,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            thread.lastTime,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: hasUnread
                                                  ? AppTheme.navy
                                                  : Colors.grey.shade500,
                                              fontWeight: hasUnread
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        thread.lastMessage,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: hasUnread
                                              ? Colors.black87
                                              : Colors.grey.shade600,
                                          fontWeight: hasUnread
                                              ? FontWeight.w500
                                              : FontWeight.normal,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.medical_services_outlined,
                                            size: 13,
                                            color: Colors.grey.shade500,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            thread.department,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          const Spacer(),
                                          if (hasUnread)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 7,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.red.shade600,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                '${thread.unreadCount} baru',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_threads.where((t) => t.unreadCount > 0).length} pasien menunggu balasan Anda',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Tutup'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(int index, String label, int count) {
    final isSelected = _selectedFilter == index;
    return ChoiceChip(
      selected: isSelected,
      label: Text('$label ($count)'),
      labelStyle: TextStyle(
        fontSize: 11.5,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : Colors.grey.shade800,
      ),
      selectedColor: AppTheme.navy,
      backgroundColor: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (_) => setState(() => _selectedFilter = index),
    );
  }
}
