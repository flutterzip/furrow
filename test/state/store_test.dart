import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furrow/config/timing.dart';
import 'package:furrow/data/models.dart';
import 'package:furrow/state/store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers.dart';

Future<(ProviderContainer, TestClock)> container([Map<String, Object> prefs = const {}]) async {
  AppTiming.scale = 0;
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  final clock = TestClock();
  final c = ProviderContainer(overrides: [
    prefsProvider.overrideWithValue(sp),
    seedProvider.overrideWithValue(testSeed),
    clockProvider.overrideWithValue(() => clock.now),
  ]);
  addTearDown(c.dispose);
  return (c, clock);
}

void main() {
  test('growth and stages come from the planting date', () {
    final f = testSeed.field('north');
    expect(f.growth, closeTo(0.98, 0.001));
    expect(f.stage, Stage.ready);
    expect(testSeed.field('garden').stage, Stage.growing);
    expect(f.daysToHarvest, 2);
  });

  test('watering raises moisture with time and keeps it after turning off', () async {
    final (c, clock) = await container();
    expect(c.read(moistureProvider('garden')), 30);
    await c.read(waterProvider.notifier).set('garden', true);
    clock.now = clock.now.add(const Duration(seconds: 40));
    c.invalidate(nowProvider);
    expect(c.read(moistureProvider('garden')), closeTo(40, 0.01));
    await c.read(waterProvider.notifier).set('garden', false);
    clock.now = clock.now.add(const Duration(minutes: 5));
    c.invalidate(nowProvider);
    expect(c.read(moistureProvider('garden')), closeTo(40, 0.01));
  });

  test('a field seeded as watering is already on, and moisture caps', () async {
    final (c, clock) = await container();
    expect(c.read(waterProvider)['river']!.on, isTrue);
    clock.now = clock.now.add(const Duration(hours: 1));
    c.invalidate(nowProvider);
    expect(c.read(moistureProvider('river')), 92);
  });

  test('thirst against the target band', () {
    final g = testSeed.field('garden');
    expect(thirstOf(g, 30), Thirst.dry);
    expect(thirstOf(g, 50), Thirst.good);
    expect(thirstOf(g, 70), Thirst.wet);
  });

  test('tasks: toggle, add, delete with undo, sorted to-do first', () async {
    final (c, _) = await container();
    final n = c.read(tasksProvider.notifier);
    expect(c.read(sortedTasksProvider).first.id, 't1');
    n.toggle('t1');
    expect(c.read(tasksProvider).firstWhere((t) => t.id == 't1').done, isTrue);
    n.add('Fix the fence', 'north', testNow);
    expect(c.read(sortedTasksProvider).first.title, 'Fix the fence');
    final undo = n.remove('t2')!;
    expect(c.read(tasksProvider).length, 2);
    n.restore(undo.$1, undo.$2);
    expect(c.read(tasksProvider).length, 3);
  });

  test('the forecast is a stable week from today', () {
    final a = forecastFrom(testNow), b = forecastFrom(testNow.add(const Duration(hours: 5)));
    expect(a.length, 7);
    expect([for (final f in a) f.high], [for (final f in b) f.high]);
    for (final f in a) {
      expect(f.low, lessThan(f.high));
    }
  });
}
