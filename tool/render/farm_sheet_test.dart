import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furrow/config/motion.dart';
import 'package:furrow/config/theme.dart';
import 'package:furrow/data/models.dart';
import 'package:furrow/widgets/farm.dart';

void main() {
  testWidgets('farm sheet', (tester) async {
    Motion.ambient = false;
    tester.view.physicalSize = const Size(1200, 760);
    tester.view.devicePixelRatio = 1;
    final fields = [for (final f in jsonDecode(File('assets/data/fields.json').readAsStringSync()) as List) Field.fromJson(f as Map<String, Object?>)];
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: RepaintBoundary(
        key: key,
        child: Container(
          color: const Color(0xFFF6F3EA),
          padding: const EdgeInsets.all(16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 440, child: FarmMap(fields: fields, moisture: (f) => f.moisture.toDouble(), watering: const {'river'}, selected: 'north')),
            const SizedBox(width: 16),
            Expanded(
              child: Wrap(children: [
                for (final c in Crop.values) Plant(crop: c, growth: 0.9, size: 210),
                const Plant(crop: Crop.lettuce, growth: 0.4, size: 210),
              ]),
            ),
          ]),
        ),
      ),
    ));
    await tester.pump(const Duration(seconds: 3));
    final img = (key.currentContext!.findRenderObject()! as dynamic).toImageSync(pixelRatio: 1.0) as ui.Image;
    final bytes = await tester.runAsync(() => img.toByteData(format: ui.ImageByteFormat.png));
    File('build/farm_sheet.png')..createSync(recursive: true)..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}
