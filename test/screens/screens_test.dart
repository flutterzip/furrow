import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furrow/screens/farm/farm_screen.dart';
import 'package:furrow/screens/field/field_screen.dart';
import 'package:furrow/screens/harvest/harvest_screen.dart';
import 'package:furrow/screens/tasks/tasks_screen.dart';
import 'package:furrow/screens/weather/weather_screen.dart';
import 'package:furrow/state/store.dart';
import 'package:furrow/widgets/widgets.dart';

import '../helpers.dart';

void main() {
  group('Farm', () {
    testWidgets('the map, the counts, and thirsty fields first', (tester) async {
      await pumpScreen(tester, const FarmScreen());
      expect(find.byType(FarmMap), findsOneWidget);
      expect(find.text('Needs water'), findsOneWidget);
      final rows = tester.widgetList<FieldRow>(find.byType(FieldRow)).toList();
      expect(rows.first.field.id, 'garden');
    });

    testWidgets('Water on a thirsty field turns it on', (tester) async {
      final (c, _) = await pumpScreen(tester, const FarmScreen());
      await tester.ensureVisible(find.text('Water'));
      await tester.pump();
      await tester.tap(find.text('Water'));
      await tester.pumpAndSettle();
      expect(c.read(waterProvider)['garden']!.on, isTrue);
    });

    testWidgets('tapping a field on the map opens it', (tester) async {
      await pumpScreen(tester, const FarmScreen());
      final map = tester.getRect(find.byType(FarmMap));
      await tester.tapAt(Offset(map.left + map.width * 0.15, map.top + map.width * 0.86 * 0.5));
      await tester.pumpAndSettle();
      expect(find.byType(FieldScreen), findsOneWidget);
      expect(find.text('North Field'), findsWidgets);
    });
  });

  group('Field', () {
    testWidgets('shows the stage, the tank and the switch', (tester) async {
      await pumpScreen(tester, FieldScreen(field: testSeed.field('garden')));
      expect(find.byType(Plant), findsOneWidget);
      expect(find.byType(StageLine), findsOneWidget);
      expect(find.byType(MoistureTank), findsOneWidget);
      expect(find.textContaining('Too dry'), findsOneWidget);
    });

    testWidgets('the switch waters, and moisture rises with time', (tester) async {
      final (c, clock) = await pumpScreen(tester, FieldScreen(field: testSeed.field('garden')));
      await tester.ensureVisible(find.byType(WaterSwitch));
      await tester.pump();
      await tester.tap(find.byType(WaterSwitch));
      await tester.pumpAndSettle();
      expect(find.text('Watering'), findsWidgets);
      clock.now = clock.now.add(const Duration(seconds: 60));
      c.invalidate(nowProvider);
      await tester.pumpAndSettle();
      expect(find.textContaining('Just right'), findsOneWidget);
    });
  });

  group('Weather', () {
    testWidgets('today and the week, and picking a day', (tester) async {
      await pumpScreen(tester, const WeatherScreen());
      expect(find.byType(DayRow), findsNWidgets(7));
      expect(find.text('Today'), findsWidgets);
      await tester.ensureVisible(find.byType(DayRow).at(3));
      await tester.pump();
      await tester.tap(find.byType(DayRow).at(3));
      await tester.pumpAndSettle();
      expect(tester.widget<DayRow>(find.byType(DayRow).at(3)).selected, isTrue);
    });
  });

  group('Tasks', () {
    testWidgets('tick one off', (tester) async {
      final (c, _) = await pumpScreen(tester, const TasksScreen());
      expect(find.text('1 left to do. Tap one when it is done.'), findsOneWidget);
      await tester.tap(find.text('Water the garden'));
      await tester.pumpAndSettle();
      expect(c.read(tasksProvider).firstWhere((t) => t.id == 't1').done, isTrue);
      expect(find.textContaining('All done'), findsOneWidget);
    });

    testWidgets('add a task: it needs a title and a field', (tester) async {
      final (c, _) = await pumpScreen(tester, const TasksScreen());
      await tester.enterText(find.byType(TextField), 'Fix the fence');
      await tester.pump();
      expect(find.text('Pick a field to add it'), findsOneWidget);
      await tester.tap(find.text('River Plot'));
      await tester.pump();
      await tester.tap(find.text('Add task'));
      await tester.pumpAndSettle();
      expect(c.read(tasksProvider).any((t) => t.title == 'Fix the fence' && t.fieldId == 'river'), isTrue);
    });

    testWidgets('swipe to delete, with undo', (tester) async {
      final (c, _) = await pumpScreen(tester, const Scaffold(body: TasksScreen()));
      await tester.drag(find.text('Soil sample'), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(c.read(tasksProvider).length, 1);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(c.read(tasksProvider).length, 2);
    });
  });

  testWidgets('Harvest totals the season and orders by soonest', (tester) async {
    await pumpScreen(tester, const HarvestScreen());
    expect(find.byType(GrowBars), findsOneWidget);
    final rows = tester.widgetList<FieldRow>(find.byType(FieldRow)).toList();
    expect(rows.first.field.id, 'north');
  });
}
