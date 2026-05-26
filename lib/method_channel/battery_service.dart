import 'package:flutter/services.dart';

class BatteryService {
  static const _channel = MethodChannel(
    'com.hendramarihot.platform_bridge/battery',
  );

  Future<int> getBatteryLevel() async {
    final level = await _channel.invokeMethod<int>('getBatteryLevel');
    return level ?? -1;
  }

  Future<String> getBatteryState() async {
    final state = await _channel.invokeMethod<String>('getBatteryState');
    return state ?? 'unknown';
  }

  Future<Map<String, dynamic>> getBatteryInfo() async {
    final info = await _channel.invokeMethod<Map>('getBatteryInfo');
    return Map<String, dynamic>.from(info ?? {});
  }
}
