import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/motion.dart';
import '../config/timing.dart';
import '../data/models.dart';

class Seed {
  const Seed({required this.fields, required this.name, required this.farm, required this.tasks, this.avatar});

  final List<Field> fields;
  final String name, farm;
  final String? avatar;

  /// (id, title, field, days from today, done)
  final List<({String id, String title, String fieldId, int dueDays, bool done})> tasks;

  Field field(String id) => fields.firstWhere((f) => f.id == id);

  String get firstName => name.split(' ').first;

  static Future<Seed> load([AssetBundle? bundle]) async {
    final b = bundle ?? rootBundle;
    final fields = jsonDecode(await b.loadString('assets/data/fields.json')) as List;
    final p = jsonDecode(await b.loadString('assets/data/profile.json')) as Map<String, Object?>;
    return Seed(
      fields: [for (final f in fields) Field.fromJson(f as Map<String, Object?>)],
      name: p['name'] as String,
      farm: p['farm'] as String,
      avatar: p['avatar'] as String?,
      tasks: [
        for (final t in p['tasks'] as List)
          (
            id: (t as Map<String, Object?>)['id'] as String,
            title: t['title'] as String,
            fieldId: t['field'] as String,
            dueDays: t['dueDays'] as int,
            done: t['done'] as bool,
          ),
      ],
    );
  }
}

final seedProvider = Provider<Seed>((_) => throw UnimplementedError());
final prefsProvider = Provider<SharedPreferences>((_) => throw UnimplementedError());
final clockProvider = Provider<DateTime Function()>((_) => DateTime.now);

/// Ticks every second while ambient motion is on, so moisture rises live
/// while a field is being watered.
final tickProvider = StreamProvider<int>((ref) {
  if (!Motion.ambient) return const Stream.empty();
  return Stream.periodic(const Duration(seconds: 1), (i) => i);
});

final nowProvider = Provider<DateTime>((ref) {
  ref.watch(tickProvider);
  return ref.watch(clockProvider)();
});

// ------------------------------------------------------------ irrigation

/// Per field: when the water was turned on (null if off) and how much
/// moisture earlier waterings have already added.
class Water {
  const Water({this.since, this.banked = 0});

  final DateTime? since;
  final double banked;

  bool get on => since != null;

  Map<String, Object?> toJson() => {'since': since?.toIso8601String(), 'banked': banked};

  factory Water.fromJson(Map<String, Object?> j) =>
      Water(since: j['since'] == null ? null : DateTime.parse(j['since'] as String), banked: (j['banked'] as num).toDouble());
}

/// Watering adds one point of moisture every four seconds of the demo.
const secondsPerPoint = 4.0;

final waterProvider = NotifierProvider<WaterNotifier, Map<String, Water>>(WaterNotifier.new);

class WaterNotifier extends Notifier<Map<String, Water>> {
  static const _key = 'furrow.water.v1';

  SharedPreferences get _prefs => ref.read(prefsProvider);

  @override
  Map<String, Water> build() {
    final raw = _prefs.getString(_key);
    if (raw != null) {
      try {
        return {for (final e in (jsonDecode(raw) as Map<String, Object?>).entries) e.key: Water.fromJson(e.value as Map<String, Object?>)};
      } catch (_) {}
    }
    final now = ref.read(clockProvider)();
    return {for (final f in ref.read(seedProvider).fields) f.id: Water(since: f.irrigating ? now : null)};
  }

  void _save(Map<String, Water> next) {
    state = next;
    _prefs.setString(_key, jsonEncode({for (final e in next.entries) e.key: e.value.toJson()}));
  }

  /// Opens or closes a field's valve.
  Future<void> set(String fieldId, bool on) async {
    await AppTiming.wait(AppTiming.valve);
    final now = ref.read(clockProvider)();
    final w = state[fieldId] ?? const Water();
    if (on == w.on) return;
    final next = on
        ? Water(since: now, banked: w.banked)
        : Water(banked: w.banked + now.difference(w.since!).inMilliseconds / 1000 / secondsPerPoint);
    _save({...state, fieldId: next});
  }
}

