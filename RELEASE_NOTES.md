# AlarmXV 2.0.0

**Stable release · نسخهٔ پایدار**

## فارسی

نسخهٔ پایدار 2.0، با شمارهٔ بیلد جدید 5007 و سه APK بازسازی‌شده. یک جهش نسبت به 1.2.0: ظاهر یکپارچهٔ Clay، نوارها و منوهای Frosted و تجربهٔ فارسی/انگلیسی.

- تم روشن، تیره و خودکار؛ هشت رنگ و دکمهٔ متحرک ماه و خورشید.
- گروه‌ها، جست‌وجو، تکثیر و نمایش زمان باقی‌مانده تا آلارم بعدی.
- دو حالت جدا: زنگ عادی با قطع مستقیم و صدای آزاد، یا بیداری مأموریتی.
- تنظیم سختی ریاضی، حافظه و تکان‌دادن؛ تایپ، ترتیب اعداد و مأموریت‌های متوالی.
- فارسی و انگلیسی با پیش‌فرض سیستم، شامل صفحهٔ زنگ، مأموریت و بررسی بیداری.
- شفافیت واقعی نوارها، منوهای گرد، اصلاح هالهٔ کارت و بک کشسان.
- اصلاح ورود مجدد از آیکون و لینک ساعت Android با حفظ جلسهٔ فعال و زمان مأموریت.
- تازه‌های نصب و بررسی دستی نسخهٔ پایدار جدید با پیشنهاد APK مناسب گوشی.

### دانلود و آپدیت

| فایل | مناسب برای |
|---|---|
| **arm64-v8a** | بیشتر گوشی‌های جدید، از جمله Galaxy A34 |
| **armeabi-v7a** | گوشی‌های قدیمی ۳۲ بیتی ARM |
| **universal** | اگر از معماری مطمئن نیستی؛ حجم بیشتر |

فقط یکی از APKها رو نصب کن. همه با امضای قبلی AlarmXV و کد 5007 هستن؛ برای آپدیت نیازی به حذف برنامه نیست. فایل **SHA256SUMS.txt** برای بررسی صحت دانلود ضمیمه شده.

### نتیجهٔ بررسی

در بررسی کد پیش‌نمایش، `flutter analyze` بدون ایراد بود و **۳۹ تست Flutter** و **۱۵ تست Native/پیکربندی** موفق شدند. رندر Flutter برای تم‌ها، اسکرول، منوها و دو زبان بررسی شد. پیش‌نمایش همین کد روی Galaxy A34 نصب شد؛ APK پایدار جدید با نسخهٔ2.0.0/5007 از نو ساخته شده و تست تازهٔ گوشی به درخواست مالک با خود اوست.

چرخهٔ کامل زنگ/مأموریت روی گوشی و اندازه‌گیری جدید FPS انجام نشده. مشکل مقطعی دو پنجره بازتولید نشد؛ مسیر ورود مجدد اصلاح شده و تأیید نهایی دستگاه باقیه. ادعای ۱۲۰ فریم ثابت نداریم. قبل از استفادهٔ روزانه یک زنگ آزمایشی با تنظیمات خودت امتحان کن.

## English

Stable 2.0, with versionCode 5007 and three freshly rebuilt Release APKs. A substantial step beyond 1.2.0: a coherent Clay interface, frosted chrome and menus, and Persian/English throughout the app.

- Light, dark and system themes, eight accents and an animated sun/moon control.
- Alarm groups, search, duplication and a next-alarm countdown.
- Separate Normal and Mission modes: direct dismissal/free volume, or configurable wake-up missions.
- Adjustable Math, Memory and Shake, plus Typing, Number Order and sequential missions.
- System-default Persian/English, including native ringing, mission and wake-check screens.
- Live clipped backdrop blur, rounded controls, corrected card shadows and an elastic Back button.
- Launcher/Android clock-link re-entry preserves the active session and mission deadline.
- In-app release notes and an on-demand stable-update check with architecture-aware browser downloads.

**Downloads:** choose **arm64-v8a** for most modern phones, **armeabi-v7a** for older 32-bit ARM devices, or **universal** when unsure. Install only one APK. All retain the existing signature and use versionCode 5007, allowing an in-place upgrade. SHA256 checksums are attached.

**Verification:** the preview implementation passed static analysis, 39 Flutter tests and 15 Native/configuration tests. Host-rendered fixtures cover themes, scrolling, menus and localization; that preview was installed on a Galaxy A34. The stable 2.0.0/code 5007 APKs are freshly rebuilt; no new stable-device test is claimed. Phone testing is being handled by the owner: no fresh full alarm/mission-cycle or frame-pacing result is claimed. The intermittent duplicate-window report was not reproduced; launcher re-entry was corrected, with final device confirmation pending. No sustained 120 FPS result is claimed; try a test alarm with your configuration before daily use.

[Source](https://github.com/bardia-us/AlarmXV) · [GPL-3.0](https://github.com/bardia-us/AlarmXV/blob/main/LICENSE) · [Changelog](https://github.com/bardia-us/AlarmXV/blob/main/CHANGELOG.md) · [Verification details](https://github.com/bardia-us/AlarmXV/blob/main/docs/qa/FROSTED_UI.md)
