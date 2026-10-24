# Changelog

## 2.0.0-preview.1+4 — Private preview / پیش‌نمایش خصوصی

### فارسی
- طراحی یکپارچه Clay، تم روشن/تیره/سیستم و هشت پالت رنگ ذخیره‌شونده.
- نمایش آلارم بعدی، جست‌وجو، مرتب‌سازی، تکثیر و مدیریت گروه‌ها.
- تنظیمات اختصاصی سختی و تعداد مراحل ریاضی، حافظه و تکان‌دادن؛ مأموریت تایپ و ترتیب اعداد.
- طراحی هماهنگ صفحهٔ Native زنگ، مأموریت و بررسی بیداری؛ اصلاح محدودهٔ Ripple و آیکون تطبیقی.
- نمایش تازه‌های نسخه بعد از نصب آپدیت و بررسی دستی GitHub با پیشنهاد معماری مناسب.
- اصلاح لغو اشتباه Snooze و مهلت مأموریت هنگام بازگشت به اپ؛ حفظ سازگاری داده‌های 1.2.
- وضعیت تست واقعی و محدودیت‌ها در docs/qa/STATUS.md ثبت شده؛ این نسخه هنوز عمومی نشده است.

### English
- Unified soft-depth Clay UI, persistent system/light/dark themes and eight accents.
- Next alarm overview, search, sorting, duplication and alarm groups.
- Per-alarm math/memory/shake configuration plus typing and number-order missions.
- Coherent native ringing and wake-check UI, clipped feedback and adaptive icons.
- Version-specific in-app What's New and manual GitHub updates with ABI-aware downloads.
- Preserve pending snoozes and mission deadlines when returning to the app; additive v1.2 migration.
- Actual QA evidence and device limitations are tracked in docs/qa/STATUS.md. Not publicly released.

## 1.2.0+3

فارسی: صفحهٔ تمام‌صفحه و بی‌صدای بررسی بیداری با مهلت ۶۰ ثانیه، اصلاح چرخه‌های تکراری، فاصلهٔ بهتر ساعت از لبه و APK جداگانه برای هر معماری.

- Added a silent full-screen Wake-up Checker with a 60-second countdown.
- Fixed repeated Checker cycles after solving a Checker-failure alarm.
- Kept the Checker screen dismissible while leaving its silent notification active.
- Moved the large ringing clock down for better system-bar spacing.
- Added per-ABI signed Release APK outputs.

## 1.1.0+2

فارسی: جریان زنگ ← شروع ← مأموریت زمان‌دار، بازگشت زنگ در پایان مهلت، بازیابی صفحه روی برنامه‌ها، انتخاب صدای گوشی و امضای Release. دکمهٔ قطع اضطراری و توقف خودکار داخل اپ در این نسخه حذف شدند؛ کنترل نهایی همچنان در اختیار سیستم Android است.

- Added a strict Ring → Start → timed Challenge flow.
- Added native challenge deadlines that restart the real alarm when missed.
- Added Display-over-apps recovery when the alarm Activity loses focus.
- Removed the in-app emergency dismissal and automatic ringing timeout.
- Guarded the Android alarm stream at maximum volume while ringing.
- Fixed Wake-up Checker so it posts a silent confirmation first and grants a
  full 60-second response window before scheduling a failure alarm.
- Prevented Wake-up Checker failure alarms when notifications are unavailable.
- Added the native Android alarm/ringtone picker for each alarm.
- Added release signing configuration without committing private key material.
