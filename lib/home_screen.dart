import 'package:flutter/material.dart';
import 'method_channel/method_channel_screen.dart';
import 'event_channel/event_channel_screen.dart';
import 'pigeon/pigeon_screen.dart';
import 'ffi/ffi_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final demos = [
      _Demo(
        title: 'MethodChannel',
        subtitle: 'Request-response pattern for one-shot native calls',
        icon: Icons.swap_horiz,
        screen: const MethodChannelScreen(),
      ),
      _Demo(
        title: 'EventChannel',
        subtitle: 'Stream-based pattern for continuous native data',
        icon: Icons.stream,
        screen: const EventChannelScreen(),
      ),
      _Demo(
        title: 'Pigeon',
        subtitle: 'Type-safe code generation for platform channels',
        icon: Icons.auto_awesome,
        screen: const PigeonScreen(),
      ),
      _Demo(
        title: 'FFI',
        subtitle: 'Direct native library calls via dart:ffi',
        icon: Icons.memory,
        screen: const FfiScreen(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Platform Bridge')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: demos.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final demo = demos[index];
          return Card(
            child: ListTile(
              leading: Icon(demo.icon, size: 32),
              title: Text(demo.title),
              subtitle: Text(demo.subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => demo.screen),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Demo {
  const _Demo({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.screen,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget screen;
}
