import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../authentication/application/auth_controller.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.time,
    required this.isMe,
    this.isDelivered = true,
    this.isRead = true,
  });

  final String id;
  final String sender;
  final String text;
  final String time;
  final bool isMe;
  final bool isDelivered;
  final bool isRead;
}

class DoctorPatientChatScreen extends ConsumerStatefulWidget {
  const DoctorPatientChatScreen({
    super.key,
    this.doctorName = 'dr. Maya Pratama, Sp.JP',
    this.specialist = 'Spesialis Jantung & Pembuluh Darah',
    this.doctorPhotoUrl = '',
  });

  final String doctorName;
  final String specialist;
  final String doctorPhotoUrl;

  @override
  ConsumerState<DoctorPatientChatScreen> createState() =>
      _DoctorPatientChatScreenState();
}

class _DoctorPatientChatScreenState extends ConsumerState<DoctorPatientChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isDoctorTyping = false;

  late final List<ChatMessage> _messages = [
    ChatMessage(
      id: 'm1',
      sender: widget.doctorName,
      text:
          'Halo! Ada keluhan apa mengenai resep obat atau tensi darah Anda hari ini?',
      time: '09:15',
      isMe: false,
    ),
    ChatMessage(
      id: 'm2',
      sender: ref.read(authControllerProvider).userFullName ?? 'Saya',
      text:
          'Selamat pagi Dok. Tekanan darah saya pagi ini 125/82 mmHg. Sudah jauh lebih stabil, tapi kadang masih ada sedikit pusing di sore hari.',
      time: '09:18',
      isMe: true,
    ),
    ChatMessage(
      id: 'm3',
      sender: widget.doctorName,
      text:
          'Bagus sekali tensinya sudah membaik. Pusing ringan di sore hari bisa karena penyesuaian vaskular. Pastikan minum air putih cukup (minimal 2 liter/hari) dan kurangi konsumsi garam berlebih ya.',
      time: '09:20',
      isMe: false,
    ),
  ];

  final List<String> _quickPrompts = [
    'Konsultasi hasil lab terbaru',
    'Apakah dosis obat tetap diminum?',
    'Jadwal kontrol berikutnya kapan ya dok?',
    'Ada pantangan makanan khusus?',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage([String? promptText]) {
    final text = promptText ?? _messageController.text.trim();
    if (text.isEmpty) return;

    final myName = ref.read(authControllerProvider).userFullName ?? 'Saya';
    final now = TimeOfDay.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, "0")}:${now.minute.toString().padLeft(2, "0")}';

    setState(() {
      _messages.add(
        ChatMessage(
          id: 'm-${DateTime.now().millisecondsSinceEpoch}',
          sender: myName,
          text: text,
          time: timeStr,
          isMe: true,
        ),
      );
      if (promptText == null) {
        _messageController.clear();
      }
    });

    _scrollToBottom();

    // Simulate doctor typing & response
    setState(() => _isDoctorTyping = true);
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() {
        _isDoctorTyping = false;
        _messages.add(
          ChatMessage(
            id: 'm-doc-${DateTime.now().millisecondsSinceEpoch}',
            sender: widget.doctorName,
            text: _generateDoctorReply(text),
            time: timeStr,
            isMe: false,
          ),
        );
      });
      _scrollToBottom();
    });
  }

  String _generateDoctorReply(String patientMessage) {
    final lower = patientMessage.toLowerCase();
    if (lower.contains('hasil lab')) {
      return 'Baik Bu Nadia, silakan unggah file PDF atau foto hasil labnya melalui tombol lampiran agar saya pelajari.';
    } else if (lower.contains('dosis') || lower.contains('obat')) {
      return 'Untuk dosis Amlodipine 5mg tetap diminum 1x sehari di pagi hari setelah makan ya. Jangan dihentikan tanpa konfirmasi.';
    } else if (lower.contains('kontrol') || lower.contains('jadwal')) {
      return 'Jadwal kontrol rutin Anda direkomendasikan 2 minggu lagi atau saat obat tersisa untuk 2 hari.';
    } else {
      return 'Terima kasih informasinya Bu Nadia. Catatan ini sudah saya masukkan ke ringkasan rekam medis Anda. Jika keluhan memberat, segera kunjungi IGD kami.';
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                  backgroundImage: widget.doctorPhotoUrl.isNotEmpty ? NetworkImage(widget.doctorPhotoUrl) : null,
                  onBackgroundImageError: widget.doctorPhotoUrl.isNotEmpty ? (_, _) {} : null,
                  child: widget.doctorPhotoUrl.isEmpty
                      ? const Icon(Icons.person, color: AppTheme.primary, size: 20)
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.doctorName,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${widget.specialist} • Online',
                    style: const TextStyle(fontSize: 11, color: Colors.green),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_outlined),
            tooltip: 'Telekonsultasi Video',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Panggilan video telekonsultasi siap dijadwalkan.')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Security disclaimer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: Colors.teal.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.lock_outline, size: 13, color: Colors.teal),
                SizedBox(width: 6),
                Text(
                  'Percakapan medis terenkripsi end-to-end (HIPAA Compliant)',
                  style: TextStyle(fontSize: 11, color: Colors.teal, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          // Chat Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildChatBubble(msg);
              },
            ),
          ),

          // Typing Indicator
          if (_isDoctorTyping)
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 8),
              child: Row(
                children: [
                  Text(
                    '${widget.doctorName} sedang mengetik...',
                    style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),

          // Quick Prompts Chips
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: _quickPrompts.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final prompt = _quickPrompts[idx];
                return InkWell(
                  onTap: () => _sendMessage(prompt),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      prompt,
                      style: const TextStyle(fontSize: 11, color: Colors.black87),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Input Bar
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file, color: Colors.grey),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pilih file lampiran resep atau hasil lab.')),
                      );
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Ketik pesan konsultasi...',
                        isDense: true,
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppTheme.primary,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 18),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage msg) {
    if (msg.isMe) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              msg.time,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.done_all, size: 14, color: Colors.blue),
            const SizedBox(width: 6),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.navy,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Text(
                  msg.text,
                  style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
              backgroundImage: widget.doctorPhotoUrl.isNotEmpty ? NetworkImage(widget.doctorPhotoUrl) : null,
              onBackgroundImageError: widget.doctorPhotoUrl.isNotEmpty ? (_, _) {} : null,
              child: widget.doctorPhotoUrl.isEmpty
                  ? const Icon(Icons.person, color: AppTheme.primary, size: 14)
                  : null,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                    bottomLeft: Radius.circular(4),
                  ),
                ),
                child: Text(
                  msg.text,
                  style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.3),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              msg.time,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      );
    }
  }
}
