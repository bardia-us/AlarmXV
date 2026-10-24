import 'package:alarm_xv/services/frame_recorder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('frame report distinguishes UI raster and missed refresh budgets', () {
    final stats = FrameStatistics(refreshRate: 120);
    stats.add(buildMs: 2, rasterMs: 3, vsyncMicros: 100000);
    stats.add(buildMs: 4, rasterMs: 9, vsyncMicros: 108333);
    stats.add(buildMs: 10, rasterMs: 2, vsyncMicros: 125000);
    final report = stats.report();
    expect(report['frames'], 3);
    expect(report['uiP95Ms'], 10);
    expect(report['rasterP99Ms'], 9);
    expect(report['jankyFrames'], 2);
    expect(report['intervalP95Ms'], closeTo(16.667, .001));
    expect(report['budgetMs'], closeTo(8.333, .001));
  });
  test('frame recorder memory stays bounded', () {
    final stats = FrameStatistics(refreshRate: 60, maxFrames: 2);
    for (var i = 0; i < 100; i++) {
      stats.add(buildMs: 1, rasterMs: 2, vsyncMicros: i * 16667);
    }
    expect(stats.report()['frames'], 2);
    expect(stats.report()['totalFramesObserved'], 100);
  });
}
