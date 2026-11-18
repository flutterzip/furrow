import 'dart:ui';

/// The land. It is the subject of the app, so it is drawn the same in light
/// and dark, and lives here rather than in the UI palette.
abstract final class FarmColors {
  static const soil = Color(0xFF8A6A4A);
  static const soilDark = Color(0xFF6E523A);
  static const soilWet = Color(0xFF5C4430);
  static const grass = Color(0xFFA7C77A);
  static const grassDark = Color(0xFF8DB063);
  static const stem = Color(0xFF5E9440);
  static const leaf = Color(0xFF6FAE47);
  static const leafLight = Color(0xFF9CCB6A);
  static const wheat = Color(0xFFE2B24E);
  static const wheatDark = Color(0xFFC08F2E);
  static const maize = Color(0xFFF1C84B);
  static const tomato = Color(0xFFE2553E);
  static const lettuce = Color(0xFF8FC75A);
  static const soy = Color(0xFF9BB75A);
  static const water = Color(0xFF4FA9D8);
  static const sun = Color(0xFFF6C344);
  static const cloud = Color(0xFFE9EEF2);
  static const cloudDark = Color(0xFFB9C3CC);
}
