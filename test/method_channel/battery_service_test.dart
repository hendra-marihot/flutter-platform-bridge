import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_bridge/method_channel/battery_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.hendramarihot.platform_bridge/battery');
  final service = BatteryService();

  void setUpMock(Future<Object?> Function(MethodCall) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, handler);
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });
  }

  group('BatteryService', () {
    group('getBatteryLevel', () {
      test('returns level from native', () async {
        setUpMock((call) async {
          if (call.method == 'getBatteryLevel') return 85;
          return null;
        });

        expect(await service.getBatteryLevel(), 85);
      });

      test('returns -1 when native returns null', () async {
        setUpMock((call) async => null);

        expect(await service.getBatteryLevel(), -1);
      });

      test('propagates PlatformException from native', () async {
        setUpMock((call) async {
          throw PlatformException(
            code: 'UNAVAILABLE',
            message: 'Battery level not available',
          );
        });

        expect(
          () => service.getBatteryLevel(),
          throwsA(isA<PlatformException>()),
        );
      });
    });

    group('getBatteryState', () {
      test('returns state from native', () async {
        setUpMock((call) async {
          if (call.method == 'getBatteryState') return 'charging';
          return null;
        });

        expect(await service.getBatteryState(), 'charging');
      });

      test('returns "unknown" when native returns null', () async {
        setUpMock((call) async => null);

        expect(await service.getBatteryState(), 'unknown');
      });

      test('propagates PlatformException from native', () async {
        setUpMock((call) async {
          throw PlatformException(
            code: 'UNAVAILABLE',
            message: 'Battery state not available',
          );
        });

        expect(
          () => service.getBatteryState(),
          throwsA(isA<PlatformException>()),
        );
      });
    });

    group('getBatteryInfo', () {
      test('returns typed map from native', () async {
        setUpMock((call) async {
          if (call.method == 'getBatteryInfo') {
            return {'level': 72, 'state': 'charging', 'technology': 'Li-ion'};
          }
          return null;
        });

        final info = await service.getBatteryInfo();
        expect(info['level'], 72);
        expect(info['state'], 'charging');
        expect(info['technology'], 'Li-ion');
      });

      test('returns empty map when native returns null', () async {
        setUpMock((call) async => null);

        expect(await service.getBatteryInfo(), isEmpty);
      });
    });
  });
}
