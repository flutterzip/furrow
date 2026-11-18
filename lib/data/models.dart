import 'dart:math' as math;
import 'dart:ui';

enum Crop {
  wheat('Wheat', 'Winter wheat', 4.2),
  maize('Maize', 'Sweet corn', 6.5),
  tomato('Tomatoes', 'Vine tomatoes', 48),
  lettuce('Lettuce', 'Butterhead', 22),
  soy('Soybeans', 'Edamame soy', 3.1);

  const Crop(this.label, this.variety, this.tonnesPerHa);
  final String label, variety;

  /// Expected yield at harvest.
  final double tonnesPerHa;
}

/// Where a crop is in its life, from its share of the growing cycle.
enum Stage {
  sprout('Sprouting', 0),
  leaves('Leafing out', 0.25),
  growing('Growing', 0.5),
  flowering('Flowering', 0.75),
  ready('Ready to harvest', 0.97);

  const Stage(this.label, this.from);
  final String label;
  final double from;

  static Stage of(double growth) => Stage.values.lastWhere((s) => growth >= s.from);
}

class Field {
  const Field({
    required this.id,
    required this.name,
    required this.crop,
    required this.hectares,
    required this.plantedDaysAgo,
    required this.cycleDays,
    required this.moisture,
    required this.targetLow,
    required this.targetHigh,
    required this.irrigating,
    required this.shape,
    required this.rowAngle,
  });

  final String id, name;
  final Crop crop;
  final double hectares;
  final int plantedDaysAgo, cycleDays;

  /// Soil moisture at the start of the demo, percent.
  final int moisture;
  final int targetLow, targetHigh;
  final bool irrigating;

  /// Corners on the farm map, as fractions of the map's size.
  final List<Offset> shape;

  /// Direction of the crop rows, radians.
  final double rowAngle;

  /// 0..1 through the growing cycle.
  double get growth => (plantedDaysAgo / cycleDays).clamp(0.0, 1.0);

  Stage get stage => Stage.of(growth);

  int get daysToHarvest => math.max(0, cycleDays - plantedDaysAgo);

  double get expectedTonnes => hectares * crop.tonnesPerHa;

  factory Field.fromJson(Map<String, Object?> j) {
    final target = j['target'] as List;
    return Field(
      id: j['id'] as String,
      name: j['name'] as String,
      crop: Crop.values.byName(j['crop'] as String),
      hectares: (j['hectares'] as num).toDouble(),
      plantedDaysAgo: j['plantedDaysAgo'] as int,
      cycleDays: j['cycleDays'] as int,
      moisture: j['moisture'] as int,
      targetLow: target[0] as int,
      targetHigh: target[1] as int,
      irrigating: j['irrigating'] as bool,
      shape: [for (final pt in j['shape'] as List) Offset(((pt as List)[0] as num).toDouble(), (pt[1] as num).toDouble())],
      rowAngle: (j['rowAngle'] as num).toDouble(),
    );
  }
}

enum Sky {
  sun('Sunny'),
  partly('Partly cloudy'),
  cloud('Cloudy'),
  rain('Rain');

  const Sky(this.label);
  final String label;
}

class Forecast {
  const Forecast({required this.day, required this.sky, required this.high, required this.low, required this.rain, required this.wind});

  final DateTime day;
  final Sky sky;
  final int high, low;

  /// Chance of rain, percent.
  final int rain;

  /// km/h
  final int wind;
}

/// A week of weather, worked out from the date so it is stable all day and
/// never goes stale.
List<Forecast> forecastFrom(DateTime today) {
  final base = DateTime(today.year, today.month, today.day);
  return [
    for (var i = 0; i < 7; i++)
      () {
        final d = base.add(Duration(days: i));
        final r = math.Random(d.year * 400 + d.month * 32 + d.day);
        final sky = Sky.values[r.nextInt(Sky.values.length)];
        final high = 22 + r.nextInt(9) - (sky == Sky.rain ? 4 : 0);
        return Forecast(
          day: d,
          sky: sky,
          high: high,
          low: high - 7 - r.nextInt(4),
          rain: switch (sky) { Sky.rain => 60 + r.nextInt(35), Sky.cloud => 20 + r.nextInt(30), _ => r.nextInt(15) },
          wind: 6 + r.nextInt(18),
        );
      }(),
  ];
}

class Task {
  const Task({required this.id, required this.title, required this.fieldId, required this.due, this.done = false});

  final String id, title, fieldId;
  final DateTime due;
  final bool done;

  Task copyWith({bool? done}) => Task(id: id, title: title, fieldId: fieldId, due: due, done: done ?? this.done);

  Map<String, Object?> toJson() => {'id': id, 'title': title, 'fieldId': fieldId, 'due': due.toIso8601String(), 'done': done};

  factory Task.fromJson(Map<String, Object?> j) => Task(
        id: j['id'] as String,
        title: j['title'] as String,
        fieldId: j['fieldId'] as String,
        due: DateTime.parse(j['due'] as String),
        done: j['done'] as bool,
      );
}

const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
String weekday(DateTime d) => _days[d.weekday - 1];
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
