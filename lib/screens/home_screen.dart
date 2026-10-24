import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/alarm.dart';
import '../models/alarm_group.dart';
import '../services/alarm_storage.dart';
import '../theme/clay_theme.dart';
import '../theme/settings_controller.dart';
import '../widgets/alarm_editor_sheet.dart';
import '../widgets/clay_components.dart';
import '../widgets/app_info_section.dart';
import 'group_manager_screen.dart';
import 'settings_screen.dart';

const dayLabels = [
  'دوشنبه',
  'سه‌شنبه',
  'چهارشنبه',
  'پنجشنبه',
  'جمعه',
  'شنبه',
  'یکشنبه',
];
String alarmTime(Alarm a) =>
    a.hour.toString().padLeft(2, '0') +
    ':' +
    a.minute.toString().padLeft(2, '0');
String alarmDays(Set<int> days) => days.length == 7
    ? 'هر روز'
    : days.isEmpty
    ? 'بدون روز تکرار'
    : (days.toList()..sort()).map((d) => dayLabels[d - 1]).join('، ');

enum AlarmSort { next, time, name }

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.storage = const AlarmStorage(),
    required this.settings,
  });
  final AlarmStorage storage;
  final SettingsController settings;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  List<Alarm> _alarms = [];
  bool _loading = true, _busy = false, _releaseNotesChecked = false;
  bool _scheduleIncomplete = false;
  String? _loadError, _group;
  final _search = TextEditingController();
  AlarmSort _sort = AlarmSort.next;
  AlarmPermissionStatus? _permissions;
  int _readGeneration = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _search.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_busy) _load(silent: true);
  }

  void _message(String message) {
    if (mounted)
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
  }

  String _error(Object e) => e is PlatformException
      ? e.message ?? 'ذخیره نشد؛ دوباره تلاش کن.'
      : 'انجام نشد؛ دوباره تلاش کن.';
  Future<void> _load({bool silent = false}) async {
    final generation = ++_readGeneration;
    if (!silent && mounted)
      setState(() {
        _loading = true;
        _loadError = null;
      });
    try {
      final result = await widget.storage.reschedule();
      final alarms = await widget.storage.load();
      if (!mounted || generation != _readGeneration) return;
      if (mounted)
        setState(() {
          _alarms = alarms;
          _permissions = result.permissions;
          _scheduleIncomplete =
              result.scheduleError != null ||
              result.scheduledCount < alarms.where((a) => a.isEnabled).length;
          _loading = false;
          _loadError = null;
        });
      if (mounted && !_releaseNotesChecked) {
        _releaseNotesChecked = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) WhatsNewSheet.showIfNeeded(context);
        });
      }
    } catch (_) {
      if (mounted && generation == _readGeneration)
        setState(() {
          _loading = false;
          _loadError = 'زنگ‌ها خوانده نشدن. دوباره تلاش کن.';
        });
    }
  }

  Future<bool> _commit(List<Alarm> next) async {
    if (_busy) return false;
    _readGeneration++;
    setState(() => _busy = true);
    try {
      final result = await widget.storage.saveAndSync(next);
      if (!mounted) return true;
      setState(() {
        _alarms = next;
        _permissions = result.permissions;
        _scheduleIncomplete =
            result.scheduleError != null ||
            result.scheduledCount < next.where((a) => a.isEnabled).length;
      });
      if (_scheduleIncomplete ||
          (next.any((a) => a.isEnabled) && !result.permissions.allGranted))
        _message(
          'زنگ ذخیره شد، اما زمان‌بندی کامل نشد؛ دسترسی‌ها را بررسی کن و دوباره تلاش کن.',
        );
      return true;
    } catch (e) {
      _message(_error(e));
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit([Alarm? alarm]) async {
    if (_busy) return;
    final draft = await showModalBottomSheet<Alarm>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AlarmEditorSheet(
        alarm: alarm,
        groups: widget.settings.settings.groups,
        defaultSnoozeMinutes: widget.settings.settings.defaultSnoozeMinutes,
        storage: widget.storage,
      ),
    );
    if (draft == null || !mounted) return;
    final saved = await _commit(
      alarm == null
          ? [..._alarms, draft]
          : _alarms.map((a) => a.id == alarm.id ? draft : a).toList(),
    );
    if (!saved && mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تغییر ذخیره نشد؛ نسخه قبلی حفظ شد.'),
          action: SnackBarAction(
            label: 'بازکردن پیش‌نویس',
            onPressed: () => _retryDraft(draft, alarm),
          ),
        ),
      );
  }

  Future<void> _retryScheduling() async {
    if (_busy) return;
    setState(() => _busy = true);
    await _load(silent: true);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _retryDraft(Alarm draft, Alarm? original) async {
    final result = await showModalBottomSheet<Alarm>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AlarmEditorSheet(
        alarm: draft,
        groups: widget.settings.settings.groups,
        storage: widget.storage,
      ),
    );
    if (result != null && mounted)
      await _commit(
        original == null
            ? [..._alarms, result]
            : _alarms.map((a) => a.id == original.id ? result : a).toList(),
      );
  }

  Future<void> _toggle(Alarm alarm, bool enabled) async {
    await _commit(
      _alarms
          .map((a) => a.id == alarm.id ? a.copyWith(isEnabled: enabled) : a)
          .toList(),
    );
  }

  Future<void> _duplicate(Alarm alarm) async {
    final copy = alarm.copyWith(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      label: alarm.label + ' • کپی',
    );
    if (await _commit([..._alarms, copy])) _message('یک کپی از زنگ ساخته شد.');
  }

  Future<void> _delete(Alarm alarm) async {
    if (!await confirmAction(
      context,
      title: 'حذف زنگ؟',
      message: '«' + alarm.label + '» از زنگ‌ها حذف می‌شه.',
      action: 'حذف',
      destructive: true,
    ))
      return;
    await _commit(_alarms.where((a) => a.id != alarm.id).toList());
  }

  Future<bool> _deleteGroup(AlarmGroup group) async {
    if (_busy) return false;
    _readGeneration++;
    final old = _alarms;
    final next = old
        .map((a) => a.groupId == group.id ? a.copyWith(clearGroup: true) : a)
        .toList();
    setState(() => _busy = true);
    var alarmsWritten = false;
    try {
      final result = await widget.storage.saveAndSync(next);
      alarmsWritten = true;
      await widget.settings.update(
        widget.settings.settings.copyWith(
          groups: widget.settings.settings.groups
              .where((g) => g.id != group.id)
              .toList(),
        ),
      );
      if (mounted)
        setState(() {
          _alarms = next;
          _permissions = result.permissions;
          _scheduleIncomplete =
              result.scheduleError != null ||
              result.scheduledCount < next.where((a) => a.isEnabled).length;
          if (_group == group.id) _group = null;
        });
      if (_scheduleIncomplete)
        _message('زنگ‌ها ذخیره شدن، اما زمان‌بندی کامل نشده؛ دوباره تلاش کن.');
      return true;
    } catch (e) {
      if (alarmsWritten) {
        try {
          final restored = await widget.storage.saveAndSync(old);
          if (mounted)
            setState(() {
              _permissions = restored.permissions;
              _scheduleIncomplete =
                  restored.scheduleError != null ||
                  restored.scheduledCount <
                      old.where((a) => a.isEnabled).length;
            });
        } catch (_) {
          await _load(silent: true);
          _message(
            'برگرداندن گروه کامل نشد؛ وضعیت ذخیره‌شده دوباره خوانده شد.',
          );
        }
      }
      _message(_error(e));
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _toggleGroup(AlarmGroup group, bool enabled) => _commit(
    _alarms
        .map((a) => a.groupId == group.id ? a.copyWith(isEnabled: enabled) : a)
        .toList(),
  );
  void _manageGroups() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => GroupManagerScreen(
        controller: widget.settings,
        alarms: () => _alarms,
        onDelete: _deleteGroup,
        onToggle: _toggleGroup,
      ),
    ),
  );
  List<Alarm> _filtered() {
    final query = _search.text.trim().toLowerCase();
    final groups = widget.settings.settings.groups;
    final list = _alarms
        .where(
          (a) =>
              (_group == null || a.groupId == _group) &&
              (query.isEmpty ||
                  a.label.toLowerCase().contains(query) ||
                  alarmTime(a).contains(query) ||
                  groups.any(
                    (g) =>
                        g.id == a.groupId &&
                        g.name.toLowerCase().contains(query),
                  )),
        )
        .toList();
    final now = DateTime.now();
    list.sort((a, b) {
      final result = switch (_sort) {
        AlarmSort.name => a.label.compareTo(b.label),
        AlarmSort.time => (a.hour * 60 + a.minute).compareTo(
          b.hour * 60 + b.minute,
        ),
        AlarmSort.next => (a.nextOccurrence(now) ?? DateTime(9999)).compareTo(
          b.nextOccurrence(now) ?? DateTime(9999),
        ),
      };
      return result == 0 ? a.id.compareTo(b.id) : result;
    });
    return list;
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.settings,
    builder: (context, _) {
      final filtered = _filtered();
      final scheme = Theme.of(context).colorScheme;
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'AlarmXV',
                                      textDirection: TextDirection.ltr,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -1,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'صبح از اینجا شروع می‌شه',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              ClayPress(
                                child: ClaySurface(
                                  padding: EdgeInsets.zero,
                                  radius: 18,
                                  child: IconButton(
                                    tooltip: 'تنظیمات',
                                    onPressed: () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => SettingsScreen(
                                          controller: widget.settings,
                                        ),
                                      ),
                                    ),
                                    icon: const Icon(Icons.tune_rounded),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 26),
                          if (!_loading && _loadError == null)
                            _NextAlarmHero(
                              alarms: _alarms,
                              ready:
                                  _permissions?.allGranted == true &&
                                  !_scheduleIncomplete,
                              schedulingFailed: _scheduleIncomplete,
                              onTap: _edit,
                            ),
                          if (_permissions case final permissions?
                              when !permissions.allGranted) ...[
                            const SizedBox(height: 18),
                            _permissionPanel(permissions),
                          ],
                          if (_scheduleIncomplete &&
                              _permissions?.allGranted == true) ...[
                            const SizedBox(height: 18),
                            ClaySurface(
                              elevated: false,
                              color: scheme.errorContainer,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'زمان‌بندی کامل نشده',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'زنگ‌ها ذخیره شدن، اما اندروید زمان‌بندی همهٔ زنگ‌ها رو تأیید نکرده.',
                                  ),
                                  const SizedBox(height: 10),
                                  OutlinedButton(
                                    onPressed: _busy ? null : _retryScheduling,
                                    child: const Text(
                                      'تلاش دوباره برای زمان‌بندی',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          SectionHeading(
                            'زنگ‌های من',
                            subtitle:
                                _alarms
                                    .where((a) => a.isEnabled)
                                    .length
                                    .toString() +
                                ' زنگ فعال از ' +
                                _alarms.length.toString(),
                            trailing: PopupMenuButton<AlarmSort>(
                              tooltip: 'مرتب‌سازی',
                              initialValue: _sort,
                              onSelected: (v) => setState(() => _sort = v),
                              icon: const Icon(Icons.sort_rounded),
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: AlarmSort.next,
                                  child: Text('نزدیک‌ترین زنگ'),
                                ),
                                PopupMenuItem(
                                  value: AlarmSort.time,
                                  child: Text('ساعت زنگ'),
                                ),
                                PopupMenuItem(
                                  value: AlarmSort.name,
                                  child: Text('نام زنگ'),
                                ),
                              ],
                            ),
                          ),
                          TextField(
                            controller: _search,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'جست‌وجوی زنگ یا گروه',
                              prefixIcon: const Icon(Icons.search_rounded),
                              suffixIcon: _search.text.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'پاک‌کردن جست‌وجو',
                                      onPressed: () => setState(_search.clear),
                                      icon: const Icon(Icons.close_rounded),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: [
                                ChoiceChip(
                                  label: const Text('همه'),
                                  selected: _group == null,
                                  onSelected: (_) =>
                                      setState(() => _group = null),
                                ),
                                for (final group
                                    in widget.settings.settings.groups) ...[
                                  const SizedBox(width: 8),
                                  ChoiceChip(
                                    avatar: Icon(
                                      groupIcon(group.icon),
                                      size: 17,
                                    ),
                                    label: Text(group.name),
                                    selected: _group == group.id,
                                    onSelected: (_) =>
                                        setState(() => _group = group.id),
                                  ),
                                ],
                                const SizedBox(width: 8),
                                ActionChip(
                                  avatar: const Icon(
                                    Icons.folder_open_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('گروه‌ها'),
                                  onPressed: _busy ? null : _manageGroups,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_loading)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(48),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    )
                  else if (_loadError != null)
                    SliverToBoxAdapter(
                      child: _empty(
                        Icons.error_outline_rounded,
                        _loadError!,
                        'اطلاعات قبلی حذف نشده؛ دوباره امتحان کن.',
                        action: 'تلاش دوباره',
                        onAction: _load,
                      ),
                    )
                  else if (filtered.isEmpty)
                    SliverToBoxAdapter(
                      child: _empty(
                        _alarms.isEmpty
                            ? Icons.alarm_add_rounded
                            : Icons.search_off_rounded,
                        _alarms.isEmpty
                            ? 'اولین صبحِ برنامه‌ریزی‌شده'
                            : 'زنگی پیدا نشد',
                        _alarms.isEmpty
                            ? 'زمان، روزها و مأموریت بیدارشدن رو انتخاب کن.'
                            : 'جست‌وجو یا فیلتر گروه رو عوض کن.',
                        action: _alarms.isEmpty
                            ? 'ساخت اولین زنگ'
                            : 'نمایش همه',
                        onAction: _alarms.isEmpty
                            ? _edit
                            : () => setState(() {
                                _search.clear();
                                _group = null;
                              }),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      sliver: _AnimatedAlarmSliver(
                        alarms: filtered,
                        builder: _alarmCard,
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 30)),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 12),
                child: ClayPress(
                  child: FilledButton.icon(
                    onPressed: _busy || _loading || _loadError != null
                        ? null
                        : _edit,
                    icon: _busy
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_alarm_rounded),
                    label: const Text('زنگ جدید'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
  Widget _empty(
    IconData icon,
    String title,
    String subtitle, {
    required String action,
    required VoidCallback onAction,
  }) => Padding(
    padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
    child: ClaySurface(
      child: Column(
        children: [
          Icon(icon, size: 44, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          OutlinedButton(onPressed: onAction, child: Text(action)),
        ],
      ),
    ),
  );
  Widget _alarmCard(Alarm alarm) {
    final scheme = Theme.of(context).colorScheme;
    final group = widget.settings.settings.groups
        .where((g) => g.id == alarm.groupId)
        .firstOrNull;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ClayPress(
        child: ClaySurface(
          onTap: _busy ? null : () => _edit(alarm),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              alarmTime(alarm),
                              style: Theme.of(context).textTheme.displaySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1.8,
                                    color: alarm.isEnabled
                                        ? scheme.onSurface
                                        : scheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          alarm.label,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Switch(
                    value: alarm.isEnabled,
                    onChanged: _busy ? null : (v) => _toggle(alarm, v),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'گزینه‌های ' + alarm.label,
                    enabled: !_busy,
                    padding: EdgeInsets.zero,
                    onSelected: (v) {
                      switch (v) {
                        case 'edit':
                          _edit(alarm);
                        case 'copy':
                          _duplicate(alarm);
                        case 'delete':
                          _delete(alarm);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('ویرایش')),
                      PopupMenuItem(value: 'copy', child: Text('ساخت کپی')),
                      PopupMenuItem(value: 'delete', child: Text('حذف زنگ')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                alarmDays(alarm.weekdays),
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant, height: 1.6),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  if (group != null)
                    StatusPill(
                      group.name,
                      icon: groupIcon(group.icon),
                      color: accessibleGroupColor(context, Color(group.color)),
                    ),
                  StatusPill(
                    alarm.challenges.take(2).map(missionName).join('، ') +
                        (alarm.challenges.length > 2
                            ? ' +' + (alarm.challenges.length - 2).toString()
                            : ''),
                    icon: Icons.bolt_rounded,
                  ),
                  if (alarm.wakeCheck.enabled)
                    const StatusPill(
                      'بررسی بیداری',
                      icon: Icons.verified_outlined,
                    ),
                  if (!alarm.isEnabled)
                    StatusPill('خاموش', color: scheme.onSurfaceVariant),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _permissionPanel(AlarmPermissionStatus status) => ClaySurface(
    elevated: false,
    color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: .55),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'برای زنگ مطمئن، دسترسی‌ها رو کامل کن',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        const Text(
          'اندروید برای زمان دقیق و نمایش زنگ روی صفحه قفل به این دسترسی‌ها نیاز داره.',
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (!status.exactAlarm)
              OutlinedButton(
                onPressed: () =>
                    _permissionAction(widget.storage.openExactAlarmSettings),
                child: const Text('زمان دقیق'),
              ),
            if (!status.notifications)
              OutlinedButton(
                onPressed: () => _permissionAction(() async {
                  await widget.storage.requestNotificationPermission();
                  final p = await widget.storage.permissionStatus();
                  if (!p.notifications)
                    await widget.storage.openNotificationSettings();
                }),
                child: const Text('اعلان‌ها'),
              ),
            if (!status.fullScreen)
              OutlinedButton(
                onPressed: () =>
                    _permissionAction(widget.storage.openFullScreenSettings),
                child: const Text('نمایش تمام‌صفحه'),
              ),
            if (!status.overlay)
              OutlinedButton(
                onPressed: () =>
                    _permissionAction(widget.storage.openOverlaySettings),
                child: const Text('نمایش روی برنامه‌ها'),
              ),
          ],
        ),
      ],
    ),
  );
  Future<void> _permissionAction(Future<void> Function() action) async {
    try {
      await action();
      final status = await widget.storage.permissionStatus();
      if (mounted) setState(() => _permissions = status);
    } catch (_) {
      _message('تنظیمات دسترسی باز نشد؛ دوباره تلاش کن.');
    }
  }
}

class _NextAlarmHero extends StatefulWidget {
  const _NextAlarmHero({
    required this.alarms,
    required this.ready,
    required this.schedulingFailed,
    required this.onTap,
  });
  final List<Alarm> alarms;
  final bool ready;
  final bool schedulingFailed;
  final ValueChanged<Alarm> onTap;
  @override
  State<_NextAlarmHero> createState() => _NextAlarmHeroState();
}

class _NextAlarmHeroState extends State<_NextAlarmHero> {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final active =
        widget.alarms.where((a) => a.nextOccurrence(now) != null).toList()
          ..sort(
            (a, b) => a.nextOccurrence(now)!.compareTo(b.nextOccurrence(now)!),
          );
    final alarm = active.firstOrNull;
    final scheme = Theme.of(context).colorScheme;
    final remaining = alarm?.nextOccurrence(now)?.difference(now);
    final minutes = remaining == null ? 0 : (remaining.inSeconds / 60).ceil();
    final countdown = minutes < 60
        ? '$minutes دقیقه دیگه'
        : (minutes ~/ 60).toString() +
              ' ساعت و ' +
              (minutes % 60).toString() +
              ' دقیقه دیگه';
    return ClaySurface(
      color: Color.alphaBlend(
        scheme.primary.withValues(alpha: .08),
        ClayTokens.of(context).surface,
      ),
      onTap: alarm == null ? null : () => widget.onTap(alarm),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'بیداری بعدی',
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              StatusPill(
                alarm == null
                    ? 'آرامش فعلاً'
                    : widget.ready
                    ? 'آماده زنگ'
                    : widget.schedulingFailed
                    ? 'نیاز به بررسی'
                    : 'نیاز به دسترسی',
                icon: alarm == null
                    ? Icons.nights_stay_outlined
                    : widget.ready
                    ? Icons.check_circle_outline_rounded
                    : Icons.info_outline_rounded,
                color: alarm != null && widget.ready
                    ? ClayTokens.of(context).success
                    : scheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          alarm == null ? '— — : — —' : alarmTime(alarm),
                          style: Theme.of(context).textTheme.displayLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -3,
                                color: scheme.primary,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      alarm?.label ?? 'هیچ زنگ فعالی نداری',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              if (MediaQuery.sizeOf(context).width > 360 &&
                  MediaQuery.textScalerOf(context).scale(1) < 1.5) ...[
                const SizedBox(width: 16),
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: .7),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: ClayTokens.of(context).border),
                    boxShadow: ClayTokens.of(context).depth,
                  ),
                  child: Icon(
                    Icons.alarm_rounded,
                    size: 38,
                    color: scheme.primary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          Text(
            alarm == null
                ? 'یک زنگ بساز یا زنگ‌های خاموش رو روشن کن.'
                : countdown,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _AnimatedAlarmSliver extends StatefulWidget {
  const _AnimatedAlarmSliver({required this.alarms, required this.builder});
  final List<Alarm> alarms;
  final Widget Function(Alarm) builder;
  @override
  State<_AnimatedAlarmSliver> createState() => _AnimatedAlarmSliverState();
}

class _AnimatedAlarmSliverState extends State<_AnimatedAlarmSliver> {
  final _key = GlobalKey<SliverAnimatedListState>();
  late List<Alarm> _items;
  @override
  void initState() {
    super.initState();
    _items = [...widget.alarms];
  }

  @override
  void didUpdateWidget(covariant _AnimatedAlarmSliver oldWidget) {
    super.didUpdateWidget(oldWidget);
    final duration = reduceMotion(context) ? Duration.zero : ClayTokens.motion;
    for (var i = _items.length - 1; i >= 0; i--) {
      if (!widget.alarms.any((a) => a.id == _items[i].id)) {
        final removed = _items.removeAt(i);
        _key.currentState?.removeItem(
          i,
          (_, animation) => SizeTransition(
            sizeFactor: animation,
            child: FadeTransition(
              opacity: animation,
              child: widget.builder(removed),
            ),
          ),
          duration: duration,
        );
      }
    }
    for (var i = 0; i < widget.alarms.length; i++) {
      final alarm = widget.alarms[i];
      if (i < _items.length && _items[i].id == alarm.id) {
        _items[i] = alarm;
        continue;
      }
      final oldIndex = _items.indexWhere((a) => a.id == alarm.id);
      if (oldIndex >= 0) {
        final removed = _items.removeAt(oldIndex);
        _key.currentState?.removeItem(
          oldIndex,
          (_, animation) => SizeTransition(
            sizeFactor: animation,
            child: widget.builder(removed),
          ),
          duration: duration,
        );
      }
      _items.insert(i, alarm);
      _key.currentState?.insertItem(i, duration: duration);
    }
  }

  @override
  Widget build(BuildContext context) => SliverAnimatedList(
    key: _key,
    initialItemCount: _items.length,
    itemBuilder: (context, index, animation) => RepaintBoundary(
      child: SizeTransition(
        sizeFactor: animation.drive(CurveTween(curve: Curves.easeOutCubic)),
        child: FadeTransition(
          opacity: animation,
          child: widget.builder(_items[index]),
        ),
      ),
    ),
  );
}
