import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_bridge/event_channel/sensor_stream.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = EventChannel(
    'com.hendramarihot.platform_bridge/accelerometer',
  );

  void mockStream(void Function(MockStreamHandlerEventSink sink) emit) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
          channel,
          MockStreamHandler.inline(onListen: (arguments, sink) => emit(sink)),
        );
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(channel, null);
    });
  }

  group('AccelerometerEvent', () {
    test('toString formats to 2 decimal places', () {
      const event = AccelerometerEvent(x: 1.5, y: -2.3, z: 9.81);
      expect(event.toString(), 'x: 1.50, y: -2.30, z: 9.81');
    });

    test('toString rounds large values', () {
      const event = AccelerometerEvent(x: 999.999, y: -100.123, z: 0.001);
      expect(event.toString(), 'x: 1000.00, y: -100.12, z: 0.00');
    });
  });

  group('SensorStream', () {
    test('accelerometerEvents returns the same stream instance', () {
      final sensorStream = SensorStream();
      final stream1 = sensorStream.accelerometerEvents;
      final stream2 = sensorStream.accelerometerEvents;
      expect(identical(stream1, stream2), isTrue);
    });

    test('maps a well-formed native event to AccelerometerEvent', () async {
      mockStream((sink) => sink.success({'x': 1.0, 'y': 2.0, 'z': 3.0}));

      final event = await SensorStream().accelerometerEvents.first;

      expect(event.x, 1.0);
      expect(event.y, 2.0);
      expect(event.z, 3.0);
    });

    test('coerces integer values from native to double', () async {
      mockStream((sink) => sink.success({'x': 1, 'y': 2, 'z': 3}));

      final event = await SensorStream().accelerometerEvents.first;

      expect(event.x, 1.0);
      expect(event.y, 2.0);
      expect(event.z, 3.0);
    });

    test('emits FormatException on event missing a key', () {
      mockStream((sink) => sink.success({'x': 1.0, 'y': 2.0}));

      expect(
        SensorStream().accelerometerEvents.first,
        throwsA(isA<FormatException>()),
      );
    });

    test('emits FormatException on non-map payload', () {
      mockStream((sink) => sink.success('not a map'));

      expect(
        SensorStream().accelerometerEvents.first,
        throwsA(isA<FormatException>()),
      );
    });
  });
}
