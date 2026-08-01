// Unit tests for lib/logic/formatting.dart — the pure helpers pulled out of
// main.dart specifically so they could be tested without a widget tree, a
// real clock, or a running server.
//
// These exist because a scripted refactor earlier today (removing dead admin
// code from main.dart) silently miscounted braces and truncated the file —
// `flutter analyze` caught the syntax break, but nothing would have caught a
// *logic* mistake in, say, the bidi percentage sign or the score thresholds.
// That's the gap this file is for.

import 'package:flutter_application_1/logic/formatting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('pctString', () {
    test('prefixes positive values with + and an LRM mark', () {
      expect(pctString(1.32), '‎+1.32%');
    });

    test('keeps the minus sign on negative values', () {
      expect(pctString(-7.3), '‎-7.30%');
    });

    test('treats zero as non-negative', () {
      expect(pctString(0), '‎+0.00%');
    });

    test('respects the digits parameter', () {
      expect(pctString(2.9, digits: 1), '‎+2.9%');
    });
  });

  group('initialsOf', () {
    test('blank name falls back to the brand letter', () {
      expect(initialsOf(''), 'F');
      expect(initialsOf('   '), 'F');
    });

    test('single Hebrew word keeps only its first letter', () {
      // Hebrew has no case, so a second arbitrary letter would not read as
      // an abbreviation the way "ID" does for a Latin name.
      expect(initialsOf('עידן'), 'ע');
    });

    test('single Latin word takes the first two letters, upper-cased', () {
      expect(initialsOf('idan'), 'ID');
    });

    test('single Latin letter does not crash on substring(0, 2)', () {
      // A lone letter skips the two-letter branch entirely (nothing to
      // slice), so it comes back exactly as typed rather than upper-cased —
      // that's the existing behaviour, not something this test changes.
      expect(initialsOf('i'), 'i');
    });

    test('two or more words take one letter from each of the first two', () {
      expect(initialsOf('Idan Amrani'), 'IA');
      expect(initialsOf('Idan Ben Amrani'), 'IB');
    });
  });

  group('recommendationTone', () {
    test('bullish verdict wins regardless of recommendation casing', () {
      expect(recommendationTone('BUY', 'Bullish'), RecTone.bullish);
    });

    test('a bare "buy" recommendation is enough without a verdict', () {
      expect(recommendationTone('Buy', 'Neutral'), RecTone.bullish);
    });

    test('bearish/sell maps to bearish', () {
      expect(recommendationTone('Sell', 'Bearish'), RecTone.bearish);
    });

    test('anything else is neutral', () {
      expect(recommendationTone('Hold', 'Neutral'), RecTone.neutral);
      expect(recommendationTone('', ''), RecTone.neutral);
    });
  });

  group('scoreBand', () {
    test('boundary at 68 is inclusive on the high side', () {
      expect(scoreBand(68), ScoreBand.high);
      expect(scoreBand(67), ScoreBand.mid);
    });

    test('boundary at 50 is inclusive on the mid side', () {
      expect(scoreBand(50), ScoreBand.mid);
      expect(scoreBand(49), ScoreBand.low);
    });

    test('extremes', () {
      expect(scoreBand(100), ScoreBand.high);
      expect(scoreBand(0), ScoreBand.low);
    });
  });

  group('freshnessSince', () {
    final now = DateTime(2026, 8, 1, 12, 0, 0);

    test('null fetch time means nothing to report', () {
      expect(freshnessSince(null, now), isNull);
    });

    test('under a minute reads as just now', () {
      final f = freshnessSince(now.subtract(const Duration(seconds: 30)), now);
      expect(f!.kind, FreshnessKind.justNow);
    });

    test('under an hour reports minutes', () {
      final f = freshnessSince(now.subtract(const Duration(minutes: 42)), now);
      expect(f!.kind, FreshnessKind.minutes);
      expect(f.n, 42);
    });

    test('an hour or more reports whole hours, rounded down', () {
      final f = freshnessSince(now.subtract(const Duration(minutes: 125)), now);
      expect(f!.kind, FreshnessKind.hours);
      expect(f.n, 2);
    });
  });

  group('shortFactorDetail', () {
    test('prefers a short value over the verdict', () {
      expect(
        shortFactorDetail(value: '63.0%', verdict: 'A long descriptive verdict'),
        '63.0%',
      );
    });

    test('falls back to the verdict when the value is too long', () {
      expect(
        shortFactorDetail(value: 'a value well past twelve chars', verdict: 'short'),
        'short',
      );
    });

    test('falls back to the verdict when the value is empty', () {
      expect(shortFactorDetail(value: '', verdict: 'the verdict'), 'the verdict');
    });

    test('empty value and empty verdict yields empty', () {
      expect(shortFactorDetail(value: '', verdict: ''), '');
    });

    test('null inputs are treated as empty, not a crash', () {
      expect(shortFactorDetail(), '');
    });
  });
}
