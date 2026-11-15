import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:echo_alert/main.dart';
import 'package:echo_alert/screens/home_screen.dart';
import 'package:echo_alert/screens/live_detection_screen.dart';
import 'package:echo_alert/screens/history_screen.dart';
import 'package:echo_alert/screens/settings_screen.dart';
import 'package:echo_alert/screens/alert_overlay.dart';

void main() {
  group('EchoAlert Widget Tests', () {
    testWidgets('EchoAlertApp renders with NavigationBar and 4 core tabs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const EchoAlertApp());
      await tester.pump();

      // Verify app title in AppBar
      expect(find.text('EchoAlert'), findsOneWidget);

      // Verify NavigationBar destinations
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Live'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('HomeScreen renders listening controls and quick stats', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pump();

      expect(find.text('EchoAlert'), findsOneWidget);
      expect(find.text('Alerts Today'), findsOneWidget);
      expect(find.text('Monitored Sounds'), findsOneWidget);
      expect(find.byIcon(Icons.mic_off), findsOneWidget);
      expect(
        find.text('Tap the button below to start background listening'),
        findsOneWidget,
      );
    });

    testWidgets('LiveDetectionScreen renders visualizer and feed sections', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: LiveDetectionScreen()));
      await tester.pump();

      expect(find.text('Live Detection'), findsOneWidget);
      expect(find.text('Recent Detections Feed'), findsOneWidget);
      expect(find.text('No Active Sound Detected'), findsOneWidget);
    });

    testWidgets('HistoryScreen renders search bar and category filter chips', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: HistoryScreen()));
      await tester.pumpAndSettle();

      expect(find.text('History Log'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Doorbell'), findsOneWidget);
      expect(find.text('Smoke / Fire Alarm'), findsWidgets);
    });

    testWidgets(
      'SettingsScreen renders categories and test diagnostic buttons',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Settings'), findsOneWidget);
        expect(find.text('Monitored Sound Categories'), findsOneWidget);
        expect(find.text('Test Notification & Vibration'), findsOneWidget);
        expect(find.text('About EchoAlert'), findsOneWidget);
      },
    );

    testWidgets(
      'AlertOverlay renders warning modal with sound label and dismiss button',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AlertOverlay(
                detectedSound: 'Smoke / Fire Alarm',
                confidence: 0.96,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('ALERT'), findsOneWidget);
        expect(find.text('Smoke / Fire Alarm'), findsOneWidget);
        expect(find.text('DISMISS'), findsOneWidget);
        expect(find.byIcon(Icons.warning_rounded), findsOneWidget);
      },
    );
  });
}
