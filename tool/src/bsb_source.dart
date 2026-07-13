import 'dart:convert';
import 'dart:io';

import 'package:tapestry/domain/book_index.dart';
import 'package:tapestry/domain/passage.dart';
import 'package:tapestry/domain/verse_id.dart';

class VerseRow {
  final int verseId;
  final int book;
  final int chapter;
  final int verse;
  final String text;
  final int passageId;

  const VerseRow({
    required this.verseId,
    required this.book,
    required this.chapter,
    required this.verse,
    required this.text,
    required this.passageId,
  });
}

class ParsedBsb {
  final List<VerseRow> verses;
  final List<Passage> passages;

  const ParsedBsb(this.verses, this.passages);
}

/// Parses a vendored `bible.helloao.org/api/BSB/complete.json` dump into
/// verse rows and BSB-heading-derived passages. Passages never cross book
/// boundaries; within a book, a new heading always starts a new passage. If a
/// book somehow opens with verses before any heading (not the case in the
/// current BSB dump, but not guaranteed forever), the book's own name is used
/// as a fallback heading rather than crashing (Check 5 input-validation floor).
ParsedBsb parseBsb(File file) {
  final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final books = data['books'];
  if (books is! List) {
    throw const FormatException('bsb_complete.json: missing "books" array');
  }

  final verses = <VerseRow>[];
  final passages = <Passage>[];
  var nextPassageId = 1;

  for (final bookJson in books) {
    final bsbId = bookJson['id'] as String?;
    final info = bsbId == null ? null : booksByBsbId[bsbId];
    if (info == null) {
      throw FormatException('bsb_complete.json: unknown book id "$bsbId"');
    }

    int? currentPassageId;
    String? currentHeading;
    int? currentStart;
    int? currentEnd;

    void finalizeCurrent() {
      if (currentPassageId != null && currentStart != null) {
        passages.add(Passage(
          id: currentPassageId!,
          book: info.order,
          startVerseId: currentStart!,
          endVerseId: currentEnd!,
          heading: currentHeading ?? info.name,
        ));
      }
    }

    void startNewPassage(String? heading) {
      finalizeCurrent();
      currentPassageId = nextPassageId++;
      currentHeading = heading;
      currentStart = null;
      currentEnd = null;
    }

    final chapters = bookJson['chapters'] as List? ?? const [];
    for (final chapterWrapper in chapters) {
      final chapter = chapterWrapper['chapter'] as Map<String, dynamic>;
      final chapterNumber = chapter['number'] as int;
      final content = chapter['content'] as List? ?? const [];

      for (final item in content) {
        final type = item['type'] as String?;
        if (type == 'heading') {
          final headingContent = item['content'] as List? ?? const [];
          final heading = headingContent.map((e) => e.toString()).join(' ').trim();
          startNewPassage(heading.isEmpty ? null : heading);
        } else if (type == 'verse') {
          final verseNumber = item['number'] as int?;
          if (verseNumber == null) {
            throw FormatException(
              'bsb_complete.json: verse missing "number" in ${info.bsbId} $chapterNumber',
            );
          }
          currentPassageId ??= () {
            startNewPassage(null);
            return currentPassageId;
          }();
          final text = _extractVerseText(item['content'] as List? ?? const []);
          final id = encodeVerseId(book: info.order, chapter: chapterNumber, verse: verseNumber);
          verses.add(VerseRow(
            verseId: id,
            book: info.order,
            chapter: chapterNumber,
            verse: verseNumber,
            text: text,
            passageId: currentPassageId!,
          ));
          currentStart ??= id;
          currentEnd = id;
        }
        // "line_break" and any other content types carry no verse text or
        // passage-boundary meaning — skipped.
      }
    }
    finalizeCurrent();
  }

  return ParsedBsb(verses, passages);
}

/// Verse `content` arrays mix plain strings with note/poem markers (see
/// tool/data/README.md for a sample). Footnote markers (`{"noteId": n}` with
/// no "text") are dropped; everything else is joined with a single space —
/// pieces are split at the exact point a footnote anchors, not at word
/// boundaries, so naive concatenation would run words together.
String _extractVerseText(List content) {
  final pieces = <String>[];
  for (final piece in content) {
    if (piece is String) {
      pieces.add(piece);
    } else if (piece is Map && piece['text'] is String) {
      pieces.add(piece['text'] as String);
    }
  }
  return pieces.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
}
