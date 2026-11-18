// Screenshots of every screen on the simulator, light and dark:
//   tool/shots.sh
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furrow/app.dart';
import 'package:furrow/demo/demo_control.dart';
import 'package:furrow/screens/field/field_screen.dart';
import 'package:furrow/screens/shell/shell.dart';
import 'package:furrow/state/store.dart';
import 'package:furrow/widgets/widgets.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const mode = String.fromEnvironment('mode', defaultValue: 'light');

Future<void> settle(WidgetTester t, [int ms = 1600]) async {
  final end = DateTime.now().add(Duration(milliseconds: ms));
  while (DateTime.now().isBefore(end)) {
    await t.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('shots $mode', (t) async {
    DemoControl.enabled = false;
    SharedPreferences.setMockInitialValues({'furrow.theme.v1': mode});
    final prefs = await SharedPreferences.getInstance();
    final seed = await Seed.load();
    final c = ProviderContainer(overrides: [prefsProvider.overrideWithValue(prefs), seedProvider.overrideWithValue(seed)]);
    await t.pumpWidget(UncontrolledProviderScope(container: c, child: const FurrowApp(splash: false)));
    await settle(t, 2500);
    Future<void> shot(String name, [int ms = 1600]) async {
      await settle(t, ms);
      await binding.takeScreenshot('${name}_$mode');
    }

    await shot('farm', 2400);
    await t.drag(find.byType(ListView).first, const Offset(0, -520));
    await shot('farm_list', 900);

    farmNavigator.currentState!.push(FurrowRoute(FieldScreen(field: seed.field('garden'))));
    await shot('field', 2200);
    await t.drag(find.byType(ListView).last, const Offset(0, -500));
    await settle(t, 700);
    await t.tap(find.byType(WaterSwitch));
    await shot('field_water', 4000);
    farmNavigator.currentState!.pop();
    await settle(t, 700);
    farmNavigator.currentState!.push(FurrowRoute(FieldScreen(field: seed.field('glasshouse'))));
    await shot('field_tomato', 2200);
    farmNavigator.currentState!.pop();
    await settle(t, 700);

    c.read(tabProvider.notifier).state = 1;
    await shot('weather', 2000);
    c.read(tabProvider.notifier).state = 2;
    await shot('tasks');
    c.read(tabProvider.notifier).state = 3;
    await shot('harvest', 2200);
  });
}
