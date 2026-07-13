import 'dart:io';

import 'package:tapestry/domain/book_index.dart';
import 'package:tapestry/domain/verse_id.dart';

class CrossRefRow {
  final int fromVerseId;
  final int toVerseId;
  final int votes;

  const CrossRefRow({required this.fromVerseId, required this.toVerseId, required this.votes});
}

class ParsedCrossRefs {
  final List<CrossRefRow> rows;
  final int malformedRowCount;

  const ParsedCrossRefs(this.rows, this.malformedRowCount);
}

/// Parses a vendored OpenBible.info `cross_references.txt` (tab-separated:
/// From Verse, To Verse, Votes; header row carries the CC-BY attribution
/// comment as a 4th field). Malformed rows are untrusted external input
/// (Check 5 floor) — rejected and counted, never allowed to crash the pipeline
/// or silently corrupt the graph.
ParsedCrossRefs parseCrossReferences(File file) {
  final lines = file.readAsLinesSync();
  final rows = <CrossRefRow>[];
  var malformed = 0;

  for (var i = 1; i < lines.length; i++) {
    final line = lines[i];
    if (line.trim().isEmpty) continue;
    final fields = line.split('\t');
    if (fields.length < 3) {
      malformed++;
      continue;
    }
    final fromId = _resolveVerseRefStart(fields[0]);
    final toId = _resolveVerseRefStart(fields[1]);
    final votes = int.tryParse(fields[2].trim());
    if (fromId == null || toId == null || votes == null) {
      malformed++;
      continue;
    }
    rows.add(CrossRefRow(fromVerseId: fromId, toVerseId: toId, votes: votes));
  }

  return ParsedCrossRefs(rows, malformed);
}

/// A verse-ref field is either `Book.Chapter.Verse` or a same-book range
/// `Book.Chapter.Verse-Book.Chapter.Verse`.
// forge-debt (low): ranges resolve to their start verse's passage only,
// rather than every passage the range touches. Ranges rarely cross a BSB
// passage boundary, so this only affects which single passage a handful of
// edges attach to — never whether a reference resolves at all — but it is a
// deliberate simplification worth revisiting if edge weights ever look off
// for passages with unusually long cross-reference ranges.
int? _resolveVerseRefStart(String field) {
  final dashIndex = field.indexOf('-');
  final firstRef = dashIndex == -1 ? field : field.substring(0, dashIndex);
  final parts = firstRef.split('.');
  if (parts.length != 3) return null;

  final book = booksByCrossRefAbbrev[parts[0]];
  final chapter = int.tryParse(parts[1]);
  final verse = int.tryParse(parts[2]);
  if (book == null || chapter == null || verse == null) return null;
  if (chapter < 1 || chapter > 999 || verse < 1 || verse > 999) return null;

  return encodeVerseId(book: book.order, chapter: chapter, verse: verse);
}
