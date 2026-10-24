# AlarmXV checkpoints

## 2026-10-24 — redesign in progress

- Base: v1.2.0+3, commit c74bcd3. Existing project relocated to Desktop/ph/AlarmXV.
- Work branch: redesign/clay-v2. Never publicly release preview without owner's approval.
- User approved autonomous full redesign: Clay/soft depth, no Liquid Glass/blur; native alarm reliability remains first.
- Plan: docs/superpowers/plans/2026-10-24-clay-redesign.md.
- Data checkpoint: additive groups/mission settings/appearance; five migration/round-trip/next-occurrence tests passed.
- New request: version-specific What's New, user-initiated GitHub update checker + ABI matching, bilingual README/changelog, final ARM64/ARMv7/universal APKs only.
- Update/profile checkpoint: version parsing, trusted URL/ABI fallback and bounded frame statistics tests passed (5 tests); no new Flutter package.
- Flutter: shared with niraNG at D:/dev/flutter, currently 3.47.6 stable / Dart3.13.5; niraNG local.properties uses same path. Official release manifest check returned404; do not claim latest SDK or mutate shared SDK until verified.
- Environment: Flutter doctor Android/JDK21 ready; no physical ADB device attached; emulator inventory empty. Gradle daemon loopback issue under investigation. Offline pub get succeeds; pub.dev online returned authorization error.
- Security: active scan5db2d728-82a7-4bd2-b12c-a999b8b035f6; partial current source audit, mutation limits declared. No final clean bill claim until completed.
- SDK checkpoint: `flutter upgrade --verify-only` confirmed stable3.47.8 revision737ba8f885, versus installed3.47.6. User requested upgrade; command-scoped upgrade underway, both projects keep same SDK path.
- Gradle checkpoint: Windows Java Unix domain socket path too long; command-scoped JAVA_TOOL_OPTIONS=-Djdk.net.unixdomain.tmpdir=C:\Windows\Temp fixes daemon startup. Do not change user global Java settings.
- Next: finish Flutter+native UI, integrate What'sNew startup, run all analyzer/tests, native regression/build, private preview QA report and APK checksum/signature evidence.

## Checkpoint 2 — integration and regression

- Git checkpoint7283ef3 preserves additive migration, app settings and mission/update contracts (10 focused Dart tests green).
- Native final Kotlin/resources compilation and7 JUnit tests green; cache XML confirms zero failures/errors.
- Native fix preserves snooze/challenge PendingIntents on app resume. AlarmStore persists with checked commit before cancellations; disabled/deleted members cancel their sessions.
- New UI initially exposed two real mismatches: unsupported wake-check timeout choices and volume-protection switch; removed unsupported controls, preserved stored fields. Checker remains60seconds.
- Integrated UI test caught keyboard+2xtext overflow; editor title moved into scroll content, no font-size clamp.8 UI tests then passed (fresh complete suite still pending).
- App WhatsNew once-per-installed-version test passed. GitHub updater tests reject wrong repo/encoded path escapes, compare prerelease correctly and match ABI with universal fallback.
- Flutter3.47.8 upgrade could not finish: Google connection reset; official mirror transferred57MB then stalled on resumed chunks. Original working3.47.6 SDK restored from existing backup, stable branch restored, incomplete download and backups preserved. No claim upgrade succeeded.
- Source review (Codex Security) completed with partial coverage, zero validated findings in reviewed controls; original snapshot unavailable warning makes it unsuitable as final-release certification.
