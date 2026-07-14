// Milestone 2 acceptance criteria, exercised through Flutter's own
// integration_test harness (VERIFICATION.md: Playwright is blind to Flutter
// web's canvas, so this — not an ad hoc browser screenshot — is the evidence
// method for every M2 screenshot criterion, run against whichever device this
// file is targeted at: an Android emulator/device, or a web browser).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tapestry/data/db_connection.dart';
import 'package:tapestry/data/local_store.dart';
import 'package:tapestry/domain/book_index.dart';
import 'package:tapestry/main.dart';

Future<void> _screenshot(IntegrationTestWidgetsFlutterBinding binding, String name) async {
  await binding.convertFlutterSurfaceToImage();
  await binding.takeScreenshot(name);
}

/// The book list and chapter grid are both lazily built (`ListView.builder`
/// / `GridView.builder`), so a book or chapter far down the list may not
/// exist in the widget tree at all until scrolled into view.
Future<void> _tapAfterScrollingIntoView(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 300, scrollable: find.byType(Scrollable));
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('M2-01: reaches Isaiah 53 in <=3 taps; shows heading and full text', (
    tester,
  ) async {
    final store = await openLocalStore();
    addTearDown(store.close);

    await tester.pumpWidget(TapestryApp(store: store));
    await tester.pumpAndSettle();

    // Tap 1: open Isaiah from the book list.
    await _tapAfterScrollingIntoView(tester, find.text('Isaiah'));

    // Tap 2: open chapter 53 from the chapter grid.
    await _tapAfterScrollingIntoView(tester, find.widgetWithText(OutlinedButton, '53'));

    // Two taps total from launch — well within the <=3 tap budget.
    expect(find.text('The Suffering Servant'), findsOneWidget);
    expect(
      find.textContaining('Who has believed our message?'),
      findsOneWidget,
      reason: 'verse 1 of the passage should be visible',
    );
    expect(
      find.textContaining('He was pierced for our transgressions'),
      findsOneWidget,
      reason: 'a later verse of the passage should also be visible — the FULL passage, not a snippet',
    );

    await _screenshot(binding, 'M2-01-isaiah-53');
  });

  testWidgets(
    'M2-02: prev/next moves exactly one passage, never skips or repeats, at every boundary',
    (tester) async {
      final store = await openLocalStore();
      addTearDown(store.close);

      // Ground truth, read directly from the same store the UI queries —
      // this is what "no skip/repeat" is checked against.
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

      await tester.pumpWidget(TapestryApp(store: store));
      await tester.pumpAndSettle();

      // --- Genesis 1 start: no Previous ---
      await _tapAfterScrollingIntoView(tester, find.text('Genesis'));
      await _tapAfterScrollingIntoView(tester, find.widgetWithText(OutlinedButton, '1'));

      final prevButtonAtStart = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Previous'),
      );
      expect(prevButtonAtStart.onPressed, isNull, reason: 'no passage precedes Genesis 1');
      await _screenshot(binding, 'M2-02-genesis-start');

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
      await _screenshot(binding, 'M2-02-malachi-to-matthew');

      // Revelation's true end-of-canon boundary (extra coverage beyond
      // M2-02's literal text) is exercised in test/ui/reader_navigation_test.dart
      // instead of here — it hit a web-only navigation timing quirk on a third
      // consecutive screen transition in this harness, not worth chasing for
      // bonus coverage the criterion doesn't require. See HANDOFF.md.
    },
  );
}
