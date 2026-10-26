# Frosted UI and localization verification — preview3

Version: 2.0.0-preview.3+5006. Canonical source: redesign/clay-v2.

## Material and scope

- Read-only reference: niraNG app_shell.dart AppBar.flexibleSpace and glass_surface.dart FrostedSurface.
- Headers and action footers: surfaceContainerHigh, sigmaX/Y8, Light alpha.64, Dark alpha.45.
- Text-rich popup and selection panels: sigma14, Light alpha.78, Dark alpha.64. One filter per panel, no per-row filters or shared keys across overlapping surfaces.
- Clipped backdrop only; sharp Material foreground. No lens/refraction shader, screenshot loop, cached page image, ImageFiltered foreground or scroll-driven page setState.
- Opaque fallback for reduced animations/accessibility navigation/high contrast. Standard navigation controls remain visible.
- Home, Settings and Groups scroll under the chrome with safe initial padding; footer buttons stay outside system/keyboard insets. Existing native alarm scheduling is untouched.

## Verified locally

- Flutter analyze: no issues.
- Flutter suite:39passed,1opt-in screenshot fixture skipped in the regular run.
- Explicit visual fixture: passed; Light/Dark, scrolled Settings, opening/closing sort menu, nested group/language selection, rounded time picker, action footer and English LTR/Persian RTL fixtures. Images retained under ignored build/ui-preview, containing sample data only.
- Pixel regression: changing the live backdrop changes the surface pixels in both themes; solid foreground pixels stay sharp. Reduced effects stop sampling the backdrop. Hit testing confirms chrome blocks taps behind it.
- Interaction checks: scroll under Settings chrome, whole-menu dismissal, completed card shadows without rectangular clipping, elastic Back press/navigation, system language and persisted overrides, settings/membership/save regressions, large RTL text and keyboard.
- Native: Release Kotlin compiled;15tests passed (11alarm contracts,2locale/parameter tests,2manifest policy guards). User-entered labels/typing answers remain data, not translation keys. Follow-up review enabled Android RTL, isolated numeric equations/counters/keypads as LTR and matched Flutter's first supported system locale.
- Launcher follow-up: Main uses singleTop and AlarmClockInfo uses a standard shared launcher intent. Main's onCreate/onNewIntent can reopen an existing strict session without restarting the service/token; onResume is unchanged so normal Back remains free. Source review found no blocking issue. These checks do not simulate Android task management.

## Limits

- These are host rendering/interaction and JVM tests, not a new real-device frame-time capture. No claim of120FPS, reduced jank, or an end-to-end lockscreen/idle/reboot/mission cycle for preview3.
- Final reviewed preview3 ARM64 Release installed on2026-10-26 at the owner's explicit instruction to install only; read-only package metadata confirms code5006 on user0 and no Dual App installation. The owner will perform phone testing; no post-install UI/alarm/launcher/FPS test was run.
- Owner reconnected the Samsung on2026-10-26. Read-only snapshot showed preview2/code5005 and exactly one user0 task, Main root/top; user95 had no AlarmXV. The reported intermittent two-task state was not present, so it is not claimed reproduced or conclusively fixed. No existing task was deleted.
- Existing toolchain emits future Gradle/AGP/Kotlin support warnings; upgrading that toolchain is outside this UI/localization patch.
- Final v8a/v7a/universal Release compilation and signature checks passed. Artifact sizes/hashes are recorded in [RELEASE_APKS.md](RELEASE_APKS.md), separately from visual verification.

خلاصه: ظاهر و تعامل با fixtureهای واقعی Flutter بررسی شد؛ این نتیجه جای تست روانی و عملکرد واقعی آلارم روی گوشی را نمی‌گیرد.
