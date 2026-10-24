# Preview verification status / وضعیت بررسی پیش‌نمایش

Target: 2.0.0-preview.1+4, based on public v1.2.0.

This file records actual evidence, not promised checks. Updated at each checkpoint.

| Check / بررسی | Status / وضعیت |
|---|---|
| Additive legacy JSON migration and new settings round-trip | 5 Dart tests passed |
| Version comparison, ABI selection, trusted GitHub link filtering | 3 Dart tests passed |
| Bounded profile frame-statistics calculation | 2 Dart tests passed; not a performance measurement |
| Integrated Flutter UI and analyzer | In progress |
| Native mission and scheduler regressions | In progress |
| Private installable APKs | Pending final build |
| Real Android device / lockscreen / reboot / idle | No physical ADB device available |
| 120 Hz P95/P99 UI + raster | Not measured; requires a physical 120 Hz device in Profile mode |
| Codex Security | Partial source review completed; no validated issue in reviewed controls; not final release clearance |

Security report retained locally under Codex Security scan5db2d728-82a7-4bd2-b12c-a999b8b035f6. The tool warned that the original target snapshot became unavailable during review, so the result cannot certify the final moving working tree. No private key data was read or committed.

هیچ ادعایی دربارهٔ ۱۲۰ فریم ثابت یا موفق‌بودن سناریوهای تست‌نشدهٔ گوشی واقعی نداریم. انتشار عمومی پیش‌نمایش تا تأیید مالک متوقف است.
