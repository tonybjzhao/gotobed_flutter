# Sleep Nudger MVP

Sleep Nudger is a minimal Flutter app that helps users go to bed on time with a gentle reminder, a stronger bedtime reminder, snooze support, and a next-morning streak summary.

## How to run

1. Install Flutter 3.35 or later.
2. From the project root run `flutter pub get`.
3. Launch on a simulator or device with `flutter run`.
4. Grant notification permission on Android or iOS when prompted.

## Package choices

- `shared_preferences`: simple local-only persistence for settings, nightly state, and streak
- `flutter_local_notifications`: local scheduling for bedtime nudges
- `timezone`: timezone-safe scheduling primitives used by the notifications package
- `flutter_timezone`: lightweight bridge to the device timezone name, which `timezone` alone does not provide

## Current MVP limitations

- morning summary is resolved when the app is opened after 6:00 AM, not in the background
- reminder timing on Android can drift slightly because the app avoids exact-alarm permissions in v1
- snooze is controlled in-app only and does not expose notification action buttons yet
- state is local to one device only
- the project still contains legacy files from the previous repo history, but the active app entrypoint is the Sleep Nudger MVP under `lib/`

## Next planned features

- notification action buttons for confirm and snooze
- better multi-day history
- optional wind-down tips
- optional soft accountability features
- more polished onboarding and visual states
