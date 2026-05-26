import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_bridge/event_channel/event_channel_screen.dart';

void main() {
  group('EventChannelScreen', () {
    Widget buildSubject() {
      return const MaterialApp(home: EventChannelScreen());
    }

    testWidgets('shows placeholder text initially', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('Press Start to receive sensor data'), findsOneWidget);
      expect(find.text('Accelerometer'), findsOneWidget);
    });

    testWidgets('has Start and Stop buttons', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('Start'), findsOneWidget);
      expect(find.text('Stop'), findsOneWidget);
    });

    testWidgets('Stop button is disabled initially', (tester) async {
      await tester.pumpWidget(buildSubject());

      final stopButton = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Stop'),
      );
      expect(stopButton.onPressed, isNull);
    });

    testWidgets('shows "How it works" explanation card', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('How it works'), findsOneWidget);
      expect(find.textContaining('persistent stream'), findsOneWidget);
    });
  });
}
