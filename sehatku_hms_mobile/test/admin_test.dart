import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sehatku_hms/features/admin/presentation/admin_dashboard_screen.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  testWidgets('AdminDashboardScreen renders tabs and switches navigation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AdminDashboardScreen())),
    );

    // Initial Overview tab
    expect(find.text('Hospital Overview'), findsOneWidget);
    expect(find.text('Pasien Terdaftar'), findsOneWidget);
    expect(find.text('Dokter Aktif'), findsOneWidget);

    // Navigate to Dokter tab
    await tester.tap(find.text('Dokter'));
    await tester.pumpAndSettle();
    expect(find.text('Manajemen Tenaga Medis & Dokter'), findsOneWidget);
    expect(find.text('Tambah Dokter'), findsOneWidget);

    // Navigate to Pasien tab
    await tester.tap(find.text('Pasien'));
    await tester.pumpAndSettle();
    expect(find.text('Master Data & Rekam Medis Pasien'), findsOneWidget);
    expect(find.text('Pasien Baru'), findsOneWidget);

    // Navigate to Reservasi tab
    await tester.tap(find.text('Reservasi'));
    await tester.pumpAndSettle();
    expect(find.text('Monitoring Reservasi & Antrean Poli'), findsOneWidget);

    // Navigate to Kasir & Tagihan tab
    await tester.tap(find.text('Kasir & Tagihan'));
    await tester.pumpAndSettle();
    expect(
      find.text('Kasir POS, Invoice & Rekonsiliasi Tagihan RS'),
      findsOneWidget,
    );

    // Navigate to Audit Log tab
    await tester.tap(find.text('Audit Log'));
    await tester.pumpAndSettle();
    expect(find.text('Audit Trail & Keamanan Aktivitas'), findsOneWidget);
  });
}
