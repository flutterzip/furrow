import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/store.dart';
import '../../widgets/widgets.dart';

/// One field up close: its crop growing, where it is in its life, its soil
/// moisture, and the water switch.
class FieldScreen extends ConsumerStatefulWidget {
  const FieldScreen({super.key, required this.field});

  final Field field;

  @override
  ConsumerState<FieldScreen> createState() => _FieldScreenState();
}

class _FieldScreenState extends ConsumerState<FieldScreen> {
  bool switching = false;
  final scroll = ScrollController();

  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  Field get field => widget.field;

  Future<void> water(bool on) async {
    setState(() => switching = true);
    await ref.read(waterProvider.notifier).set(field.id, on);
    if (mounted) setState(() => switching = false);
  }

  @override
  Widget build(BuildContext context) {
    final moisture = ref.watch(moistureProvider(field.id));
    final on = ref.watch(waterProvider.select((w) => w[field.id]?.on ?? false));
    final thirst = thirstOf(field, moisture);
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    // The device's own inset: the tab bar slides away on this page, so the
    // padding the shell reserves for it does not apply.
    final safe = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          ListView(
            controller: scroll,
            padding: EdgeInsets.fromLTRB(Tokens.gutter, TopChrome.extent(context), Tokens.gutter, safe + 32),
            children: [
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [p.accentWash, p.accentWash.withValues(alpha: 0)]),
                  ),
                  child: Plant(crop: field.crop, growth: field.growth, size: 250),
                ),
              ),
              Entrance(
                spacing: 20,
                children: [
                  Column(
                    children: [
                      Text(field.name, style: text.headlineSmall),
                      Text('${field.crop.variety} · ${field.stage.label}', style: text.bodyMedium!.copyWith(color: p.accentDeep)),
                    ],
                  ),
                  StageLine(stage: field.stage, growth: field.growth),
                  Row(
                    children: [
                      Expanded(
                        child: Tally(value: '${field.plantedDaysAgo}', label: 'days in', icon: Icons.spa_outlined),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Tally(value: '${field.daysToHarvest}', label: 'days to harvest', icon: Icons.event_rounded),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Tally(value: field.expectedTonnes.toStringAsFixed(1), label: 'tonnes due', icon: Icons.agriculture_rounded),
                      ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      MoistureTank(percent: moisture, low: field.targetLow, high: field.targetHigh),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Soil moisture', style: text.titleMedium),
                            const SizedBox(height: 4),
                            Text(switch (thirst) {
                              Thirst.dry => 'Too dry. ${field.crop.label} likes ${field.targetLow} to ${field.targetHigh}%.',
                              Thirst.good => 'Just right for ${field.crop.label.toLowerCase()}.',
                              Thirst.wet => 'Wetter than it needs. Turn the water off.',
                            }, style: text.bodyMedium!.copyWith(color: thirst == Thirst.good ? p.accentDeep : p.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  WaterSwitch(on: on, busy: switching, onChanged: water),
                ],
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: TopChrome(
              controller: scroll,
              title: field.name,
              titleAfter: 270,
              leading: RoundButton(icon: Icons.arrow_back_rounded, label: 'Back', onTap: () => Navigator.of(context).pop()),
              trailing: Text('${field.hectares} ha', style: text.titleMedium),
            ),
          ),
        ],
      ),
    );
  }
}
