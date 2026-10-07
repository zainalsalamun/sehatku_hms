import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sehatku_hms/features/patient/presentation/doctor_patient_chat_screen.dart';
import 'package:sehatku_hms/features/patient/presentation/patient_home_screen.dart';
import 'package:sehatku_hms/features/patient/presentation/widgets/queue_ticket_dialog.dart';
import 'package:sehatku_hms/shared/models/health_models.dart';

void main() {
  testWidgets(
    'PatientHomeScreen renders upcoming appointment and quick actions',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: PatientHomeScreen())),
      );

      expect(find.text('RESERVASI BERIKUTNYA'), findsOneWidget);
      expect(find.text('Akses cepat'), findsOneWidget);
      expect(find.text('Reservasi'), findsOneWidget);
      expect(find.text('Tiket Antrean'), findsOneWidget);
      expect(find.text('Chat dokter'), findsOneWidget);
    },
  );

  testWidgets('QueueTicketDialog renders queue status and QR scan display', (
    tester,
  ) async {
    const testAppt = Appointment(
      id: 'a-test',
      doctorName: 'dr. Maya Pratama, Sp.JP',
      patientName: 'Nadia Putri',
      dateLabel: 'Hari ini',
      time: '09:30 WIB',
      status: 'Menunggu',
      queueNumber: 'A-032',
      department: 'Kardiologi & Vaskular',
    );

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: QueueTicketDialog(appointment: testAppt)),
        ),
      ),
    );

    expect(find.text('Tiket Antrean Digital'), findsOneWidget);
    expect(find.text('A-032'), findsOneWidget);
    expect(find.text('Simulasikan Check-In Kiosk'), findsOneWidget);
  });

  testWidgets(
    'DoctorPatientChatScreen renders messages and sends quick prompt',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: DoctorPatientChatScreen()),
      );

      expect(find.text('dr. Maya Pratama, Sp.JP'), findsWidgets);
      expect(find.text('Konsultasi hasil lab terbaru'), findsOneWidget);

      // Tap quick prompt
      await tester.tap(find.text('Konsultasi hasil lab terbaru'));
      await tester.pump();

      expect(find.text('Konsultasi hasil lab terbaru'), findsWidgets);
    },
  );
}
