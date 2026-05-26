import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'battery_service.dart';

class MethodChannelScreen extends StatefulWidget {
  const MethodChannelScreen({super.key});

  @override
  State<MethodChannelScreen> createState() => _MethodChannelScreenState();
}

class _MethodChannelScreenState extends State<MethodChannelScreen> {
  final _batteryService = BatteryService();
  int? _batteryLevel;
  String? _batteryState;
  String? _error;
  bool _loading = false;

  Future<void> _fetchBatteryLevel() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final level = await _batteryService.getBatteryLevel();
      final state = await _batteryService.getBatteryState();
      if (!mounted) return;
      setState(() {
        _batteryLevel = level;
        _batteryState = state;
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message ?? 'Error: ${e.code}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('MethodChannel')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Battery Level', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 16),
                    if (_loading)
                      const CircularProgressIndicator()
                    else if (_error != null)
                      Text(
                        _error!,
                        style: TextStyle(color: theme.colorScheme.error),
                      )
                    else if (_batteryLevel != null)
                      Column(
                        children: [
                          Text(
                            '$_batteryLevel%',
                            style: theme.textTheme.displayMedium?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          Text('State: $_batteryState'),
                        ],
                      )
                    else
                      Text(
                        'Tap the button to fetch battery info',
                        style: theme.textTheme.bodyLarge,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loading ? null : _fetchBatteryLevel,
              icon: const Icon(Icons.battery_full),
              label: const Text('Get Battery Level'),
            ),
            const SizedBox(height: 32),
            Card(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('How it works', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Text(
                      'MethodChannel uses a request-response pattern. '
                      'Dart sends a method name + arguments to the native side, '
                      'which processes the request and returns a result. '
                      'Data is serialized via StandardMethodCodec (binary).',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
