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

String missionName(ChallengeType type) => switch (type) {
  ChallengeType.math => 'ریاضی',
  ChallengeType.memory => 'حافظه',
  ChallengeType.shake => 'تکان‌دادن',
  ChallengeType.typing => 'تایپ عبارت',
  ChallengeType.order => 'ترتیب اعداد',
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
  late bool _enabled, _protectVolume, _wakeEnabled;
  late int _snooze, _maxSnoozes, _wakeDelay, _wakeTimeout, _wakeCount;
  String? _groupId, _soundUri;
  late String _soundName;
  bool _pickingSound = false;
  @override
  void initState() {
    super.initState();
    final a = widget.alarm;
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
      helpText: 'زمان بیداری',
      cancelText: 'انصراف',
      confirmText: 'تأیید',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: Directionality(textDirection: TextDirection.rtl, child: child!),
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
          const SnackBar(
            content: Text('انتخاب صدای گوشی باز نشد؛ دوباره امتحان کن.'),
          ),
        );
    } finally {
      if (mounted) setState(() => _pickingSound = false);
    }
  }

  void _save() {
    if (!_form.currentState!.validate() || _days.isEmpty || _challenges.isEmpty)
      return;
    Navigator.pop(
      context,
      Alarm(
        id:
            widget.alarm?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        label: _label.text.trim().isEmpty ? 'زنگ بیداری' : _label.text.trim(),
        hour: _time.hour,
        minute: _time.minute,
        weekdays: Set.unmodifiable(_days),
        isEnabled: _enabled,
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
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .95,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
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
                    padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
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
                                      ? 'یک بیداری تازه'
                                      : 'ویرایش زنگ',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'بستن ویرایشگر',
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
                              theme.colorScheme.primary.withValues(alpha: .08),
                              ClayTokens.of(context).surface,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'زمان بیداری',
                                  style: theme.textTheme.labelLarge,
                                ),
                                const SizedBox(height: 8),
                                Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      _time.hour.toString().padLeft(2, '0') +
                                          ':' +
                                          _time.minute.toString().padLeft(
                                            2,
                                            '0',
                                          ),
                                      style: theme.textTheme.displayLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -2,
                                            color: theme.colorScheme.primary,
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text('برای تغییر ساعت بزن'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        TextFormField(
                          controller: _label,
                          maxLength: 40,
                          decoration: const InputDecoration(
                            labelText: 'نام زنگ',
                            hintText: 'مثلاً یک شروع زودهنگام',
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _groupId ?? '',
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'گروه زنگ',
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: '',
                              child: Text('بدون گروه'),
                            ),
                            ...widget.groups.map(
                              (g) => DropdownMenuItem(
                                value: g.id,
                                child: Row(
                                  children: [
                                    Icon(groupIcon(g.icon), size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        g.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => _groupId = v == '' ? null : v),
                        ),
                        const SizedBox(height: 22),
                        _section(
                          'روزهای تکرار',
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
                                        const [
                                          'دوشنبه',
                                          'سه‌شنبه',
                                          'چهارشنبه',
                                          'پنجشنبه',
                                          'جمعه',
                                          'شنبه',
                                          'یکشنبه',
                                        ][day - 1],
                                      ),
                                      selected: _days.contains(day),
                                      onSelected: (v) => setState(() {
                                        v ? _days.add(day) : _days.remove(day);
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
                                    child: const Text('هر روز'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        setState(() => _days = {6, 7, 1, 2, 3}),
                                    child: const Text('شنبه تا چهارشنبه'),
                                  ),
                                ],
                              ),
                              if (_days.isEmpty)
                                Text(
                                  'حداقل یک روز انتخاب کن.',
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        _section(
                          'مأموریت بیدارشدن',
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 7,
                                runSpacing: 7,
                                children: [
                                  for (final type in ChallengeType.values)
                                    FilterChip(
                                      avatar: Icon(missionIcon(type), size: 18),
                                      label: Text(missionName(type)),
                                      selected: _challenges.contains(type),
                                      onSelected: (v) => setState(() {
                                        v
                                            ? _challenges.add(type)
                                            : _challenges.remove(type);
                                      }),
                                    ),
                                ],
                              ),
                              if (_challenges.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Text(
                                    'برای خاموش‌کردن زنگ حداقل یک مأموریت انتخاب کن.',
                                    style: TextStyle(
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                ),
                              for (var i = 0; i < _challenges.length; i++) ...[
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
                                        missionName(_challenges[i]),
                                        style: theme.textTheme.titleSmall,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'مأموریت بالاتر',
                                      onPressed: i == 0
                                          ? null
                                          : () => _moveMission(i, -1),
                                      icon: const Icon(
                                        Icons.arrow_upward_rounded,
                                        size: 18,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'مأموریت پایین‌تر',
                                      onPressed: i == _challenges.length - 1
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
                          subtitle: 'مأموریت‌ها به همین ترتیب اجرا می‌شن؛ ترتیب و سختی رو خودت انتخاب کن.',
                        ),
                        _section(
                          'تعویق زنگ',
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final minutes in ({
                                    0,
                                    5,
                                    10,
                                    15,
                                    _snooze,
                                  }.toList()..sort()))
                                    ChoiceChip(
                                      label: Text(
                                        minutes == 0
                                            ? 'خاموش'
                                            : '$minutes دقیقه',
                                      ),
                                      selected: _snooze == minutes,
                                      onSelected: (_) =>
                                          setState(() => _snooze = minutes),
                                    ),
                                ],
                              ),
                              if (_snooze > 0)
                                NumberControl(
                                  label: 'حداکثر دفعات تعویق',
                                  value: _maxSnoozes,
                                  min: 0,
                                  max: 10,
                                  onChanged: (v) =>
                                      setState(() => _maxSnoozes = v),
                                ),
                            ],
                          ),
                        ),
                        const SectionHeading('صدای بیداری'),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'انتخاب صدای زنگ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      _soundName,
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
                        const SizedBox(height: 12),
                        const ClaySurface(
                          elevated: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'زنگ با حداکثر صدای آلارم پخش می‌شه و بعد از پایان، بلندی صدای قبلی برمی‌گرده.',
                                style: TextStyle(height: 1.6),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        _section(
                          'بررسی بیداری',
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('مطمئن شو بیدار موندی'),
                                subtitle: const Text(
                                  'اگر تأیید نکنی، زنگ دوباره شروع می‌شه.',
                                ),
                                value: _wakeEnabled,
                                onChanged: (v) =>
                                    setState(() => _wakeEnabled = v),
                              ),
                              if (_wakeEnabled) ...[
                                const SizedBox(height: 12),
                                _dropdown(
                                  'بررسی بعد از',
                                  _wakeDelay,
                                  {2, 3, 5, 10, _wakeDelay},
                                  (v) => setState(() => _wakeDelay = v),
                                  unit: 'دقیقه',
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'مهلت تأیید هر بررسی ۶۰ ثانیه است؛ اگر تأیید نکنی، زنگ دوباره شروع می‌شه.',
                                ),
                                const SizedBox(height: 8),
                                NumberControl(
                                  label: 'دفعات بررسی',
                                  value: _wakeCount,
                                  max: 5,
                                  onChanged: (v) =>
                                      setState(() => _wakeCount = v),
                                ),
                              ],
                            ],
                          ),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('زنگ روشن باشه'),
                          value: _enabled,
                          onChanged: (v) => setState(() => _enabled = v),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 14),
                child: SizedBox(
                  width: double.infinity,
                  child: ClayPress(
                    child: FilledButton.icon(
                      onPressed: _days.isEmpty || _challenges.isEmpty
                          ? null
                          : _save,
                      icon: const Icon(Icons.check_rounded),
                      label: Text(
                        widget.alarm == null ? 'ذخیره زنگ' : 'ذخیره تغییرات',
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

  Widget _dropdown(
    String label,
    int value,
    Set<int> values,
    ValueChanged<int> onChanged, {
    String unit = '',
  }) => DropdownButtonFormField<int>(
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: (values.toList()..sort())
        .map((v) => DropdownMenuItem(value: v, child: Text('$v $unit')))
        .toList(),
    onChanged: (v) {
      if (v != null) onChanged(v);
    },
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
            for (final item in const {
              'easy': 'آسان',
              'medium': 'متوسط',
              'hard': 'سخت',
              'custom': 'دلخواه',
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
          label: 'تعداد سؤال',
          value: _mission.mathQuestions,
          max: 20,
          onChanged: (v) =>
              setState(() => _mission = _mission.copyWith(mathQuestions: v)),
        ),
        if (_mission.mathDifficulty == 'custom')
          NumberControl(
            label: 'بزرگ‌ترین عدد',
            value: _mission.mathMaxOperand,
            min: 5,
            max: 999,
            step: 10,
            onChanged: (v) =>
                setState(() => _mission = _mission.copyWith(mathMaxOperand: v)),
          ),
        const SizedBox(height: 8),
        const Text('عملیات'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final operation in const {
              'add': 'جمع +',
              'subtract': 'تفریق −',
              'multiply': 'ضرب ×',
              'divide': 'تقسیم ÷',
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
          label: 'اندازه شبکه',
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
          label: 'خانه‌های هدف',
          value: _mission.memoryTargets,
          max: _mission.memoryGridSize * _mission.memoryGridSize - 1,
          onChanged: (v) =>
              setState(() => _mission = _mission.copyWith(memoryTargets: v)),
        ),
        NumberControl(
          label: 'تعداد دور',
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
          label: 'تعداد تکان',
          value: _mission.shakeCount,
          min: 3,
          max: 100,
          onChanged: (v) =>
              setState(() => _mission = _mission.copyWith(shakeCount: v)),
        ),
        const SizedBox(height: 10),
        const Text('شدت تکان موردنیاز'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final item in {
              1.8: 'ملایم',
              2.4: 'معمولی',
              3.2: 'محکم',
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
        const Text(
          'گوشی رو امن نگه دار؛ تکان کوتاه کافیه.',
          style: TextStyle(fontSize: 12),
        ),
      ],
    ),
    ChallengeType.typing => Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextFormField(
        controller: _phrase,
        maxLength: 120,
        minLines: 1,
        maxLines: 3,
        decoration: const InputDecoration(labelText: 'عبارتی که باید تایپ کنی'),
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'یک عبارت وارد کن.' : null,
      ),
    ),
    ChallengeType.order => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NumberControl(
          label: 'تعداد اعداد',
          value: _mission.numberCount,
          min: 4,
          max: 12,
          onChanged: (v) =>
              setState(() => _mission = _mission.copyWith(numberCount: v)),
        ),
        const Text('هنگام زنگ، اعداد رو از کوچک به بزرگ انتخاب می‌کنی.'),
      ],
    ),
  };
}
