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
                field: f,
                moisture: moisture(f),
                onTap: () => open(f),
                trailing: thirsty.contains(f) && !watering.contains(f.id)
                    ? SizedBox(
                        width: 112,
                        child: FurrowButton(label: 'Water', icon: Icons.water_drop_rounded, onPressed: () => ref.read(waterProvider.notifier).set(f.id, true)),
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
