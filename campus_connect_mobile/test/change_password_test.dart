import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_connect_mobile/screens/auth/change_password_screen.dart';
import 'package:campus_connect_mobile/core/services/auth_service.dart';

// Mock AuthService that doesn't initialize Firebase
class MockAuthService extends ChangeNotifier implements AuthService {
  @override
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ChangePasswordScreen UI and Validation Tests', () {
    late MockAuthService mockAuth;

    setUp(() {
      mockAuth = MockAuthService();
    });

    Widget createScreen({bool isFirstLogin = false}) {
      return MaterialApp(
        home: ChangePasswordScreen(
          authService: mockAuth,
          isFirstLogin: isFirstLogin,
        ),
      );
    }

    testWidgets('Renders all input fields and update button', (WidgetTester tester) async {
      await tester.pumpWidget(createScreen());

      expect(find.text('CHANGE PASSWORD'), findsOneWidget);
      expect(find.text('Current Password'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm New Password'), findsOneWidget);
      expect(find.text('UPDATE PASSWORD'), findsOneWidget);
      // Back button present for non-first login
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    });

    testWidgets('First login mode shows SET NEW PASSWORD and Sign Out option without back arrow', (WidgetTester tester) async {
      await tester.pumpWidget(createScreen(isFirstLogin: true));

      expect(find.text('SET NEW PASSWORD'), findsOneWidget);
      expect(find.text('Please set a new password to continue'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
    });

    testWidgets('Rejects empty fields with clear validation messages', (WidgetTester tester) async {
      await tester.pumpWidget(createScreen());

      // Tap UPDATE PASSWORD without typing anything
      await tester.tap(find.text('UPDATE PASSWORD'));
      await tester.pump();

      expect(find.text('Current password is required'), findsOneWidget);
      expect(find.text('New password is required'), findsOneWidget);
      expect(find.text('Please confirm your new password'), findsOneWidget);
    });

    testWidgets('Rejects new password shorter than 8 characters', (WidgetTester tester) async {
      await tester.pumpWidget(createScreen());

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'CurrentPass@1');
      await tester.enterText(textFields.at(1), 'Short1!');
      await tester.enterText(textFields.at(2), 'Short1!');

      await tester.tap(find.text('UPDATE PASSWORD'));
      await tester.pump();

      expect(find.text('Password must be at least 8 characters'), findsOneWidget);
    });

    testWidgets('Rejects new password without uppercase letter', (WidgetTester tester) async {
      await tester.pumpWidget(createScreen());

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'CurrentPass@1');
      await tester.enterText(textFields.at(1), 'password123!');
      await tester.enterText(textFields.at(2), 'password123!');

      await tester.tap(find.text('UPDATE PASSWORD'));
      await tester.pump();

      expect(find.text('Password must contain at least one uppercase letter (A–Z)'), findsOneWidget);
    });

    testWidgets('Rejects new password without lowercase letter', (WidgetTester tester) async {
      await tester.pumpWidget(createScreen());

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'CurrentPass@1');
      await tester.enterText(textFields.at(1), 'PASSWORD123!');
      await tester.enterText(textFields.at(2), 'PASSWORD123!');

      await tester.tap(find.text('UPDATE PASSWORD'));
      await tester.pump();

      expect(find.text('Password must contain at least one lowercase letter (a–z)'), findsOneWidget);
    });

    testWidgets('Rejects new password without digit', (WidgetTester tester) async {
      await tester.pumpWidget(createScreen());

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'CurrentPass@1');
      await tester.enterText(textFields.at(1), 'PasswordOnly!');
      await tester.enterText(textFields.at(2), 'PasswordOnly!');

      await tester.tap(find.text('UPDATE PASSWORD'));
      await tester.pump();

      expect(find.text('Password must contain at least one digit (0–9)'), findsOneWidget);
    });

    testWidgets('Rejects new password without special character', (WidgetTester tester) async {
      await tester.pumpWidget(createScreen());

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'CurrentPass@1');
      await tester.enterText(textFields.at(1), 'Password123');
      await tester.enterText(textFields.at(2), 'Password123');

      await tester.tap(find.text('UPDATE PASSWORD'));
      await tester.pump();

      expect(find.text('Password must contain at least one special character (!@#\$%...)'), findsOneWidget);
    });

    testWidgets('Rejects mismatched confirm password', (WidgetTester tester) async {
      await tester.pumpWidget(createScreen());

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'CurrentPass@1');
      await tester.enterText(textFields.at(1), 'ValidPassword123!');
      await tester.enterText(textFields.at(2), 'DifferentPassword123!');

      await tester.tap(find.text('UPDATE PASSWORD'));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('Accepts new password that satisfies all requirements and submits', (WidgetTester tester) async {
      await tester.pumpWidget(createScreen());

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'CurrentPass@1');
      await tester.enterText(textFields.at(1), 'ValidPass123@#');
      await tester.enterText(textFields.at(2), 'ValidPass123@#');

      await tester.tap(find.text('UPDATE PASSWORD'));
      await tester.pump();

      // No validation errors displayed
      expect(find.text('Password must be at least 8 characters'), findsNothing);
      expect(find.text('Password must contain at least one uppercase letter (A–Z)'), findsNothing);
      expect(find.text('Password must contain at least one lowercase letter (a–z)'), findsNothing);
      expect(find.text('Password must contain at least one digit (0–9)'), findsNothing);
      expect(find.text('Password must contain at least one special character (!@#\$%...)'), findsNothing);
      expect(find.text('Passwords do not match'), findsNothing);
    });

    testWidgets('Toggles password visibility when eye icon clicked', (WidgetTester tester) async {
      await tester.pumpWidget(createScreen());

      // Eye icons are present
      final eyeIcons = find.byIcon(Icons.visibility_off_outlined);
      expect(eyeIcons, findsNWidgets(3));

      // Tap the first eye icon to toggle visibility
      await tester.tap(eyeIcons.first);
      await tester.pump();

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsNWidgets(2));
    });
  });
}
