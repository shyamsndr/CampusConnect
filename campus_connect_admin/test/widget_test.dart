import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_connect_admin/main.dart';

void main() {
  testWidgets('CampusConnect Admin portal smoke test',
      (WidgetTester tester) async {
    // Set a desktop-sized test screen
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const CampusConnectAdminApp());
    await tester.pumpAndSettle();

    // Verify key brand elements and layout are rendered
    expect(find.text('CampusConnect'), findsWidgets);
    expect(find.text('Admin Portal'), findsWidgets);
    expect(find.text('Welcome back, Admin'), findsOneWidget);
    expect(find.text('Total Users'), findsOneWidget);
    expect(find.text('Total Complaints'), findsOneWidget);
  });
}
