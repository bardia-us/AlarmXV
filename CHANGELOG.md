# Changelog

## 1.2.0+3

- Added a silent full-screen Wake-up Checker with a 60-second countdown.
- Fixed repeated Checker cycles after solving a Checker-failure alarm.
- Kept the Checker screen dismissible while leaving its silent notification active.
- Moved the large ringing clock down for better system-bar spacing.
- Added per-ABI signed Release APK outputs.

## 1.1.0+2

- Added a strict Ring → Start → timed Challenge flow.
- Added native challenge deadlines that restart the real alarm when missed.
- Added Display-over-apps recovery when the alarm Activity loses focus.
- Removed the in-app emergency dismissal and automatic ringing timeout.
- Guarded the Android alarm stream at maximum volume while ringing.
- Fixed Wake-up Checker so it posts a silent confirmation first and grants a
  full 60-second response window before scheduling a failure alarm.
- Prevented Wake-up Checker failure alarms when notifications are unavailable.
- Added the native Android alarm/ringtone picker for each alarm.
- Added release signing configuration without committing private key material.
