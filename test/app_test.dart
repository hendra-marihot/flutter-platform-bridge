import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_bridge/app.dart';
import 'package:platform_bridge/home_screen.dart';

void main() {
  group('PlatformBridgeApp', () {
    testWidgets('renders MaterialApp with HomeScreen', (tester) async {
      await tester.pumpWidget(const PlatformBridgeApp());

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('does not show debug banner', (tester) async {
      await tester.pumpWidget(const PlatformBridgeApp());

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.debugShowCheckedModeBanner, isFalse);
    });

    testWidgets('uses Material 3', (tester) async {
      await tester.pumpWidget(const PlatformBridgeApp());

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.theme?.useMaterial3, isTrue);
    });

    testWidgets('has dark theme configured', (tester) async {
      await tester.pumpWidget(const PlatformBridgeApp());

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.darkTheme, isNotNull);
      expect(app.darkTheme?.brightness, Brightness.dark);
    });
  });
}
