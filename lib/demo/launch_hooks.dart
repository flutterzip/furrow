import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/field/field_screen.dart';
import '../screens/shell/shell.dart';
import '../state/store.dart';
import '../widgets/routes.dart';

/// Opens a screen straight after the splash, for screenshots and
/// recordings: `--dart-define=startRoute=field`. Off by default, so a
/// release build is unaffected.
///
/// field (the Kitchen Garden, which is thirsty), weather, tasks, harvest.
const startRoute = String.fromEnvironment('startRoute');

void runLaunchHooks(WidgetRef ref) {
  switch (startRoute) {
    case 'field':
      farmNavigator.currentState?.push(FurrowRoute(FieldScreen(field: ref.read(seedProvider).field('garden'))));
    case 'weather':
      ref.read(tabProvider.notifier).state = 1;
    case 'tasks':
      ref.read(tabProvider.notifier).state = 2;
    case 'harvest':
      ref.read(tabProvider.notifier).state = 3;
  }
}
