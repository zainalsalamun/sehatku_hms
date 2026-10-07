import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sehatku_hms/app.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  testWidgets('app opens splash and navigates to login', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SehatKuApp()));

    expect(find.text('SehatKu'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();

    expect(find.text('Selamat datang'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
  });

  testWidgets('patient demo login opens patient dashboard', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SehatKuApp()));
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Masuk'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.text('Halo, Nadia'), findsOneWidget);
    expect(find.text('RESERVASI BERIKUTNYA'), findsOneWidget);
  });
}
