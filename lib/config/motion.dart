import 'package:flutter/widgets.dart';

/// How things move. How long the app *waits* is a different question and
/// lives in `AppTiming`.
abstract final class Motion {
  static const quick = Duration(milliseconds: 160);
  static const short = Duration(milliseconds: 240);
  static const medium = Duration(milliseconds: 380);
  static const long = Duration(milliseconds: 600);

  /// A screen's sections rising in, from one controller sliced by intervals.
  static const entrance = Duration(milliseconds: 1000);

  /// One screen handing over to the next (the field flies between them).
  static const route = Duration(milliseconds: 620);

  /// A gauge or ring filling to a new value.
  static const ring = Duration(milliseconds: 1100);

  /// Crops growing to their stage when a field first appears.
  static const grow = Duration(milliseconds: 1600);

  static const shake = Duration(milliseconds: 520);

  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;
  static const settle = Curves.easeOutQuart;
  static const spring = Curves.easeOutBack;

  /// Ambient loops (rain, water, sprinklers, swaying crops) run only when
  /// this is true. Tests switch it off so `pumpAndSettle` can settle.
  static bool ambient = true;

  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  static bool loops(BuildContext context) => ambient && !reduced(context);
}
