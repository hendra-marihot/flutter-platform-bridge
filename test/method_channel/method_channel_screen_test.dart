import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_bridge/method_channel/method_channel_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.hendramarihot.platform_bridge/battery');

  void setUpMockChannel({
    int level = 85,
    String state = 'discharging',
    String technology = 'Li-ion',
  }) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'getBatteryInfo':
              return {'level': level, 'state': state, 'technology': technology};
            default:
              throw PlatformException(code: 'NOT_IMPLEMENTED');
          }
        });
  }

  void clearMockChannel() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  }

  Widget buildSubject() {
    return const MaterialApp(home: MethodChannelScreen());
  }

  group('MethodChannelScreen', () {
    testWidgets('shows placeholder text initially', (tester) async {
      setUpMockChannel();
      addTearDown(clearMockChannel);

      await tester.pumpWidget(buildSubject());

      expect(find.text('Tap the button to fetch battery info'), findsOneWidget);
      expect(find.text('Battery Info'), findsOneWidget);
    });

    testWidgets('displays battery info after tapping button', (tester) async {
      setUpMockChannel(level: 85, state: 'discharging', technology: 'Li-ion');
      addTearDown(clearMockChannel);

      await tester.pumpWidget(buildSubject());
      await tester.tap(find.text('Get Battery Info'));
      await tester.pumpAndSettle();

      expect(find.text('85%'), findsOneWidget);
      expect(find.text('State: discharging'), findsOneWidget);
      expect(find.text('Technology: Li-ion'), findsOneWidget);
    });

    testWidgets('shows friendly message when level is unavailable', (
      tester,
    ) async {
      setUpMockChannel(level: -1, state: 'unknown', technology: 'unknown');
      addTearDown(clearMockChannel);

      await tester.pumpWidget(buildSubject());
      await tester.tap(find.text('Get Battery Info'));
      await tester.pumpAndSettle();

      expect(find.text('Battery level unavailable'), findsOneWidget);
      expect(find.text('-1%'), findsNothing);
    });

    testWidgets('shows error when PlatformException occurs', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            throw PlatformException(
              code: 'UNAVAILABLE',
              message: 'Battery not available',
            );
          });
      addTearDown(clearMockChannel);

      await tester.pumpWidget(buildSubject());
      await tester.tap(find.text('Get Battery Info'));
      await tester.pumpAndSettle();

      expect(find.text('Battery not available'), findsOneWidget);
    });

    testWidgets('shows loading indicator and disables button during fetch', (
      tester,
    ) async {
      final completer = Completer<Map<Object?, Object?>>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'getBatteryInfo') return completer.future;
            return null;
          });
      addTearDown(clearMockChannel);

      await tester.pumpWidget(buildSubject());
      await tester.tap(find.text('Get Battery Info'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final button = tester.widget<FilledButton>(
        find.bySubtype<FilledButton>(),
      );
      expect(button.onPressed, isNull);

      completer.complete({
        'level': 85,
        'state': 'discharging',
        'technology': 'Li-ion',
      });
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows "How it works" explanation card', (tester) async {
      setUpMockChannel();
      addTearDown(clearMockChannel);

      await tester.pumpWidget(buildSubject());

      expect(find.text('How it works'), findsOneWidget);
      expect(find.textContaining('request-response pattern'), findsOneWidget);
    });
  });
}
