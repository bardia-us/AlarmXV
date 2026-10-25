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
- Native: Release Kotlin compiled;11existing alarm contracts and1bilingual string-parameter test passed. User-entered labels/typing answers remain data, not translation keys.

## Limits

- These are host rendering/interaction and JVM tests, not a new real-device frame-time capture. No claim of120FPS, reduced jank, or an end-to-end lockscreen/idle/reboot/mission cycle for preview3.
- No preview3 installation or launcher inspection on the phone yet. The previous preview2 install was explicitly scoped to user0 and did not create a Dual App installation.
- Existing toolchain emits future Gradle/AGP/Kotlin support warnings; upgrading that toolchain is outside this UI/localization patch.
- Release artifact compilation/signature results are recorded after completion, separately from visual verification.

خلاصه: ظاهر و تعامل با fixtureهای واقعی Flutter بررسی شد؛ این نتیجه جای تست روانی و عملکرد واقعی آلارم روی گوشی را نمی‌گیرد.
