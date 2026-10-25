import '../l10n/app_strings.dart';

import 'package:flutter/material.dart';

import '../services/update_service.dart';

class WhatsNewSheet {
  static Future<void> showIfNeeded(BuildContext context) async {
    const service = UpdateService();
    try {
      final info = await service.appInfo();
      if (!context.mounted || info.lastSeenVersion == info.versionName) return;
      await show(context, version: info.versionName);
      await service.markWhatsNewSeen(info.versionName);
    } catch (_) {
      // Release notes never prevent access to alarms if the platform is unavailable.
    }
  }

  static Future<void> show(
    BuildContext context, {
    String version = '2.0.0-preview.3',
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: 44,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              context.tr("تازه‌های AlarmXV"),
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              version,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            for (final item in [
              (
                Icons.blur_on_rounded,
                context.tr('سطوح مات و پس‌زمینهٔ واقعی'),
                context.tr(
                  'نوارهای ثابت و منوها با بلور محدود و متن واضح؛ بدون افکت لنزی.',
                ),
              ),
              (
                Icons.language_rounded,
                context.tr('دو زبان، یک تجربه'),
                context.tr(
                  'فارسی و انگلیسی با انتخاب خودکار زبان سیستم؛ قابل تغییر از تنظیمات.',
                ),
              ),
              (
                Icons.alarm_on_rounded,
                context.tr("زنگ عادی یا بیداری مأموریتی"),
                context.tr(
                  "حالت عادی را مستقیم قطع کن؛ از صدای فعلی گوشی یا بلندی دلخواه استفاده کن. حالت مأموریتی جدا باقی مانده.",
                ),
              ),
              (
                Icons.palette_outlined,
                context.tr("یک ظاهر تازه"),
                context.tr(
                  "طراحی نرم Clay، منوهای گرد و نوارهای پایین با محوشدن ملایم؛ بدون افکت شیشه‌ای سنگین.",
                ),
              ),
              (
                Icons.folder_outlined,
                context.tr("آلارم‌های مرتب‌تر"),
                context.tr("گروه‌ها، جست‌وجو، تکثیر و نمایش آلارم بعدی."),
              ),
              (
                Icons.extension_outlined,
                context.tr("بیدارشدن با انتخاب خودت"),
                context.tr(
                  "تنظیم سختی مأموریت‌ها؛ تایپ و ترتیب اعداد کنار ریاضی، حافظه و تکان‌دادن.",
                ),
              ),
              (
                Icons.system_update_rounded,
                context.tr("آپدیت با یک لمس"),
                context.tr(
                  "بررسی دستی نسخه جدید و پیشنهاد فایل مناسب گوشی از GitHub.",
                ),
              ),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(item.$1, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.$2,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(item.$3),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr("بریم سراغش")),
            ),
          ],
        ),
      ),
    ),
  );
}

class AppInfoSection extends StatefulWidget {
  const AppInfoSection({super.key});
  @override
  State<AppInfoSection> createState() => _AppInfoSectionState();
}

class _AppInfoSectionState extends State<AppInfoSection> {
  static const _service = UpdateService();
  bool _checking = false;

  void _message(String text) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _open(Uri url) async {
    try {
      await _service.openUrl(url);
    } catch (_) {
      _message(context.tr("مرورگر باز نشد؛ دوباره امتحان کن."));
    }
  }

  Future<void> _check() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final info = await _service.appInfo();
      final release = await _service.latestRelease();
      if (!mounted) return;
      if (AppVersion.parse(release.version)
              .compareTo(AppVersion.parse(info.versionName)) <=
          0) {
        _message(context.tr("نسخه جدیدتری منتشر نشده؛ به‌روزی."));
        return;
      }
      final asset = release.recommendedAsset(info.supportedAbis);
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            context.tr("نسخه {p0} آماده است", {'p0': release.version}),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset == null
                      ? context.tr(
                          "فایل سازگار پیدا نشد؛ فهرست دانلودها در مرورگر باز می‌شود.",
                        )
                      : context.tr(
                          "پیشنهاد برای این گوشی: {p0}\nدانلود و نصب را در مرورگر ادامه بده.",
                          {'p0': asset.abi},
                        ),
                ),
                if (release.notes.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    release.notes.length > 2500
                        ? '${release.notes.substring(0, 2500)}…'
                        : release.notes,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr("بعداً")),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _open(asset?.url ?? release.page);
              },
              child: Text(context.tr("دانلود در مرورگر")),
            ),
          ],
        ),
      );
    } catch (_) {
      _message(
        context.tr(
          "بررسی آپدیت ممکن نشد. اینترنت یا دسترسی GitHub را بررسی کن و دوباره بزن.",
        ),
      );
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        leading: const Icon(Icons.balance_rounded),
        title: Text(context.tr("متن‌باز با مجوز GPL-3.0")),
        subtitle: Text(context.tr("مجوز برنامه و کتابخانه‌ها")),
        onTap: () =>
            showLicensePage(context: context, applicationName: 'AlarmXV'),
      ),
      ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        leading: const Icon(Icons.auto_awesome_outlined),
        title: Text(context.tr("تازه‌های نسخه")),
        trailing: const Icon(Icons.chevron_left_rounded),
        onTap: () => WhatsNewSheet.show(context),
      ),
      ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        leading: const Icon(Icons.code_rounded),
        title: Text(context.tr("AlarmXV در GitHub")),
        subtitle: Text(context.tr("متن‌باز، ساخته‌شده برای بیدارشدن")),
        trailing: const Icon(Icons.open_in_new_rounded),
        onTap: () => _open(Uri.parse(UpdateService.projectUrl)),
      ),
      ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        leading: _checking
            ? const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.system_update_rounded),
        title: Text(
          _checking
              ? context.tr("در حال بررسی…")
              : context.tr("بررسی به‌روزرسانی"),
        ),
        subtitle: Text(context.tr("فقط با درخواست تو؛ دانلود از مرورگر")),
        onTap: _checking ? null : _check,
      ),
    ],
  );
}
