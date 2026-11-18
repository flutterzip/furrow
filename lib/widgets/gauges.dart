import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/motion.dart';
import '../config/palette.dart';
import '../data/models.dart';
import 'farm_colors.dart';

/// Soil moisture as a tank of water: the level rises and falls to
/// [percent], the surface rolls in two waves, and the crop's target band is
/// marked on the side.
class MoistureTank extends StatefulWidget {
  const MoistureTank({super.key, required this.percent, required this.low, required this.high, this.width = 120, this.height = 170});

  final double percent;
  final int low, high;
  final double width, height;

  @override
  State<MoistureTank> createState() => _MoistureTankState();
}

class _MoistureTankState extends State<MoistureTank> with SingleTickerProviderStateMixin {
  late final _wave = AnimationController(vsync: this, duration: const Duration(seconds: 3));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.loops(context)) {
      if (!_wave.isAnimating) _wave.repeat();
    } else {
      _wave.stop();
    }
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      label: 'Soil moisture ${widget.percent.round()} percent, target ${widget.low} to ${widget.high}',
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: widget.percent),
        duration: Motion.ring,
        curve: Motion.settle,
        builder: (_, level, _) => AnimatedBuilder(
          animation: _wave,
          builder: (_, _) => CustomPaint(
            size: Size(widget.width, widget.height),
            painter: _TankPainter(level, widget.low, widget.high, _wave.value, p.accent, p.accentGlow, p.line, p.card, p.ink),
          ),
        ),
      ),
    );
  }
}

class _TankPainter extends CustomPainter {
  _TankPainter(this.level, this.low, this.high, this.t, this.water, this.light, this.line, this.glass, this.ink);

  final double level, t;
  final int low, high;
  final Color water, light, line, glass, ink;

  @override
  void paint(Canvas c, Size s) {
    final body = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, s.width - 18, s.height), const Radius.circular(26));
    c.drawRRect(body, Paint()..color = glass);
    c.save();
    c.clipRRect(body);
    final top = s.height * (1 - level / 100);
    final a = t * math.pi * 2;
    Path wave(double amp, double phase) {
      final p = Path()..moveTo(0, s.height);
      for (var x = 0.0; x <= body.width; x += 2) {
        p.lineTo(x, top + math.sin(x / body.width * math.pi * 2 + a + phase) * amp);
      }
      return p
        ..lineTo(body.width, s.height)
        ..close();
    }

    c.drawPath(wave(5, 1.6), Paint()..color = light.withValues(alpha: 0.55));
    c.drawPath(wave(4, 0), Paint()..shader = ui.Gradient.linear(Offset(0, top), Offset(0, s.height), [light, water]));
    // Bubbles rising.
    final rng = math.Random(5);
    for (var i = 0; i < 6; i++) {
      final x = 14 + rng.nextDouble() * (body.width - 28);
      final y = s.height - ((t + i / 6) % 1) * (s.height - top);
      c.drawCircle(Offset(x, y), 2 + rng.nextDouble() * 2, Paint()..color = const Color(0x66FFFFFF));
    }
    c.restore();
    c.drawRRect(body, Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
    // The target band on the side.
    final yHigh = s.height * (1 - high / 100), yLow = s.height * (1 - low / 100);
    final band = RRect.fromRectAndRadius(Rect.fromLTRB(s.width - 10, yHigh, s.width - 2, yLow), const Radius.circular(4));
    c.drawRRect(band, Paint()..color = water.withValues(alpha: 0.35));
    final tp = TextPainter(
      text: TextSpan(text: '${level.round()}%', style: TextStyle(fontFamily: 'Bricolage', fontSize: 26, fontWeight: FontWeight.w800, color: level > 55 ? const Color(0xFFFFFFFF) : ink)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset((body.width - tp.width) / 2, s.height * 0.42 - tp.height / 2));
  }

  @override
  bool shouldRepaint(_TankPainter old) => true;
}

/// A big switch for a field's water. When on, water runs through the track
/// and three sprinklers spray arcs above it.
class WaterSwitch extends StatefulWidget {
  const WaterSwitch({super.key, required this.on, required this.onChanged, this.busy = false});

  final bool on, busy;
  final ValueChanged<bool> onChanged;

  @override
  State<WaterSwitch> createState() => _WaterSwitchState();
}

