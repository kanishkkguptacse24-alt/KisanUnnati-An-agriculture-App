import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Make sure this import matches your actual project name
import 'package:kisan_unnati/main.dart';

void main() {
  testWidgets('App loads and shows Dashboard navigation', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const KisanUnnatiApp());

    // Verify that our Bottom Navigation Bar renders correctly
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Schemes'), findsOneWidget);
    expect(find.text('Market'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}