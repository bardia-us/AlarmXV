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
    String version = '2.0.0-preview.1',
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
              'تازه‌های AlarmXV',
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
            for (final item in const [
              (
                Icons.palette_outlined,
                'یک ظاهر تازه',
                'طراحی نرم Clay، تم روشن و تیره، رنگ‌های قابل انتخاب.',
              ),
              (
                Icons.folder_outlined,
                'آلارم‌های مرتب‌تر',
                'گروه‌ها، جست‌وجو، تکثیر و نمایش آلارم بعدی.',
              ),
              (
                Icons.extension_outlined,
                'بیدارشدن با انتخاب خودت',
                'تنظیم سختی مأموریت‌ها؛ تایپ و ترتیب اعداد کنار ریاضی، حافظه و تکان‌دادن.',
              ),
              (
                Icons.system_update_rounded,
                'آپدیت با یک لمس',
                'بررسی دستی نسخه جدید و پیشنهاد فایل مناسب گوشی از GitHub.',
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
              child: const Text('بریم سراغش'),
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
      _message('مرورگر باز نشد؛ دوباره امتحان کن.');
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
        _message('نسخه جدیدتری منتشر نشده؛ به‌روزی.');
        return;
      }
      final asset = release.recommendedAsset(info.supportedAbis);
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('نسخه ${release.version} آماده است'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset == null
                      ? 'فایل سازگار پیدا نشد؛ فهرست دانلودها در مرورگر باز می‌شود.'
                      : 'پیشنهاد برای این گوشی: ${asset.abi}\nدانلود و نصب را در مرورگر ادامه بده.',
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
              child: const Text('بعداً'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _open(asset?.url ?? release.page);
              },
              child: const Text('دانلود در مرورگر'),
            ),
          ],
        ),
      );
    } catch (_) {
      _message(
        'بررسی آپدیت ممکن نشد. اینترنت یا دسترسی GitHub را بررسی کن و دوباره بزن.',
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
        title: const Text('متن‌باز با مجوز GPL-3.0'),
        subtitle: const Text('مجوز برنامه و کتابخانه‌ها'),
        onTap: () =>
            showLicensePage(context: context, applicationName: 'AlarmXV'),
      ),
      ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        leading: const Icon(Icons.auto_awesome_outlined),
        title: const Text('تازه‌های نسخه'),
        trailing: const Icon(Icons.chevron_left_rounded),
        onTap: () => WhatsNewSheet.show(context),
      ),
      ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        leading: const Icon(Icons.code_rounded),
        title: const Text('AlarmXV در GitHub'),
        subtitle: const Text('متن‌باز، ساخته‌شده برای بیدارشدن'),
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
        title: Text(_checking ? 'در حال بررسی…' : 'بررسی به‌روزرسانی'),
        subtitle: const Text('فقط با درخواست تو؛ دانلود از مرورگر'),
        onTap: _checking ? null : _check,
      ),
    ],
  );
}
