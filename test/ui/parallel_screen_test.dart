// M4-01, M4-02, M4-03: ParallelScreen, exercised entirely against a Fake
// TranslationService — no test or gate step ever calls the live API.Bible
// service (docs/MILESTONES.md M4-04).
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapestry/data/local_store.dart';
import 'package:tapestry/domain/book_index.dart';
import 'package:tapestry/domain/verse_id.dart';
import 'package:tapestry/domain/verse_status.dart';
import 'package:tapestry/ui/parallel_screen.dart';

import '../support/fake_translation_service.dart';
import '../support/test_store.dart';

void main() {
  testWidgets('M4-01: parallel view aligns BSB/NIV verse-by-verse for Romans 8', (tester) async {
    final store = await openTestStore();
    addTearDown(store.close);

    final romans = booksByOrder.values.firstWhere((b) => b.name == 'Romans');
    final bsbVerses = await store.versesForChapter(romans.order, 8);
    expect(bsbVerses, isNotEmpty);

    final fakeNiv = {
      for (final v in bsbVerses) v.id: VersePresent('NIV text for verse ${v.verse}'),
    };
    final service = FakeTranslationService(
      bibleIds: const {'NIV': 'fake-niv-id'},
      versesByBibleId: {'fake-niv-id': fakeNiv},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ParallelScreen(
          store: store,
          translationService: service,
          book: romans.order,
          chapter: 8,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Every verse's BSB text and its aligned NIV text are both visible,
    // proving verse-by-verse alignment (not just "some NIV text somewhere").
    // Romans 8 has 39 verses — more than fit in the test viewport at once,
    // and the underlying ListView.builder only mounts nearby items, so each
    // must be scrolled into view first (same pattern as the lazy book/
    // chapter grids in reader_navigation_test.dart).
    for (final v in bsbVerses) {
      final bsbFinder = find.textContaining(v.content);
      // A small delta and a high iteration cap: with ~300px steps, a
      // single drag could jump clean over a short verse's mount window
      // between visibility checks (items are only built near the
      // viewport), silently skipping past it — reproduced with Romans
      // 8:6, which never registered as visible even after scrolling to
      // the end of the list.
      await tester.scrollUntilVisible(
        bsbFinder,
        60,
        scrollable: find.byType(Scrollable),
        maxScrolls: 200,
      );
      expect(bsbFinder, findsOneWidget, reason: 'BSB verse ${v.verse}');
      expect(
        find.textContaining('NIV text for verse ${v.verse}'),
        findsOneWidget,
        reason: 'NIV verse ${v.verse}',
      );
    }
  });

  testWidgets(
    'M4-02: a footnoted verse renders a marker at the correct position; tapping reveals the note',
    (tester) async {
      // Real BSB (like most modern translations) omits Matthew 17:21
      // entirely — there's no row to test "present in BSB, absent in NIV"
      // against. Seeding a tiny synthetic store lets this test exercise the
      // exact scenario the criterion names, using the same schema/query
      // path (LocalStore.versesForChapter) as real data.
      //
      // A real temp file, not NativeDatabase.memory() — drift warned of
      // state bleeding between separate in-memory databases opened in the
      // same test process (matches the file-based pattern test_store.dart
      // already uses for its own reasons).
      //
      // No manual CREATE TABLE: a fresh db's default MigrationStrategy
      // already runs drift's own onCreate (m.createAll()), so the schema
      // exists before any statement of ours runs — a second CREATE TABLE
      // collided with it ("table verses already exists").
      final tempDir = Directory.systemTemp.createTempSync('parallel_screen_test');
      final dbFile = File('${tempDir.path}/seed.db');
      final store = LocalStore(NativeDatabase(dbFile));
      final matthew = booksByOrder.values.firstWhere((b) => b.name == 'Matthew');
      for (final verse in [19, 20, 21, 22]) {
        final id = encodeVerseId(book: matthew.order, chapter: 17, verse: verse);
        await store.customStatement(
          'INSERT INTO verses (id, book, chapter, verse, text, passage_id) VALUES '
          '($id, ${matthew.order}, 17, $verse, "BSB verse $verse text", 0)',
        );
      }
      addTearDown(store.close);

      final verse21Id = encodeVerseId(book: matthew.order, chapter: 17, verse: 21);
      // Verses 19/20/22 are explicitly VersePresent so the footnote marker
      // (FakeTranslationService defaults any unmapped verse to footnoted)
      // appears only for verse 21 — isolating the scenario this test names.
      final service = FakeTranslationService(
        bibleIds: const {'NIV': 'fake-niv-id'},
        versesByBibleId: {
          'fake-niv-id': {
            for (final verse in [19, 20, 22])
              encodeVerseId(book: matthew.order, chapter: 17, verse: verse):
                  VersePresent('NIV verse $verse text'),
            verse21Id: const VerseFootnoted(
              'Early manuscripts do not include this verse (cf. Mark 9:29).',
            ),
          },
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ParallelScreen(
            store: store,
            translationService: service,
            book: matthew.order,
            chapter: 17,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Before tapping: the footnote marker shows, not the manuscript note,
      // and verse 21's BSB text is still shown (never a silent gap).
      expect(find.textContaining('BSB verse 21 text'), findsOneWidget);
      expect(find.textContaining('[footnote]'), findsOneWidget);
      expect(find.textContaining('Early manuscripts'), findsNothing);

      await tester.tap(find.textContaining('[footnote]'));
      await tester.pumpAndSettle();

      // After tapping: the note is revealed.
      expect(find.textContaining('Early manuscripts do not include this verse'), findsOneWidget);
    },
  );

  testWidgets('M4-03: with no API key configured, runs in BSB-only mode — no crash, no blank pane', (
    tester,
  ) async {
    final store = await openTestStore();
    addTearDown(store.close);

    final genesis = booksByOrder.values.firstWhere((b) => b.name == 'Genesis');

    await tester.pumpWidget(
      MaterialApp(
        home: ParallelScreen(
          store: store,
          translationService: null, // no key configured
          book: genesis.order,
          chapter: 1,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('No API.Bible key is configured'), findsOneWidget);
    expect(find.textContaining('In the beginning God created'), findsOneWidget);
  });

  testWidgets('the NIV/NKJV picker switches which translation is aligned against BSB', (
    tester,
  ) async {
    final store = await openTestStore();
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
        home: ParallelScreen(
          store: store,
          translationService: service,
          book: romans.order,
          chapter: 8,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Defaults to NIV.
    expect(find.text('NIV  NIV text for verse 1'), findsOneWidget);
    expect(find.textContaining('NKJV text for verse 1'), findsNothing);

    await tester.tap(find.text('NKJV'));
    await tester.pumpAndSettle();

    // Switched to NKJV — NIV text is gone, NKJV text is aligned in its place.
    expect(find.text('NKJV  NKJV text for verse 1'), findsOneWidget);
    expect(find.textContaining('NIV text for verse 1'), findsNothing);
  });
}
