import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_bridge/home_screen.dart';
import 'package:platform_bridge/method_channel/method_channel_screen.dart';
import 'package:platform_bridge/event_channel/event_channel_screen.dart';
import 'package:platform_bridge/pigeon/pigeon_screen.dart';
import 'package:platform_bridge/ffi/ffi_screen.dart';

void main() {
  Widget buildSubject() {
    return const MaterialApp(home: HomeScreen());
  }

  group('HomeScreen', () {
    testWidgets('displays all four demo entries', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('MethodChannel'), findsOneWidget);
      expect(find.text('EventChannel'), findsOneWidget);
      expect(find.text('Pigeon'), findsOneWidget);
      expect(find.text('FFI'), findsOneWidget);
    });

    testWidgets('displays subtitles for each demo', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(
        find.text('Request-response pattern for one-shot native calls'),
        findsOneWidget,
      );
      expect(
        find.text('Stream-based pattern for continuous native data'),
        findsOneWidget,
      );
      expect(
        find.text('Type-safe code generation for platform channels'),
        findsOneWidget,
      );
      expect(
        find.text('Direct native library calls via dart:ffi'),
        findsOneWidget,
      );
    });

    testWidgets('shows app title', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('Platform Bridge'), findsOneWidget);
    });

    testWidgets('navigates to MethodChannelScreen on tap', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.tap(find.text('MethodChannel'));
      await tester.pumpAndSettle();

      expect(find.byType(MethodChannelScreen), findsOneWidget);
    });

    testWidgets('navigates to EventChannelScreen on tap', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.tap(find.text('EventChannel'));
      await tester.pumpAndSettle();

      expect(find.byType(EventChannelScreen), findsOneWidget);
    });

    testWidgets('navigates to PigeonScreen on tap', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.tap(find.text('Pigeon'));
      await tester.pumpAndSettle();

      expect(find.byType(PigeonScreen), findsOneWidget);
    });

    testWidgets('navigates to FfiScreen on tap', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.tap(find.text('FFI'));
      await tester.pumpAndSettle();

      expect(find.byType(FfiScreen), findsOneWidget);
    });
  });
}
