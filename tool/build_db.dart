// Tapestry data forge — builds assets/bible.db from vendored BSB text and
// OpenBible.info cross-references. See docs/MILESTONES.md (Milestone 1) and
// docs/ARCHITECTURE.md for the data model this implements.
//
// ignore_for_file: avoid_print — this CLI's job is printing captured stdout
// for the gate's smoke-check evidence (docs/VERIFICATION.md §3).
import 'dart:io';

import 'package:tapestry/domain/book_index.dart';
import 'package:tapestry/domain/verse_id.dart';

import 'src/bsb_source.dart';
import 'src/cross_ref_source.dart';
import 'src/edge_builder.dart';
import 'src/sqlite_writer.dart';

void main(List<String> args) {
  final root = Directory.current.path;
  final bsbFile = File('$root/tool/data/bsb_complete.json');
  final crossRefFile = File('$root/tool/data/cross_references.txt');
  final outputPath = '$root/assets/bible.db';

  if (!bsbFile.existsSync()) {
    stderr.writeln('build_db: missing ${bsbFile.path}');
    exit(1);
  }
  if (!crossRefFile.existsSync()) {
    stderr.writeln('build_db: missing ${crossRefFile.path}');
    exit(1);
  }

  print('Tapestry data forge — building assets/bible.db');

  final bsb = parseBsb(bsbFile);
  print('Parsed BSB: ${kBooks.length} books, ${bsb.verses.length} verses, '
      '${bsb.passages.length} passages');

  final crossRefs = parseCrossReferences(crossRefFile);
  print('Parsed cross-references: ${crossRefs.rows.length} usable rows, '
      '${crossRefs.malformedRowCount} malformed rows rejected');

  final edgeResult = buildEdges(bsb.verses, crossRefs.rows);
  print('Built edges: ${edgeResult.edges.length} passage-level edges '
      '(${edgeResult.unresolvedRowCount} unresolved refs, '
      '${edgeResult.selfEdgeRowCount} self-edges, '
      '${edgeResult.droppedNonPositiveCount} non-positive-weight pairs dropped)');

  Directory('$root/assets').createSync(recursive: true);
  writeDatabase(
    outputPath: outputPath,
    verses: bsb.verses,
    passages: bsb.passages,
    edges: edgeResult.edges,
    meta: {
      'cross_reference_attribution': 'Cross-reference data from OpenBible.info, CC-BY',
      'bsb_source': 'Berean Standard Bible (public domain), via bible.helloao.org',
      'built_at': DateTime.now().toUtc().toIso8601String(),
    },
  );
  print('Wrote $outputPath');

  _runSmokeChecks(bsb, edgeResult);
}

void _runSmokeChecks(ParsedBsb bsb, EdgeBuildResult edgeResult) {
  print('\n--- Smoke checks ---');

  print('Books: ${kBooks.length} (expect 66)');
  print('Verses: ${bsb.verses.length} (expect >= 31000)');

  final john = booksByBsbId['JHN']!;
  final john316Id = encodeVerseId(book: john.order, chapter: 3, verse: 16);
  final john316 = bsb.verses.firstWhere((v) => v.verseId == john316Id);
  final hasExpectedWording =
      john316.text.contains('only begotten') || john316.text.contains('one and only');
  print('John 3:16: "${john316.text}"');
  print('  contains "only begotten" or "one and only": $hasExpectedWording');

  final isaiah = booksByBsbId['ISA']!;
  final isa535Id = encodeVerseId(book: isaiah.order, chapter: 53, verse: 5);
  final isa535 = bsb.verses.firstWhere((v) => v.verseId == isa535Id);
  final isa53Passage = bsb.passages.firstWhere((p) => p.id == isa535.passageId);
  final rangeStart = encodeVerseId(book: isaiah.order, chapter: 52, verse: 13);
  final rangeEnd = encodeVerseId(book: isaiah.order, chapter: 53, verse: 12);
  final withinRange =
      isa53Passage.startVerseId >= rangeStart && isa53Passage.endVerseId <= rangeEnd;
  print('Isaiah 53:5 passage: "${isa53Passage.heading}" '
      '(${_ref(isa53Passage.startVerseId)}-${_ref(isa53Passage.endVerseId)})');
  print('  within Isaiah 52:13-53:12: $withinRange; carries a heading: '
      '${isa53Passage.heading.isNotEmpty}');

  final touchingIsa53 = edgeResult.edges
      .where((e) => e.fromPassageId == isa53Passage.id || e.toPassageId == isa53Passage.id)
      .toList()
    ..sort((a, b) => b.weight.compareTo(a.weight));
  if (touchingIsa53.isEmpty) {
    print('Top-weighted edge from Isaiah 53 passage: NONE FOUND');
  } else {
    final top = touchingIsa53.first;
    final otherId = top.fromPassageId == isa53Passage.id ? top.toPassageId : top.fromPassageId;
    final other = bsb.passages.firstWhere((p) => p.id == otherId);
    final isNewTestament = other.book >= kFirstNewTestamentBookOrder;
    print('Top-weighted edge from Isaiah 53 passage: -> "${other.heading}" '
        '(${_ref(other.startVerseId)}-${_ref(other.endVerseId)}), '
        'weight ${top.weight}');
    print('  points to New Testament passage: $isNewTestament');
  }

  print('No orphan edges: verified during write (validation would have failed otherwise)');
}

String _ref(int verseId) {
  final v = decodeVerseId(verseId);
  final book = booksByOrder[v.book]!;
  return '${book.name} ${v.chapter}:${v.verse}';
}
