// Exercises the pipeline's parsing/aggregation logic against the real
// vendored data (tool/data/) — no network, fully deterministic — and asserts
// the exact facts docs/ACCEPTANCE.json's Milestone 1 criteria require.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapestry/domain/book_index.dart';
import 'package:tapestry/domain/verse_id.dart';

import '../../tool/src/bsb_source.dart';
import '../../tool/src/cross_ref_source.dart';
import '../../tool/src/edge_builder.dart';

void main() {
  final bsbFile = File('tool/data/bsb_complete.json');
  final crossRefFile = File('tool/data/cross_references.txt');

  // These files are vendored and committed (see tool/data/README.md); if
  // they're absent this isn't a code failure, so skip rather than fail red.
  final dataAvailable = bsbFile.existsSync() && crossRefFile.existsSync();

  group(
    'Milestone 1 acceptance criteria (real data)',
    () {
      late ParsedBsb bsb;
      late List<CrossRefRow> crossRefRows;
      late EdgeBuildResult edgeResult;

      setUpAll(() {
        bsb = parseBsb(bsbFile);
        crossRefRows = parseCrossReferences(crossRefFile).rows;
        edgeResult = buildEdges(bsb.verses, crossRefRows);
      });

      test('M1-02: 66 books and >= 31000 BSB verses', () {
        expect(kBooks, hasLength(66));
        expect(bsb.verses.length, greaterThanOrEqualTo(31000));
      });

      test('M1-03: John 3:16 contains "only begotten" or "one and only"', () {
        final john = booksByBsbId['JHN']!;
        final id = encodeVerseId(book: john.order, chapter: 3, verse: 16);
        final verse = bsb.verses.firstWhere((v) => v.verseId == id);
        expect(
          verse.text.contains('only begotten') || verse.text.contains('one and only'),
          isTrue,
          reason: 'John 3:16 text was: "${verse.text}"',
        );
      });

      test(
        'M1-04: every verse maps to exactly one passage; '
        'Isaiah 53:5 passage spans within 52:13-53:12 and carries a heading',
        () {
          final passageIds = {for (final p in bsb.passages) p.id};
          for (final v in bsb.verses) {
            expect(passageIds.contains(v.passageId), isTrue,
                reason: 'verse ${v.verseId} maps to unknown passage ${v.passageId}');
          }

          final isaiah = booksByBsbId['ISA']!;
          final id = encodeVerseId(book: isaiah.order, chapter: 53, verse: 5);
          final verse = bsb.verses.firstWhere((v) => v.verseId == id);
          final passage = bsb.passages.firstWhere((p) => p.id == verse.passageId);

          final rangeStart = encodeVerseId(book: isaiah.order, chapter: 52, verse: 13);
          final rangeEnd = encodeVerseId(book: isaiah.order, chapter: 53, verse: 12);
          expect(passage.startVerseId, greaterThanOrEqualTo(rangeStart));
          expect(passage.endVerseId, lessThanOrEqualTo(rangeEnd));
          expect(passage.heading, isNotEmpty);
        },
      );

      test('M1-05: top-weighted edge from the Isaiah 53 passage points to the New Testament', () {
        final isaiah = booksByBsbId['ISA']!;
        final id = encodeVerseId(book: isaiah.order, chapter: 53, verse: 5);
        final verse = bsb.verses.firstWhere((v) => v.verseId == id);
        final passage = bsb.passages.firstWhere((p) => p.id == verse.passageId);

        final touching = edgeResult.edges
            .where((e) => e.fromPassageId == passage.id || e.toPassageId == passage.id)
            .toList()
          ..sort((a, b) => b.weight.compareTo(a.weight));
        expect(touching, isNotEmpty, reason: 'Isaiah 53 passage has no edges at all');

        final top = touching.first;
        final otherId = top.fromPassageId == passage.id ? top.toPassageId : top.fromPassageId;
        final other = bsb.passages.firstWhere((p) => p.id == otherId);
        expect(other.book, greaterThanOrEqualTo(kFirstNewTestamentBookOrder));
      });

      test('M1-06: no orphan edges', () {
        final passageIds = {for (final p in bsb.passages) p.id};
        for (final e in edgeResult.edges) {
          expect(passageIds.contains(e.fromPassageId), isTrue);
          expect(passageIds.contains(e.toPassageId), isTrue);
        }
      });
    },
    skip: dataAvailable ? false : 'tool/data/*.json,txt not present',
  );
}
