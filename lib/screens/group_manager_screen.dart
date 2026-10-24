import 'package:flutter/material.dart';

import '../models/alarm.dart';
import '../models/alarm_group.dart';
import '../models/app_settings.dart';
import '../theme/clay_theme.dart';
import '../theme/settings_controller.dart';
import '../widgets/clay_components.dart';

IconData groupIcon(String name) => switch (name) {
  'work' => Icons.work_outline_rounded,
  'school' => Icons.school_outlined,
  'weekend' => Icons.weekend_outlined,
  'fitness' => Icons.fitness_center_rounded,
  'sun' => Icons.wb_sunny_outlined,
  _ => Icons.alarm_rounded,
};
Color accessibleGroupColor(BuildContext context, Color color) =>
    HSLColor.fromColor(color)
        .withLightness(
          Theme.of(context).brightness == Brightness.dark ? .76 : .34,
        )
        .toColor();

class GroupManagerScreen extends StatefulWidget {
  const GroupManagerScreen({
    super.key,
    required this.controller,
    required this.alarms,
    required this.onDelete,
    required this.onToggle,
  });
  final SettingsController controller;
  final List<Alarm> Function() alarms;
  final Future<bool> Function(AlarmGroup) onDelete;
  final Future<bool> Function(AlarmGroup, bool) onToggle;
  @override
  State<GroupManagerScreen> createState() => _GroupManagerScreenState();
}

class _GroupManagerScreenState extends State<GroupManagerScreen> {
  bool _busy = false;
  void _message(String text) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<bool> _save(List<AlarmGroup> groups) async {
    try {
      await widget.controller.update(
        widget.controller.settings.copyWith(
          groups: [
            for (var i = 0; i < groups.length; i++)
              groups[i].copyWith(sortOrder: i),
          ],
        ),
      );
      return true;
    } catch (_) {
      _message('گروه ذخیره نشد؛ حالت قبلی حفظ شد.');
      return false;
    }
  }

  Future<void> _edit([AlarmGroup? group]) async {
    final result = await showDialog<AlarmGroup>(
      context: context,
      builder: (_) => _GroupDialog(group: group),
    );
    if (result == null || !mounted) return;
    await _save(
      group == null
          ? [...widget.controller.settings.groups, result]
          : widget.controller.settings.groups
                .map((g) => g.id == group.id ? result : g)
                .toList(),
    );
  }

