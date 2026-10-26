# Changelog

## 2.0.0-preview.3+5006 — Private preview / پیش‌نمایش خصوصی

### فارسی
- اصلاح مسیر ورود مجدد از آیکون برنامه و لینک ساعت اندروید: صفحهٔ فعال زنگ بی‌دلیل بسته و دوباره ساخته نمی‌شود؛ جلسه و مهلت مأموریت حفظ می‌شود.
- نوار بالای تنظیمات، خانه و گروه‌ها و نوار ثابت دکمه‌ها از پس‌زمینهٔ واقعی با بلور محدود استفاده می‌کنند؛ متن و آیکون‌ها واضح باقی می‌مانند.
- منوهای بازشونده و انتخابگرها متریال Frosted یکپارچه و گذار مشترک سطح/محتوا دارند؛ کاهش افکت و کنتراست بالا از سطح مات استفاده می‌کنند.
- اصلاح بریدگی مستطیلی سایهٔ کارت آلارم پس از پایان انیمیشن و گوشه‌های انتخاب ساعت؛ دکمهٔ برگشت گرد با کشش ملایم.
- فارسی و انگلیسی در رابط Flutter، زنگ Native، مأموریت‌ها و بررسی بیداری؛ پیش‌فرض زبان سیستم و انتخاب دستی در تنظیمات، بدون تغییر نام‌ها و عبارت‌های ذخیره‌شدهٔ کاربر.
- نسخه و تازه‌های نصب به‌روز شدند. شواهد تست و محدودیت عملکرد در docs/qa/FROSTED_UI.md ثبت می‌شود؛ انتشار عمومی انجام نشده است.

### English
- Normalize launcher/AlarmClockInfo entry and retain the active alarm screen/session when reopening the app; avoid clearing the native screen above Main.
- Real clipped backdrop blur for Home, Settings and Groups app bars and fixed action footers, with sharp text and icons.
- Unified frosted popup/selection panels with one material/content transition and opaque reduced-effects/high-contrast fallback.
- Removed settled list-animation clipping of rounded alarm-card shadows; rounded time selections and an elastic Back button.
- System-default Persian/English, with a persisted manual preference across Flutter and native alarm/mission/wake-check interfaces. User labels and typing phrases remain unchanged.
- Updated version and in-app release notes. Verification evidence and performance limits are recorded separately; no public Release.

## 2.0.0-preview.2+5005 — Private preview / پیش‌نمایش خصوصی

### فارسی
- حالت جداگانهٔ زنگ عادی: قطع مستقیم، بدون مأموریت و بررسی اجباری بیداری، بلندی فعلی گوشی یا درصد دلخواه و امکان تغییر صدا با دکمه‌ها.
- یکپارچه‌کردن Task و مسیرهای نمایش Native برای جلوگیری از ساخت چند پنجرهٔ آلارم.
- عمق واضح‌تر Clay در تم تیره، انتخابگرهای گرد و هماهنگ، نوارهای پایین با محوشدن شفاف و ناوبری edge-to-edge.
- دکمهٔ متحرک ماه/خورشید با پیش‌فرض سیستم و گذار تغییر گروه حتی برای فهرست‌های یکسان؛ حفظ دسترسی به نوار ناوبری و حریم امن دکمه‌ها.
- ارتقای SDK مشترک با نیرا به Flutter3.47.8 stable / Dart3.13.7.
- طبق درخواست مالک، تست تازه و نصب روی گوشی برای این تغییرات انجام نشده؛ نتیجهٔ کامپایل و APKها جدا گزارش می‌شود.

### English
- Separate normal alarm mode with direct dismissal, optional custom or system volume, free volume keys, and no mandatory missions or wake checks.
- Unified Android task affinity and native launch identity to avoid duplicate alarm windows.
- Stronger dark Clay depth, rounded selection surfaces and translucent fading action footers with edge-to-edge navigation.
- Animated moon/sun control with system default; explicit group transitions even for identical contents; visible system navigation and safe action insets.
- Shared SDK upgraded to Flutter3.47.8 stable / Dart3.13.7.
- No new tests or device installation at the owner's request; compiler/APK results are reported separately.

## 2.0.0-preview.1+5004 — Private preview / پیش‌نمایش خصوصی

### فارسی
- طراحی یکپارچه Clay، تم روشن/تیره/سیستم و هشت پالت رنگ ذخیره‌شونده.
- نمایش آلارم بعدی، جست‌وجو، مرتب‌سازی، تکثیر و مدیریت گروه‌ها.
- تنظیمات اختصاصی سختی و تعداد مراحل ریاضی، حافظه و تکان‌دادن؛ مأموریت تایپ و ترتیب اعداد.
- طراحی هماهنگ صفحهٔ Native زنگ، مأموریت و بررسی بیداری؛ اصلاح محدودهٔ Ripple و آیکون تطبیقی.
- نمایش تازه‌های نسخه بعد از نصب آپدیت و بررسی دستی GitHub با پیشنهاد معماری مناسب.
- اصلاح لغو اشتباه Snooze و مهلت مأموریت هنگام بازگشت به اپ؛ حفظ سازگاری داده‌های 1.2.
- وضعیت تست واقعی و محدودیت‌ها در docs/qa/STATUS.md ثبت شده؛ این نسخه هنوز عمومی نشده است.
- مجوز GPL-3.0؛ کد5004 مشترک بین APKها برای آپدیت بدون حذف داده.

### English
- Unified soft-depth Clay UI, persistent system/light/dark themes and eight accents.
- Next alarm overview, search, sorting, duplication and alarm groups.
- Per-alarm math/memory/shake configuration plus typing and number-order missions.
- Coherent native ringing and wake-check UI, clipped feedback and adaptive icons.
- Version-specific in-app What's New and manual GitHub updates with ABI-aware downloads.
- Preserve pending snoozes and mission deadlines when returning to the app; additive v1.2 migration.
- Actual QA evidence and device limitations are tracked in docs/qa/STATUS.md. Not publicly released.
- GPL-3.0 license and shared APK version code5004 for non-destructive upgrades.

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
