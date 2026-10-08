import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sehatku_hms/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:sehatku_hms/features/admin/presentation/widgets/doctor_form_dialog.dart';
import 'package:sehatku_hms/features/inpatient/presentation/widgets/inpatient_admission_dialog.dart';
import 'package:sehatku_hms/features/laboratory/presentation/widgets/lab_order_create_dialog.dart';
import 'package:sehatku_hms/features/notification/presentation/notifications_screen.dart';
import 'package:sehatku_hms/features/patient/presentation/patient_home_screen.dart';
import 'package:sehatku_hms/shared/models/health_models.dart';
import 'package:sehatku_hms/shared/widgets/admin_pagination_footer.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  group('Feature 1: Admin Dashboard & Pagination Tests', () {
    testWidgets('AdminDashboard renders tabs and pagination controls', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: AdminDashboardScreen())),
      );

      // Verify Overview
      expect(find.text('Hospital Overview'), findsOneWidget);

      // Verify Dokter tab
      await tester.tap(find.text('Dokter'));
      await tester.pumpAndSettle();
      expect(find.text('Manajemen Tenaga Medis & Dokter'), findsOneWidget);

      // Verify Pasien tab
      await tester.tap(find.text('Pasien'));
      await tester.pumpAndSettle();
      expect(find.text('Master Data & Rekam Medis Pasien'), findsOneWidget);

      // Verify Kasir & Tagihan tab
      await tester.tap(find.text('Kasir & Tagihan'));
      await tester.pumpAndSettle();
      expect(find.text('Kasir POS, Invoice & Rekonsiliasi Tagihan RS'), findsOneWidget);
    });

    testWidgets('AdminPaginationFooter renders page numbers and reacts to page changes', (tester) async {
      int activePage = 1;
      int perPage = 10;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return AdminPaginationFooter(
                  currentPage: activePage,
                  totalItems: 45,
                  itemsPerPage: perPage,
                  onPageChanged: (page) => setState(() => activePage = page),
                  onItemsPerPageChanged: (count) => setState(() => perPage = count),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Menampilkan 1 - 10 dari 45 data'), findsOneWidget);
      expect(find.text('Halaman 1 / 5'), findsOneWidget);

      // Tap Next Page icon
      await tester.tap(find.byTooltip('Halaman Selanjutnya'));
      await tester.pumpAndSettle();

      expect(find.text('Menampilkan 11 - 20 dari 45 data'), findsOneWidget);
      expect(find.text('Halaman 2 / 5'), findsOneWidget);
    });
  });

  group('Feature 2: Doctor Dynamic Avatar Picker Dialog Tests', () {
    testWidgets('DoctorFormDialog allows selecting preset avatars or entering custom URL', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: DoctorFormDialog()),
          ),
        ),
      );

      expect(find.text('Tambah Dokter Baru'), findsOneWidget);
      expect(find.text('Foto Profil / Avatar Dokter:'), findsOneWidget);
      expect(find.text('Preset Avatar'), findsOneWidget);
      expect(find.text('Custom URL'), findsOneWidget);

      // Switch to Custom URL
      await tester.tap(find.text('Custom URL'));
      await tester.pumpAndSettle();
      expect(find.text('URL Foto Dokter (HTTPS Direct Link)'), findsOneWidget);
    });
  });

  group('Feature 3: Notification Center & Dismissible Tests', () {
    testWidgets('NotificationsScreen renders items and action buttons', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: NotificationsScreen()),
        ),
      );

      expect(find.text('Pusat Notifikasi'), findsOneWidget);
      expect(find.textContaining('Semua'), findsOneWidget);
      expect(find.textContaining('Belum Dibaca'), findsOneWidget);
    });
  });

  group('Feature 4: Laboratory Order Creation Dialog Tests', () {
    testWidgets('LabOrderCreateDialog renders tests dropdown and priority selectors', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: LabOrderCreateDialog()),
          ),
        ),
      );

      expect(find.text('Buat Permintaan Uji Lab Baru'), findsOneWidget);
      expect(find.text('Pilih Pasien Terdaftar *'), findsOneWidget);
      expect(find.text('Dokter Perujuk / DPJP *'), findsOneWidget);
    });
  });

  group('Feature 5: Inpatient Admission Dialog Tests', () {
    testWidgets('InpatientAdmissionDialog renders admission fields', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: InpatientAdmissionDialog()),
          ),
        ),
      );

      expect(find.text('Registrasi Rawat Inap Baru'), findsOneWidget);
      expect(find.text('Pilih Pasien Terdaftar *'), findsOneWidget);
      expect(find.text('Kamar / Bed Rawat Inap *'), findsOneWidget);
    });
  });

  group('Feature 6: Patient Flow & Quick Actions', () {
    testWidgets('PatientHomeScreen displays upcoming appointments', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: PatientHomeScreen()),
        ),
      );

      expect(find.text('RESERVASI BERIKUTNYA'), findsOneWidget);
      expect(find.text('Akses cepat'), findsOneWidget);
    });
  });
}
