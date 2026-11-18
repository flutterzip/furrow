import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/motion.dart';
import '../config/palette.dart';
import '../config/theme.dart';
import '../data/models.dart';
import 'farm.dart';
import 'gauges.dart';

/// A field in a list: a small plant at its stage, the name, crop and stage,
/// and its moisture as a ring that is the accent when in range.
class FieldRow extends StatelessWidget {
  const FieldRow({super.key, required this.field, required this.moisture, required this.onTap, this.trailing});

  final Field field;
  final double moisture;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final ok = moisture >= field.targetLow && moisture <= field.targetHigh;
    return Semantics(
      button: true,
      label: '${field.name}, ${field.crop.label}, ${moisture.round()} percent moisture',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: p.card.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(22), border: Border.all(color: p.line)),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 66,
                  height: 66,
                  color: p.field,
                  child: FittedBox(child: Plant(crop: field.crop, growth: field.growth, size: 150)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(field.name, style: text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('${field.crop.label} · ${field.stage.label}', style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(
                      ok ? 'Moisture is right' : (moisture < field.targetLow ? 'Too dry' : 'Too wet'),
                      style: text.labelSmall!.copyWith(color: ok ? p.accentDeep : p.error),
                    ),
                  ],
                ),
              ),
              trailing ??
                  Text('${moisture.round()}%', style: text.titleLarge!.copyWith(color: ok ? p.accentDeep : p.error)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A task with a round check that fills and ticks.
class TaskTile extends StatelessWidget {
  const TaskTile({super.key, required this.title, required this.subtitle, required this.done, required this.onToggle});

  final String title, subtitle;
  final bool done;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Semantics(
      checked: done,
      label: title,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onToggle();
        },
        child: AnimatedContainer(
          duration: Motion.medium,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: done ? p.field : p.card.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(Tokens.fieldRadius + 2),
            border: Border.all(color: done ? Colors.transparent : p.line),
          ),
          child: Row(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(end: done ? 1 : 0),
                duration: Motion.medium,
                curve: Motion.spring,
                builder: (_, t, _) => Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.lerp(Colors.transparent, p.accent, t.clamp(0.0, 1.0)),
                    border: Border.all(color: Color.lerp(p.muted, p.accent, t.clamp(0.0, 1.0))!, width: 2),
                  ),
                  child: Transform.scale(scale: t.clamp(0.0, 1.2), child: Icon(Icons.check_rounded, size: 18, color: p.onAccent)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: Motion.medium,
                      style: text.titleMedium!.copyWith(
                        color: done ? p.muted : p.ink,
                        decoration: done ? TextDecoration.lineThrough : null,
                        decorationColor: p.muted,
                      ),
                      child: Text(title, maxLines: 2),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: text.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A count with a label and an icon, in a small card.
class Tally extends StatelessWidget {
  const Tally({super.key, required this.value, required this.label, required this.icon, this.alert = false});

  final String value, label;
  final IconData icon;

  /// Shows the count in the error colour (something needs attention).
  final bool alert;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final color = alert ? p.error : p.accentDeep;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(color: p.card.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(20), border: Border.all(color: p.line)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: Motion.medium,
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: Text(value, key: ValueKey(value), style: text.titleLarge!.copyWith(color: alert ? p.error : p.ink)),
          ),
          Text(label, style: text.labelSmall, maxLines: 1),
        ],
      ),
    );
  }
}

/// A crop's life as a line: five stages as dots, filled up to where the
/// crop is now, the current one glowing.
class StageLine extends StatelessWidget {
  const StageLine({super.key, required this.stage, required this.growth});

  final Stage stage;
  final double growth;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Semantics(
      label: '${stage.label}, ${(growth * 100).round()} percent of the way to harvest',
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          return SizedBox(
            height: 62,
            child: Stack(
              children: [
                Positioned(left: 12, right: 12, top: 11, child: Container(height: 4, decoration: BoxDecoration(color: p.line, borderRadius: BorderRadius.circular(2)))),
                Positioned(
                  left: 12,
                  top: 11,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: growth),
                    duration: Motion.grow,
                    curve: Motion.settle,
                    builder: (_, v, _) => Container(width: (w - 24) * v, height: 4, decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(2))),
                  ),
                ),
                for (final s in Stage.values)
                  Positioned(
                    left: 12 + (w - 24) * (s.index / (Stage.values.length - 1)) - 13,
                    top: 0,
                    width: 26,
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: Motion.medium,
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: s.index <= stage.index ? p.accent : p.card,
                            border: Border.all(color: s.index <= stage.index ? p.accent : p.line, width: 2),
                            boxShadow: [BoxShadow(color: p.accent.withValues(alpha: s == stage ? 0.45 : 0), blurRadius: 12)],
                          ),
                          child: s.index < stage.index ? Icon(Icons.check_rounded, size: 15, color: p.onAccent) : null,
                        ),
                      ],
                    ),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Sown', style: text.labelSmall),
                      Text(stage.label, style: text.labelMedium!.copyWith(color: p.accentDeep)),
                      Text('Harvest', style: text.labelSmall),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// A day of the forecast: its sky, chance of rain, and its low to high as a
/// bar placed on the week's range.
class DayRow extends StatelessWidget {
  const DayRow({super.key, required this.forecast, required this.label, required this.lowest, required this.highest, required this.selected, required this.onTap});

  final Forecast forecast;
  final String label;
  final int lowest, highest;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final span = (highest - lowest).clamp(1, 100);
    return Semantics(
      button: true,
      selected: selected,
      label: '$label, ${forecast.sky.label}, ${forecast.low} to ${forecast.high} degrees, ${forecast.rain} percent rain',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: Motion.medium,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? p.accentWash : p.card.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? p.accent : p.line),
          ),
          child: Row(
            children: [
              SizedBox(width: 52, child: Text(label, style: text.titleMedium)),
              SkyIcon(sky: forecast.sky, size: 40),
              SizedBox(
                width: 46,
                child: Text('${forecast.rain}%', textAlign: TextAlign.right, style: text.labelSmall!.copyWith(color: forecast.rain >= 60 ? p.accentDeep : p.muted)),
              ),
              const SizedBox(width: 12),
              Text('${forecast.low}°', style: text.labelMedium!.copyWith(color: p.muted)),
              const SizedBox(width: 8),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) {
                    final w = box.maxWidth;
                    final left = (forecast.low - lowest) / span * w;
                    final right = (forecast.high - lowest) / span * w;
                    return SizedBox(
                      height: 8,
                      child: Stack(
                        children: [
                          Container(decoration: BoxDecoration(color: p.line, borderRadius: BorderRadius.circular(4))),
                          Positioned(
                            left: left,
                            width: (right - left).clamp(6.0, w),
                            top: 0,
                            bottom: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [p.accentGlow, p.accent]),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text('${forecast.high}°', style: text.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}
