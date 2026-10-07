import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/queue_voice_service.dart';

class ActiveQueueCall {
  const ActiveQueueCall({
    required this.queueNumber,
    required this.patientName,
    required this.destination,
    required this.calledAt,
    this.isFlashing = true,
  });

  final String queueNumber;
  final String patientName;
  final String destination;
  final DateTime calledAt;
  final bool isFlashing;

  ActiveQueueCall copyWith({
    String? queueNumber,
    String? patientName,
    String? destination,
    DateTime? calledAt,
    bool? isFlashing,
  }) {
    return ActiveQueueCall(
      queueNumber: queueNumber ?? this.queueNumber,
      patientName: patientName ?? this.patientName,
      destination: destination ?? this.destination,
      calledAt: calledAt ?? this.calledAt,
      isFlashing: isFlashing ?? this.isFlashing,
    );
  }
}

class QueueDisplayState {
  const QueueDisplayState({
    this.activeCall,
    this.recentCalls = const [],
    this.isMuted = false,
  });

  final ActiveQueueCall? activeCall;
  final List<ActiveQueueCall> recentCalls;
  final bool isMuted;

  QueueDisplayState copyWith({
    ActiveQueueCall? activeCall,
    List<ActiveQueueCall>? recentCalls,
    bool? isMuted,
  }) {
    return QueueDisplayState(
      activeCall: activeCall ?? this.activeCall,
      recentCalls: recentCalls ?? this.recentCalls,
      isMuted: isMuted ?? this.isMuted,
    );
  }
}

class QueueDisplayNotifier extends Notifier<QueueDisplayState> {
  @override
  QueueDisplayState build() {
    return QueueDisplayState(
      activeCall: ActiveQueueCall(
        queueNumber: 'A-001',
        patientName: 'Nadia Putri',
        destination: 'Poli Kardiologi (Ruang 1)',
        calledAt: DateTime.now(),
        isFlashing: false,
      ),
      recentCalls: [
        ActiveQueueCall(
          queueNumber: 'A-001',
          patientName: 'Nadia Putri',
          destination: 'Poli Kardiologi (Ruang 1)',
          calledAt: DateTime.now().subtract(const Duration(minutes: 5)),
          isFlashing: false,
        ),
        ActiveQueueCall(
          queueNumber: 'B-001',
          patientName: 'Raka Mahendra',
          destination: 'Loket Kasir 1',
          calledAt: DateTime.now().subtract(const Duration(minutes: 12)),
          isFlashing: false,
        ),
      ],
    );
  }

  void callPatient({
    required String queueNumber,
    required String patientName,
    required String destination,
  }) {
    final newCall = ActiveQueueCall(
      queueNumber: queueNumber,
      patientName: patientName,
      destination: destination,
      calledAt: DateTime.now(),
      isFlashing: true,
    );

    state = state.copyWith(
      activeCall: newCall,
      recentCalls: [
        newCall.copyWith(isFlashing: false),
        ...state.recentCalls.where((c) => c.queueNumber != queueNumber).take(5),
      ],
    );

    if (!state.isMuted) {
      QueueVoiceService.instance.announce(
        queueNumber: queueNumber,
        patientName: patientName,
        destination: destination,
      );
    }
  }

  void toggleMute() {
    state = state.copyWith(isMuted: !state.isMuted);
  }
}

final queueDisplayProvider =
    NotifierProvider<QueueDisplayNotifier, QueueDisplayState>(
  QueueDisplayNotifier.new,
);
