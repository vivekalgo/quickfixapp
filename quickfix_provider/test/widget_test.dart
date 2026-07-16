import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:quickfix_provider/main.dart';

void main() {
  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('hive_test');
    Hive.init(tempDir.path);
    await Hive.openBox('provider_settings');
  });

  testWidgets('Provider App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: QuickFixProviderApp()));
    expect(find.byType(QuickFixProviderApp), findsOneWidget);

    // Advance the virtual clock to allow the splash screen timer (2.2s) to fire
    await tester.pump(const Duration(seconds: 3));

    // Pump a few frames to let the routing and transition finalize
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  });
}
