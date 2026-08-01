import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

/// ───────────────────────────────────────────────────────────────────────────
/// Finova design tokens.
///
/// This file is the single source of truth for every colour, gradient, radius,
/// border, shadow, spacing step and text style in the app. Nothing below the
/// design layer may hardcode a colour or a radius — widgets read from here.
///
/// Colours live on [FScheme] rather than as plain constants because the app
/// still ships a light-mode toggle. [FScheme.dark] is the palette from the
/// design plan and is the default; [FScheme.light] is its counterpart so the
/// existing toggle keeps working instead of being deleted.
/// ───────────────────────────────────────────────────────────────────────────

@immutable
class FScheme {
  const FScheme({
    required this.brightness,
    required this.bgApp,
    required this.bgSurface,
    required this.bgSurface2,
    required this.bgElevated,
    required this.bgInput,
    required this.bgNav,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textQuiet,
    required this.brandViolet,
    required this.brandVioletBright,
    required this.brandCyan,
    required this.accentGreen,
    required this.accentGreenDim,
    required this.accentRed,
    required this.accentRedDim,
    required this.accentAmber,
    required this.accentAmberDim,
    required this.link,
    required this.hairline,
    required this.hairlineStrong,
    required this.gradIcon,
    required this.scoreHigh,
    required this.scoreMid,
    required this.scoreLow,
  });

  final Brightness brightness;

  // ── backgrounds ──
  final Color bgApp;
  final Color bgSurface;
  final Color bgSurface2;
  final Color bgElevated;
  final Color bgInput;
  final Color bgNav;

  // ── text ──
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  /// Decorative only — dividers, disabled glyphs, ornament. Below 4.5:1 by
  /// design, so it must never carry text the user has to read.
  final Color textQuiet;

  // ── brand ──
  final Color brandViolet;
  final Color brandVioletBright;
  final Color brandCyan;

  // ── semantic ──
  final Color accentGreen;
  final Color accentGreenDim;
  final Color accentRed;
  final Color accentRedDim;
  final Color accentAmber;
  final Color accentAmberDim;
  final Color link;

  // ── lines ──
  final Color hairline;
  final Color hairlineStrong;

  // ── the violet icon tile gradient, which has to invert in light mode ──
  final List<Color> gradIcon;

  /// Score quality scale, deliberately *not* green/red: the sub-scores
  /// (quality / growth / value / risk) sit four in a row, and in green-red
  /// they read as four stocks rising and falling rather than as a rating.
  final Color scoreHigh;
  final Color scoreMid;
  final Color scoreLow;

  /// Const aliases for the two market colours, for the handful of painters
  /// that have a Canvas but no BuildContext to resolve a scheme from.
  static const Color darkAccentGreen = Color(0xFF22C55E);
  static const Color darkAccentRed = Color(0xFFEF4444);

