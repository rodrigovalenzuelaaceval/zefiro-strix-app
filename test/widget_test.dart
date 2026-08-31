// Smoke test for the Zefiro Strix app.
//
// This test only verifies that the app boots and navigates to the scanner
// screen without throwing any exceptions. It does not mock BleService nor
// simulate real BLE hardware.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:apk_zefiro/main.dart';

void main() {
  testWidgets('App boots and shows the scanner screen', (WidgetTester tester) async {
    // Build the app and trigger a frame.
    await tester.pumpWidget(const ZefiroApp());

    // Verify that no exception was thrown while building the widget tree.
    expect(tester.takeException(), isNull);

    // Verify that the AppBar title of the initial (scanner) screen is shown.
    expect(find.text('Zéfiro Strix Scanner'), findsOneWidget);
  });
}
