# Flutter Platform Bridge

A Flutter app that implements every pattern for communicating between Dart and
native platform code — MethodChannel, EventChannel, Pigeon, and dart:ffi — with
working Android handlers, a full test suite, and CI.

I built this to demonstrate a skill that's fundamental to senior-level Flutter
work: understanding how the framework boundary actually works, not just which
package to install. It's one piece of a broader portfolio; each repo isolates a
different area of mobile engineering depth.

<!-- TODO: Add a ~10s GIF showing:
  Home screen → tap MethodChannel → battery result appears → back →
  tap EventChannel → tap Start → live accelerometer data streaming.
  Capture on a real Android device for authentic sensor data.
  Recommended: Android Studio screen recorder or `scrcpy` with `ffmpeg` to GIF.
  Then uncomment the line below:
![Demo](docs/demo.gif)
-->

## What's here

| Pattern | Screen | Status | When you'd use it |
|---------|--------|--------|-------------------|
| MethodChannel | Battery level + state | Functional | One-shot native calls: battery, clipboard, device info |
| EventChannel | Live accelerometer | Functional | Continuous native streams: sensors, location, Bluetooth |
| Pigeon | Concept showcase | Display-only | Any channel call at scale — eliminates stringly-typed boilerplate |
| dart:ffi | Concept showcase | Display-only | C/C++ libraries: image processing, crypto, ML inference |

The two functional demos make real native calls through Android's BatteryManager
and SensorManager. The two concept screens show annotated code walkthroughs and
tradeoff comparisons — they exist to demonstrate awareness of the full landscape,
not to pad the demo count.

<!-- TODO: Review this section — the reasoning was inferred from the code, not
  from your words. Rewrite anything that doesn't match your actual thinking. -->
## Decisions and tradeoffs

### Zero external dependencies

The only dependencies are `flutter`, `flutter_test`, and `flutter_lints`. That's
deliberate. This project is about the platform boundary itself — adding packages
would obscure whether I understand the underlying mechanism or just know which
import to reach for. Every line of channel code, serialization handling, and
lifecycle management is visible in the repo.

### Two functional, two conceptual

I implemented MethodChannel and EventChannel end-to-end because they're the
patterns a Flutter developer actually writes by hand. Pigeon and FFI are shown as
annotated code walkthroughs with tradeoff tables because implementing them would
add build complexity (code generation, C compilation) without demonstrating
additional judgment — the interesting decision with Pigeon is *when* to adopt it,
not how to run `dart run pigeon`.

### Stream caching with `late final`

`SensorStream.accelerometerEvents` is a `late final` field, not a getter. This
matters: `EventChannel.receiveBroadcastStream()` creates a new native listener
subscription each time it's called. A getter that calls it on every access would
silently leak native sensor listeners. The `late final` pattern ensures one
native subscription per `SensorStream` instance, with `onListen`/`onCancel`
firing correctly on each Dart subscribe/unsubscribe cycle. I found this bug
during development — the fix is small but the failure mode is subtle.

### `mounted` guards after every await

`MethodChannelScreen._fetchBatteryLevel()` has four `mounted` checks — after the
service calls, in both catch blocks, and in `finally`. Verbose, but every async
gap in a StatefulWidget is a potential `setState`-after-dispose crash. I'd rather
be explicit than debug a race condition.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  Flutter (Dart)                                                 │
│                                                                 │
│  MethodChannelScreen ──► BatteryService ──► MethodChannel ──────┤──►
│                          (typed async)      (binary codec)      │
│                                                                 │   Native (Kotlin)
│  EventChannelScreen ──► SensorStream ──► EventChannel ──────────┤──►
│                         (late final       (broadcast stream)    │
│                          cached stream)                         │
│                                                                 │   MainActivity.kt
│  PigeonScreen ─────── display-only ─────────────────────────────┤   ├─ MethodCallHandler
│  FfiScreen ────────── display-only ─────────────────────────────┤   │  getBatteryLevel()
└─────────────────────────────────────────────────────────────────┘   │  getBatteryState()
                                                                      │  getBatteryInfo()
                                                                      │
                                                                      └─ AccelerometerStreamHandler
                                                                         onListen → registerListener
                                                                         onCancel → unregisterListener
