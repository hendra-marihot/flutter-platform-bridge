import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_bridge/event_channel/event_channel_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = EventChannel(
    'com.hendramarihot.platform_bridge/accelerometer',
  );

  void mockStream(
    void Function(MockStreamHandlerEventSink sink) onListen, {
    VoidCallback? onCancel,
  }) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
          channel,
          MockStreamHandler.inline(
            onListen: (arguments, sink) => onListen(sink),
            onCancel: (arguments) => onCancel?.call(),
          ),
        );
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(channel, null);
    });
  }

  Widget buildSubject() {
    return const MaterialApp(home: EventChannelScreen());
  }

  group('EventChannelScreen', () {
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

    testWidgets('renders sensor values and listening state after Start', (
      tester,
    ) async {
      mockStream((sink) => sink.success({'x': 1.0, 'y': 2.0, 'z': 3.0}));

      await tester.pumpWidget(buildSubject());
      await tester.tap(find.text('Start'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      expect(find.text('1.00'), findsOneWidget);
      expect(find.text('2.00'), findsOneWidget);
      expect(find.text('3.00'), findsOneWidget);
      expect(find.text('Listening…'), findsOneWidget);

      final stopButton = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Stop'),
      );
      expect(stopButton.onPressed, isNotNull);
    });

    testWidgets('shows error and stops listening on stream error', (
      tester,
    ) async {
      mockStream(
        (sink) => sink.error(
          code: 'NO_SENSOR',
          message: 'Accelerometer not available on this device',
        ),
      );

      await tester.pumpWidget(buildSubject());
      await tester.tap(find.text('Start'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      expect(
        find.text('Accelerometer not available on this device'),
        findsOneWidget,
      );
      expect(find.text('Listening…'), findsNothing);

      final startButton = tester.widget<FilledButton>(
        find.bySubtype<FilledButton>(),
      );
      expect(startButton.onPressed, isNotNull);
    });

    testWidgets('cancels the subscription on dispose', (tester) async {
      var cancelled = false;
      mockStream(
        (sink) => sink.success({'x': 0.0, 'y': 0.0, 'z': 0.0}),
        onCancel: () => cancelled = true,
      );

      await tester.pumpWidget(buildSubject());
      await tester.tap(find.text('Start'));
      await tester.pump();

      // Replace the screen with a different widget to trigger dispose().
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pump();

      expect(cancelled, isTrue);
    });
  });
}
