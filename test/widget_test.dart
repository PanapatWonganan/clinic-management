// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clinic_app/main.dart';

void main() {
  testWidgets('App should start with login screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ClinicApp());

    // Wait for the app to settle
    await tester.pumpAndSettle();

    // Verify that login screen elements are present
    // We expect to find text fields or login-related widgets
    expect(find.byType(TextField), findsWidgets);
  });
}