  static const FScheme dark = FScheme(
    brightness: Brightness.dark,
    bgApp: Color(0xFF050508),
    bgSurface: Color(0xFF0E0E14),
    bgSurface2: Color(0xFF14141C),
    bgElevated: Color(0xFF1A1A24),
    bgInput: Color(0xFF0C0C12),
    bgNav: Color(0xFF08080C),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF9A9AAE),
    // Plan says #5C5C70. That measures 2.96:1 on --bg-surface and fails the
    // plan's own 4.5:1 floor (§8), so readable text uses this lightened value
    // (4.65:1) and #5C5C70 survives as [textQuiet] for ornament.
    textTertiary: Color(0xFF7A7A90),
    textQuiet: Color(0xFF5C5C70),
    brandViolet: Color(0xFF7C3AED),
    brandVioletBright: Color(0xFFA855F7),
    brandCyan: Color(0xFF22D3EE),
    accentGreen: Color(0xFF22C55E),
    accentGreenDim: Color(0x1F22C55E),
    accentRed: Color(0xFFEF4444),
    accentRedDim: Color(0x1FEF4444),
    accentAmber: Color(0xFFF59E0B),
    accentAmberDim: Color(0x1FF59E0B),
    link: Color(0xFF60A5FA),
    hairline: Color(0x0FFFFFFF),
    hairlineStrong: Color(0x14FFFFFF),
    gradIcon: [Color(0xFF3B1E6E), Color(0xFF1E1B3A)],
    scoreHigh: Color(0xFF2DD4BF),
    scoreMid: Color(0xFF818CF8),
    scoreLow: Color(0xFFC084FC),
  );

  static const FScheme light = FScheme(
    brightness: Brightness.light,
    bgApp: Color(0xFFF3F4F9),
    bgSurface: Color(0xFFFFFFFF),
    bgSurface2: Color(0xFFF0F1F7),
    bgElevated: Color(0xFFFFFFFF),
    bgInput: Color(0xFFFFFFFF),
    bgNav: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF0E0E16),
    textSecondary: Color(0xFF4A4A60),
    textTertiary: Color(0xFF6E6E86),
    textQuiet: Color(0xFF9A9AAE),
    brandViolet: Color(0xFF6D28D9),
    brandVioletBright: Color(0xFF7C3AED),
    brandCyan: Color(0xFF0891B2),
    accentGreen: Color(0xFF15803D),
    accentGreenDim: Color(0x1F22C55E),
    accentRed: Color(0xFFDC2626),
    accentRedDim: Color(0x1FEF4444),
    accentAmber: Color(0xFFB45309),
    accentAmberDim: Color(0x1FF59E0B),
    link: Color(0xFF1D4ED8),
    hairline: Color(0x14000000),
    hairlineStrong: Color(0x1F000000),
    gradIcon: [Color(0xFFEDE4FF), Color(0xFFE2E0F5)],
    scoreHigh: Color(0xFF0D9488),
    scoreMid: Color(0xFF4F46E5),
    scoreLow: Color(0xFF9333EA),
  );
}

/// Makes the active scheme available to the whole tree.
class FTheme extends InheritedWidget {
  const FTheme({super.key, required this.scheme, required super.child});

  final FScheme scheme;

  static FScheme of(BuildContext context) {
    final t = context.dependOnInheritedWidgetOfExactType<FTheme>();
    return t?.scheme ?? FScheme.dark;
  }

  @override
  bool updateShouldNotify(FTheme oldWidget) => oldWidget.scheme != scheme;
}

extension FThemeContext on BuildContext {
  /// `context.c.bgSurface` — the scheme, kept short because every build
  /// method in the app opens with it.
  FScheme get c => FTheme.of(this);

  /// True when the user asked the OS to cut down on animation.
  bool get reducedMotion =>
      MediaQuery.maybeOf(this)?.disableAnimations ?? false;
}

/// ── gradients ──
class FGrad {
  const FGrad._();

  /// Logo, avatar. 135deg violet → cyan.
  static const LinearGradient brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C3AED), Color(0xFF22D3EE)],
  );

  /// Violet icon tiles. 160deg — scheme-aware because it inverts in light.
  static LinearGradient icon(FScheme c) => LinearGradient(
    begin: const Alignment(-0.34, -1),
    end: const Alignment(0.34, 1),
    colors: c.gradIcon,
  );

  /// The wash behind the hero card. 180deg, fading out at 60%.
  static const LinearGradient hero = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x1A7C3AED), Color(0x000E0E14)],
    stops: [0.0, 0.6],
  );
}

/// ── corner radii ──
class FRadius {
  const FRadius._();

  /// Chips, "why?" tiles.
  static const double sm = 10;

  /// Small stock cards.
  static const double md = 14;

  /// Primary cards, search field.
  static const double lg = 18;

  static const double pill = 999;

  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
  static BorderRadius get pillAll => BorderRadius.circular(pill);
}

/// ── borders ──
class FBorder {
  const FBorder._();

