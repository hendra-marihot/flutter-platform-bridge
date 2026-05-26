import 'package:flutter_test/flutter_test.dart';
import 'package:platform_bridge/event_channel/sensor_stream.dart';

void main() {
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
  });
}