/// A field's soil moisture now, percent.
double moistureOf(Field f, Water? w, DateTime now) {
  var extra = w?.banked ?? 0;
  if (w?.since != null) extra += now.difference(w!.since!).inMilliseconds / 1000 / secondsPerPoint;
  return math.min(92, f.moisture + extra);
}

final moistureProvider = Provider.family<double, String>((ref, id) {
  final f = ref.watch(seedProvider).field(id);
  return moistureOf(f, ref.watch(waterProvider)[id], ref.watch(nowProvider));
});

/// Too dry, fine or too wet, against the crop's target band.
enum Thirst { dry, good, wet }

Thirst thirstOf(Field f, double moisture) => moisture < f.targetLow ? Thirst.dry : (moisture > f.targetHigh ? Thirst.wet : Thirst.good);

final forecastProvider = Provider<List<Forecast>>((ref) => forecastFrom(ref.watch(clockProvider)()));

// ------------------------------------------------------------ tasks

final tasksProvider = NotifierProvider<TasksNotifier, List<Task>>(TasksNotifier.new);

class TasksNotifier extends Notifier<List<Task>> {
  static const _key = 'furrow.tasks.v1';

  SharedPreferences get _prefs => ref.read(prefsProvider);

  @override
  List<Task> build() {
    final raw = _prefs.getString(_key);
    if (raw != null) {
      try {
        return [for (final t in jsonDecode(raw) as List) Task.fromJson(t as Map<String, Object?>)];
      } catch (_) {}
    }
    final today = dateOnly(ref.read(clockProvider)());
    return [
      for (final t in ref.read(seedProvider).tasks)
        Task(id: t.id, title: t.title, fieldId: t.fieldId, due: today.add(Duration(days: t.dueDays)), done: t.done),
    ];
  }

  void _save(List<Task> next) {
    state = next;
    _prefs.setString(_key, jsonEncode([for (final t in next) t.toJson()]));
  }

  void toggle(String id) => _save([for (final t in state) t.id == id ? t.copyWith(done: !t.done) : t]);

  void add(String title, String fieldId, DateTime due) {
    final now = ref.read(clockProvider)();
    _save([...state, Task(id: 'task-${now.microsecondsSinceEpoch}', title: title.trim(), fieldId: fieldId, due: dateOnly(due))]);
  }

  /// Removes a task and hands back what is needed to put it back.
  (Task, int)? remove(String id) {
    final i = state.indexWhere((t) => t.id == id);
    if (i < 0) return null;
    final t = state[i];
    _save([...state]..removeAt(i));
    return (t, i);
  }

  void restore(Task t, int i) => _save([...state]..insert(i.clamp(0, state.length), t));
}

/// To do first (soonest), then done.
final sortedTasksProvider = Provider<List<Task>>((ref) {
  final list = [...ref.watch(tasksProvider)];
  list.sort((a, b) => a.done != b.done ? (a.done ? 1 : -1) : a.due.compareTo(b.due));
  return list;
});

// ------------------------------------------------------------ settings

class DemoSettings {
  const DemoSettings({this.theme = ThemeMode.system});

  final ThemeMode theme;
}

final demoSettingsProvider = NotifierProvider<DemoSettingsNotifier, DemoSettings>(DemoSettingsNotifier.new);

class DemoSettingsNotifier extends Notifier<DemoSettings> {
  static const _theme = 'furrow.theme.v1';

  @override
  DemoSettings build() =>
      DemoSettings(theme: ThemeMode.values.asNameMap()[ref.read(prefsProvider).getString(_theme)] ?? ThemeMode.system);

  Future<void> setTheme(ThemeMode mode) async {
    state = DemoSettings(theme: mode);
    await ref.read(prefsProvider).setString(_theme, mode.name);
  }
}

Future<void> resetDemo(WidgetRef ref) async {
  await ref.read(prefsProvider).clear();
  ref.invalidate(waterProvider);
  ref.invalidate(tasksProvider);
  ref.invalidate(demoSettingsProvider);
}
