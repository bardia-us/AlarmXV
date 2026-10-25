# Frosted chrome and bilingual UI implementation plan

> Execution: superpowers:executing-plans, inline in the existing redesign/clay-v2 checkout. Owner supplied the material specification and authorized autonomous implementation.

**Goal:** Real clipped frosted chrome/menus, rounded interaction/shadows, and Persian/English UI following the system by default.

**Architecture:** One shader-free FrostedSurface based on niraNG's explicitly requested FrostedSurface (read-only reference). App bars and fixed action footers sample actual scrolling content. Menu panels have one filter and one shared geometry transition, with sharp foreground. Existing Clay cards and the native alarm scheduler remain intact. Locale is additive in appearance settings, using Flutter SDK localization and matching native strings.

**Constraints:** Header sigma8, surfaceContainerHigh Light alpha.64/Dark alpha.45. Text-rich menus may use sigma14 and stronger tint. Clip blur bounds; no shared BackdropKey, per-row blur, screen capture loop, global opacity/image filter or scroll-driven setState. Accessibility/reduced effects use opaque surfaces. Preserve package/signature/data and the existing three final APK variants. Only user0 for any authorized phone installation.

## Tasks

- [x] Pin regression checks for real scrolling behind Settings chrome, header hit testing, menu transitions, steady rounded card shadows, and keyboard/footer insets. Run failing checks first.
- [x] Implement lib/widgets/frosted_surface.dart plus shared frosted app bar, elastic Back, menu route and choice sheet. Integrate Home/Settings/Groups and the existing fixed footer without redesigning page content.
- [x] Remove completed list-size transition clipping of card shadows; unify the time picker's rounded selection shapes and inspect rendered edges.
- [x] Add persisted system/fa/en language selection, standard Material/Cupertino/Widgets localization, LTR/RTL and English/Persian strings for Flutter and native alarm/checker/notifications. Preserve user-entered labels/phrases and stored alarm data.
- [x] Run scoped widget/unit checks, analyzer and visual fixtures in both themes/languages, menu open/close and scrolled header states. Capture images only in explicit test fixtures, never app rendering. Inspect SafeArea and large text/keyboard.
- [ ] Compile Android output, record what was actually tested and any unmeasured runtime performance. No public Release or additional device installation without applicable authorization. Save checkpoint/changelog/What's New with versioned artifacts if built.

**Review focus:** Overlapping footer/menu filters stay independent; topmost material blocks taps; initial content is below status/toolbar; popups do not fade text separately; stable card shadows are not rectangularly clipped; system locale changes preserve manual preference; native challenge parsing is locale-safe.

**Reference:** niraNG lib/features/vpn/app_shell.dart AppBar.flexibleSpace and lib/core/widgets/glass_surface.dart FrostedSurface; no niraNG source modifications.
