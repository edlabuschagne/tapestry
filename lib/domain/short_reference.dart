import 'book_index.dart';
import 'verse_id.dart';

/// A compact scripture reference for a constellation node label — book name
/// + chapter, or a chapter range if the passage spans more than one chapter
/// (e.g. "Isaiah 53" or "Isaiah 52-53").
///
/// Takes raw fields rather than a `Passage` object because two distinct
/// `Passage` types exist in this codebase: the pipeline's own
/// (`lib/domain/passage.dart`, used only by tool/build_db.dart while
/// building assets/bible.db) and drift's auto-generated one (from the
/// `Passages` table, used everywhere at app runtime). This function works
/// with either.
String shortReference({required int book, required int startVerseId, required int endVerseId}) {
  final bookInfo = booksByOrder[book]!;
  final startChapter = decodeVerseId(startVerseId).chapter;
  final endChapter = decodeVerseId(endVerseId).chapter;

  if (startChapter == endChapter) {
    return '${bookInfo.name} $startChapter';
  }
  return '${bookInfo.name} $startChapter-$endChapter';
}
