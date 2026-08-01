// Widget-level smoke test for pieces that render without hitting the
// network or a real clock.
//
// The default Flutter template shipped here tested a counter demo that was
// never part of this app (`find.byIcon(Icons.add)` and text '0'/'1'), so it
// always failed and nobody noticed. Pumping the real `MyApp` isn't safe in
// CI either — `DashboardScreen.initState` calls `fetchStockData` and starts
// live timers immediately, so it needs a mocked http client before it can be
// pumped without hanging or hitting the network. Until that mock exists,
// this file sticks to widgets that render standalone.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/design/logo.dart';
import 'package:flutter_application_1/design/primitives.dart';
import 'package:flutter_application_1/design/tokens.dart';

void main() {
  testWidgets('Logo renders with a Finova semantic label', (tester) async {
    // bySemanticsLabel only sees anything once a semantics tree exists;
    // outside a real app SemanticsBinding.ensureSemantics() was never
    // called, so the tree has to be switched on for this test explicitly.
    // Disposed at the end of the body rather than via addTearDown: the
    // framework's "no dangling SemanticsHandle" check runs before
    // addTearDown callbacks fire, so that ordering trips it.
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Logo())),
    );

    // The mark's own "Finova" label and the wordmark Text's "FINOVA" merge
    // into one semantics node (Flutter folds adjacent text runs together),
    // so this matches on substring rather than an exact "Finova".
    expect(find.bySemanticsLabel(RegExp('Finova')), findsOneWidget);

    handle.dispose();
  });

  testWidgets('FScheme.dark is used when no FTheme ancestor is present', (
    tester,
  ) async {
    // FTheme.of falls back to FScheme.dark rather than throwing, so screens
    // reached without the app's root theme (e.g. in isolated widget tests)
    // still render instead of crashing. This guards that fallback.
    late FScheme resolved;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            resolved = context.c;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(resolved, FScheme.dark);
  });

  testWidgets('FChip shows its label and can be tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FChip(
            label: 'AAPL',
            tone: FTone.green,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('AAPL'), findsOneWidget);
    await tester.tap(find.text('AAPL'));
    await tester.pump();
    expect(tapped, isTrue);
  });
}
