# Verification status / وضعیت بررسی نسخه‌ها

## Stable2.0.0+5007

Published as Stable/Latest on2026-10-26: [v2.0.0](https://github.com/bardia-us/AlarmXV/releases/tag/v2.0.0), draft=false/prerelease=false. All four remote assets (three APKs and checksums) match local SHA256/byte lengths.

Owner requested stable/latest publication with an actual app-version increase. All three Release APKs were freshly rebuilt for2.0.0/code5007 and their embedded manifest versions and unchanged signing certificate verified. This is a version/packaging change over the reviewed preview implementation; the39Flutter/15Native test results below are earlier implementation evidence, not freshly rerun stable tests. No new phone install or interaction was performed for this release. See [APK evidence](RELEASE_APKS.md) and [v2.0.0](https://github.com/bardia-us/AlarmXV/releases/tag/v2.0.0).

## Historical preview3 verification

Current pre-release: **2.0.0-preview.3+5006**. See [Frosted UI/localization verification](FROSTED_UI.md): analyzer clean,39Flutter tests passed,15Native unit/configuration tests passed, explicit visual fixtures passed. This does not establish real-device frame pacing. All three signed Release APKs built; ARM64 installed successfully on user0 at the owner's explicit install-only request on2026-10-26. No subsequent phone UI/alarm test. The owner then authorized GitHub publication as a public pre-release; stable1.2.0 is unchanged. See [APK evidence](RELEASE_APKS.md) and the [release page](https://github.com/bardia-us/AlarmXV/releases/tag/v2.0.0-preview.3).

## Historical preview2 evidence

Target: 2.0.0-preview.2+5005, based on public v1.2.0.

This file records actual evidence, not promised checks. Updated at each checkpoint.

| Check / بررسی | Status / وضعیت |
|---|---|
| Additive legacy JSON migration and new settings round-trip | 5 Dart tests passed |
| Version comparison, ABI selection, trusted GitHub link filtering | 3 Dart tests passed |
| Bounded profile frame-statistics calculation | 2 Dart tests passed; not a performance measurement |
| Earlier preview1 Flutter UI and analyzer | 27 automated tests passed; analyzer clean; opt-in visual capture also passed |
| Earlier preview1 native regressions | 11 JVM tests passed; Kotlin/resources compiled |
| Preview2 normal mode, task, footer, theme/group changes | Static review + compiler builds only; no new tests at owner's request |
| Private signed Release APKs | ARM64/ARMv7/universal built successfully with Flutter3.47.8/Dart3.13.7; all code5005, one launcher and same signing identity |
| Real Android device | Signed Profile preview installed over1.2.0 on Galaxy A34 Android16 without uninstall; What's New rendered |
| Lockscreen / reboot / idle / full mission cycle | Not run; owner explicitly ended further testing |
|120Hz Profile, warm editor scrolling | 977frames; UI P95/P99 3.595/4.452ms; Raster P95/P99 6.003/7.471ms;6over-budget frames |
| Codex Security | Partial source review completed; no validated issue in reviewed controls; not final release clearance |

Security report retained locally under Codex Security scan5db2d728-82a7-4bd2-b12c-a999b8b035f6. The tool warned that the original target snapshot became unavailable during review, so the result cannot certify the final moving working tree. No private key data was read or committed.

Measurement used Flutter3.47.6 Profile on a120Hz Galaxy A34; Android GPU-watch overlay was enabled. Capture label was initially home-scroll-warm, but the pre-capture screenshot shows the new-alarm editor: these timings are correctly attributed to the editor, not Home. Vsync interval P95/P99 8.341/16.666ms includes gaps between ADB gestures. No claim of sustained120FPS, of native alarm frame performance, or of equivalent results on a later SDK build.

Owner requested no further testing after this sample. No reboot, force-idle, timezone change or additional device intervention was performed. Public preview release still requires approval.

New preview2 code is not installed on the connected phone; it still has the earlier Profile preview1. GitHub quality workflow is manual-only so source/documentation backup does not trigger more test runs after this request.

Final artifacts: local dist/2.0.0-preview.2, ARM64 18,524,225B, ARMv7 15,943,577B, universal53,406,571B. Universal includes ARM64, ARMv7 andx86_64; no standalone x86 APK was built. All manifests: applicationId com.alarmxv.alarm_xv, versionName2.0.0-preview.2, versionCode5005, one MainActivity launcher. All signatures verified against v1.2 certificate SHA2564f15672645bdf1ca9a382ee715ff3fd4ae124ea9cd56c744a1178253c45c5cd6. No public GitHub Release and no new device installation.

Owner clarified duplicate **launcher icons**, not merely Recents cards. A read-only package/launcher query was attempted, but the previously connected phone was no longer in ADB. Actual duplicate-package versus duplicate-shortcut cause is UNCONFIRMED; same-ID/signer APK evidence does not prove the launcher's existing state. No uninstall or shortcut deletion was performed.

هیچ ادعایی دربارهٔ ۱۲۰ فریم ثابت یا موفق‌بودن سناریوهای تست‌نشده نداریم. به درخواست مالک تست بیشتر متوقف شد؛ انتشار عمومی پیش‌نمایش هم تا تأیید مالک متوقف است.