```

Each pattern is self-contained in its own directory under `lib/`. The service
layer (`BatteryService`, `SensorStream`) wraps the raw channel and exposes typed
Dart APIs — the UI never touches `MethodChannel` or `EventChannel` directly.

On the native side, `MainActivity.kt` registers both handlers in
`configureFlutterEngine`. The accelerometer handler implements proper lifecycle
management: sensor listener is registered in `onListen` and unregistered in
`onCancel`, with references nulled out to avoid leaks.

## How the patterns compare

| | MethodChannel | EventChannel | Pigeon | dart:ffi |
|---|---|---|---|---|
| **Data flow** | Dart → Native → Dart | Native → Dart (stream) | Dart ↔ Native | Dart ↔ Native |
| **Type safety** | Runtime (Map) | Runtime (Map) | Compile-time (generated) | Compile-time (typedefs) |
| **Serialization** | StandardMethodCodec | StandardMethodCodec | StandardMethodCodec | None — direct ABI |
| **Boilerplate** | Manual per method | Manual handler | Code-generated | Manual typedefs |
| **Error model** | PlatformException | Stream onError | Typed exceptions | Native crashes / segfaults |
| **Best for** | One-shot calls | Continuous events | Scaling past 5+ methods | C/C++ library bindings |

## Testing platform code

Platform channels are awkward to test because the native side doesn't exist in
`flutter test`. The strategy here splits along that boundary:

**Fully testable** (100% coverage): `BatteryService` and `MethodChannelScreen`
are tested by intercepting the channel with
`TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler`.
This covers the happy path, null fallbacks, `PlatformException` propagation,
loading states, and error display — everything on the Dart side of the boundary.

**Partially testable** (~40-47%): `SensorStream` and `EventChannelScreen` can
verify stream caching (`identical(stream1, stream2)`) and initial widget state,
but the stream callback paths require a real native sensor. That's not a coverage
gap I'd try to close with more mocks — it would test the mock, not the code.

**30 tests total** across 6 files. CI gates at 60% overall, which is honest
given that half the screens are display-only and EventChannel callbacks need
hardware.

## What's not here

**iOS native handlers.** The Dart side is platform-agnostic, but I scoped native
implementation to Android. Adding iOS would mean Swift/CoreMotion for the
accelerometer and UIDevice for battery — same patterns, different APIs. The
architecture supports it without changes to the Dart layer.

**Live Pigeon codegen or FFI calls.** The concept screens show the code and
explain the tradeoffs. Making them functional would require build-time code
generation (Pigeon) and C compilation (FFI), adding toolchain complexity that
doesn't demonstrate additional engineering judgment for this project's purpose.

**State management, DI, networking.** Deliberately excluded. This repo is about
one thing. Those are covered in other portfolio projects.

## Project structure

```
lib/
├── main.dart                       Entry point
├── app.dart                        MaterialApp, Material 3 theming
├── home_screen.dart                Navigation hub (4 demo cards)
├── method_channel/
│   ├── battery_service.dart        Typed MethodChannel wrapper
│   └── method_channel_screen.dart  Battery demo UI + state management
├── event_channel/
│   ├── sensor_stream.dart          Typed EventChannel wrapper (late final cache)
│   └── event_channel_screen.dart   Live accelerometer UI + start/stop lifecycle
├── pigeon/
│   └── pigeon_screen.dart          Code walkthrough + comparison table
└── ffi/
    └── ffi_screen.dart             Code walkthrough + memory model diagram

android/app/src/main/kotlin/.../
└── MainActivity.kt                 BatteryManager + SensorManager handlers (99 lines)

test/                               30 tests across 6 files, mirroring lib/ structure
```

## Running locally

Requires Flutter stable channel (Dart SDK 3.8+, per `pubspec.yaml`) and an
Android device or emulator — the MethodChannel and EventChannel demos make real
native calls that won't work without one.

```bash
flutter pub get
flutter run                         # Needs a connected device
flutter test                        # 30 tests, no device needed
flutter analyze                     # Lint + type checks
```

## CI

GitHub Actions runs on every push and PR to `main`: static analysis
(`--fatal-infos`), format enforcement (`dart format --set-exit-if-changed`),
tests with coverage, and a coverage gate that fails the build below 60%. The
gate uses raw `awk` on the lcov output rather than requiring the `lcov` CLI —
one less tool dependency in the pipeline.

## What I'd do next

1. **iOS parity** — Swift handlers for battery (UIDevice) and accelerometer
   (CMMotionManager), same channel names, no Dart changes needed.
2. **Make Pigeon functional** — run the codegen end-to-end to show the generated
   type-safe API replacing raw MethodChannel calls. This is the strongest
   upgrade because Pigeon is what you'd actually adopt in a production codebase
   scaling past a handful of channel methods.
3. **Bidirectional communication** — add an example where native code initiates a
   call to Dart (e.g., push notifications or deep links), showing the reverse
   direction of the bridge.

## License

Copyright 2026 Hendra Marihot. Apache License 2.0 — see [LICENSE](LICENSE) for details.
