import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/alarm.dart';
import '../services/alarm_storage.dart';
import '../widgets/alarm_editor_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.storage = const AlarmStorage()});

  final AlarmStorage storage;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  List<Alarm> _alarms = [];
  bool _isLoading = true;
  AlarmPermissionStatus? _permissions;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAlarms();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed)
      _refreshPermissions(reschedule: true);
  }

  Future<void> _loadAlarms() async {
    try {
      final alarms = await widget.storage.load();
      final result = await widget.storage.reschedule();
      if (mounted) {
        setState(() {
          _alarms = alarms;
          _permissions = result.permissions;
          _isLoading = false;
        });
      }
    } on PlatformException {
      if (mounted) {
        setState(() => _isLoading = false);
        _showMessage('Could not load or schedule saved alarms.');
      }
    }
  }

  Future<void> _refreshPermissions({bool reschedule = false}) async {
    try {
      final status = reschedule
          ? (await widget.storage.reschedule()).permissions
          : await widget.storage.permissionStatus();
      if (mounted) setState(() => _permissions = status);
    } on PlatformException {
      if (mounted) _showMessage('Could not check Android alarm access.');
    }
  }

  Future<void> _persist() async {
    try {
      final result = await widget.storage.saveAndSync(_alarms);
      if (!mounted) return;
      setState(() => _permissions = result.permissions);
      final activeCount = _alarms.where((alarm) => alarm.isEnabled).length;
      if (activeCount > 0 && result.scheduledCount < activeCount) {
        _showMessage(
          'Alarm saved, but Android access is required to schedule it.',
        );
      }
    } on PlatformException catch (error) {
      if (mounted)
        _showMessage(error.message ?? 'Could not schedule this alarm.');
    }
  }

  Future<void> _openEditor([Alarm? alarm]) async {
    final updated = await showModalBottomSheet<Alarm>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (context) => AlarmEditorSheet(alarm: alarm),
    );
    if (updated == null) return;

    setState(() {
      if (alarm == null) {
        _alarms = [..._alarms, updated];
      } else {
        _alarms = _alarms
            .map((item) => item.id == alarm.id ? updated : item)
            .toList();
      }
    });
    await _persist();
  }

  Future<void> _toggleAlarm(Alarm alarm, bool enabled) async {
    setState(() {
      _alarms = _alarms
          .map(
            (item) =>
                item.id == alarm.id ? item.copyWith(isEnabled: enabled) : item,
          )
          .toList();
    });
    await _persist();
  }

  Future<void> _deleteAlarm(Alarm alarm) async {
    setState(() {
      _alarms = _alarms.where((item) => item.id != alarm.id).toList();
    });
    await _persist();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatTime(Alarm alarm) {
    final hour = alarm.hour.toString().padLeft(2, '0');
    final minute = alarm.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDays(Set<int> weekdays) {
    if (weekdays.length == 7) return 'Every day';
    if (weekdays.containsAll({1, 2, 3, 4, 5}) && weekdays.length == 5) {
      return 'Weekdays';
    }
    return weekdays.map((day) => _dayLabels[day - 1]).join('  ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AlarmXV')),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openEditor,
        icon: const Icon(Icons.add_alarm_rounded),
        label: const Text('New alarm'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        if (_permissions case final permissions? when !permissions.allGranted)
          _PermissionPanel(
            status: permissions,
            onExactAlarm: widget.storage.openExactAlarmSettings,
            onNotifications: () async {
              await widget.storage.requestNotificationPermission();
              await _refreshPermissions();
              if (_permissions?.notifications == false) {
                await widget.storage.openNotificationSettings();
              }
            },
            onFullScreen: widget.storage.openFullScreenSettings,
            onOverlay: widget.storage.openOverlaySettings,
          ),
        Expanded(child: _buildAlarmList()),
      ],
    );
  }

  Widget _buildAlarmList() {
    if (_alarms.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.alarm_off_rounded,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                'No alarms yet',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Create your first alarm and choose the days it should repeat.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: _alarms.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final alarm = _alarms[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _openEditor(alarm),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatTime(alarm),
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                                color: alarm.isEnabled
                                    ? null
                                    : Theme.of(context).disabledColor,
                              ),
                        ),
                        Text(
                          alarm.label,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 3),
                        Text(_formatDays(alarm.weekdays)),
                      ],
                    ),
                  ),
                  Switch(
                    value: alarm.isEnabled,
                    onChanged: (enabled) => _toggleAlarm(alarm, enabled),
                  ),
                  IconButton(
                    tooltip: 'Delete alarm',
                    onPressed: () => _deleteAlarm(alarm),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PermissionPanel extends StatelessWidget {
  const _PermissionPanel({
    required this.status,
    required this.onExactAlarm,
    required this.onNotifications,
    required this.onFullScreen,
    required this.onOverlay,
  });

  final AlarmPermissionStatus status;
  final VoidCallback onExactAlarm;
  final VoidCallback onNotifications;
  final VoidCallback onFullScreen;
  final VoidCallback onOverlay;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Android access required',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'These permissions let alarms ring on time and keep the alarm screen visible.',
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (!status.exactAlarm)
                  OutlinedButton(
                    onPressed: onExactAlarm,
                    child: const Text('Allow exact alarms'),
                  ),
                if (!status.notifications)
                  OutlinedButton(
                    onPressed: onNotifications,
                    child: const Text('Allow notifications'),
                  ),
                if (!status.fullScreen)
                  OutlinedButton(
                    onPressed: onFullScreen,
                    child: const Text('Allow full-screen alarms'),
                  ),
                if (!status.overlay)
                  OutlinedButton(
                    onPressed: onOverlay,
                    child: const Text('Allow display over apps'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
