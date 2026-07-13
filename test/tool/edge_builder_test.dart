import 'package:flutter_test/flutter_test.dart';

import '../../tool/src/bsb_source.dart';
import '../../tool/src/cross_ref_source.dart';
import '../../tool/src/edge_builder.dart';

VerseRow _verse(int verseId, int passageId) => VerseRow(
      verseId: verseId,
      book: 1,
      chapter: 1,
      verse: 1,
      text: 'placeholder',
      passageId: passageId,
    );

void main() {
  group('buildEdges', () {
    test('aggregates votes between two passages, order-independent', () {
      final verses = [_verse(100, 1), _verse(200, 2)];
      final refs = [
        const CrossRefRow(fromVerseId: 100, toVerseId: 200, votes: 5),
        const CrossRefRow(fromVerseId: 200, toVerseId: 100, votes: 3),
      ];
      final result = buildEdges(verses, refs);

      expect(result.edges, hasLength(1));
      expect(result.edges.single.weight, 8);
      expect({result.edges.single.fromPassageId, result.edges.single.toPassageId}, {1, 2});
    });

    test('drops self-edges (both ends resolve to the same passage)', () {
      final verses = [_verse(100, 1), _verse(101, 1)];
      final refs = [const CrossRefRow(fromVerseId: 100, toVerseId: 101, votes: 10)];
      final result = buildEdges(verses, refs);

      expect(result.edges, isEmpty);
      expect(result.selfEdgeRowCount, 1);
    });

    test('drops edges whose net weight is non-positive', () {
      final verses = [_verse(100, 1), _verse(200, 2)];
      final refs = [
        const CrossRefRow(fromVerseId: 100, toVerseId: 200, votes: 3),
        const CrossRefRow(fromVerseId: 100, toVerseId: 200, votes: -5),
      ];
      final result = buildEdges(verses, refs);

      expect(result.edges, isEmpty);
      expect(result.droppedNonPositiveCount, 1);
    });

    test('counts refs that resolve to no known verse as unresolved', () {
      final verses = [_verse(100, 1)];
      final refs = [const CrossRefRow(fromVerseId: 100, toVerseId: 999999, votes: 1)];
      final result = buildEdges(verses, refs);

      expect(result.edges, isEmpty);
      expect(result.unresolvedRowCount, 1);
    });

    test('no orphan edges: every edge endpoint is a passage id seen in verses', () {
      final verses = [_verse(100, 1), _verse(200, 2), _verse(300, 3)];
      final refs = [
        const CrossRefRow(fromVerseId: 100, toVerseId: 200, votes: 4),
        const CrossRefRow(fromVerseId: 200, toVerseId: 300, votes: 2),
      ];
      final result = buildEdges(verses, refs);

      final knownPassageIds = verses.map((v) => v.passageId).toSet();
      for (final e in result.edges) {
        expect(knownPassageIds.contains(e.fromPassageId), isTrue);
        expect(knownPassageIds.contains(e.toPassageId), isTrue);
      }
    });
  });
}
