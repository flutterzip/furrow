import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/store.dart';
import '../../widgets/widgets.dart';
import '../field/field_screen.dart';
import '../shell/shell.dart';

/// What the season will bring in: the total, each field's share growing up
/// as bars, and what comes in first.
class HarvestScreen extends ConsumerStatefulWidget {
  const HarvestScreen({super.key});

  @override
  ConsumerState<HarvestScreen> createState() => _HarvestScreenState();
}

class _HarvestScreenState extends ConsumerState<HarvestScreen> {
  @override
  Widget build(BuildContext context) {
    final seed = ref.watch(seedProvider);
    final fields = [...seed.fields]..sort((a, b) => a.daysToHarvest.compareTo(b.daysToHarvest));
    final total = seed.fields.fold(0.0, (n, f) => n + f.expectedTonnes);
    final next = fields.first;
    final text = Theme.of(context).textTheme;
    final p = context.palette;

    return ListView(
      padding: EdgeInsets.fromLTRB(Tokens.gutter, MediaQuery.paddingOf(context).top + 12, Tokens.gutter, 130),
      children: [
        Entrance(
          spacing: 18,
          children: [
            Text('Harvest', style: text.headlineSmall),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: p.card.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(Tokens.cardRadius), border: Border.all(color: p.line)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Expected this season', style: text.bodyMedium),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      RollingNumber(total.round(), style: text.displaySmall!.copyWith(color: p.accentDeep, fontSize: 54)),
                      Padding(padding: const EdgeInsets.only(bottom: 12, left: 6), child: Text('tonnes', style: text.titleMedium)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  GrowBars(
                    values: [for (final f in seed.fields) f.expectedTonnes],
                    labels: [for (final f in seed.fields) f.crop.label],
                    highlight: seed.fields.indexOf(next),
                  ),
                ],
              ),
            ),
            SectionTitle('Coming in first'),
            for (final f in fields)
              FieldRow(
                field: f,
                moisture: ref.watch(moistureProvider(f.id)),
                onTap: () => openInFarm(ref, FieldScreen(field: f)),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(f.daysToHarvest == 0 ? 'Now' : '${f.daysToHarvest} d', style: text.titleLarge!.copyWith(color: f == next ? p.accentDeep : p.ink)),
                    Text('${f.expectedTonnes.toStringAsFixed(1)} t', style: text.labelSmall),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
