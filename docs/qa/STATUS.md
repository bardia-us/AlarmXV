# Preview verification status / وضعیت بررسی پیش‌نمایش

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
| Private installable APKs | Pending final build |
| Real Android device | Signed Profile preview installed over1.2.0 on Galaxy A34 Android16 without uninstall; What's New rendered |
| Lockscreen / reboot / idle / full mission cycle | Not run; owner explicitly ended further testing |
|120Hz Profile, warm editor scrolling | 977frames; UI P95/P99 3.595/4.452ms; Raster P95/P99 6.003/7.471ms;6over-budget frames |
| Codex Security | Partial source review completed; no validated issue in reviewed controls; not final release clearance |

Security report retained locally under Codex Security scan5db2d728-82a7-4bd2-b12c-a999b8b035f6. The tool warned that the original target snapshot became unavailable during review, so the result cannot certify the final moving working tree. No private key data was read or committed.

Measurement used Flutter3.47.6 Profile on a120Hz Galaxy A34; Android GPU-watch overlay was enabled. Capture label was initially home-scroll-warm, but the pre-capture screenshot shows the new-alarm editor: these timings are correctly attributed to the editor, not Home. Vsync interval P95/P99 8.341/16.666ms includes gaps between ADB gestures. No claim of sustained120FPS, of native alarm frame performance, or of equivalent results on a later SDK build.

Owner requested no further testing after this sample. No reboot, force-idle, timezone change or additional device intervention was performed. Public preview release still requires approval.

New preview2 code is not installed on the connected phone; it still has the earlier Profile preview1. GitHub quality workflow is manual-only so source/documentation backup does not trigger more test runs after this request.

هیچ ادعایی دربارهٔ ۱۲۰ فریم ثابت یا موفق‌بودن سناریوهای تست‌نشده نداریم. به درخواست مالک تست بیشتر متوقف شد؛ انتشار عمومی پیش‌نمایش هم تا تأیید مالک متوقف است.
