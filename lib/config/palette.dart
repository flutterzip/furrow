import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Every UI colour in Furrow is defined in this file.
//
// To re-skin the app, edit [Palette.light] and [Palette.dark] below. Every
// screen, the gauges, the weather and the irrigation read their colours from
// here through `context.palette`.
//
// Deliberately not here: the land itself (soil, crops, wheat, tomatoes),
// drawn in lib/widgets/farm_colors.dart. It is the subject, like product
// photography, so it looks the same in light and dark.
//
// The system: cream paper, earthy ink and exactly one accent (water teal).
// Ink is never pure black and paper is never pure white.
// ---------------------------------------------------------------------------

@immutable
class Palette extends ThemeExtension<Palette> {
  const Palette({
    required this.paper,
    required this.card,
    required this.ink,
    required this.inkSoft,
    required this.muted,
    required this.line,
    required this.field,
    required this.accent,
    required this.accentDeep,
    required this.accentGlow,
    required this.onAccent,
    required this.accentWash,
    required this.error,
    required this.eye,
    required this.face,
    required this.shadow,
    required this.scrim,
  });

  /// The page ground.
  final Color paper;

  /// Raised surfaces: the form card, sheets, the keypad keys.
  final Color card;

  /// Headlines and primary type.
  final Color ink;

  /// Body copy.
  final Color inkSoft;

  /// Hints, captions, inactive icons.
  final Color muted;

  /// Hairlines and resting field borders.
  final Color line;

  /// The fill of a field at rest.
  final Color field;

  /// The one accent: water. Buttons, moisture, irrigation, the chosen field.
  final Color accent;

  /// Pressed and emphasised accent.
  final Color accentDeep;

  /// A lighter accent for glows and gradients.
  final Color accentGlow;

  /// Type and icons on top of [accent].
  final Color onAccent;

  /// A pale tint of the accent for selected states and notices.
  final Color accentWash;

  /// Errors stay in the family: a deeper, redder neighbour of the accent.
  final Color error;

  /// The brightest highlight (sparkles on water).
  final Color eye;

  /// The darkest ink, the same in both modes.
  final Color face;

  /// Shadows under raised surfaces.
  final Color shadow;

  /// Behind sheets.
  final Color scrim;

  static const light = Palette(
    paper: Color(0xFFF6F3EA),
    card: Color(0xFFFFFDF7),
    ink: Color(0xFF1D2420),
    inkSoft: Color(0xFF4C5650),
    muted: Color(0xFF8A928C),
    line: Color(0xFFE3E0D3),
    field: Color(0xFFEEEBDF),
    accent: Color(0xFF14908A),
    accentDeep: Color(0xFF0B6B66),
    accentGlow: Color(0xFF6CC7C0),
    onAccent: Color(0xFFF2FBFA),
    accentWash: Color(0xFFDDF0EE),
    error: Color(0xFFB4492F),
    eye: Color(0xFFFFFFFC),
    face: Color(0xFF1D2420),
    shadow: Color(0x2E2E3A20),
    scrim: Color(0x661D2420),
  );

  static const dark = Palette(
    paper: Color(0xFF111614),
    card: Color(0xFF1A201D),
    ink: Color(0xFFEDF2EE),
    inkSoft: Color(0xFFC3CCC6),
    muted: Color(0xFF85908A),
    line: Color(0xFF26302B),
    field: Color(0xFF1F2723),
    accent: Color(0xFF4FC6BC),
    accentDeep: Color(0xFF2A9C93),
    accentGlow: Color(0xFF94E0D9),
    onAccent: Color(0xFF052523),
    accentWash: Color(0xFF173431),
    error: Color(0xFFEA866A),
    eye: Color(0xFFFFFFFC),
    face: Color(0xFF1D2420),
    shadow: Color(0x66000000),
    scrim: Color(0x99000000),
  );

  @override
  Palette copyWith() => this;

  @override
  Palette lerp(Palette? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return Palette(
      paper: c(paper, other.paper),
      card: c(card, other.card),
      ink: c(ink, other.ink),
      inkSoft: c(inkSoft, other.inkSoft),
      muted: c(muted, other.muted),
      line: c(line, other.line),
      field: c(field, other.field),
      accent: c(accent, other.accent),
      accentDeep: c(accentDeep, other.accentDeep),
      accentGlow: c(accentGlow, other.accentGlow),
      onAccent: c(onAccent, other.onAccent),
      accentWash: c(accentWash, other.accentWash),
      error: c(error, other.error),
      eye: c(eye, other.eye),
      face: c(face, other.face),
      shadow: c(shadow, other.shadow),
      scrim: c(scrim, other.scrim),
    );
  }
}

extension PaletteContext on BuildContext {
  Palette get palette => Theme.of(this).extension<Palette>()!;
}
