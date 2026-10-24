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
