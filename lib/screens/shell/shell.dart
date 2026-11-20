import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/store.dart';
import '../../widgets/widgets.dart';
import '../weather/weather_screen.dart';
import '../farm/farm_screen.dart';
import '../harvest/harvest_screen.dart';
import '../tasks/tasks_screen.dart';

final tabProvider = StateProvider<int>((_) => 0);

/// The Farm tab's own navigator: a field opens inside the tab, and the bar
/// slides away while it is open so the field has the whole screen.
final farmNavigator = GlobalKey<NavigatorState>(debugLabel: 'farm');

/// Whether the Farm tab has a page open over its home.
class _Depth extends NavigatorObserver {
  final deep = ValueNotifier(false);
  var _n = 0;

  void _set(int n) {
    _n = n;
    deep.value = _n > 1;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _set(_n + 1);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _set(_n - 1);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) => _set(_n - 1);
}

class Shell extends ConsumerStatefulWidget {
  const Shell({super.key});

  @override
  ConsumerState<Shell> createState() => _ShellState();
}

class _ShellState extends ConsumerState<Shell> {
  final _heroes = HeroController();
  final _depth = _Depth();
  final _built = <int>{0};

  @override
  void dispose() {
    _depth.deep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(tabProvider);
    _built.add(tab);
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: IndexedStack(
        index: tab,
        children: [
          HeroMode(
            enabled: tab == 0,
            child: NavigatorPopHandler(
              onPopWithResult: (_) => farmNavigator.currentState?.maybePop(),
              child: Navigator(
                key: farmNavigator,
                observers: [_heroes, _depth],
                onGenerateRoute: (_) => FurrowRoute<void>(const StatusFrost(child: FarmScreen())),
              ),
            ),
          ),
          _built.contains(1) ? const StatusFrost(child: WeatherScreen()) : const SizedBox(),
          _built.contains(2) ? const StatusFrost(child: TasksScreen()) : const SizedBox(),
          _built.contains(3) ? const StatusFrost(child: HarvestScreen()) : const SizedBox(),
        ],
      ),
      bottomNavigationBar: ValueListenableBuilder(
        valueListenable: _depth.deep,
        builder: (context, deep, bar) {
          final hide = deep && tab == 0;
          return IgnorePointer(
            ignoring: hide,
            child: AnimatedSlide(offset: Offset(0, hide ? 1.2 : 0), duration: Motion.medium, curve: Motion.spring, child: bar),
          );
        },
        child: GlassTabBar(
          index: tab,
          onTap: (i) {
            if (i == tab && i == 0) farmNavigator.currentState?.popUntil((r) => r.isFirst);
            ref.read(tabProvider.notifier).state = i;
          },
          items: [
            const TabItem('Farm', Icons.grass_outlined, Icons.grass_rounded),
            const TabItem('Weather', Icons.wb_cloudy_outlined, Icons.wb_cloudy_rounded),
            TabItem('Tasks', Icons.checklist_rounded, Icons.checklist_rtl_rounded, badge: ref.watch(tasksProvider).where((t) => !t.done).length),
            const TabItem('Harvest', Icons.agriculture_outlined, Icons.agriculture_rounded),
          ],
        ),
      ),
    );
  }
}

/// Opens a page inside the Farm tab, from anywhere.
void openInFarm(WidgetRef ref, Widget page) {
  ref.read(tabProvider.notifier).state = 0;
  farmNavigator.currentState?.push(FurrowRoute<void>(page));
}
