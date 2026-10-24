# Android acceptance matrix

Preview release gate: NOT performed on a physical device. Unit/widget success does not substitute for the rows below. No device or working installed emulator image was available at development time.

| Scenario | Expected behavior | Evidence now |
|---|---|---|
| Background/closed task | Exact AlarmManager starts foreground ringing at scheduled time | Native source reviewed; physical test pending |
| Locked/display off/Doze | Notification/full-screen access or overlay presents ringing; sound and vibration loop | Physical test pending |
| System force stop | Android may block delivery until app is reopened | Platform limit; never promise bypass |
| Process killed during mission | Saved progress + native challenge timeout remain recoverable | Persistence reviewed; physical test pending |
| Change time/timezone | Main weekly occurrence recomputed via broadcast receiver | Source-reviewed; device pending |
| Reboot | Boot broadcast restores active weekly alarms and checker state | Source-reviewed; device pending |
| Close/reopen while snoozed | Pending snooze is retained | Session cancellation policy regression test passes; Android intent test pending |
| Edit unrelated alarm during mission | Existing challenge deadline is retained | Session policy regression test passes; Android intent test pending |
| Disable/delete group member | Active main/session intents cancelled, records survive unrelated group edits | JVM policy + widget transaction tests; device pending |
| Two alarms close together | Current single ringing service handles replacement; no reliable queue is claimed | Known architectural limit; see STATUS |
| Mission complete then checker count1 | Silent60s check; no new checker cycle after failure alarm is solved | Existing Dart transition tests + native source; device pending |
| Large text/RTL/keyboard | Home/editor/settings stay usable with scrolling | Automated widget tests, not Android keyboard test |
| Light/dark/ripple | Coherent surfaces, rounded clipped touch feedback | Widget captures; native lockscreen inspection pending |
| Sound choice | System picker previews installed sounds; selected URI persists | Source reviewed, physical test pending |
| Sensor absent/rejected | Math fallback remains available | Native branch reviewed; hardware test pending |
| Manual update | GitHub request only on tap; compatible APK opens in browser | ABI/version/link unit tests; browser integration device pending |
|120Hz Profile | P95/P99 UI+raster and native frame traces captured on physical hardware | Not measured; no FPS assertion |

## Profiling procedure

Use a physical phone: `flutter run --profile --dart-define=ALARMXV_PROFILE=true`. Record continuous scrolling, sheet opening, theme selection and menus separately. Filter `ALARMXV_FRAME_REPORT` in logs for bounded Flutter UI/raster P95/P99 and observed vsync intervals. Idle gaps are not proof of jank. Use Flutter DevTools for rebuild tracing and Android Perfetto/FrameMetrics for native Ringing/WakeCheck; Flutter timings do not measure Android Views. Keep display refresh mode/battery saver/thermal state with each result. A release build alone is not a profile result.
