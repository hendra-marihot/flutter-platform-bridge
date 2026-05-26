import 'package:flutter/services.dart';

class SensorStream {
  static const _channel = EventChannel(
    'com.hendramarihot.platform_bridge/accelerometer',
  );

  late final Stream<AccelerometerEvent> accelerometerEvents = _channel
      .receiveBroadcastStream()
      .map((event) {
        final data = Map<String, dynamic>.from(event as Map);
        return AccelerometerEvent(
          x: (data['x'] as num).toDouble(),
          y: (data['y'] as num).toDouble(),
          z: (data['z'] as num).toDouble(),
        );
      });
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
