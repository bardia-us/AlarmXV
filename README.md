# AlarmXV

AlarmXV is an Android-first Flutter alarm clock designed for heavy sleepers.
It schedules exact alarms with Android `AlarmManager`, rings from a foreground
service, and requires Math, Memory, or Shake challenges before dismissal.

## Features

- Exact weekly alarms that survive app closure, idle mode, and device reboot
- Full-screen lock-screen alarm flow with a Display-over-apps fallback
- Separate ringing and timed challenge phases
- Math, Memory, and accelerometer-based Shake challenges
- Per-alarm snooze and configurable Wake-up Checker
- Silent 60-second Wake-up Checker confirmation notification
- Native Android picker for the phone's installed alarm sounds and ringtones
- Maximum alarm-stream volume while ringing, restored afterward
- Local storage with no account or network dependency

## Android access

For reliable behavior, grant the access cards shown inside the app:

- Alarms & reminders / Exact alarms
- Notifications
- Full-screen alarms where Android exposes that setting
- Display over other apps

## Build

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Release builds require a private keystore and `android/key.properties`. A safe
template is provided at `android/key.properties.example`; real signing files are
excluded by `.gitignore` and must never be committed.

## Architecture

Flutter owns the alarm list, editor, local model, and settings UI. Native Android
code owns exact scheduling, boot restoration, foreground ringing, lock-screen and
overlay presentation, audio/vibration, Wake-up Checker delivery, and challenge
timeout recovery.

## Current release

Version `1.1.0` (`versionCode 2`). See [CHANGELOG.md](CHANGELOG.md).
