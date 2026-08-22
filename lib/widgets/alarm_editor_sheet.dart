import 'package:flutter/material.dart';

import '../challenges/challenge_type.dart';
import '../models/alarm.dart';
import '../models/wake_check_settings.dart';
import '../services/alarm_storage.dart';

class AlarmEditorSheet extends StatefulWidget {
  const AlarmEditorSheet({super.key, this.alarm});

  final Alarm? alarm;

  @override
  State<AlarmEditorSheet> createState() => _AlarmEditorSheetState();
}

class _AlarmEditorSheetState extends State<AlarmEditorSheet> {
  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _snoozeOptions = [0, 5, 10, 15];
  static const _wakeDelayOptions = [2, 3, 5, 10];
  static const _wakeCountOptions = [1, 2, 3, 5];

  late final TextEditingController _labelController;
  late TimeOfDay _time;
  late Set<int> _weekdays;
  late Set<ChallengeType> _challenges;
  late bool _isEnabled;
  late int _snoozeMinutes;
  late bool _preventVolumeReduction;
  late bool _wakeCheckEnabled;
  late int _wakeCheckDelayMinutes;
  late int _wakeCheckTimeoutSeconds;
  late int _wakeCheckCount;
  String? _alarmSoundUri;
  late String _alarmSoundName;

  bool get _isEditing => widget.alarm != null;

  @override
  void initState() {
    super.initState();
    final alarm = widget.alarm;
    _labelController = TextEditingController(text: alarm?.label ?? 'Alarm');
    _time = alarm == null
        ? TimeOfDay.now()
        : TimeOfDay(hour: alarm.hour, minute: alarm.minute);
    _weekdays = {...?alarm?.weekdays};
    if (_weekdays.isEmpty) _weekdays.addAll({1, 2, 3, 4, 5});
    _challenges = {...?alarm?.challenges};
    if (_challenges.isEmpty) _challenges.add(ChallengeType.math);
    _isEnabled = alarm?.isEnabled ?? true;
    _snoozeMinutes = alarm?.snoozeMinutes ?? 5;
    _preventVolumeReduction = true;
    _wakeCheckEnabled = alarm?.wakeCheck.enabled ?? false;
    _wakeCheckDelayMinutes = alarm?.wakeCheck.delayMinutes ?? 3;
    _wakeCheckTimeoutSeconds = alarm?.wakeCheck.timeoutSeconds ?? 60;
    _wakeCheckCount = alarm?.wakeCheck.checkCount ?? 1;
    _alarmSoundUri = alarm?.alarmSoundUri;
    _alarmSoundName = alarm?.alarmSoundName ?? 'Default alarm sound';
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(context: context, initialTime: _time);
    if (selected != null) setState(() => _time = selected);
  }

  Future<void> _pickAlarmSound() async {
    final selected = await const AlarmStorage().pickAlarmSound(_alarmSoundUri);
    if (selected == null || !mounted) return;
    setState(() {
      _alarmSoundUri = selected.uri.isEmpty ? null : selected.uri;
      _alarmSoundName = selected.name;
    });
  }

  void _save() {
    final existing = widget.alarm;
    Navigator.pop(
      context,
      Alarm(
        id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        label: _labelController.text.trim().isEmpty
            ? 'Alarm'
            : _labelController.text.trim(),
        hour: _time.hour,
        minute: _time.minute,
        weekdays: Set.unmodifiable(_weekdays),
        isEnabled: _isEnabled,
        challenges: Set.unmodifiable(_challenges),
        snoozeMinutes: _snoozeMinutes,
        maxSnoozes: existing?.maxSnoozes ?? 3,
        preventVolumeReduction: _preventVolumeReduction,
        alarmSoundUri: _alarmSoundUri,
        alarmSoundName: _alarmSoundName,
        wakeCheck: WakeCheckSettings(
          enabled: _wakeCheckEnabled,
          delayMinutes: _wakeCheckDelayMinutes,
          timeoutSeconds: _wakeCheckTimeoutSeconds,
          checkCount: _wakeCheckCount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          12,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _isEditing ? 'Edit alarm' : 'New alarm',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _labelController,
              maxLength: 40,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Alarm name',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: _pickTime,
              icon: const Icon(Icons.schedule_rounded),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _time.format(context),
                  style: theme.textTheme.headlineMedium,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Repeat on', style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(7, (index) {
                final day = index + 1;
                return FilterChip(
                  label: Text(_dayLabels[index]),
                  selected: _weekdays.contains(day),
                  onSelected: (selected) {
                    setState(() {
                      selected ? _weekdays.add(day) : _weekdays.remove(day);
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 20),
            Text('Challenges', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Selected challenges run in order before the alarm can stop.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: ChallengeType.values.map((challenge) {
                return FilterChip(
                  avatar: Icon(switch (challenge) {
                    ChallengeType.math => Icons.calculate_outlined,
                    ChallengeType.memory => Icons.grid_view_rounded,
                    ChallengeType.shake => Icons.vibration_rounded,
                  }, size: 18),
                  label: Text(challenge.label),
                  selected: _challenges.contains(challenge),
                  onSelected: (selected) {
                    setState(() {
                      selected
                          ? _challenges.add(challenge)
                          : _challenges.remove(challenge);
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<int>(
              initialValue: _snoozeMinutes,
              decoration: const InputDecoration(
                labelText: 'Snooze',
                border: OutlineInputBorder(),
                helperText: 'Up to 3 times per alarm occurrence',
              ),
              items: _snoozeOptions
                  .map(
                    (minutes) => DropdownMenuItem(
                      value: minutes,
                      child: Text(minutes == 0 ? 'Off' : '$minutes minutes'),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _snoozeMinutes = value ?? 0),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.music_note_rounded),
              title: const Text('Alarm sound'),
              subtitle: Text(_alarmSoundName),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _pickAlarmSound,
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.volume_up_rounded),
              title: Text('Maximum alarm volume'),
              subtitle: Text(
                'Uses the phone’s alarm sound at maximum volume while ringing, then restores the previous volume.',
              ),
            ),
            const Divider(height: 28),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.fact_check_outlined),
              title: const Text('Enable Wake-up Checker'),
              subtitle: const Text(
                'Confirm that you stayed awake after dismissal.',
              ),
              value: _wakeCheckEnabled,
              onChanged: (value) => setState(() => _wakeCheckEnabled = value),
            ),
            if (_wakeCheckEnabled) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _wakeCheckDelayMinutes,
                      decoration: const InputDecoration(
                        labelText: 'Check after',
                        border: OutlineInputBorder(),
                      ),
                      items: _wakeDelayOptions
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text('$value min'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _wakeCheckDelayMinutes = value ?? 3);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _wakeCheckCount,
                      decoration: const InputDecoration(
                        labelText: 'Checks',
                        border: OutlineInputBorder(),
                      ),
                      items: _wakeCountOptions
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text('$value'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _wakeCheckCount = value ?? 1);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _wakeCheckTimeoutSeconds,
                decoration: const InputDecoration(
                  labelText: 'Confirmation timeout',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 60, child: Text('60 seconds')),
                ],
                onChanged: (value) {
                  setState(() => _wakeCheckTimeoutSeconds = value ?? 60);
                },
              ),
            ],
            const Divider(height: 28),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Alarm enabled'),
              value: _isEnabled,
              onChanged: (value) => setState(() => _isEnabled = value),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _weekdays.isEmpty || _challenges.isEmpty
                  ? null
                  : _save,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(_isEditing ? 'Save changes' : 'Save alarm'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
