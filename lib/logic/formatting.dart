/// ───────────────────────────────────────────────────────────────────────────
/// Pure formatting/classification helpers, extracted out of main.dart so they
/// can be unit tested without spinning up a widget tree or a real clock.
///
/// Nothing in this file touches BuildContext, network, or DateTime.now() —
/// every function takes what it needs as a parameter. main.dart's methods of
/// the same name are now one-line wrappers around these.
/// ───────────────────────────────────────────────────────────────────────────
library;

/// Three-way tone a recommendation/score can carry. Kept separate from the
/// design layer's FTone so this file has zero UI dependencies; main.dart
/// maps one to the other at the call site.
enum RecTone { bullish, bearish, neutral }

/// Signed percentage, e.g. `pctString(1.32)` -> `"+1.32%"`.
///
/// Starts with U+200E (left-to-right mark). Without it, inside Hebrew text
/// the sign renders on the wrong side — "1.32%+" instead of "+1.32%" — because
/// the bidi algorithm treats the digits as a number but the leading `+`/`-`
/// as a neutral character that gets reordered with the surrounding RTL run.
String pctString(num value, {int digits = 2}) {
  final sign = value >= 0 ? '+' : '';
  return '‎$sign${value.toStringAsFixed(digits)}%';
}

/// Avatar initials for a display name.
///
/// - Empty/blank name -> 'F' (the brand fallback, never a blank avatar).
/// - Single Hebrew word -> its first letter only (Hebrew has no uppercase, so
///   two letters would just be two arbitrary letters, not an abbreviation).
/// - Single Latin word -> first two letters, upper-cased ("Idan" -> "ID").
/// - Two or more words -> first letter of each of the first two, upper-cased.
String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return 'F';
  if (parts.length == 1) {
    final w = parts.first;
    // Hebrew block starts at U+0590; below that is Latin/ASCII.
    final isLatin = w.codeUnitAt(0) < 0x590;
    return (isLatin && w.length > 1)
        ? w.substring(0, 2).toUpperCase()
        : w.substring(0, 1);
  }
  return (parts[0][0] + parts[1][0]).toUpperCase();
}

/// Classifies an AI recommendation/verdict pair into a market tone.
/// Case-insensitive on both `finalRecommendation` and `verdict`, matching
/// against "bullish"/"buy" and "bearish"/"sell". Anything else is neutral.
RecTone recommendationTone(String recommendation, String verdict) {
  final rec = recommendation.toLowerCase();
  final v = verdict.toLowerCase();
  if (v.contains('bullish') || rec.contains('buy')) return RecTone.bullish;
  if (v.contains('bearish') || rec.contains('sell')) return RecTone.bearish;
  return RecTone.neutral;
}

/// Three-band classification of a Finova score (0-100), used to give the
/// four sub-scores (quality/growth/value/risk) their own teal/indigo/violet
/// scale instead of green/red — see design/tokens.dart FScheme.scoreHigh/Mid/Low
/// for why: green/red on four side-by-side numbers reads as four stocks
/// moving, not as a quality rating.
enum ScoreBand { high, mid, low }

ScoreBand scoreBand(int score) {
  if (score >= 68) return ScoreBand.high;
  if (score >= 50) return ScoreBand.mid;
  return ScoreBand.low;
}

/// How the "freshness" footer on the hero card should read, expressed as
/// data rather than a formatted string, so the caller supplies the
/// translated template and this function stays free of a translation table.
enum FreshnessKind { justNow, minutes, hours }

class Freshness {
  const Freshness(this.kind, this.n);
  final FreshnessKind kind;
  final int n;
}

/// [now] and [fetchedAt] are both explicit so this is testable without a
/// real clock. Returns null when nothing has been fetched yet.
Freshness? freshnessSince(DateTime? fetchedAt, DateTime now) {
  if (fetchedAt == null) return null;
  final mins = now.difference(fetchedAt).inMinutes;
  if (mins < 1) return const Freshness(FreshnessKind.justNow, 0);
  if (mins < 60) return Freshness(FreshnessKind.minutes, mins);
  return Freshness(FreshnessKind.hours, mins ~/ 60);
}

/// The short line under a "why?" tile: prefers the raw value if it's short
/// enough to survive a quarter-screen-wide tile, falls back to the verdict
/// text, which is usually longer but the only thing available.
String shortFactorDetail({String? value, String? verdict}) {
  final v = (value ?? '').trim();
  if (v.isNotEmpty && v.length <= 12) return v;
  final verd = (verdict ?? '').trim();
  if (verd.isNotEmpty) return verd;
  return v;
}
