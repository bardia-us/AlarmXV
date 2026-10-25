import '../l10n/app_strings.dart';

import 'package:flutter/material.dart';

import '../challenges/challenge_type.dart';
import '../models/alarm.dart';
import '../models/alarm_group.dart';
import '../models/mission_settings.dart';
import '../models/wake_check_settings.dart';
import '../services/alarm_storage.dart';
import '../theme/clay_theme.dart';
import '../screens/group_manager_screen.dart';
import 'clay_components.dart';

String missionName(BuildContext context, ChallengeType type) => switch (type) {
  ChallengeType.math => context.tr("ریاضی"),
  ChallengeType.memory => context.tr("حافظه"),
  ChallengeType.shake => context.tr("تکان‌دادن"),
  ChallengeType.typing => context.tr("تایپ عبارت"),
  ChallengeType.order => context.tr("ترتیب اعداد"),
};
IconData missionIcon(ChallengeType type) => switch (type) {
  ChallengeType.math => Icons.calculate_outlined,
  ChallengeType.memory => Icons.grid_view_rounded,
  ChallengeType.shake => Icons.vibration_rounded,
  ChallengeType.typing => Icons.keyboard_outlined,
  ChallengeType.order => Icons.format_list_numbered_rounded,
};

class AlarmEditorSheet extends StatefulWidget {
  const AlarmEditorSheet({
    super.key,
    this.alarm,
    this.groups = const [],
    this.defaultSnoozeMinutes = 5,
    this.storage = const AlarmStorage(),
  });
  final Alarm? alarm;
  final List<AlarmGroup> groups;
  final int defaultSnoozeMinutes;
  final AlarmStorage storage;
  @override
  State<AlarmEditorSheet> createState() => _AlarmEditorSheetState();
}

