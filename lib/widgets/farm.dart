import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/motion.dart';
import '../config/palette.dart';
import '../data/models.dart';
import 'farm_colors.dart';

/// Colour of a crop's plants.
Color cropColor(Crop c) => switch (c) {
      Crop.wheat => FarmColors.wheat,
      Crop.maize => FarmColors.leaf,
      Crop.tomato => FarmColors.leaf,
      Crop.lettuce => FarmColors.lettuce,
      Crop.soy => FarmColors.soy,
    };

/// Soil, darker the wetter it is (0..100).
Color soilColor(double moisture) => Color.lerp(FarmColors.soil, FarmColors.soilWet, (moisture / 80).clamp(0.0, 1.0))!;

/// The whole farm from above: fields cut into the grass with their crops
/// growing in rows, a well in the middle, and water running out to any
/// field being watered. Tap a field to choose it.
class FarmMap extends StatefulWidget {
  const FarmMap({
    super.key,
    required this.fields,
    required this.moisture,
    required this.watering,
    this.selected,
    this.onTap,
    this.labels = true,
  });

  final List<Field> fields;
  final double Function(Field) moisture;
  final Set<String> watering;
  final String? selected;
  final ValueChanged<Field>? onTap;
  final bool labels;

  @override
  State<FarmMap> createState() => _FarmMapState();
}