class _WaterSwitchState extends State<WaterSwitch> with SingleTickerProviderStateMixin {
  late final _flow = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(WaterSwitch old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (widget.on && Motion.loops(context)) {
      if (!_flow.isAnimating) _flow.repeat();
    } else {
      _flow.stop();
    }
  }

  @override
  void dispose() {
    _flow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Semantics(
      toggled: widget.on,
      label: 'Watering',
      button: true,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: widget.busy
            ? null
            : () {
                HapticFeedback.mediumImpact();
                widget.onChanged(!widget.on);
              },
        child: Column(
          children: [
            SizedBox(
              height: 64,
              child: AnimatedBuilder(
                animation: _flow,
                builder: (_, _) => CustomPaint(
                  size: const Size(double.infinity, 64),
                  painter: _SprayPainter(widget.on ? 1 : 0, _flow.value),
                ),
              ),
            ),
            AnimatedContainer(
              duration: Motion.medium,
              curve: Motion.settle,
              height: 74,
              decoration: BoxDecoration(
                color: widget.on ? p.accent : p.field,
                borderRadius: BorderRadius.circular(37),
                border: Border.all(color: widget.on ? p.accent : p.line),
                boxShadow: [BoxShadow(color: p.accent.withValues(alpha: widget.on ? 0.4 : 0), blurRadius: 24, offset: const Offset(0, 10))],
              ),
              child: Stack(
                children: [
                  if (widget.on)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(37),
                        child: AnimatedBuilder(animation: _flow, builder: (_, _) => CustomPaint(painter: _FlowPainter(_flow.value, p.onAccent))),
                      ),
                    ),
                  AnimatedAlign(
                    duration: Motion.medium,
                    curve: Motion.spring,
                    alignment: widget.on ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.all(7),
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.on ? p.onAccent : p.card,
                        boxShadow: [BoxShadow(color: p.shadow, blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: widget.busy
                          ? Padding(padding: const EdgeInsets.all(18), child: CircularProgressIndicator(strokeWidth: 2.4, color: p.accent))
                          : Icon(widget.on ? Icons.water_drop_rounded : Icons.water_drop_outlined, color: p.accentDeep, size: 28),
                    ),
                  ),
                  Center(
                    child: AnimatedSwitcher(
                      duration: Motion.short,
                      child: Text(
                        widget.on ? 'Watering' : 'Water this field',
                        key: ValueKey(widget.on),
                        style: text.labelLarge!.copyWith(color: widget.on ? p.onAccent : p.ink),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlowPainter extends CustomPainter {
  _FlowPainter(this.t, this.color);

  final double t;
  final Color color;

  @override
  void paint(Canvas c, Size s) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final y = s.height * (0.3 + i * 0.2);
      for (var x = -40.0 + (t * 40) % 40 + i * 13; x < s.width; x += 40) {
        c.drawLine(Offset(x, y), Offset(x + 16, y), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_FlowPainter old) => old.t != t;
}

class _SprayPainter extends CustomPainter {
  _SprayPainter(this.on, this.t);

  final double on, t;

  @override
  void paint(Canvas c, Size s) {
    if (on == 0) return;
    for (var k = 0; k < 3; k++) {
      final base = Offset(s.width * (0.22 + k * 0.28), s.height);
      c.drawRect(Rect.fromCenter(center: base - const Offset(0, 4), width: 4, height: 10), Paint()..color = const Color(0xFF8A928C));
      for (var i = 0; i < 9; i++) {
        final life = (t + i / 9 + k * 0.13) % 1;
        final ang = -math.pi / 2 + (i / 8 - 0.5) * 1.6;
        final dist = life * s.height * 0.95;
        final pos = base - const Offset(0, 9) + Offset(math.cos(ang) * dist, math.sin(ang) * dist + life * life * 26);
        c.drawCircle(pos, 2.4 * (1 - life * 0.5), Paint()..color = FarmColors.water.withValues(alpha: (1 - life) * 0.9));
      }
    }
  }

  @override
  bool shouldRepaint(_SprayPainter old) => old.t != t;
}

/// The sky for a day, drawn and moving: the sun's rays turn, clouds drift,
/// rain falls.
class SkyIcon extends StatefulWidget {
  const SkyIcon({super.key, required this.sky, this.size = 64});

  final Sky sky;
  final double size;

  @override
  State<SkyIcon> createState() => _SkyIconState();
}

class _SkyIconState extends State<SkyIcon> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(seconds: 6));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.loops(context)) {
      if (!_c.isAnimating) _c.repeat();
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.sky.label,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(size: Size.square(widget.size), painter: _SkyPainter(widget.sky, _c.value)),
      ),
    );
  }
}

class _SkyPainter extends CustomPainter {
  _SkyPainter(this.sky, this.t);

  final Sky sky;
  final double t;

  void _sun(Canvas c, Offset ctr, double r) {
    final a = t * math.pi * 2;
    final ray = Paint()
      ..color = FarmColors.sun
      ..strokeWidth = r * 0.18
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final ang = a * 0.5 + i * math.pi / 4;
      final d = Offset(math.cos(ang), math.sin(ang));
      c.drawLine(ctr + d * r * 1.35, ctr + d * r * (1.7 + 0.1 * math.sin(a * 2 + i)), ray);
    }
    c.drawCircle(ctr, r, Paint()..shader = ui.Gradient.radial(ctr - Offset(r * 0.3, r * 0.3), r * 1.2, [const Color(0xFFFFE08A), FarmColors.sun]));
  }

  void _cloud(Canvas c, Offset ctr, double w, Color color) {
    final p = Paint()..color = color;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: ctr + Offset(0, w * 0.1), width: w, height: w * 0.36), Radius.circular(w * 0.18)), p);
    c.drawCircle(ctr + Offset(-w * 0.18, -w * 0.05), w * 0.22, p);
    c.drawCircle(ctr + Offset(w * 0.1, -w * 0.12), w * 0.28, p);
  }

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final drift = math.sin(t * math.pi * 2) * w * 0.05;
    switch (sky) {
      case Sky.sun:
        _sun(c, s.center(Offset.zero), w * 0.22);
      case Sky.partly:
        _sun(c, Offset(w * 0.38, w * 0.38), w * 0.18);
        _cloud(c, Offset(w * 0.58 + drift, w * 0.62), w * 0.62, FarmColors.cloud);
      case Sky.cloud:
        _cloud(c, Offset(w * 0.4 - drift, w * 0.42), w * 0.5, FarmColors.cloudDark);
        _cloud(c, Offset(w * 0.56 + drift, w * 0.6), w * 0.66, FarmColors.cloud);
      case Sky.rain:
        for (var i = 0; i < 6; i++) {
          final life = (t * 3 + i / 6) % 1;
          final x = w * (0.28 + (i % 3) * 0.2) + (i > 2 ? w * 0.08 : 0);
          final y = w * 0.6 + life * w * 0.38;
          c.drawLine(Offset(x, y), Offset(x - w * 0.03, y + w * 0.1), Paint()
            ..color = FarmColors.water.withValues(alpha: 1 - life)
            ..strokeWidth = w * 0.045
            ..strokeCap = StrokeCap.round);
        }
        _cloud(c, Offset(w * 0.5 + drift * 0.5, w * 0.45), w * 0.7, FarmColors.cloudDark);
    }
  }

  @override
  bool shouldRepaint(_SkyPainter old) => old.t != t || old.sky != sky;
}

/// Bars that grow up from the baseline one after another, each labelled.
class GrowBars extends StatelessWidget {
  const GrowBars({super.key, required this.values, required this.labels, this.unit = 't', this.height = 170, this.highlight});

  final List<double> values;
  final List<String> labels;
  final String unit;
  final double height;
  final int? highlight;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final top = values.fold(0.0, math.max);
    return SizedBox(
      height: height + 54,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: values[i] / (top == 0 ? 1 : top)),
                duration: Duration(milliseconds: 900 + i * 140),
                curve: Motion.spring,
                builder: (_, v, _) => Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('${values[i].toStringAsFixed(values[i] >= 10 ? 0 : 1)} $unit', style: text.labelSmall!.copyWith(color: p.ink)),
                    const SizedBox(height: 4),
                    Container(
                      height: (height * v).clamp(4.0, height),
                      margin: const EdgeInsets.symmetric(horizontal: 7),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: i == highlight ? [p.accentGlow, p.accent] : [p.accentWash, p.accentGlow.withValues(alpha: 0.6)],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(labels[i], style: text.labelSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
