import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_bridge/method_channel/method_channel_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.hendramarihot.platform_bridge/battery');

  void setUpMockChannel({int level = 85, String state = 'discharging'}) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'getBatteryLevel':
              return level;
            case 'getBatteryState':
              return state;
            case 'getBatteryInfo':
              return {'level': level, 'state': state, 'technology': 'Li-ion'};
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
      expect(find.text('Battery Level'), findsOneWidget);
    });

    testWidgets('displays battery level after tapping button', (tester) async {
      setUpMockChannel(level: 85, state: 'discharging');
      addTearDown(clearMockChannel);

      await tester.pumpWidget(buildSubject());
      await tester.tap(find.text('Get Battery Level'));
      await tester.pumpAndSettle();

      expect(find.text('85%'), findsOneWidget);
      expect(find.text('State: discharging'), findsOneWidget);
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
      await tester.tap(find.text('Get Battery Level'));
      await tester.pumpAndSettle();

      expect(find.text('Battery not available'), findsOneWidget);
    });

    testWidgets('shows loading indicator during fetch', (tester) async {
      final completer = Completer<int>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'getBatteryLevel') return completer.future;
            if (call.method == 'getBatteryState') return 'discharging';
            return null;
          });
      addTearDown(clearMockChannel);

      await tester.pumpWidget(buildSubject());
      await tester.tap(find.text('Get Battery Level'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete(85);
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
