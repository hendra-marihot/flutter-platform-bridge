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
  Map<String, dynamic>? _info;
  String? _error;
  bool _loading = false;

  Future<void> _fetchBatteryInfo() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final info = await _batteryService.getBatteryInfo();
      if (!mounted) return;
      setState(() => _info = info);
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
                    Text('Battery Info', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 16),
                    if (_loading)
                      const CircularProgressIndicator()
                    else if (_error != null)
                      Text(
                        _error!,
                        style: TextStyle(color: theme.colorScheme.error),
                      )
                    else if (_info != null)
                      _BatteryInfoDisplay(info: _info!, theme: theme)
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
              onPressed: _loading ? null : _fetchBatteryInfo,
              icon: const Icon(Icons.battery_full),
              label: const Text('Get Battery Info'),
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
                      'getBatteryInfo returns level, state, and technology in a '
                      'single round-trip, serialized via StandardMethodCodec.',
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

class _BatteryInfoDisplay extends StatelessWidget {
  const _BatteryInfoDisplay({required this.info, required this.theme});

  final Map<String, dynamic> info;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final level = info['level'] as int?;
    final state = info['state'] as String? ?? 'unknown';
    final technology = info['technology'] as String?;
    final hasLevel = level != null && level >= 0;

    return Column(
      children: [
        if (hasLevel)
          Text(
            '$level%',
            style: theme.textTheme.displayMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          )
        else
          Text(
            'Battery level unavailable',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        Text('State: $state'),
        if (technology != null) Text('Technology: $technology'),
      ],
    );
  }
}
