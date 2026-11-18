import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furrow/config/motion.dart';
import 'package:furrow/config/theme.dart';
import 'package:furrow/config/timing.dart';
import 'package:furrow/data/models.dart';
import 'package:furrow/state/store.dart';
import 'package:furrow/widgets/backdrop.dart';
import 'package:shared_preferences/shared_preferences.dart';

final testNow = DateTime(2026, 11, 18, 9, 41);

Field field(String id, String name, Crop crop, {int moisture = 50, int low = 40, int high = 60, int planted = 50, bool irrigating = false, double dx = 0}) => Field(
      id: id,
      name: name,
      crop: crop,
      hectares: 2,
      plantedDaysAgo: planted,
      cycleDays: 100,
      moisture: moisture,
      targetLow: low,
      targetHigh: high,
      irrigating: irrigating,
      shape: [Offset(dx, 0), Offset(dx + 0.3, 0), Offset(dx + 0.3, 0.9), Offset(dx, 0.9)],
      rowAngle: 0,
    );

final testSeed = Seed(
  fields: [
    field('north', 'North Field', Crop.wheat, planted: 98),
    field('garden', 'Kitchen Garden', Crop.lettuce, moisture: 30, dx: 0.33),
    field('river', 'River Plot', Crop.maize, irrigating: true, dx: 0.66),
  ],
  name: 'Olympicson',
  farm: 'Olympicson Farm',
  tasks: const [
    (id: 't1', title: 'Water the garden', fieldId: 'garden', dueDays: 0, done: false),
    (id: 't2', title: 'Soil sample', fieldId: 'north', dueDays: -1, done: true),
  ],
);

class TestClock {
  DateTime now = testNow;
}

Future<(ProviderContainer, TestClock)> pumpScreen(WidgetTester tester, Widget screen, {Map<String, Object> prefs = const {}}) async {
  Motion.ambient = false;
  AppTiming.scale = 0;
  tester.view.physicalSize = const Size(1320, 2868);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  final clock = TestClock();
  final container = ProviderContainer(overrides: [
    prefsProvider.overrideWithValue(sp),
    seedProvider.overrideWithValue(testSeed),
    clockProvider.overrideWithValue(() => clock.now),
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.light(),
      builder: (context, child) => PaperBackdrop(child: child!),
      home: Material(type: MaterialType.transparency, child: screen),
    ),
  ));
  await tester.pumpAndSettle();
  return (container, clock);
}