  Future<void> _delete(AlarmGroup group) async {
    if (!await confirmAction(
      context,
      title: 'حذف گروه؟',
      message:
          'زنگ‌های «' + group.name + '» باقی می‌مونن و فقط از گروه خارج می‌شن.',
      action: 'حذف گروه',
      destructive: true,
    ))
      return;
    setState(() => _busy = true);
    await widget.onDelete(group);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _toggle(AlarmGroup group, bool enabled) async {
    final count = widget.alarms().where((a) => a.groupId == group.id).length;
    if (!await confirmAction(
      context,
      title: enabled ? 'روشن‌کردن گروه؟' : 'خاموش‌کردن گروه؟',
      message:
          '$count زنگ در این گروه ' + (enabled ? 'روشن' : 'خاموش') + ' می‌شن.',
      action: 'تأیید',
    ))
      return;
    setState(() => _busy = true);
    await widget.onToggle(group, enabled);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    if (_busy || widget.controller.isSaving) return;
    final groups = [...widget.controller.settings.groups];
    groups.insert(newIndex, groups.removeAt(oldIndex));
    await _save(groups);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final groups = widget.controller.settings.groups;
      final busy = _busy || widget.controller.isSaving;
      return Scaffold(
        appBar: AppBar(title: const Text('گروه‌های زنگ')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(22),
                    child: Text(
                      'برای کار، درس یا آخرهفته گروه بساز. دستگیره رو نگه دار و ترتیب گروه‌ها رو عوض کن.',
                    ),
                  ),
                  if (busy) const LinearProgressIndicator(minHeight: 2),
                  Expanded(
                    child: groups.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.create_new_folder_outlined,
                                    size: 54,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text('هنوز گروهی نساختی'),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'زنگ‌ها رو با نام و رنگ دلخواهت مرتب کن.',
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ReorderableListView.builder(
                            padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
                            buildDefaultDragHandles: false,
                            onReorderItem: _reorder,
                            itemCount: groups.length,
                            itemBuilder: (context, index) {
                              final group = groups[index];
                              final members = widget
                                  .alarms()
                                  .where((a) => a.groupId == group.id)
                                  .toList();
                              final enabled =
                                  members.isNotEmpty &&
                                  members.every((a) => a.isEnabled);
                              return Padding(
                                key: ValueKey(group.id),
                                padding: const EdgeInsets.only(bottom: 16),
                                child: ClaySurface(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            groupIcon(group.icon),
                                            color: accessibleGroupColor(
                                              context,
                                              Color(group.color),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              group.name,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium,
                                            ),
                                          ),
                                          PopupMenuButton<String>(
                                            enabled: !busy,
                                            tooltip:
                                                'گزینه‌های گروه ' + group.name,
                                            onSelected: (v) => v == 'edit'
                                                ? _edit(group)
                                                : _delete(group),
                                            itemBuilder: (_) => const [
                                              PopupMenuItem(
                                                value: 'edit',
                                                child: Text('ویرایش گروه'),
                                              ),
                                              PopupMenuItem(
                                                value: 'delete',
                                                child: Text('حذف گروه'),
                                              ),
                                            ],
                                          ),
                                          ReorderableDragStartListener(
                                            index: index,
                                            enabled: !busy,
                                            child: const Padding(
                                              padding: EdgeInsets.all(12),
                                              child: Icon(
                                                Icons.drag_indicator_rounded,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SwitchListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(
                                          members.length.toString() + ' زنگ',
                                        ),
                                        subtitle: Text(
                                          members
                                                  .where((a) => a.isEnabled)
                                                  .length
                                                  .toString() +
                                              ' فعال',
                                        ),
                                        value: enabled,
                                        onChanged: busy || members.isEmpty
                                            ? null
                                            : (v) => _toggle(group, v),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
            child: FilledButton.icon(
              onPressed: busy ? null : _edit,
              icon: const Icon(Icons.create_new_folder_outlined),
              label: const Text('گروه جدید'),
            ),
          ),
        ),
      );
    },
  );
}

class _GroupDialog extends StatefulWidget {
  const _GroupDialog({this.group});
  final AlarmGroup? group;
  @override
  State<_GroupDialog> createState() => _GroupDialogState();
}

class _GroupDialogState extends State<_GroupDialog> {
  late final TextEditingController _name;
  late Color _color;
  late String _icon;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.group?.name);
    _color = Color(widget.group?.color ?? AccentPalette.ocean.color.toARGB32());
    _icon = widget.group?.icon ?? 'alarm';
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.group == null ? 'گروه جدید' : 'ویرایش گروه'),
    content: SizedBox(
      width: 360,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              maxLength: 30,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'نام گروه'),
            ),
            const SizedBox(height: 14),
            const Text('رنگ گروه'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final accent in AccentPalette.values)
                  Semantics(
                    selected: _color == accent.color,
                    label: accent.label,
                    button: true,
                    child: Material(
                      color: accent.color,
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => setState(() => _color = accent.color),
                        child: SizedBox.square(
                          dimension: 44,
                          child: _color == accent.color
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('نماد گروه'),
            Wrap(
              spacing: 4,
              children: [
                for (final icon in [
                  'alarm',
                  'work',
                  'school',
                  'weekend',
                  'fitness',
                  'sun',
                ])
                  IconButton.filledTonal(
                    isSelected: _icon == icon,
                    tooltip: icon,
                    onPressed: () => setState(() => _icon = icon),
                    icon: Icon(groupIcon(icon)),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('انصراف'),
      ),
      FilledButton(
        onPressed: _name.text.trim().isEmpty
            ? null
            : () => Navigator.pop(
                context,
                AlarmGroup(
                  id:
                      widget.group?.id ??
                      DateTime.now().microsecondsSinceEpoch.toString(),
                  name: _name.text.trim(),
                  color: _color.toARGB32(),
                  icon: _icon,
                  sortOrder: widget.group?.sortOrder ?? 0,
                ),
              ),
        child: const Text('ذخیره گروه'),
      ),
    ],
  );
}
