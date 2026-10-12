import 'package:flutter/material.dart';

/// Colour tokens, mirroring the "Tiny Treasury" variable collection in Figma.
class TT {
  TT._();

  static const ink = Color(0xFF16425B);
  static const bg = Color(0xFFECFDFF);
  static const surface = Color(0xFFFFFFFF);
  static const muted = Color(0xFF5E7B88);
  static const teal = Color(0xFF1FA39A);
  static const tealDark = Color(0xFF12807A);
  static const gold = Color(0xFFFFC83D);
  static const sky = Color(0xFF4FC3F7);
  static const purple = Color(0xFF8E5BE8);
  static const coral = Color(0xFFFF6B57);
  static const coralStrong = Color(0xFFF0573F);
  static const pink = Color(0xFFFF5FA2);
  static const skySoft = Color(0xFFD6F3FF);
  static const goldSoft = Color(0xFFFFF3CC);
  static const tealSoft = Color(0xFFD7F3EF);
  static const purpleSoft = Color(0xFFECE3FC);
  static const coralSoft = Color(0xFFFFE4DF);
  static const track = Color(0xFFE2F3F6);

  // Icon tints used inside pastel tiles.
  static const iconCoral = Color(0xFFE8543F);
  static const iconSky = Color(0xFF1E8FC4);
  static const iconGold = Color(0xFFD98A00);

  // Spacing / radii
  static const gutter = 24.0;
  static const rCard = 24.0;
  static const rField = 18.0;

  static const _fredoka = 'Fredoka';
  static const _nunito = 'Nunito';

  /// Fredoka (headings, numbers). Falls back to Nunito for glyphs Fredoka lacks, e.g. ₹.
  static TextStyle display(double size, {Color color = ink, double? height}) => TextStyle(
        fontFamily: _fredoka,
        fontFamilyFallback: const [_nunito],
        fontWeight: FontWeight.w600,
        fontSize: size,
        height: height,
        color: color,
      );

  /// Nunito (labels, body).
  static TextStyle body(double size, {Color color = ink, double? height, TextDecoration? decoration}) => TextStyle(
        fontFamily: _nunito,
        fontWeight: FontWeight.w600,
        fontSize: size,
        height: height,
        color: color,
        decoration: decoration,
        decorationColor: color,
      );

  static List<BoxShadow> softShadow([double opacity = 0.08]) => [
        BoxShadow(color: alpha(ink, opacity), blurRadius: 18, offset: const Offset(0, 6)),
      ];

  /// Version-safe alpha helper (avoids withOpacity/withValues API differences).
  static Color alpha(Color c, double opacity) => c.withAlpha((opacity * 255).round());

  static ThemeData theme() {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(seedColor: tealDark, surface: surface, primary: tealDark),
      fontFamily: _nunito,
      splashFactory: InkSparkle.splashFactory,
    );
    return base.copyWith(
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: coralStrong,
        selectionColor: tealSoft,
        selectionHandleColor: tealDark,
      ),
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Colors.transparent, elevation: 0),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: SoftPageTransitionsBuilder(),
        TargetPlatform.iOS: SoftPageTransitionsBuilder(),
      }),
    );
  }
}

/// Avatar colour pairs assigned to kids in order.
class KidPalette {
  final Color bg;
  final Color fg;
  const KidPalette(this.bg, this.fg);

  static const all = [
    KidPalette(TT.purpleSoft, TT.purple),
    KidPalette(TT.coralSoft, TT.coralStrong),
    KidPalette(TT.skySoft, TT.ink),
    KidPalette(TT.tealSoft, TT.tealDark),
    KidPalette(TT.goldSoft, TT.ink),
  ];

  static KidPalette of(int index) => all[index % all.length];
}

/// Gentle page motion: the new page fades in while sliding up a little.
class SoftPageTransitionsBuilder extends PageTransitionsBuilder {
  const SoftPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(curved),
        child: child,
      ),
    );
  }
}

/// Standard motion values used across the app.
class Motion {
  Motion._();
  static const fast = Duration(milliseconds: 180);
  static const medium = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 450);
  static const curve = Curves.easeOutCubic;
}
