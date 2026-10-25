import 'dart:ui' as ui;

import 'package:alarm_xv/models/app_settings.dart';
import 'package:alarm_xv/theme/clay_theme.dart';
import 'package:alarm_xv/widgets/frosted_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('chrome blocks taps on content painted behind it', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: const FrostedAppBar(title: Text('Settings')),
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => taps++,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
    await tester.tapAt(const Offset(400, 30));
    expect(taps, 0);
    await tester.tapAt(const Offset(400, 120));
    expect(taps, 1);
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      'real backdrop changes while foreground stays sharp ($brightness)',
      (tester) async {
        const key = ValueKey('pixels');
        Future<List<int>> pixel(int x, int y) async {
          return (await tester.runAsync(() async {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(key),
            );
            final image = await boundary.toImage();
            final data = await image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            );
            final offset = (y * image.width + x) * 4;
            final value = data!.buffer.asUint8List().sublist(
              offset,
              offset + 4,
            );
            image.dispose();
            return value;
          }))!;
        }

        Future<void> draw(Color background, {bool reduced = false}) =>
            tester.pumpWidget(
              MaterialApp(
                theme: buildClayTheme(brightness, AccentPalette.ocean),
                home: MediaQuery(
                  data: MediaQueryData(disableAnimations: reduced),
                  child: RepaintBoundary(
                    key: key,
                    child: ColoredBox(
                      color: background,
                      child: Center(
                        child: SizedBox(
                          width: 160,
                          height: 100,
                          child: FrostedSurface(
                            borderRadius: BorderRadius.circular(28),
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: ColoredBox(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
        await draw(Colors.red);
        await tester.pumpAndSettle();
        final red = await pixel(350, 300);
        expect(await pixel(400, 300), [255, 255, 255, 255]);
        await draw(Colors.blue);
        await tester.pumpAndSettle();
        expect(await pixel(350, 300), isNot(red));
        expect(await pixel(400, 300), [255, 255, 255, 255]);
        // Reduced effects must not sample the changing backdrop at all.
        await draw(Colors.red, reduced: true);
        await tester.pumpAndSettle();
        final solid = await pixel(350, 300);
        expect(find.byType(BackdropFilter), findsNothing);
        await draw(Colors.blue, reduced: true);
        await tester.pumpAndSettle();
        expect(await pixel(350, 300), solid);
      },
    );
  }
}
