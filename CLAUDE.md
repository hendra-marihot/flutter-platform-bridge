# CLAUDE.md — flutter-platform-bridge

## Project overview

`platform_bridge` is a Flutter demo app that showcases four different patterns for
communicating between Flutter (Dart) and native platform code. It is an **app**, not a
package. Each communication pattern lives in its own directory under `lib/`.

The four patterns demonstrated:

| Screen | Pattern | Status |
|---|---|---|
| MethodChannel | Request-response via `MethodChannel` | Functional (requires real device/emulator) |
| EventChannel | Continuous stream via `EventChannel` | Functional (requires real device/emulator) |
| Pigeon | Type-safe codegen showcase | Display-only (concept screen, no actual Pigeon codegen) |
| FFI | `dart:ffi` direct C call showcase | Display-only (concept screen, no actual FFI calls) |

Channel names are namespaced under `com.hendramarihot.platform_bridge/`.

## Directory layout

```
lib/
  main.dart                                   ← entry point
  app.dart                                    ← MaterialApp
  home_screen.dart                            ← navigation home
  method_channel/
    battery_service.dart                      ← BatteryService (MethodChannel client)
    method_channel_screen.dart                ← UI for battery demo
  event_channel/
    sensor_stream.dart                        ← SensorStream (EventChannel client)
    event_channel_screen.dart                 ← UI for accelerometer demo
  pigeon/
    pigeon_screen.dart                        ← display-only Pigeon concept screen
  ffi/
    ffi_screen.dart                           ← display-only FFI concept screen

android/
  app/src/main/kotlin/com/hendramarihot/platform_bridge/
    MainActivity.kt                           ← native handlers (battery + accelerometer)

test/
  app_test.dart                               ← MaterialApp config tests
  home_screen_test.dart                       ← navigation + rendering tests
  method_channel/
    battery_service_test.dart                 ← MethodChannel mock tests
    method_channel_screen_test.dart           ← widget interaction tests
  event_channel/
    sensor_stream_test.dart                   ← AccelerometerEvent, stream caching + parsing
    event_channel_screen_test.dart            ← widget + stream behavior (data/error/dispose)
```

## Build commands

```bash
# Fetch dependencies
flutter pub get

# Run on a connected device or emulator (required for channel demos)
flutter run

# Run the test suite
flutter test

# Analyze for lint and type errors
flutter analyze

# Auto-format all Dart files
dart format .
```

Note: `flutter run` without a device will fail. The MethodChannel and EventChannel demos
require a physical Android device or running emulator to function. The Pigeon and FFI
screens are display-only and work in any environment including `flutter test`.

## Architecture

Each communication pattern is self-contained in its own subdirectory:

- **method_channel/**: `BatteryService` wraps the `MethodChannel` and exposes typed async
  methods. `MethodChannelScreen` calls `getBatteryInfo()` for a single round-trip returning
  level, state, and technology, and manages loading/error/data state. A level outside
  `0..100` renders as "Battery level unavailable" rather than a raw percentage.
- **event_channel/**: `SensorStream` wraps the `EventChannel` and exposes a typed
  `Stream<AccelerometerEvent>`. `EventChannelScreen` subscribes in `_startListening()` and
  cancels in `_stopListening()` and `dispose()`.
- **pigeon/**: `PigeonScreen` is a static display screen showing code snippets. No
  generated Pigeon files exist yet.
- **ffi/**: `FfiScreen` is a static display screen showing `dart:ffi` code snippets.
  No actual FFI calls are made.

## Native code

**Android** (Kotlin): `android/app/src/main/kotlin/com/hendramarihot/platform_bridge/MainActivity.kt`

- `MethodChannel` handler for `getBatteryLevel`, `getBatteryState`, `getBatteryInfo` using
  `BatteryManager`. `getBatteryLevel` clamps to `0..100` (returns `-1` otherwise) because
  `getIntProperty` returns `Integer.MIN_VALUE` on some emulators; `getBatteryInfo` reads the
  real `EXTRA_TECHNOLOGY` from the sticky `ACTION_BATTERY_CHANGED` intent.
- `EventChannel` handler via `AccelerometerStreamHandler` using `SensorManager` /
  `SensorEventListener`. Sensor events are posted to the main thread before
  `EventSink.success` (the sink is `@UiThread`).
- Sensor listener is registered in `onListen` and unregistered in `onCancel`. Channel
  handlers are detached in `cleanUpFlutterEngine` to avoid leaking the Activity via a cached
  engine; `AccelerometerStreamHandler` holds an application `Context`, not the Activity.

**iOS**: No native handlers exist yet.

## Code conventions

Follow the project's existing Flutter/Dart style:

- 2-space indentation, max 100 characters per line.
- `const` constructors on every widget that allows it.
- Single quotes for all string literals.
- `super.key` in every widget constructor (never `Key? key` + `super(key: key)`).
- `final` for all variables unless reassignment is required.
- Use `Theme.of(context).colorScheme.*` — no hardcoded colors.
- Check `mounted` before calling `setState` after any `await`.
- Cancel `StreamSubscription`s in both `_stopListening()` and `dispose()`.
- Use typed exceptions: `on PlatformException catch (e)`, not bare `catch`.

## Testing

39 tests across 6 files. Run with `flutter test` or `flutter test --coverage`.

Mock MethodChannel in tests via:
```dart
TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
    .setMockMethodCallHandler(channel, handler);
```

Mock EventChannel streams via `setMockStreamHandler` + `MockStreamHandler.inline(...)`,
then drive the widget with `await tester.pump()` — never `pumpAndSettle()` while the
"Listening…" spinner is on screen (indefinite animation → test timeout).

## Gotchas

- `PlatformException.message` is `String?` — always provide a fallback (e.g.,
  `e.message ?? 'Error: ${e.code}'`) or the error will be silently swallowed.
- `EventChannel.receiveBroadcastStream()` returns a re-subscribable broadcast stream.
  Caching it as `late final` is correct — `onListen`/`onCancel` fire on each
  subscribe/unsubscribe cycle. Do NOT replace with a getter that calls
  `receiveBroadcastStream()` on every access (leaks native listeners).
- `flutter test --coverage` writes `coverage/lcov.info` but the `lcov` CLI may not be
  installed. Parse the file directly with awk (`LF:`/`LH:` lines) for CI.
- Sensor data is parsed defensively in `SensorStream._parseEvent`: malformed/partial native
  payloads throw a `FormatException` (surfaced via the screen's `onError`) instead of a raw
  `TypeError` that would tear down the whole stream on one bad frame.
- In widget tests, `.icon` buttons (`FilledButton.icon`, etc.) are private subtypes — use
  `find.bySubtype<FilledButton>()`, not `find.byType(FilledButton)` (which matches exact
  runtime type and finds nothing).
- Always run `dart format .` before committing — the project enforces formatting in CI.

## Important constraints

- MethodChannel and EventChannel demos require a real Android device or emulator. They will
  produce `PlatformException` errors on iOS simulator (no iOS handlers) or in unit tests
  without mocking.
- Pigeon and FFI screens are intentionally concept/display-only. The code snippets shown
  are illustrative and not executed.
- Do not add `pigeon` or `ffi` to `pubspec.yaml` dependencies unless making those screens
  functional.
