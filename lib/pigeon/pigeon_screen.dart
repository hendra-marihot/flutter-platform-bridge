import 'package:flutter/material.dart';

class PigeonScreen extends StatelessWidget {
  const PigeonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Pigeon')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'What is Pigeon?',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pigeon generates type-safe platform channel code from a single Dart '
                    'definition file. Instead of writing string-keyed method calls and '
                    'manually casting Map values, you define an @HostApi or @FlutterApi '
                    'interface once — Pigeon generates the boilerplate for both Dart and '
                    'Kotlin/Swift.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Definition file (pigeons/battery_api.dart)',
            style: theme.textTheme.labelMedium,
          ),
          const SizedBox(height: 4),
          _CodeBlock(
            theme: theme,
            code: '''
import 'package:pigeon/pigeon.dart';

class BatteryInfo {
  late int level;
  late String state;
  late String technology;
}

@HostApi()
abstract class BatteryHostApi {
  int getBatteryLevel();
  String getBatteryState();
  BatteryInfo getBatteryInfo();
}''',
          ),
          const SizedBox(height: 16),
          Text('Generated Dart usage', style: theme.textTheme.labelMedium),
          const SizedBox(height: 4),
          _CodeBlock(
            theme: theme,
            code: '''
// Auto-generated — do not edit.
// Run: dart run pigeon --input pigeons/battery_api.dart

final api = BatteryHostApi();
final info = await api.getBatteryInfo();
// info.level  → int (not dynamic)
// info.state  → String (not dynamic)
// Full null safety, no manual Map casting''',
          ),
          const SizedBox(height: 16),
          Text('Generated Kotlin stub', style: theme.textTheme.labelMedium),
          const SizedBox(height: 4),
          _CodeBlock(
            theme: theme,
            code: '''
// Auto-generated — implement in native code
interface BatteryHostApi {
  fun getBatteryLevel(): Long
  fun getBatteryState(): String
  fun getBatteryInfo(): BatteryInfo

  companion object {
    fun setUp(binaryMessenger: BinaryMessenger, api: BatteryHostApi?) { ... }
  }
}''',
          ),
          const SizedBox(height: 16),
          _ComparisonCard(theme: theme),
        ],
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.theme, required this.code});

  final ThemeData theme;
  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text(
          code,
          style: theme.textTheme.bodySmall?.copyWith(
            fontFamily: 'monospace',
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pigeon vs raw MethodChannel',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            _ComparisonRow(
              theme: theme,
              aspect: 'Type safety',
              raw: 'Manual cast from dynamic',
              pigeon: 'Strongly-typed generated API',
            ),
            _ComparisonRow(
              theme: theme,
              aspect: 'Boilerplate',
              raw: 'Write for each platform',
              pigeon: 'Single definition, auto-generated',
            ),
            _ComparisonRow(
              theme: theme,
              aspect: 'Refactoring',
              raw: 'Update strings manually',
              pigeon: 'Change definition, regenerate',
            ),
            _ComparisonRow(
              theme: theme,
              aspect: 'Null safety',
              raw: 'Manual null checks',
              pigeon: 'Enforced by generated code',
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.theme,
    required this.aspect,
    required this.raw,
    required this.pigeon,
  });

  final ThemeData theme;
  final String aspect;
  final String raw;
  final String pigeon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(aspect, style: theme.textTheme.labelSmall),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.remove_circle_outline,
                      size: 14,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(raw, style: theme.textTheme.bodySmall),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(pigeon, style: theme.textTheme.bodySmall),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