class _FarmMapState extends State<FarmMap> with TickerProviderStateMixin {
  late final _grow = AnimationController(vsync: this, duration: Motion.grow);
  late final _loop = AnimationController(vsync: this, duration: const Duration(seconds: 4));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _grow.value = 1;
    } else if (_grow.value == 0 && !_grow.isAnimating) {
      _grow.forward();
    }
    if (Motion.loops(context)) {
      if (!_loop.isAnimating) _loop.repeat();
    } else {
      _loop.stop();
    }
  }

  @override
  void dispose() {
    _grow.dispose();
    _loop.dispose();
    super.dispose();
  }

  void _tap(Offset local, Size size) {
    for (final f in widget.fields) {
      final path = Path()..addPolygon([for (final p in f.shape) Offset(p.dx * size.width, p.dy * size.height)], true);
      if (path.contains(local)) {
        HapticFeedback.selectionClick();
        widget.onTap?.call(f);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return LayoutBuilder(
      builder: (context, box) {
        final size = Size(box.maxWidth, box.maxWidth * 0.86);
        return Semantics(
          label: 'Farm map with ${widget.fields.length} fields',
          child: GestureDetector(
            onTapUp: widget.onTap == null ? null : (d) => _tap(d.localPosition, size),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: AnimatedBuilder(
                animation: Listenable.merge([_grow, _loop]),
                builder: (context, _) => CustomPaint(
                  size: size,
                  painter: _FarmPainter(
                    fields: widget.fields,
                    moisture: widget.moisture,
                    watering: widget.watering,
                    selected: widget.selected,
                    grow: Curves.easeOutCubic.transform(_grow.value),
                    t: _loop.value,
                    accent: p.accent,
                    glow: p.accentGlow,
                    labelBg: p.card,
                    labelFg: p.ink,
                    labels: widget.labels,
                    dark: Theme.of(context).brightness == Brightness.dark,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FarmPainter extends CustomPainter {
  _FarmPainter({
    required this.fields,
    required this.moisture,
    required this.watering,
    required this.selected,
    required this.grow,
    required this.t,
    required this.accent,
    required this.glow,
    required this.labelBg,
    required this.labelFg,
    required this.labels,
    required this.dark,
  });

  final List<Field> fields;
  final double Function(Field) moisture;
  final Set<String> watering;
  final String? selected;
  final double grow, t;
  final Color accent, glow, labelBg, labelFg;
  final bool labels, dark;

  static const _well = Offset(0.525, 0.475);

  @override
  void paint(Canvas c, Size s) {
    final a = t * math.pi * 2;
    // Grass, with a soft lighter patch and a scatter of tufts.
    c.drawRect(Offset.zero & s, Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(s.width, s.height), [FarmColors.grass, FarmColors.grassDark]));
    final rng = math.Random(9);
    final tuft = Paint()..color = FarmColors.grassDark.withValues(alpha: 0.6);
    for (var i = 0; i < 140; i++) {
      c.drawCircle(Offset(rng.nextDouble() * s.width, rng.nextDouble() * s.height), 1 + rng.nextDouble() * 1.6, tuft);
    }

    final well = Offset(_well.dx * s.width, _well.dy * s.height);
    // Pipes from the well to fields being watered, with water pulsing along.
    for (final f in fields.where((f) => watering.contains(f.id))) {
      final to = _centroid(f, s);
      final pipe = Path()
        ..moveTo(well.dx, well.dy)
        ..quadraticBezierTo((well.dx + to.dx) / 2, well.dy, to.dx, to.dy);
      c.drawPath(pipe, Paint()
        ..color = const Color(0x55FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round);
      final m = pipe.computeMetrics().first;
      for (var d = (t * 24) % 24; d < m.length; d += 24) {
        final pos = m.getTangentForOffset(d)!.position;
        c.drawCircle(pos, 2.6, Paint()..color = FarmColors.water);
      }
    }

    for (final f in fields) {
      _field(c, s, f, a);
    }
    // Trees along the edges, each canopy breathing a little in the wind.
    for (final (x, y, r) in const [(0.03, 0.06, 13.0), (0.97, 0.12, 15.0), (0.96, 0.9, 12.0), (0.03, 0.95, 14.0), (0.5, 0.97, 11.0), (0.51, 0.04, 10.0)]) {
      final ctr = Offset(x * s.width, y * s.height);
      final rr = r * (1 + 0.04 * math.sin(a + x * 9));
      c.drawCircle(ctr + const Offset(4, 5), rr, Paint()..color = const Color(0x33000000));
      c.drawCircle(ctr, rr, Paint()..shader = ui.Gradient.radial(ctr - Offset(rr * 0.35, rr * 0.35), rr * 1.3, [FarmColors.leafLight, FarmColors.grassDark]));
    }

    // The well: a ring of stone and water that glints.
    c.drawCircle(well, 15, Paint()..color = const Color(0xFFB7AA95));
    c.drawCircle(well, 11, Paint()..shader = ui.Gradient.radial(well, 11, [FarmColors.water, const Color(0xFF2F7FA8)]));
    c.drawCircle(well + Offset(-3 + math.sin(a) * 1.5, -3), 2.2, Paint()..color = const Color(0xCCFFFFFF));

    // At night the farm sits back a little, so it does not glare.
    if (dark) c.drawRect(Offset.zero & s, Paint()..color = const Color(0x52081210));
    if (labels) {
      for (final f in fields) {
        _label(c, s, f);
      }
    }
  }

  Offset _centroid(Field f, Size s) {
    var x = 0.0, y = 0.0;
    for (final p in f.shape) {
      x += p.dx;
      y += p.dy;
    }
    return Offset(x / f.shape.length * s.width, y / f.shape.length * s.height);
  }

  void _field(Canvas c, Size s, Field f, double a) {
    final pts = [for (final p in f.shape) Offset(p.dx * s.width, p.dy * s.height)];
    final path = Path()..addPolygon(pts, true);
    final m = moisture(f);
    final chosen = f.id == selected;
    if (chosen) {
      c.drawPath(path, Paint()
        ..color = glow.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    }
    c.drawPath(path, Paint()..color = soilColor(m));
    c.save();
    c.clipPath(path);
    final bounds = path.getBounds();
    final ctr = bounds.center;
    final reach = bounds.longestSide;
    // Furrows and plants along them.
    c.save();
    c.translate(ctr.dx, ctr.dy);
    c.rotate(f.rowAngle);
    const gap = 11.0;
    final furrow = Paint()
      ..color = FarmColors.soilDark.withValues(alpha: 0.55)
      ..strokeWidth = 3;
    final g = f.growth * grow;
    for (var y = -reach; y <= reach; y += gap) {
      c.drawLine(Offset(-reach, y + gap / 2), Offset(reach, y + gap / 2), furrow);
      for (var x = -reach; x <= reach; x += 12) {
        final sway = math.sin(a + x * 0.05 + y * 0.03) * 1.4 * g;
        _plant(c, f.crop, Offset(x + sway, y), g);
      }
    }
    c.restore();
    // A sheen of water sweeping across a field being watered.
    if (watering.contains(f.id)) {
      final sweep = (t * 1.6 % 1.6 - 0.3) * bounds.width;
      c.drawRect(
        bounds,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(bounds.left + sweep, bounds.top),
            Offset(bounds.left + sweep + bounds.width * 0.4, bounds.bottom),
            [FarmColors.water.withValues(alpha: 0), FarmColors.water.withValues(alpha: 0.35), FarmColors.water.withValues(alpha: 0)],
            [0, 0.5, 1],
          ),
      );
    }
    c.restore();
    c.drawPath(path, Paint()
      ..color = chosen ? accent : FarmColors.soilDark.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = chosen ? 3 : 1.5
      ..strokeJoin = StrokeJoin.round);
  }

  /// One plant on the map at [p], grown [g] (0..1).
  void _plant(Canvas c, Crop crop, Offset p, double g) {
    if (g <= 0.02) return;
    switch (crop) {
      case Crop.wheat:
        final paint = Paint()
          ..color = Color.lerp(FarmColors.leaf, FarmColors.wheat, g)!
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round;
        for (final dx in [-2.0, 0.0, 2.0]) {
          c.drawLine(p, p + Offset(dx, -7 * g), paint);
        }
      case Crop.maize:
        c.drawLine(p, p + Offset(0, -9 * g), Paint()
          ..color = FarmColors.stem
          ..strokeWidth = 1.8);
        c.drawOval(Rect.fromCenter(center: p + Offset(2.5, -5 * g), width: 5 * g, height: 2.4 * g), Paint()..color = FarmColors.leaf);
        if (g > 0.6) c.drawCircle(p + Offset(-1.5, -6 * g), 1.6, Paint()..color = FarmColors.maize);
      case Crop.tomato:
        c.drawCircle(p, 4.2 * g, Paint()..color = FarmColors.leaf);
        if (g > 0.55) {
          c.drawCircle(p + const Offset(1.6, -1), 1.5, Paint()..color = FarmColors.tomato);
          c.drawCircle(p + const Offset(-1.8, 1.2), 1.3, Paint()..color = FarmColors.tomato);
        }
      case Crop.lettuce:
        c.drawCircle(p, 4.5 * g, Paint()..color = FarmColors.lettuce);
        c.drawCircle(p, 2 * g, Paint()..color = FarmColors.leafLight);
      case Crop.soy:
        final paint = Paint()..color = FarmColors.soy;
        c.drawCircle(p + Offset(-1.8 * g, 0), 2.2 * g, paint);
        c.drawCircle(p + Offset(1.8 * g, -1 * g), 2.2 * g, paint);
        c.drawCircle(p + Offset(0, -2.6 * g), 2 * g, paint);
    }
  }

  void _label(Canvas c, Size s, Field f) {
    final ctr = _centroid(f, s);
    final tp = TextPainter(
      text: TextSpan(text: f.name, style: TextStyle(fontFamily: 'Bricolage', fontSize: 10.5, fontWeight: FontWeight.w700, color: labelFg)),
      textDirection: TextDirection.ltr,
    )..layout();
    final r = RRect.fromRectAndRadius(Rect.fromCenter(center: ctr, width: tp.width + 14, height: tp.height + 6), const Radius.circular(10));
    c.drawRRect(r, Paint()..color = labelBg.withValues(alpha: 0.9));
    tp.paint(c, ctr - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_FarmPainter old) => true;
}

/// One plant up close, grown to [growth] (0..1): a stem that rises from a
/// mound of soil, leaves that unfold in turn, and the crop's crown (ears of
/// wheat, a cob, tomatoes, a lettuce head, pods) once it is far enough on.
/// It grows from bare soil to [growth] when it appears and sways after.
class Plant extends StatefulWidget {
  const Plant({super.key, required this.crop, required this.growth, this.size = 220});

  final Crop crop;
  final double growth;
  final double size;

  @override
  State<Plant> createState() => _PlantState();
}

class _PlantState extends State<Plant> with TickerProviderStateMixin {
  late final _grow = AnimationController(vsync: this, duration: Motion.grow);
  late final _sway = AnimationController(vsync: this, duration: const Duration(seconds: 3));
  late double _from = 0;
  late double _to = widget.growth;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _grow.value = 1;
    } else if (_grow.value == 0 && !_grow.isAnimating) {
      _grow.forward();
    }
    if (Motion.loops(context)) {
      if (!_sway.isAnimating) _sway.repeat();
    } else {
      _sway.stop();
    }
  }

  @override
  void didUpdateWidget(Plant old) {
    super.didUpdateWidget(old);
    if (old.growth != widget.growth) {
      _from = _now;
      _to = widget.growth;
      _grow.forward(from: Motion.reduced(context) ? 1 : 0);
    }
  }

  double get _now => _from + (_to - _from) * Curves.easeOutCubic.transform(_grow.value);

  @override
  void dispose() {
    _grow.dispose();
    _sway.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: Listenable.merge([_grow, _sway]),
        builder: (context, _) => CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _PlantPainter(widget.crop, _now, math.sin(_sway.value * math.pi * 2), p.shadow),
        ),
      ),
    );
  }
}

class _PlantPainter extends CustomPainter {
  _PlantPainter(this.crop, this.g, this.sway, this.shadow);

  final Crop crop;
  final double g, sway;
  final Color shadow;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final ground = h * 0.86;
    c.drawOval(Rect.fromCenter(center: Offset(w / 2, ground + 8), width: w * 0.62, height: 18), Paint()
      ..color = shadow
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    // The mound of soil.
    final mound = Path()
      ..moveTo(w * 0.2, ground + 6)
      ..quadraticBezierTo(w * 0.5, ground - 22, w * 0.8, ground + 6)
      ..close();
    c.drawPath(mound, Paint()..shader = ui.Gradient.linear(Offset(0, ground - 20), Offset(0, ground + 6), [FarmColors.soil, FarmColors.soilDark]));
    if (g <= 0.01) return;

    final lettuce = crop == Crop.lettuce;
    final height = lettuce ? h * 0.12 * g : h * (0.12 + 0.6 * g);
    final base = Offset(w / 2, ground - 10);
    final tip = Offset(w / 2 + sway * 8 * g, base.dy - height);
    final stem = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(w / 2 - sway * 4, base.dy - height * 0.55, tip.dx, tip.dy);
    if (!lettuce) {
      c.drawPath(stem, Paint()
        ..color = crop == Crop.wheat ? Color.lerp(FarmColors.stem, FarmColors.wheatDark, g)! : FarmColors.stem
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 + 3 * g
        ..strokeCap = StrokeCap.round);
    }
    final metric = stem.computeMetrics().first;
    // Leaves unfold one after another up the stem.
    final leaves = lettuce ? 0 : (1 + g * 6).floor();
    for (var i = 0; i < leaves; i++) {
      final at = 0.18 + i * 0.13;
      if (at > 0.9) break;
      final tan = metric.getTangentForOffset(metric.length * at)!;
      final side = i.isEven ? -1.0 : 1.0;
      final open = ((g * 7 - i) / 1.5).clamp(0.0, 1.0);
      c.save();
      c.translate(tan.position.dx, tan.position.dy);
      c.rotate(side * (0.9 - open * 0.35) + sway * 0.05);
      final len = (crop == Crop.maize ? 62.0 : 48.0) * open;
      final leaf = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(side * len * 0.5, -len * 0.35, side * len, -len * 0.1)
        ..quadraticBezierTo(side * len * 0.5, len * 0.12, 0, 0)
        ..close();
      c.drawPath(leaf, Paint()..color = crop == Crop.wheat ? Color.lerp(FarmColors.leaf, FarmColors.wheat, g)! : FarmColors.leaf);
      c.drawLine(Offset.zero, Offset(side * len * 0.8, -len * 0.18), Paint()
        ..color = FarmColors.leafLight.withValues(alpha: 0.7)
        ..strokeWidth = 1.2);
      c.restore();
    }
    final crown = ((g - 0.6) / 0.4).clamp(0.0, 1.0);
    switch (crop) {
      case Crop.wheat:
        if (crown > 0) {
          for (var i = 0; i < 7; i++) {
            final y = tip.dy + i * 9 * crown;
            for (final side in [-1.0, 1.0]) {
              c.drawOval(Rect.fromCenter(center: Offset(tip.dx + side * 4, y), width: 9 * crown, height: 13 * crown), Paint()..color = FarmColors.wheat);
            }
          }
        }
      case Crop.maize:
        if (crown > 0) {
          final cob = Rect.fromCenter(center: Offset(tip.dx + 12, tip.dy + height * 0.35), width: 14 * crown, height: 34 * crown);
          c.drawRRect(RRect.fromRectAndRadius(cob, const Radius.circular(8)), Paint()..color = FarmColors.maize);
          c.drawArc(cob.inflate(2), 1.2, 1.6, false, Paint()
            ..color = FarmColors.leaf
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4);
        }
        c.drawLine(tip, tip + const Offset(0, -10), Paint()
          ..color = FarmColors.wheatDark
          ..strokeWidth = 2);
      case Crop.tomato:
        if (crown > 0) {
          for (final (dx, dy) in [(-18.0, 0.32), (16.0, 0.45), (-10.0, 0.6)]) {
            final pos = Offset(tip.dx + dx, tip.dy + height * dy);
            c.drawCircle(pos, 11 * crown, Paint()..shader = ui.Gradient.radial(pos - const Offset(3, 3), 12, [const Color(0xFFF07A5E), FarmColors.tomato]));
            c.drawCircle(pos - Offset(0, 10 * crown), 2.4 * crown, Paint()..color = FarmColors.stem);
          }
        }
      case Crop.lettuce:
        // A rosette: three rings of ruffled leaves, dark outside to pale in
        // the heart, opening wider as it grows.
        final r = w * (0.17 + 0.17 * g);
        for (final (ring, n, color) in [(1.0, 9, FarmColors.leaf), (0.72, 7, FarmColors.lettuce), (0.45, 5, FarmColors.leafLight)]) {
          for (var i = 0; i < n; i++) {
            final ang = i / n * math.pi * 2 + ring * 1.3 + sway * 0.06;
            final len = r * ring;
            c.save();
            c.translate(base.dx, base.dy - r * 0.35 * ring);
            c.scale(1, 0.62);
            c.rotate(ang);
            final leaf = Path()..moveTo(0, 0);
            const steps = 14;
            for (var k = 0; k <= steps; k++) {
              final tt = k / steps;
              final a2 = (tt - 0.5) * 1.5;
              final rr = len * (0.75 + 0.25 * math.sin(tt * math.pi)) + math.sin(tt * math.pi * 6) * len * 0.06;
              leaf.lineTo(math.cos(a2) * rr, math.sin(a2) * rr);
            }
            leaf.close();
            c.drawPath(leaf, Paint()..color = Color.lerp(color, FarmColors.leaf, (i % 3) * 0.12)!);
            c.drawLine(Offset.zero, Offset(len * 0.8, 0), Paint()
              ..color = FarmColors.leafLight.withValues(alpha: 0.55)
              ..strokeWidth = 1.4);
            c.restore();
          }
        }
        c.drawCircle(base + Offset(0, -r * 0.2), r * 0.22, Paint()..shader = ui.Gradient.radial(base + Offset(0, -r * 0.2), r * 0.22, [const Color(0xFFEAF5BE), FarmColors.leafLight]));
      case Crop.soy:
        if (crown > 0) {
          for (final (dx, dy) in [(-14.0, 0.3), (12.0, 0.42), (-8.0, 0.55), (10.0, 0.2)]) {
            final pos = Offset(tip.dx + dx, tip.dy + height * dy);
            c.save();
            c.translate(pos.dx, pos.dy);
            c.rotate(dx > 0 ? 0.5 : -0.5);
            c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 9 * crown, height: 24 * crown), const Radius.circular(6)), Paint()..color = FarmColors.soy);
            c.restore();
          }
        }
    }
  }

  @override
  bool shouldRepaint(_PlantPainter old) => old.g != g || old.sway != sway || old.crop != crop;
}

/// Paints one plant into [size] on [canvas], without a widget: for the app
/// icon and anything else drawn off screen.
void paintPlant(Canvas canvas, Size size, Crop crop, double growth, {Color shadow = const Color(0x332E2E3A)}) =>
    _PlantPainter(crop, growth, 0, shadow).paint(canvas, size);
