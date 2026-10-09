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
    Future.microtask(() => _fetch());

    return const NotificationsState(
      items: [],
      unreadCount: 0,
      isLoading: true,
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

  Future<void> _fetch() async {
    final client = ref.read(apiClientProvider);
    final role = _getCurrentRole();
    final notifs = await client.getNotifications(role: role);

    final unread = notifs.where((n) => !n.isRead).length;
    state = NotificationsState(
      items: notifs,
      unreadCount: unread,
      isLoading: false,
    );
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
