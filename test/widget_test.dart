import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:cliply/models/item.dart';
import 'package:cliply/main.dart';

void main() {
  setUpAll(() async {
    // Set up a temporary directory for Hive to store test data
    final tempDir = Directory.systemTemp.createTempSync('cliply_test_hive');
    Hive.init(tempDir.path);
    // Register ItemAdapter if it's not already registered
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ItemAdapter());
    }
  });

  setUp(() async {
    await Hive.openBox<Item>('itemsBox');
  });

  tearDown(() async {
    await Hive.close();
  });

  testWidgets('Cliply app renders and displays brand header', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify that the brand name "Cliply" is displayed.
    expect(find.text('Cliply'), findsOneWidget);
  });
}
