# Normal alarm and task/surface polish

User request: preserve strict wake missions, add a separate ordinary alarm with free dismissal and phone/custom volume; fix duplicate Android tasks and sharp/opaque menu/footer surfaces. Keep the stronger light-clay reference and improve depth in dark mode without blur.

- [x] Read existing task flags, affinity, native lifecycle, audio guard, Flutter editor/menu/footer and checkpoint state.
- [x] Add additive mode/volume fields to Dart+Kotlin. Legacy alarms remain challenge mode. Normal mode ignores missions/checker without deleting saved configuration.
- [x] Unify app affinity and native singleTask launches/canonical intent. Native dismissal finishes Activity only; do not remove the shared launcher task.
- [x] Normal mode: Dismiss+Snooze, allowed Back/Home, no wake-check/overlay relaunch/forced maximum, system or custom alarm-stream volume with restoration.
- [x] Shared rounded choice sheets/menus and translucent gradient footer; transparent system navigation. Stronger bounded dark clay depth. No BackdropFilter.
- [x] Static review, compiler builds and signed ARMv7/ARM64/universal APKs. Version2.0.0-preview.2+5005. No runtime tests at owner's request; later read-only duplicate-icon query failed as phone disconnected.
- [x] Complete SDK3.47.8/Dart3.13.7 tool bootstrap and record checkpoint. Bilingual changelog/README and GitHub source review branch prepared; no public Release.

Interfaces: AlarmMode enum challenge/normal; JSON mode string, volumeMode system/custom, volumePercent0..100(default70). Existing/no field=>challenge/system/70. No applicationId/signing change.

Decisions: normal mode is genuinely permissive (even zero volume), strict retains the existing mission contract. Task duplication has code evidence (empty launcher affinity vs package native affinity, singleTop and mixed relaunch flags). Runtime reproduction is deferred at the user's request; do not claim device verification of these new changes.
