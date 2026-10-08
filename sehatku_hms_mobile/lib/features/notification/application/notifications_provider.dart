import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/api_client_provider.dart';
import '../../../shared/models/health_models.dart';
import '../../authentication/application/auth_controller.dart';

class NotificationsState {
  const NotificationsState({
    this.items = const [],
    this.unreadCount = 0,
    this.isLoading = false,
  });

  final List<AppNotification> items;
  final int unreadCount;
  final bool isLoading;

  NotificationsState copyWith({
    List<AppNotification>? items,
    int? unreadCount,
    bool? isLoading,
  }) {
    return NotificationsState(
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class NotificationsNotifier extends Notifier<NotificationsState> {
  @override
  NotificationsState build() {
    final role = _getCurrentRole();
    final defaultItems = _getDefaultNotifications(role);
    final unread = defaultItems.where((n) => !n.isRead).length;

    // Fetch from API in background without wiping default data
    Future.microtask(() => _fetch());

    return NotificationsState(
      items: defaultItems,
      unreadCount: unread,
      isLoading: false,
    );
  }

  String _getCurrentRole() {
    final auth = ref.watch(authControllerProvider);
    switch (auth.role) {
      case UserRole.doctor:
        return 'doctor';
      case UserRole.admin:
        return 'admin';
      case UserRole.patient:
        return 'patient';
    }
  }

  List<AppNotification> _getDefaultNotifications(String role) {
    final now = DateTime.now();
    if (role == 'doctor') {
      return [
        AppNotification(
          id: '90000000-0000-4000-8000-000000000003',
          role: 'doctor',
          title: 'Pasien Reservasi Baru Masuk',
          message:
              'Pasien Nadia Putri (MRN-2026-001) telah memesan sesi konsultasi di Poli Kardiologi hari ini pukul 09:30 WIB.',
          type: 'appointment',
          targetId: '50000000-0000-4000-8000-000000000001',
          isRead: false,
          createdAt: now.subtract(const Duration(minutes: 10)),
        ),
        AppNotification(
          id: '90000000-0000-4000-8000-000000000010',
          role: 'doctor',
          title: 'Jadwal Praktek & Antrean Pasien Hari Ini',
          message:
              'Anda memiliki 3 antrean pasien aktif terdaftar di Poli Kardiologi & Vaskular.',
          type: 'appointment',
          targetId: '50000000-0000-4000-8000-000000000001',
          isRead: false,
          createdAt: now.subtract(const Duration(hours: 1)),
        ),
        AppNotification(
          id: '90000000-0000-4000-8000-000000000011',
          role: 'doctor',
          title: 'Hasil Lab Pasien Tersedia',
          message:
              'Hasil evaluasi profil lipid dan elektrokardiogram untuk pasien Raka Mahendra telah terbit.',
          type: 'clinical',
          targetId: '40000000-0000-4000-8000-000000000002',
          isRead: true,
          createdAt: now.subtract(const Duration(hours: 3)),
        ),
      ];
    } else if (role == 'admin') {
      return [
        AppNotification(
          id: '90000000-0000-4000-8000-000000000004',
          role: 'admin',
          title: 'Peringatan Stok Obat Farmasi',
          message:
              'Stok Omeprazole 20mg tersisa 25 strip (di bawah batas minimum 80 strip). Harap lakukan restock.',
          type: 'prescription',
          targetId: '78000000-0000-4000-8000-000000000004',
          isRead: false,
          createdAt: now.subtract(const Duration(minutes: 15)),
        ),
        AppNotification(
          id: '90000000-0000-4000-8000-000000000012',
          role: 'admin',
          title: 'Reservasi Baru Terdaftar',
          message:
              'Tiket antrean A-001 terbit untuk Nadia Putri di Poli Kardiologi & Vaskular.',
          type: 'appointment',
          targetId: '50000000-0000-4000-8000-000000000001',
          isRead: false,
          createdAt: now.subtract(const Duration(minutes: 30)),
        ),
        AppNotification(
          id: '90000000-0000-4000-8000-000000000005',
          role: 'admin',
          title: 'Kasir POS: Pembayaran Selesai',
          message:
              'Tagihan INV-2026-101 atas nama Nadia Putri telah lunas via QRIS Dinamis sebesar Rp 350.000.',
          type: 'billing',
          targetId: '80000000-0000-4000-8000-000000000001',
          isRead: false,
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
        AppNotification(
          id: '90000000-0000-4000-8000-000000000013',
          role: 'admin',
          title: 'Audit Log: Pendaftaran Pasien',
          message:
              'Petugas Siti Rahma mendaftarkan pasien baru MRN-2026-003 ke sistem database.',
          type: 'system',
          targetId: '40000000-0000-4000-8000-000000000003',
          isRead: true,
          createdAt: now.subtract(const Duration(hours: 4)),
        ),
      ];
    } else {
      // Patient
      return [
        AppNotification(
          id: '90000000-0000-4000-8000-000000000001',
          role: 'patient',
          title: 'Reservasi Poli Kardiologi Terkonfirmasi',
          message:
              'Reservasi Anda dengan dr. Maya Pratama, Sp.JP pada pukul 09:30 WIB telah terdaftar dengan Nomor Antrean A-001.',
          type: 'appointment',
          targetId: '50000000-0000-4000-8000-000000000001',
          isRead: false,
          createdAt: now.subtract(const Duration(minutes: 8)),
        ),
        AppNotification(
          id: '90000000-0000-4000-8000-000000000014',
          role: 'patient',
          title: 'Hasil Pemeriksaan & E-Resep Terbit',
          message:
              'Pemeriksaan oleh dr. Maya Pratama telah selesai. Diagnosa: Hipertensi Primer. Lembar rekam medis dan e-resep siap diakses.',
          type: 'clinical',
          targetId: '60000000-0000-4000-8000-000000000001',
          isRead: false,
          createdAt: now.subtract(const Duration(hours: 1)),
        ),
        AppNotification(
          id: '90000000-0000-4000-8000-000000000015',
          role: 'patient',
          title: 'Obat Siap Diambil di Loket Farmasi',
          message:
              'Resep obat Anda telah selesai diracik oleh instalasi farmasi RS. Silakan menuju Loket Pengambilan Obat.',
          type: 'prescription',
          targetId: '70000000-0000-4000-8000-000000000001',
          isRead: false,
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
        AppNotification(
          id: '90000000-0000-4000-8000-000000000002',
          role: 'patient',
          title: 'Kwitansi Pembayaran Resmi Terbit',
          message:
              'Pembayaran tagihan INV-2026-101 sebesar Rp 350.000 via QRIS Dinamis telah diverifikasi lunas.',
          type: 'billing',
          targetId: '80000000-0000-4000-8000-000000000001',
          isRead: true,
          createdAt: now.subtract(const Duration(hours: 3)),
        ),
      ];
    }
  }

  Future<void> _fetch() async {
    final client = ref.read(apiClientProvider);
    final role = _getCurrentRole();
    final notifs = await client.getNotifications(role: role);

    if (notifs.isNotEmpty) {
      final unread = notifs.where((n) => !n.isRead).length;
      state = NotificationsState(
        items: notifs,
        unreadCount: unread,
        isLoading: false,
      );
    }
  }

  Future<void> refresh() async => _fetch();

  Future<void> markAsRead(String id) async {
    state = state.copyWith(
      items: [
        for (final n in state.items)
          if (n.id == id) n.copyWith(isRead: true) else n,
      ],
      unreadCount: (state.unreadCount - 1).clamp(0, 999),
    );
    await ref.read(apiClientProvider).markNotificationRead(id);
  }

  void addNotification(AppNotification item) {
    state = state.copyWith(
      items: [item, ...state.items],
      unreadCount: item.isRead ? state.unreadCount : state.unreadCount + 1,
    );
  }

  Future<void> markAllAsRead() async {
    final role = _getCurrentRole();
    state = state.copyWith(
      items: [
        for (final n in state.items) n.copyWith(isRead: true),
      ],
      unreadCount: 0,
    );
    await ref.read(apiClientProvider).markAllNotificationsRead(role: role);
  }

  Future<void> deleteNotification(String id) async {
    final updatedItems = state.items.where((n) => n.id != id).toList();
    final newUnread = updatedItems.where((n) => !n.isRead).length;
    state = state.copyWith(
      items: updatedItems,
      unreadCount: newUnread,
    );
    await ref.read(apiClientProvider).deleteNotification(id);
  }

  Future<void> clearAllRead() async {
    final readItems = state.items.where((n) => n.isRead).toList();
    final updatedItems = state.items.where((n) => !n.isRead).toList();
    state = state.copyWith(
      items: updatedItems,
      unreadCount: updatedItems.length,
    );
    for (final item in readItems) {
      ref.read(apiClientProvider).deleteNotification(item.id);
    }
  }
}

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, NotificationsState>(
  NotificationsNotifier.new,
);

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifState = ref.watch(notificationsProvider);
  return notifState.unreadCount;
});
