import 'package:flutter/services.dart';

class SensorStream {
  static const _channel = EventChannel(
    'com.hendramarihot.platform_bridge/accelerometer',
  );

  late final Stream<AccelerometerEvent> accelerometerEvents = _channel
      .receiveBroadcastStream()
      .map(_parseEvent);

  static AccelerometerEvent _parseEvent(Object? event) {
    if (event is! Map) {
      throw FormatException('Expected a map sensor event, got $event');
    }
    final x = (event['x'] as num?)?.toDouble();
    final y = (event['y'] as num?)?.toDouble();
    final z = (event['z'] as num?)?.toDouble();
    if (x == null || y == null || z == null) {
      throw FormatException('Sensor event missing x/y/z values: $event');
    }
    return AccelerometerEvent(x: x, y: y, z: z);
  }
}

class AccelerometerEvent {
  const AccelerometerEvent({required this.x, required this.y, required this.z});

  final double x;
  final double y;
  final double z;

  @override
  String toString() =>
      'x: ${x.toStringAsFixed(2)}, y: ${y.toStringAsFixed(2)}, z: ${z.toStringAsFixed(2)}';
}