  static Border subtle(FScheme c) => Border.all(color: c.hairline, width: 1);
  static Border card(FScheme c) =>
      Border.all(color: c.hairlineStrong, width: 1);
  static Border active(FScheme c) =>
      Border.all(color: c.brandViolet.withValues(alpha: 0.55), width: 1);
  static Border hero(FScheme c) =>
      Border.all(color: c.brandViolet.withValues(alpha: 0.35), width: 1);
}

/// ── shadows ──
class FShadow {
  const FShadow._();

  static List<BoxShadow> violet(FScheme c) => [
    BoxShadow(
      color: c.brandViolet.withValues(alpha: 0.18),
      blurRadius: 24,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> green(FScheme c) => [
    BoxShadow(
      color: c.accentGreen.withValues(alpha: 0.20),
      blurRadius: 20,
      spreadRadius: 0,
    ),
  ];
}

/// ── spacing scale: 4 / 8 / 12 / 16 / 20 / 24 / 32 ──
class FSpace {
  const FSpace._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  /// Global inline padding of every screen.
  static const double screen = 20;

  /// Vertical gap between stacked cards.
  static const double cardGap = 14;

  /// Inner padding of a card.
  static const double cardPad = 16;

  /// Inner padding of the hero card, which carries more.
  static const double heroPad = 18;

  /// Height of the fixed bottom nav, before the safe area.
  static const double navHeight = 60;

  /// Height of the sticky header.
  static const double headerHeight = 56;

  /// Scroll padding that keeps the last card clear of the nav.
  static const double scrollBottom = 96;
}

/// ── typography ──
///
/// One family for Hebrew and Latin (Heebo), tabular figures everywhere so
/// prices refreshing every 15s don't shift width mid-update.
class FType {
  const FType._();

  static const String family = 'Heebo';
  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  static TextStyle _base(
    double size,
    FontWeight weight,
    double height, {
    double? spacing,
  }) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: weight,
    height: height,
    letterSpacing: spacing,
    fontFeatures: _tabular,
  );

  /// 34/700 — the AI score.
  static TextStyle get display => _base(34, FontWeight.w700, 1.15);

  /// 24/700 — the greeting.
  static TextStyle get h1 => _base(24, FontWeight.w700, 1.3);

  /// 20/700 — stock name in the hero card.
  static TextStyle get h2 => _base(20, FontWeight.w700, 1.3);

  /// 16/600 — card headings.
  static TextStyle get h3 => _base(16, FontWeight.w600, 1.4);

  /// 14/400 — running text.
  static TextStyle get body => _base(14, FontWeight.w400, 1.5);

  /// 12/400 — secondary descriptions.
  static TextStyle get caption => _base(12, FontWeight.w400, 1.4);

  /// 11/500 — "why?" tile labels, tab labels.
  static TextStyle get micro => _base(11, FontWeight.w500, 1.3);

  /// 12/500 +0.04em — stock symbols.
  static TextStyle get ticker => _base(12, FontWeight.w500, 1.0, spacing: 0.48);

  /// The wordmark: uppercase, wide tracking.
  static TextStyle get wordmark =>
      _base(20, FontWeight.w600, 1.0, spacing: 1.6);
}

/// ── motion ──
class FMotion {
  const FMotion._();

  static const Duration screenEnter = Duration(milliseconds: 260);
  static const Duration stagger = Duration(milliseconds: 40);
  static const Duration ring = Duration(milliseconds: 900);
  static const Duration press = Duration(milliseconds: 120);
  static const Duration tab = Duration(milliseconds: 220);
  static const Duration shimmer = Duration(milliseconds: 1400);

  static const Curve ringCurve = Cubic(0.2, 0.8, 0.2, 1);
  static const Curve enter = Curves.easeOut;

  /// Collapses a duration to zero when the user asked for reduced motion.
  static Duration respect(BuildContext context, Duration d) =>
      context.reducedMotion ? Duration.zero : d;
}
