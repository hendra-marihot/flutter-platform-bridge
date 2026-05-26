import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'sensor_stream.dart';

class EventChannelScreen extends StatefulWidget {
  const EventChannelScreen({super.key});

  @override
  State<EventChannelScreen> createState() => _EventChannelScreenState();
}

class _EventChannelScreenState extends State<EventChannelScreen> {
  final _sensorStream = SensorStream();
  StreamSubscription<AccelerometerEvent>? _subscription;
  AccelerometerEvent? _latest;
  String? _error;
  bool _listening = false;

  void _startListening() {
    setState(() {
      _error = null;
      _listening = true;
    });
    _subscription = _sensorStream.accelerometerEvents.listen(
      (event) {
        if (mounted) setState(() => _latest = event);
      },
      onError: (Object error) {
        if (!mounted) return;
        final message = error is PlatformException
            ? (error.message ?? 'Error: ${error.code}')
            : error.toString();
        setState(() {
          _error = message;
          _listening = false;
        });
      },
      onDone: () {
        if (mounted) setState(() => _listening = false);
      },
    );
  }

  void _stopListening() {
    _subscription?.cancel();
    _subscription = null;
    setState(() => _listening = false);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('EventChannel')),
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
                    Text('Accelerometer', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 16),
                    if (_error != null)
                      Text(
                        _error!,
                        style: TextStyle(color: theme.colorScheme.error),
                      )
                    else if (_latest != null)
                      _AccelerometerDisplay(event: _latest!, theme: theme)
                    else
                      Text(
                        'Press Start to receive sensor data',
                        style: theme.textTheme.bodyLarge,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _listening ? null : _startListening,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _listening ? _stopListening : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                  ),
                ),
              ],
            ),
            if (_listening) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text('Listening…', style: theme.textTheme.bodySmall),
                ],
              ),
            ],
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
                      'EventChannel establishes a persistent stream from native to Dart. '
                      'The native side calls EventSink.success() for each event and '
                      'EventSink.error() for errors. Dart receives a broadcast Stream '
                      'that can be subscribed and cancelled independently. '
                      'The native handler is registered with setStreamHandler().',
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

class _AccelerometerDisplay extends StatelessWidget {
  const _AccelerometerDisplay({required this.event, required this.theme});

  final AccelerometerEvent event;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AxisRow(label: 'X', value: event.x, theme: theme),
        const SizedBox(height: 8),
        _AxisRow(label: 'Y', value: event.y, theme: theme),
        const SizedBox(height: 8),
        _AxisRow(label: 'Z', value: event.z, theme: theme),
      ],
    );
  }
}

class _AxisRow extends StatelessWidget {
  const _AxisRow({
    required this.label,
    required this.value,
    required this.theme,
  });

  final String label;
  final double value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final clamped = (value.abs() / 20.0).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 20,
          child: Text(label, style: theme.textTheme.labelMedium),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: LinearProgressIndicator(
            value: clamped,
            minHeight: 12,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 56,
          child: Text(
            value.toStringAsFixed(2),
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
