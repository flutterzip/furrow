// Draws the app icon to assets/brand/icon_1024.png from the same wheat
// stalk the app grows. Then: python3 tool/make_icons.py
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furrow/config/palette.dart';
import 'package:furrow/data/models.dart';
import 'package:furrow/widgets/farm.dart';

void main() {
  test('icon', () async {
    const s = 1024.0;
    const p = Palette.light;
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    c.drawRect(const Rect.fromLTWH(0, 0, s, s), Paint()..shader = ui.Gradient.linear(Offset.zero, const Offset(s, s), [p.accentGlow, p.accentDeep]));
    // A low sun behind the stalk.
    c.drawCircle(const Offset(512, 470), 300, Paint()..shader = ui.Gradient.radial(const Offset(512, 470), 300, [const Color(0x66FFF4D6), const Color(0x00FFF4D6)]));
    // Furrows in the ground.
    for (var i = 0; i < 4; i++) {
      final y = 800.0 + i * 70;
      c.drawLine(Offset(-40, y), Offset(s + 40, y - 40), Paint()
        ..color = const Color(0x22000000)
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round);
    }
    c.save();
    // The plant is drawn at app size, so scale it up rather than enlarge it.
    c.translate(152, 60);
    c.scale(3.6);
    paintPlant(c, const Size(200, 220), Crop.wheat, 1, shadow: const Color(0x33000000));
    c.restore();
    final img = await rec.endRecording().toImage(s.toInt(), s.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    File('assets/brand/icon_1024.png')..createSync(recursive: true)..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}
