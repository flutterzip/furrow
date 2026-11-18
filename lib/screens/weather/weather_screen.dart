import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/store.dart';
import '../../widgets/widgets.dart';

/// Today's sky, the week ahead, and what it means for watering.
class WeatherScreen extends ConsumerStatefulWidget {
  const WeatherScreen({super.key});

  @override
  ConsumerState<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends ConsumerState<WeatherScreen> {
  int day = 0;

  @override
  Widget build(BuildContext context) {
    final week = ref.watch(forecastProvider);
    final today = week[day];
    final rainDay = week.skip(1).where((f) => f.rain >= 60).firstOrNull;
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final lowest = week.map((f) => f.low).reduce((a, b) => a < b ? a : b);
    final highest = week.map((f) => f.high).reduce((a, b) => a > b ? a : b);

    return ListView(
      padding: EdgeInsets.fromLTRB(Tokens.gutter, MediaQuery.paddingOf(context).top + 12, Tokens.gutter, 130),
      children: [
        Entrance(
          spacing: 18,
          children: [
            Text('Weather', style: text.headlineSmall),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Tokens.cardRadius),
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [p.accentGlow, p.accent]),
                boxShadow: [BoxShadow(color: p.accent.withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, 14))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(day == 0 ? 'Today' : weekday(today.day), style: text.titleMedium!.copyWith(color: p.onAccent)),
                        RollingNumber(today.high, suffix: '°', style: text.displaySmall!.copyWith(color: p.onAccent, fontSize: 64)),
                        Text('${today.sky.label} · low ${today.low}°', style: text.bodyMedium!.copyWith(color: p.onAccent)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.water_drop_outlined, size: 16, color: p.onAccent),
                            Text(' ${today.rain}%', style: text.labelMedium!.copyWith(color: p.onAccent)),
                            const SizedBox(width: 14),
                            Icon(Icons.air_rounded, size: 16, color: p.onAccent),
                            Text(' ${today.wind} km/h', style: text.labelMedium!.copyWith(color: p.onAccent)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: Motion.medium,
                    child: SkyIcon(key: ValueKey(today.sky), sky: today.sky, size: 120),
                  ),
                ],
              ),
            ),
            if (rainDay != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: p.accentWash, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    Icon(Icons.tips_and_updates_outlined, color: p.accentDeep),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Rain likely on ${weekday(rainDay.day)} (${rainDay.rain}%). Hold off watering the day before.', style: text.bodyMedium)),
                  ],
                ),
              ),
            const SectionTitle('This week'),
            for (var i = 0; i < week.length; i++)
              DayRow(
                forecast: week[i],
                label: i == 0 ? 'Today' : weekday(week[i].day),
                lowest: lowest,
                highest: highest,
                selected: i == day,
                onTap: () => setState(() => day = i),
              ),
          ],
        ),
      ],
    );
  }
}
