# AlarmXV Clay redesign implementation plan

> For agentic workers: use superpowers:executing-plans. Track evidence below; preserve the v1.2.0 alarm contract.

Goal: a coherent clay-inspired Android alarm app, persistent appearance/groups/mission settings, improved native ringing, and an installable private preview.

Architecture: keep AlarmManager, native foreground audio, receiver and wake-check lifecycle. Flutter owns editor/home/settings; native Android owns lockscreen missions. Both deserialize the same additive JSON contract. No camera, cloud, blur, shader or extra runtime permission.

Tech stack: existing Flutter/Dart, Kotlin Android Views, existing MethodChannel and SharedPreferences. Material 3 interaction, custom theme tokens and bounded motion.

## Constraints and decisions
- Existing application ID, signing and alarms stay intact; defaults migrate v1.2.0 without discarding records.
- User explicitly requested autonomous execution after planning; no extra design approval gate.
- Work on branch redesign/clay-v2 in the existing relocated project Desktop/ph/AlarmXV; no public push/release.
- Native mission settings: math difficulty/operations/questions; memory grid/targets/rounds; shake count/sensitivity; typing phrase and number-order mission. Fixed ordered mission pipeline with existing Set insertion preserved.
- Groups stored separately; alarms keep groupId. Deleting a group unassigns its alarms, never deletes them. Group toggles change member enabled states only after confirmation.
- Persistent appearance: system/light/dark and 8 accents. Native activity reads the same appearance preferences.
- No QR/photo in this preview: camera registration and fallback require separate device validation.
- No physical ADB device present at audit. Do not claim real-device tests or 120 FPS without measurement.

## Review focus
1. v1.2 JSON round-trip must preserve alarm identity, weekdays, sound, wake-check and added fields across native rewrites.
2. Pending snooze/challenge timeouts must not disappear when app resumes or unrelated alarms change.
3. Group delete/toggle and native write failure must not lose alarms.
4. Small screens, RTL, 2x text, keyboard and reduced motion must keep controls usable.
5. Math valid division, repeated memory rounds, unavailable shake sensor, and checker single-cycle must remain solvable.

## Tasks / measurable checkpoints
- [ ] Audit: read all Dart/native sources/tests/resources, baseline analyze/tests, inspect GitHub history/issues, Context7 docs, ADB availability.
- [ ] Data: add migration-tested Group, Appearance and MissionSettings models; extend Alarm; native settings persistence and round-trip; tests first.
- [ ] Design: centralized semantic color/depth/radius/motion tokens, adaptive contrast, rounded clipped interactions, app settings and appearance persistence.
- [ ] Flutter UI: redesigned home with next alarm, countdown, search/sort/group filtering; group manager; alarm editor with mission settings/snooze/sound; duplicate; empty/error/loading states.
- [ ] Native UI/features: coherent Ringing/WakeCheck screens, native theme bridge; configurable math/memory/shake, typing/number-order, sensor fallback, inset/ripple/icon fixes. Keep scheduling/audio lifecycle.
- [ ] Regression: scheduling cancel/reschedule review and unit tests, migration/widget tests, analyze, Android build and native tests.
- [ ] Performance/QA: profile-only bounded frame recorder with P95/P99, intervals and jank; APK; honest device test matrix and security report.
- [ ] Release preparation: private preview version/changelog, locally inspect APK identity/signature, evidence report. No GitHub release.

## Progress
2026-10-24: baseline Git clean, c74bcd3, v1.2.0+3. Flutter 3.47.6 / Dart 3.13.5. ADB starts elevated, no device attached. pub.dev returns authorization failed; retry using cached dependencies/official mirror before adding packages. Project moved from Desktop/AlarmXV to Desktop/ph/AlarmXV.
