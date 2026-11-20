import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/store.dart';
import '../../widgets/widgets.dart';
import '../field/field_screen.dart';

/// The whole farm: the map with every field growing, and what needs you.
class FarmScreen extends ConsumerStatefulWidget {
  const FarmScreen({super.key});

  @override
  ConsumerState<FarmScreen> createState() => _FarmScreenState();
}

class _FarmScreenState extends ConsumerState<FarmScreen> {
  String? chosen;

  /// Fields whose valve is opening.
  final opening = <String>{};

  Future<void> turnOn(Field f) async {
    setState(() => opening.add(f.id));
    await ref.read(waterProvider.notifier).set(f.id, true);
    if (mounted) setState(() => opening.remove(f.id));
  }

  void open(Field field) {
    setState(() => chosen = field.id);
    context.open(FieldScreen(field: field));
  }

  @override
  Widget build(BuildContext context) {
    final seed = ref.watch(seedProvider);
    final water = ref.watch(waterProvider);
    final today = ref.watch(forecastProvider).first;
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    double moisture(Field f) => ref.watch(moistureProvider(f.id));
    final thirsty = seed.fields.where((f) => moisture(f) < f.targetLow).toList();
    final watering = {for (final e in water.entries) if (e.value.on) e.key};

    return ListView(
      padding: EdgeInsets.fromLTRB(Tokens.gutter, MediaQuery.paddingOf(context).top + 12, Tokens.gutter, 130),
      children: [
        Entrance(
          spacing: 20,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hi, ${seed.firstName}', style: text.headlineSmall),
                      Text('${seed.farm} · ${today.high}° and ${today.sky.label.toLowerCase()}', style: text.bodyMedium),
                    ],
                  ),
                ),
                SkyIcon(sky: today.sky, size: 52),
              ],
            ),
            FarmMap(
              fields: seed.fields,
              moisture: moisture,
              watering: watering,
              selected: chosen,
              onTap: open,
            ),
            Row(
              children: [
                Expanded(child: Tally(value: '${seed.fields.length}', label: 'fields', icon: Icons.grid_view_rounded)),
                const SizedBox(width: 10),
                Expanded(child: Tally(value: '${watering.length}', label: 'watering', icon: Icons.water_drop_rounded)),
                const SizedBox(width: 10),
                Expanded(child: Tally(value: '${thirsty.length}', label: 'thirsty', icon: Icons.warning_amber_rounded, alert: thirsty.isNotEmpty)),
              ],
            ),
            SectionTitle(thirsty.isEmpty ? 'Every field' : 'Needs water'),
            for (final f in [...thirsty, ...seed.fields.where((f) => !thirsty.contains(f))])
              FieldRow(
                key: ValueKey(f.id),
                field: f,
                moisture: moisture(f),
                onTap: () => open(f),
                // Turning the water on is the farm's small win: the button
                // breaks apart and flies together as the running sprinkler.
                trailing: thirsty.contains(f)
                    ? SizedBox(
                        width: 112,
                        child: ParticleMorph(
                          child: watering.contains(f.id)
                              ? _Watering(key: ValueKey('on-${f.id}'))
                              : FurrowButton(key: ValueKey('water-${f.id}'), label: 'Water', icon: Icons.water_drop_rounded, busy: opening.contains(f.id), onPressed: () => turnOn(f)),
                        ),
                      )
                    : null,
              ),
            if (thirsty.isEmpty) Text('Everything is in range. Nice.', style: text.bodyMedium!.copyWith(color: p.accentDeep)),
          ],
        ),
      ],
    );
  }
}

/// Where the Water button was, once the sprinkler is running.
class _Watering extends StatelessWidget {
  const _Watering({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      height: Tokens.buttonHeight,
      decoration: BoxDecoration(color: p.accentWash, borderRadius: BorderRadius.circular(Tokens.buttonRadius)),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.water_drop_rounded, size: 16, color: p.accentDeep),
            const SizedBox(width: 6),
            Text(
              'Watering',
              style: Theme.of(context).textTheme.labelMedium!.copyWith(color: p.accentDeep, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
