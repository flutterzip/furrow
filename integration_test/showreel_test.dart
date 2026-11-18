// Drives the real app on the simulator at human speed, for recording and
// for judging motion frame by frame:   tool/rec.sh farm
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furrow/app.dart';
import 'package:furrow/state/store.dart';
import 'package:furrow/widgets/widgets.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pause(WidgetTester t, int ms) async {
  final end = DateTime.now().add(Duration(milliseconds: ms));
  while (DateTime.now().isBefore(end)) {
    await t.pump(const Duration(milliseconds: 16));
  }
}

Future<void> typeInto(WidgetTester t, Finder field, String text) async {
  await t.tap(field);
  await pause(t, 300);
  for (var i = 1; i <= text.length; i++) {
    await t.enterText(field, text.substring(0, i));
    await pause(t, 90);
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('showreel', (t) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final seed = await Seed.load();
    await t.pumpWidget(ProviderScope(
      overrides: [prefsProvider.overrideWithValue(prefs), seedProvider.overrideWithValue(seed)],
      child: const FurrowApp(),
    ));
    await pause(t, 5200);

    // Tap the Kitchen Garden on the map.
    final map = t.getRect(find.byType(FarmMap));
    final garden = seed.field('garden');
    final cx = garden.shape.map((p) => p.dx).reduce((a, b) => a + b) / garden.shape.length;
    final cy = garden.shape.map((p) => p.dy).reduce((a, b) => a + b) / garden.shape.length;
    await t.tapAt(Offset(map.left + map.width * cx, map.top + map.width * 0.86 * cy + 26));
    await pause(t, 2600);
    await t.drag(find.byType(ListView).last, const Offset(0, -480));
    await pause(t, 900);
    await t.tap(find.byType(WaterSwitch));
    await pause(t, 7000);
    await t.drag(find.byType(ListView).last, const Offset(0, 600));
    await pause(t, 700);
    await t.tap(find.byIcon(Icons.arrow_back_rounded));
    await pause(t, 2200);

    await t.tap(find.byIcon(Icons.wb_cloudy_outlined));
    await pause(t, 1800);
    for (final i in [2, 4, 1]) {
      await t.tap(find.byType(DayRow).at(i));
      await pause(t, 1100);
    }

    await t.tap(find.byIcon(Icons.checklist_rounded));
    await pause(t, 1400);
    await t.tap(find.byType(TaskTile).first);
    await pause(t, 1200);
    await typeInto(t, find.byType(TextField), 'Check the pump');
    await pause(t, 500);
    await t.tap(find.text('River Plot'));
    await pause(t, 700);
    await t.tap(find.text('Add task'));
    await pause(t, 1800);

    await t.tap(find.byIcon(Icons.agriculture_outlined));
    await pause(t, 3200);
  });
}
