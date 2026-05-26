// dart:ffi enables direct calls into C/C++ native libraries without any
// platform channel overhead. This screen demonstrates the API concepts.
// To run the strlen example in production, add package:ffi which provides
// Utf8 helpers and the calloc allocator.

import 'package:flutter/material.dart';

class FfiScreen extends StatelessWidget {
  const FfiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('dart:ffi')),
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
                        Icons.memory,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'What is dart:ffi?',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'dart:ffi (Foreign Function Interface) lets Dart call C/C++ '
                    'functions directly from the Dart VM, bypassing the Flutter '
                    'engine message codec entirely. It gives zero-copy access to '
                    'native memory and sub-microsecond call overhead — ideal for '
                    'compute-heavy libraries like codecs, crypto, or SIMD math.',
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
            'Example: calling strlen from libc',
            style: theme.textTheme.labelMedium,
          ),
          const SizedBox(height: 4),
          _CodeBlock(
            theme: theme,
            code: '''
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart'; // provides Utf8, calloc

// 1. Declare the C signature as Dart typedefs
typedef StrlenNative = Int32 Function(Pointer<Utf8>);
typedef StrlenDart   = int   Function(Pointer<Utf8>);

// 2. Open the native library
final lib = Platform.isAndroid
    ? DynamicLibrary.open('libc.so')
    : DynamicLibrary.process(); // iOS: libc is statically linked

// 3. Look up the symbol — type-checked at lookup time
final strlen = lib.lookupFunction<StrlenNative, StrlenDart>('strlen');

// 4. Allocate native memory, call, free
final ptr = 'Hello from dart:ffi!'.toNativeUtf8();
final len = strlen(ptr); // Direct C ABI call — no codec encoding
calloc.free(ptr);
// len == 20''',
          ),
          const SizedBox(height: 16),
          Text('Memory model', style: theme.textTheme.labelMedium),
          const SizedBox(height: 4),
          _CodeBlock(
            theme: theme,
            code: '''
// Dart heap  ──────────────────────────────────  Native heap
//
//  Dart String "Hello"
//       │
//       │  toNativeUtf8()         calloc.free(ptr)
//       ▼                               │
//  Pointer<Utf8> ──► [H|e|l|l|o|\\0] ──►freed
//                     (native memory, not GC'd)
//
// Key: native memory is NOT managed by the Dart GC.
//      Always free pointers you allocate.''',
          ),
          const SizedBox(height: 16),
          Text(
            'Calling a custom C library',
            style: theme.textTheme.labelMedium,
          ),
          const SizedBox(height: 4),
          _CodeBlock(
            theme: theme,
            code: '''
// native/src/fast_hash.c
// int32_t fast_hash(const uint8_t* data, int32_t len) { ... }

// In CMakeLists.txt (Android) or Podfile (iOS), compile the .c file
// into a shared library: libfast_hash.so / libfast_hash.dylib

typedef _HashNative = Int32 Function(Pointer<Uint8>, Int32);
typedef _HashDart   = int   Function(Pointer<Uint8>, int);

final lib = DynamicLibrary.open('libfast_hash.so');
final fastHash = lib.lookupFunction<_HashNative, _HashDart>('fast_hash');

// Allocate and fill a buffer, then call
final buf = calloc<Uint8>(1024);
// ... fill buf ...
final hash = fastHash(buf, 1024);
calloc.free(buf);''',
          ),
          const SizedBox(height: 16),
          _TradeoffsCard(theme: theme),
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

class _TradeoffsCard extends StatelessWidget {
  const _TradeoffsCard({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    const rows = [
      _Row(
        'Performance',
        'No serialization, direct C ABI call',
        'Encodes args via StandardMethodCodec',
      ),
      _Row(
        'Complexity',
        'Manual pointer and memory management',
        'Higher-level, strings/maps handled for you',
      ),
      _Row(
        'Use case',
        'CPU-intensive libs, SIMD, codecs, crypto',
        'OS APIs, UI events, device hardware',
      ),
      _Row(
        'Platform',
        'Single C binary works on Android & iOS',
        'Separate handler implementation per platform',
      ),
      _Row(
        'Safety',
        'Unsafe by default — crashes on bad pointer',
        'Exceptions caught and forwarded to Dart',
      ),
    ];

    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('FFI vs MethodChannel', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            ...rows.map((r) => _TradeoffRow(row: r, theme: theme)),
          ],
        ),
      ),
    );
  }
}

class _TradeoffRow extends StatelessWidget {
  const _TradeoffRow({required this.row, required this.theme});

  final _Row row;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(row.aspect, style: theme.textTheme.labelSmall),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.bolt,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'FFI: ${row.ffi}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.swap_horiz,
                      size: 14,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'MC: ${row.mc}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Row {
  const _Row(this.aspect, this.ffi, this.mc);

  final String aspect;
  final String ffi;
  final String mc;
}
