// M2-02's "widget test" evidence, run through plain flutter_test (proven
// reliable on this machine) rather than the on-device integration_test
// harness (blocked — see HANDOFF.md). Screenshots for the same scenarios are
// captured separately via a real running build.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapestry/data/local_store.dart';
import 'package:tapestry/domain/book_index.dart';
import 'package:tapestry/main.dart';

import '../support/test_store.dart';

Future<void> _tapAfterScrollingIntoView(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 300, scrollable: find.byType(Scrollable));
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'M2-02: prev/next moves exactly one passage, never skips or repeats, at every boundary',
    (tester) async {
      final store = await openTestStore();
      addTearDown(store.close);

      // Ground truth, read directly from the same store the UI queries.
      final malachi = booksByOrder.values.firstWhere((b) => b.name == 'Malachi');
      final firstMalachi4Verse = await store.passageContainingVerse(
        malachi.order,
        malachi.order * 1000000 + 4 * 1000 + 1,
      );
      final maxId = await store.maxPassageId();
      final sequenceFromMalachi4 = <Passage>[];
      for (var id = firstMalachi4Verse.id; id <= maxId; id++) {
        final p = await store.passageById(id);
        sequenceFromMalachi4.add(p);
        if (p.book != malachi.order) break; // stop one passage into Matthew
      }
      final lastOverall = await store.passageById(maxId);

      await tester.pumpWidget(TapestryApp(store: store, translationService: null));
      await tester.pumpAndSettle();

      // --- Genesis 1 start: no Previous ---
      await _tapAfterScrollingIntoView(tester, find.text('Genesis'));
      await _tapAfterScrollingIntoView(tester, find.widgetWithText(OutlinedButton, '1'));

      final prevButtonAtStart = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Previous'),
      );
      expect(prevButtonAtStart.onPressed, isNull, reason: 'no passage precedes Genesis 1');

      // --- Malachi's last passage -> Next continues into Matthew, no skip ---
      await tester.tap(find.byIcon(Icons.menu_book));
      await tester.pumpAndSettle();
      await _tapAfterScrollingIntoView(tester, find.text('Malachi'));
      await _tapAfterScrollingIntoView(tester, find.widgetWithText(OutlinedButton, '4'));

      expect(find.text(sequenceFromMalachi4.first.heading), findsOneWidget);
      for (final expected in sequenceFromMalachi4.skip(1)) {
        await tester.tap(find.widgetWithText(TextButton, 'Next'));
        await tester.pumpAndSettle();
        expect(
          find.text(expected.heading),
          findsOneWidget,
          reason: 'expected passage ${expected.id} ("${expected.heading}") next in sequence',
        );
      }

      // --- Revelation's last passage: no Next (the true end of the canon) ---
      await tester.tap(find.byIcon(Icons.menu_book));
      await tester.pumpAndSettle();
      await _tapAfterScrollingIntoView(tester, find.text('Revelation'));
      await _tapAfterScrollingIntoView(tester, find.widgetWithText(OutlinedButton, '22'));

      while (find.text(lastOverall.heading).evaluate().isEmpty) {
        await tester.tap(find.widgetWithText(TextButton, 'Next'));
        await tester.pumpAndSettle();
      }
      final nextButtonAtEnd = tester.widget<TextButton>(find.widgetWithText(TextButton, 'Next'));
      expect(nextButtonAtEnd.onPressed, isNull, reason: 'no passage follows the end of Revelation');
    },
  );
}
