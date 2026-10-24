import 'dart:collection';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Bounded, opt-in telemetry for local profile sessions. Never uploads data.
class FrameStatistics {
  FrameStatistics({required this.refreshRate, this.maxFrames = 3600});
  final double refreshRate;
  final int maxFrames;
  final _build = Queue<double>();
  final _raster = Queue<double>();
  final _interval = Queue<double>();
  int _total = 0;
  int? _lastVsync;

  void add({
    required double buildMs,
    required double rasterMs,
    required int vsyncMicros,
  }) {
    _total++;
    _build.add(buildMs);
    _raster.add(rasterMs);
    if (_lastVsync != null) _interval.add((vsyncMicros - _lastVsync!) / 1000);
    _lastVsync = vsyncMicros;
    while (_build.length > maxFrames) {
      _build.removeFirst();
      _raster.removeFirst();
    }
    while (_interval.length > maxFrames) {
      _interval.removeFirst();
    }
  }

  Map<String, Object> report() {
    double percentile(Iterable<double> values, double p) {
      final sorted = values.toList()..sort();
      return sorted.isEmpty
          ? 0
          : sorted[(sorted.length * p).ceil().clamp(1, sorted.length) - 1];
    }

    final budget = 1000 / (refreshRate > 0 ? refreshRate : 60);
    final builds = _build.toList();
    final rasters = _raster.toList();
    return {
      'frames': builds.length,
      'totalFramesObserved': _total,
      'refreshHz': refreshRate,
      'budgetMs': budget,
      'uiP95Ms': percentile(builds, .95),
      'uiP99Ms': percentile(builds, .99),
      'rasterP95Ms': percentile(rasters, .95),
      'rasterP99Ms': percentile(rasters, .99),
      'intervalP95Ms': percentile(_interval, .95),
      'intervalP99Ms': percentile(_interval, .99),
      'jankyFrames': List.generate(
        builds.length,
        (i) => i,
      ).where((i) => builds[i] > budget || rasters[i] > budget).length,
      'scope': 'Flutter frames only; native ringing requires Android FrameMetrics/Perfetto',
      'intervalCaution': 'Vsync gaps include idle periods; capture one continuous interaction per window.',
    };
  }
}

class ProfileFrameRecorder {
  static FrameStatistics? _stats;
  static int _lastEmission = 0;
  static String _label = 'startup';

  static void start() {
    if (!kProfileMode || !const bool.fromEnvironment('ALARMXV_PROFILE')) return;
    final display = PlatformDispatcher.instance.views.firstOrNull?.display;
    _stats = FrameStatistics(refreshRate: display?.refreshRate ?? 60);
    SchedulerBinding.instance.addTimingsCallback(_record);
    // Profile-only VM service controls isolate each measured interaction window.
    developer.registerExtension('ext.alarmxv.capture', (_, parameters) async {
      _label = parameters['label'] ?? 'interaction';
      _stats = FrameStatistics(refreshRate: display?.refreshRate ?? 60);
      return developer.ServiceExtensionResponse.result(
        jsonEncode({'label': _label}),
      );
    });
    developer.registerExtension(
      'ext.alarmxv.report',
      (_, _) async => developer.ServiceExtensionResponse.result(
        jsonEncode({'label': _label, ...?_stats?.report()}),
      ),
    );
  }

  static void _record(List<FrameTiming> timings) {
    for (final frame in timings) {
      _stats?.add(
        buildMs: frame.buildDuration.inMicroseconds / 1000,
        rasterMs: frame.rasterDuration.inMicroseconds / 1000,
        vsyncMicros: frame.timestampInMicroseconds(FramePhase.vsyncStart),
      );
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastEmission > 5000 && _stats != null) {
      _lastEmission = now;
      debugPrint(
        'ALARMXV_FRAME_REPORT ${jsonEncode({'label': _label, ..._stats!.report()})}',
      );
    }
  }
}