class _AlarmEditorSheetState extends State<AlarmEditorSheet> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _label, _phrase;
  late TimeOfDay _time;
  late Set<int> _days;
  late List<ChallengeType> _challenges;
  late MissionSettings _mission;
  late AlarmMode _mode;
  late String _volumeMode;
  late int _volumePercent;
  bool get _isChallenge => _mode == AlarmMode.challenge;
  double get _footerSpace =>
      124 +
      MediaQuery.paddingOf(context).bottom +
      MediaQuery.textScalerOf(context).scale(24);
  late bool _enabled, _protectVolume, _wakeEnabled;
  late int _snooze, _maxSnoozes, _wakeDelay, _wakeTimeout, _wakeCount;
  String? _groupId, _soundUri;
  late String _soundName;
  bool _pickingSound = false;
  @override
  void initState() {
    super.initState();
    final a = widget.alarm;
    _mode = a?.mode ?? AlarmMode.challenge;
    _volumeMode = a?.volumeMode ?? 'system';
    _volumePercent = a?.volumePercent ?? 70;
    _label = TextEditingController(text: a?.label ?? '');
    _mission = a?.missionSettings ?? const MissionSettings();
    _phrase = TextEditingController(text: _mission.typingPhrase);
    _time = a == null
        ? const TimeOfDay(hour: 7, minute: 0)
        : TimeOfDay(hour: a.hour, minute: a.minute);
    _days = {...?a?.weekdays};
    if (a == null) _days.addAll({1, 2, 3, 4, 5});
    _challenges = a?.challenges.toList() ?? [ChallengeType.math];
    _enabled = a?.isEnabled ?? true;
    _protectVolume = a?.preventVolumeReduction ?? true;
    _snooze = a?.snoozeMinutes ?? widget.defaultSnoozeMinutes;
    _maxSnoozes = a?.maxSnoozes ?? 3;
    _wakeEnabled = a?.wakeCheck.enabled ?? false;
    _wakeDelay = a?.wakeCheck.delayMinutes ?? 3;
    _wakeTimeout = 60;
    _wakeCount = a?.wakeCheck.checkCount ?? 1;
    _groupId = widget.groups.any((g) => g.id == a?.groupId) ? a?.groupId : null;
    _soundUri = a?.alarmSoundUri;
    _soundName = a?.alarmSoundName ?? 'صدای پیش‌فرض گوشی';
  }

  @override
  void dispose() {
    _label.dispose();
    _phrase.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final result = await showTimePicker(
      context: context,
      initialTime: _time,
      helpText: context.tr("زمان بیداری"),
      cancelText: context.tr("انصراف"),
      confirmText: context.tr("تأیید"),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (result != null && mounted) setState(() => _time = result);
  }

  Future<void> _pickSound() async {
    setState(() => _pickingSound = true);
    try {
      final result = await widget.storage.pickAlarmSound(_soundUri);
      if (result != null && mounted)
        setState(() {
          _soundUri = result.uri.isEmpty ? null : result.uri;
          _soundName = result.name;
        });
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr("انتخاب صدای گوشی باز نشد؛ دوباره امتحان کن."),
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _pickingSound = false);
    }
  }

  void _save() {
    if (!_form.currentState!.validate() ||
        _days.isEmpty ||
        (_isChallenge && _challenges.isEmpty))
      return;
    Navigator.pop(
      context,
      Alarm(
        id:
            widget.alarm?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        label: _label.text.trim().isEmpty
            ? context.tr("زنگ بیداری")
            : _label.text.trim(),
        hour: _time.hour,
        minute: _time.minute,
        weekdays: Set.unmodifiable(_days),
        isEnabled: _enabled,
        mode: _mode,
        volumeMode: _volumeMode,
        volumePercent: _volumePercent,
        challenges: Set.unmodifiable(_challenges),
        groupId: _groupId,
        missionSettings: _mission.copyWith(typingPhrase: _phrase.text.trim()),
        snoozeMinutes: _snooze,
        maxSnoozes: _maxSnoozes,
        preventVolumeReduction: _protectVolume,
        alarmSoundUri: _soundUri,
        alarmSoundName: _soundName,
        wakeCheck: WakeCheckSettings(
          enabled: _wakeEnabled,
          delayMinutes: _wakeDelay,
          timeoutSeconds: _wakeTimeout,
          checkCount: _wakeCount,
        ),
      ),
    );
  }

  Widget _section(String title, Widget child, {String? subtitle}) => Padding(
    padding: const EdgeInsets.only(bottom: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeading(title, subtitle: subtitle),
        ClaySurface(child: child),
      ],
    ),
  );
  void _moveMission(int index, int delta) => setState(() {
    final type = _challenges.removeAt(index);
    _challenges.insert(index + delta, type);
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final footerSpace = _footerSpace;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .95,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  Expanded(
                    child: Form(
                      key: _form,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(22, 8, 22, footerSpace),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 18),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.alarm == null
                                          ? context.tr("یک بیداری تازه")
                                          : context.tr("ویرایش زنگ"),
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: context.tr("بستن ویرایشگر"),
                                    onPressed: () => Navigator.pop(context),
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                                ],
                              ),
                            ),
                            ClayPress(
                              child: ClaySurface(
                                onTap: _pickTime,
                                color: Color.alphaBlend(
                                  theme.colorScheme.primary.withValues(
                                    alpha: .08,
                                  ),
                                  ClayTokens.of(context).surface,
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      context.tr("زمان زنگ"),
                                      style: theme.textTheme.labelLarge,
                                    ),
                                    const SizedBox(height: 8),
                                    Directionality(
                                      textDirection: TextDirection.ltr,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          _time.hour.toString().padLeft(
                                                2,
                                                '0',
                                              ) +
                                              ':' +
                                              _time.minute.toString().padLeft(
                                                2,
                                                '0',
                                              ),
                                          style: theme.textTheme.displayLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: -2,
                                                color:
                                                    theme.colorScheme.primary,
                                              ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(context.tr("برای تغییر ساعت بزن")),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),
                            _section(
                              context.tr("نوع زنگ"),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      ChoiceChip(
                                        avatar: const Icon(
                                          Icons.alarm_rounded,
                                          size: 18,
                                        ),
                                        label: Text(context.tr("زنگ عادی")),
                                        selected: !_isChallenge,
                                        onSelected: (_) => setState(
                                          () => _mode = AlarmMode.normal,
                                        ),
                                      ),
                                      ChoiceChip(
                                        avatar: const Icon(
                                          Icons.bolt_rounded,
                                          size: 18,
                                        ),
                                        label: Text(
                                          context.tr("بیداری مأموریتی"),
                                        ),
                                        selected: _isChallenge,
                                        onSelected: (_) => setState(
                                          () => _mode = AlarmMode.challenge,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    _isChallenge
                                        ? context.tr(
                                            "برای خاموش‌کردن زنگ، مأموریت‌هایی که انتخاب می‌کنی انجام می‌شن.",
                                          )
                                        : context.tr(
                                            "با دکمهٔ توقف خاموش می‌شه؛ بدون مأموریت و بررسی بیداری. بلندی صدا هم دست خودته.",
                                          ),
                                  ),
                                ],
                              ),
                            ),
                            TextFormField(
                              controller: _label,
                              scrollPadding: EdgeInsets.only(
                                bottom: footerSpace,
                              ),
                              maxLength: 40,
                              decoration: InputDecoration(
                                labelText: context.tr("نام زنگ"),
                                hintText: context.tr("مثلاً یک شروع زودهنگام"),
                                counterText: '',
                              ),
                            ),
                            const SizedBox(height: 16),
                            ClaySelectionTile<String>(
                              label: context.tr("گروه زنگ"),
                              value: _groupId ?? '',
                              options: [
                                ClaySelectionOption(
                                  value: '',
                                  label: context.tr("بدون گروه"),
                                  icon: Icons.alarm_rounded,
                                ),
                                for (final group in widget.groups)
                                  ClaySelectionOption(
                                    value: group.id,
                                    label: group.name,
                                    icon: groupIcon(group.icon),
                                  ),
                              ],
                              onChanged: (value) => setState(
                                () => _groupId = value.isEmpty ? null : value,
                              ),
                            ),
                            const SizedBox(height: 22),
                            _section(
                              context.tr("روزهای تکرار"),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 7,
                                    runSpacing: 7,
                                    children: [
                                      for (final day in [6, 7, 1, 2, 3, 4, 5])
                                        FilterChip(
                                          label: Text(
                                            [
                                              context.tr("دوشنبه"),
                                              context.tr("سه‌شنبه"),
                                              context.tr("چهارشنبه"),
                                              context.tr("پنجشنبه"),
                                              context.tr("جمعه"),
                                              context.tr("شنبه"),
                                              context.tr("یکشنبه"),
                                            ][day - 1],
                                          ),
                                          selected: _days.contains(day),
                                          onSelected: (selected) =>
                                              setState(() {
                                                selected
                                                    ? _days.add(day)
                                                    : _days.remove(day);
                                              }),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      TextButton(
                                        onPressed: () => setState(
                                          () => _days = {1, 2, 3, 4, 5, 6, 7},
                                        ),
                                        child: Text(context.tr("هر روز")),
                                      ),
                                      TextButton(
                                        onPressed: () => setState(
                                          () => _days = {6, 7, 1, 2, 3},
                                        ),
                                        child: Text(
                                          context.tr("شنبه تا چهارشنبه"),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_days.isEmpty)
                                    Text(
                                      context.tr("حداقل یک روز انتخاب کن."),
                                      style: TextStyle(
                                        color: theme.colorScheme.error,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (_isChallenge)
                              _section(
                                context.tr("مأموریت بیدارشدن"),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      spacing: 7,
                                      runSpacing: 7,
                                      children: [
                                        for (final type in ChallengeType.values)
                                          FilterChip(
                                            avatar: Icon(
                                              missionIcon(type),
                                              size: 18,
                                            ),
                                            label: Text(
                                              missionName(context, type),
                                            ),
                                            selected: _challenges.contains(
                                              type,
                                            ),
                                            onSelected: (selected) => setState(
                                              () {
                                                selected
                                                    ? _challenges.add(type)
                                                    : _challenges.remove(type);
                                              },
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (_challenges.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 12),
                                        child: Text(
                                          context.tr(
                                            "برای خاموش‌کردن زنگ حداقل یک مأموریت انتخاب کن.",
                                          ),
                                          style: TextStyle(
                                            color: theme.colorScheme.error,
                                          ),
                                        ),
                                      ),
                                    for (
                                      var i = 0;
                                      i < _challenges.length;
                                      i++
                                    ) ...[
                                      const SizedBox(height: 14),
                                      Divider(
                                        color: theme.colorScheme.outlineVariant
                                            .withValues(alpha: .6),
                                      ),
                                      Row(
                                        children: [
                                          StatusPill((i + 1).toString()),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              missionName(
                                                context,
                                                _challenges[i],
                                              ),
                                              style: theme.textTheme.titleSmall,
                                            ),
                                          ),
                                          IconButton(
                                            tooltip: context.tr(
                                              "مأموریت بالاتر",
                                            ),
                                            onPressed: i == 0
                                                ? null
                                                : () => _moveMission(i, -1),
                                            icon: const Icon(
                                              Icons.arrow_upward_rounded,
                                              size: 18,
                                            ),
                                          ),
                                          IconButton(
                                            tooltip: context.tr(
                                              "مأموریت پایین‌تر",
                                            ),
                                            onPressed:
                                                i == _challenges.length - 1
                                                ? null
                                                : () => _moveMission(i, 1),
                                            icon: const Icon(
                                              Icons.arrow_downward_rounded,
                                              size: 18,
                                            ),
                                          ),
                                        ],
                                      ),
                                      _missionControls(_challenges[i]),
                                    ],
                                  ],
                                ),
                                subtitle: context.tr(
                                  "مأموریت‌ها به همین ترتیب اجرا می‌شن؛ ترتیب و سختی رو خودت انتخاب کن.",
                                ),
                              ),
                            _section(
                              context.tr("تعویق زنگ"),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClaySelectionTile<int>(
                                    label: context.tr("مدت تعویق"),
                                    value: _snooze,
                                    options: [
                                      for (final minutes in ({
                                        0,
                                        5,
                                        10,
                                        15,
                                        _snooze,
                                      }.toList()..sort()))
                                        ClaySelectionOption(
                                          value: minutes,
                                          label: minutes == 0
                                              ? context.tr("بدون تعویق")
                                              : context.tr("{p0} دقیقه", {
                                                  'p0': minutes,
                                                }),
                                          icon: Icons.snooze_rounded,
                                        ),
                                    ],
                                    onChanged: (value) =>
                                        setState(() => _snooze = value),
                                  ),
                                  if (_snooze > 0)
                                    NumberControl(
                                      label: context.tr("حداکثر دفعات تعویق"),
                                      value: _maxSnoozes,
                                      min: 0,
                                      max: 10,
                                      onChanged: (value) =>
                                          setState(() => _maxSnoozes = value),
                                    ),
                                ],
                              ),
                            ),
                            SectionHeading(context.tr("صدای زنگ")),
                            ClaySurface(
                              onTap: _pickingSound ? null : _pickSound,
                              padding: const EdgeInsets.all(18),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.music_note_rounded,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          context.tr("انتخاب صدای زنگ"),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          _soundUri == null
                                              ? context.tr('صدای پیش‌فرض گوشی')
                                              : _soundName,
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  _pickingSound
                                      ? const SizedBox.square(
                                          dimension: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.chevron_left_rounded),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_isChallenge)
                              ClaySurface(
                                elevated: false,
                                child: Text(
                                  context.tr(
                                    "بیداری مأموریتی با حداکثر صدای آلارم پخش می‌شه و بعد از پایان، بلندی صدای قبلی برمی‌گرده.",
                                  ),
                                  style: const TextStyle(height: 1.6),
                                ),
                              )
                            else
                              _normalVolumeControls(),
                            const SizedBox(height: 22),
                            if (_isChallenge)
                              _section(
                                context.tr("بررسی بیداری"),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SwitchListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        context.tr("مطمئن شو بیدار موندی"),
                                      ),
                                      subtitle: Text(
                                        context.tr(
                                          "اگر تأیید نکنی، زنگ دوباره شروع می‌شه.",
                                        ),
                                      ),
                                      value: _wakeEnabled,
                                      onChanged: (value) =>
                                          setState(() => _wakeEnabled = value),
                                    ),
                                    if (_wakeEnabled) ...[
                                      const SizedBox(height: 12),
                                      _dropdown(
                                        context.tr("بررسی بعد از"),
                                        _wakeDelay,
                                        {2, 3, 5, 10, _wakeDelay},
                                        (value) =>
                                            setState(() => _wakeDelay = value),
                                        unit: context.tr("دقیقه"),
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        context.tr(
                                          "مهلت تأیید هر بررسی ۶۰ ثانیه است؛ اگر تأیید نکنی، زنگ دوباره شروع می‌شه.",
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      NumberControl(
                                        label: context.tr("دفعات بررسی"),
                                        value: _wakeCount,
                                        max: 5,
                                        onChanged: (value) =>
                                            setState(() => _wakeCount = value),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(context.tr("زنگ روشن باشه")),
                              value: _enabled,
                              onChanged: (value) =>
                                  setState(() => _enabled = value),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              PositionedDirectional(
                start: 0,
                end: 0,
                bottom: 0,
                child: ClayActionFooter(
                  child: ClayPress(
                    child: FilledButton.icon(
                      onPressed:
                          _days.isEmpty || (_isChallenge && _challenges.isEmpty)
                          ? null
                          : _save,
                      icon: const Icon(Icons.check_rounded),
                      label: Text(
                        widget.alarm == null
                            ? context.tr("ذخیره زنگ")
                            : context.tr("ذخیره تغییرات"),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _normalVolumeControls() => _section(
    context.tr("بلندی صدای زنگ"),
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClaySelectionTile<String>(
          label: context.tr("کنترل بلندی صدا"),
          value: _volumeMode,
          options: [
            ClaySelectionOption(
              value: 'system',
              label: context.tr("صدای آلارم گوشی"),
              icon: Icons.volume_up_rounded,
              description: context.tr(
                "از بلندی صدای آلارم در تنظیمات گوشی استفاده می‌کنه.",
              ),
            ),
            ClaySelectionOption(
              value: 'custom',
              label: context.tr("صدای دلخواه این زنگ"),
              icon: Icons.tune_rounded,
              description: context.tr("بلندی صدای همین زنگ رو خودت انتخاب کن."),
            ),
          ],
          onChanged: (value) => setState(() => _volumeMode = value),
        ),
        if (_volumeMode == 'custom') ...[
          const SizedBox(height: 16),
          Text(
            context.tr("بلندی صدا: {p0}٪", {'p0': _volumePercent}),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Slider(
            value: _volumePercent.toDouble(),
            min: 0,
            max: 100,
            divisions: 100,
            label: context.tr("{p0}٪", {'p0': _volumePercent}),
            onChanged: (value) =>
                setState(() => _volumePercent = value.round()),
          ),
          Text(
            _volumePercent == 0
                ? context.tr("۰٪ یعنی این زنگ بدون صدای زنگ پخش می‌شه.")
                : context.tr(
                    "بعد از پایان زنگ، بلندی صدای قبلی گوشی برمی‌گرده.",
                  ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    ),
  );

  Widget _dropdown(
    String label,
    int value,
    Set<int> values,
    ValueChanged<int> onChanged, {
    String unit = '',
  }) => ClaySelectionTile<int>(
    label: label,
    value: value,
    options: [
      for (final item in (values.toList()..sort()))
        ClaySelectionOption(
          value: item,
          label: '$item $unit',
          icon: Icons.schedule_rounded,
        ),
    ],
    onChanged: onChanged,
  );
  Widget _missionControls(ChallengeType type) => switch (type) {
    ChallengeType.math => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final item in {
              'easy': context.tr("آسان"),
              'medium': context.tr("متوسط"),
              'hard': context.tr("سخت"),
              'custom': context.tr("دلخواه"),
            }.entries)
              ChoiceChip(
                label: Text(item.value),
                selected: _mission.mathDifficulty == item.key,
                onSelected: (_) => setState(
                  () => _mission = _mission.copyWith(
                    mathDifficulty: item.key,
                    mathMaxOperand: switch (item.key) {
                      'easy' => 20,
                      'medium' => 90,
                      'hard' => 999,
                      _ => _mission.mathMaxOperand,
                    },
                  ),
                ),
              ),
          ],
        ),
        NumberControl(
          label: context.tr("تعداد سؤال"),
          value: _mission.mathQuestions,
          max: 20,
          onChanged: (v) =>
              setState(() => _mission = _mission.copyWith(mathQuestions: v)),
        ),
        if (_mission.mathDifficulty == 'custom')
          NumberControl(
            label: context.tr("بزرگ‌ترین عدد"),
            value: _mission.mathMaxOperand,
            min: 5,
            max: 999,
            step: 10,
            onChanged: (v) =>
                setState(() => _mission = _mission.copyWith(mathMaxOperand: v)),
          ),
        const SizedBox(height: 8),
        Text(context.tr("عملیات")),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final operation in {
              'add': context.tr("جمع +"),
              'subtract': context.tr("تفریق −"),
              'multiply': context.tr("ضرب ×"),
              'divide': context.tr("تقسیم ÷"),
            }.entries)
              FilterChip(
                label: Text(operation.value),
                selected: _mission.mathOperations.contains(operation.key),
                onSelected: (v) {
                  final ops = {..._mission.mathOperations};
                  if (!v && ops.length == 1) return;
                  v ? ops.add(operation.key) : ops.remove(operation.key);
                  setState(
                    () => _mission = _mission.copyWith(mathOperations: ops),
                  );
                },
              ),
          ],
        ),
      ],
    ),
    ChallengeType.memory => Column(
      children: [
        NumberControl(
          label: context.tr("اندازه شبکه"),
          value: _mission.memoryGridSize,
          min: 3,
          max: 5,
          suffix: ' × ' + _mission.memoryGridSize.toString(),
          onChanged: (v) => setState(
            () => _mission = _mission.copyWith(
              memoryGridSize: v,
              memoryTargets: _mission.memoryTargets.clamp(1, v * v - 1),
            ),
          ),
        ),
        NumberControl(
          label: context.tr("خانه‌های هدف"),
          value: _mission.memoryTargets,
          max: _mission.memoryGridSize * _mission.memoryGridSize - 1,
          onChanged: (v) =>
              setState(() => _mission = _mission.copyWith(memoryTargets: v)),
        ),
        NumberControl(
          label: context.tr("تعداد دور"),
          value: _mission.memoryRounds,
          max: 10,
          onChanged: (v) =>
              setState(() => _mission = _mission.copyWith(memoryRounds: v)),
        ),
      ],
    ),
    ChallengeType.shake => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NumberControl(
          label: context.tr("تعداد تکان"),
          value: _mission.shakeCount,
          min: 3,
          max: 100,
          onChanged: (v) =>
              setState(() => _mission = _mission.copyWith(shakeCount: v)),
        ),
        const SizedBox(height: 10),
        Text(context.tr("شدت تکان موردنیاز")),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final item in {
              1.8: context.tr("ملایم"),
              2.4: context.tr("معمولی"),
              3.2: context.tr("محکم"),
            }.entries)
              ChoiceChip(
                label: Text(item.value),
                selected: (_mission.shakeThreshold - item.key).abs() < .1,
                onSelected: (_) => setState(
                  () => _mission = _mission.copyWith(shakeThreshold: item.key),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          context.tr("گوشی رو امن نگه دار؛ تکان کوتاه کافیه."),
          style: const TextStyle(fontSize: 12),
        ),
      ],
    ),
    ChallengeType.typing => Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextFormField(
        controller: _phrase,
        scrollPadding: EdgeInsets.only(bottom: _footerSpace),
        maxLength: 120,
        minLines: 1,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: context.tr("عبارتی که باید تایپ کنی"),
        ),
        validator: (v) => v == null || v.trim().isEmpty
            ? context.tr("یک عبارت وارد کن.")
            : null,
      ),
    ),
    ChallengeType.order => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NumberControl(
          label: context.tr("تعداد اعداد"),
          value: _mission.numberCount,
          min: 4,
          max: 12,
          onChanged: (v) =>
              setState(() => _mission = _mission.copyWith(numberCount: v)),
        ),
        Text(context.tr("هنگام زنگ، اعداد رو از کوچک به بزرگ انتخاب می‌کنی.")),
      ],
    ),
  };
}
