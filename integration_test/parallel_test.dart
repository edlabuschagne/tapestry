// Milestone 4 acceptance criteria, exercised through Flutter's own
// integration_test harness (see integration_test/app_test.dart's header for
// why this is the evidence method, not an ad hoc browser screenshot).
//
// Uses FakeTranslationService throughout — no test or gate step ever calls
// the live API.Bible service (docs/MILESTONES.md M4-04).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tapestry/data/db_connection.dart';
import 'package:tapestry/domain/book_index.dart';
import 'package:tapestry/domain/verse_id.dart';
import 'package:tapestry/domain/verse_status.dart';
import 'package:tapestry/ui/parallel_screen.dart';

import 'support/fake_translation_service.dart';

Future<void> _screenshot(IntegrationTestWidgetsFlutterBinding binding, String name) async {
  await binding.convertFlutterSurfaceToImage();
  await binding.takeScreenshot(name);
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('M4-01: parallel view aligns BSB/NIV verse-by-verse for Romans 8', (tester) async {
    final store = await openLocalStore();
    addTearDown(store.close);

    final romans = booksByOrder.values.firstWhere((b) => b.name == 'Romans');
    final bsbVerses = await store.versesForChapter(romans.order, 8);
    final service = FakeTranslationService(
      bibleIds: const {'NIV': 'fake-niv-id'},
      versesByBibleId: {
        'fake-niv-id': {
          for (final v in bsbVerses) v.id: VersePresent('NIV text for verse ${v.verse}'),
        },
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ParallelScreen(store: store, translationService: service, book: romans.order, chapter: 8),
      ),
    );
    await tester.pumpAndSettle();

    // Exact match, not textContaining: "verse 1" is itself a substring of
    // "verse 10"/"verse 19", so a containing-match is ambiguous here.
    expect(find.textContaining(bsbVerses.first.content), findsOneWidget);
    expect(find.text('NIV  NIV text for verse ${bsbVerses.first.verse}'), findsOneWidget);
    await _screenshot(binding, 'M4-01-romans-8-parallel');
  });

  testWidgets(
    'M4-02: a footnoted verse renders a marker at the correct position; tapping reveals the note',
    (tester) async {
      final store = await openLocalStore();
      addTearDown(store.close);

      // Real BSB (like most modern translations) omits Matthew 17:21
      // entirely — there's no row there to test "present in BSB, absent in
      // NIV" against. Seed just that one missing row through the store's
      // own (cross-platform) executor — dart:io/NativeDatabase, used by the
      // equivalent flutter_test seed in test/ui/parallel_screen_test.dart,
      // isn't available when this target compiles for web.
      final matthew = booksByOrder.values.firstWhere((b) => b.name == 'Matthew');
      final verse21Id = encodeVerseId(book: matthew.order, chapter: 17, verse: 21);
      // Single-quoted string literal: the web/WASM sqlite engine is strict
      // SQL and treats a double-quoted literal as an (invalid) identifier
      // reference, unlike native sqlite3's more permissive legacy behavior.
      await store.customStatement(
        'INSERT INTO verses (id, book, chapter, verse, text, passage_id) VALUES '
        "($verse21Id, ${matthew.order}, 17, 21, 'For the Son of Man came to save that which was lost.', 0)",
      );
      final bsbVerses = await store.versesForChapter(matthew.order, 17);
      final service = FakeTranslationService(
        bibleIds: const {'NIV': 'fake-niv-id'},
        versesByBibleId: {
          'fake-niv-id': {
            for (final v in bsbVerses)
              v.id: v.id == verse21Id
                  ? const VerseFootnoted('Early manuscripts do not include this verse (cf. Mark 9:29).')
                  : VersePresent('NIV text for verse ${v.verse}'),
          },
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ParallelScreen(store: store, translationService: service, book: matthew.order, chapter: 17),
        ),
      );
      await tester.pumpAndSettle();

      final footnoteFinder = find.textContaining('[footnote]');
      await tester.scrollUntilVisible(
        footnoteFinder,
        60,
        scrollable: find.byType(Scrollable),
        maxScrolls: 200,
      );
      expect(footnoteFinder, findsOneWidget);
      expect(find.textContaining('Early manuscripts'), findsNothing);
      await _screenshot(binding, 'M4-02-footnote-marker');

      // Extra settle: on web, layout from the incremental scroll above can
      // still be catching up to the browser's real render pipeline when
      // scrollUntilVisible returns, which was enough to make the tap below
      // miss its target (reproduced: dialog never opened).
      await tester.pumpAndSettle();
      await tester.tap(footnoteFinder);
      await tester.pumpAndSettle();

      expect(find.textContaining('Early manuscripts do not include this verse'), findsOneWidget);
      await _screenshot(binding, 'M4-02-footnote-revealed');
    },
  );

  testWidgets('M4-03: with no API key configured, runs in BSB-only mode — no crash, no blank pane', (
    tester,
  ) async {
    final store = await openLocalStore();
    addTearDown(store.close);

    final genesis = booksByOrder.values.firstWhere((b) => b.name == 'Genesis');

    await tester.pumpWidget(
      MaterialApp(
        home: ParallelScreen(store: store, translationService: null, book: genesis.order, chapter: 1),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('No API.Bible key is configured'), findsOneWidget);
    expect(find.textContaining('In the beginning God created'), findsOneWidget);
    await _screenshot(binding, 'M4-03-no-key-bsb-only');
  });

  testWidgets('the NIV/NKJV picker switches which translation is aligned against BSB', (
    tester,
  ) async {
    final store = await openLocalStore();
    addTearDown(store.close);

    final romans = booksByOrder.values.firstWhere((b) => b.name == 'Romans');
    final bsbVerses = await store.versesForChapter(romans.order, 8);
    final service = FakeTranslationService(
      bibleIds: const {'NIV': 'fake-niv-id', 'NKJV': 'fake-nkjv-id'},
      versesByBibleId: {
        'fake-niv-id': {
          for (final v in bsbVerses) v.id: VersePresent('NIV text for verse ${v.verse}'),
        },
        'fake-nkjv-id': {
          for (final v in bsbVerses) v.id: VersePresent('NKJV text for verse ${v.verse}'),
        },
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ParallelScreen(store: store, translationService: service, book: romans.order, chapter: 8),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('NIV  NIV text for verse ${bsbVerses.first.verse}'), findsOneWidget);
    await _screenshot(binding, 'M4-06-niv-selected');

    await tester.tap(find.text('NKJV'));
    await tester.pumpAndSettle();

    expect(find.text('NKJV  NKJV text for verse ${bsbVerses.first.verse}'), findsOneWidget);
    expect(find.textContaining('NIV text for verse ${bsbVerses.first.verse}'), findsNothing);
    await _screenshot(binding, 'M4-06-nkjv-selected');
  });
}
