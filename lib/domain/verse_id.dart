/// Canonical VerseId scheme (see docs/ARCHITECTURE.md): a single integer
/// `BBCCCVVV` — book order (1-66) · chapter · verse — that every translation
/// layer maps onto. Packing keeps ordering and range queries trivial (a whole
/// book or chapter is a contiguous integer range).
int encodeVerseId({required int book, required int chapter, required int verse}) {
  assert(book >= 1 && book <= 66, 'book out of range: $book');
  assert(chapter >= 1 && chapter <= 999, 'chapter out of range: $chapter');
  assert(verse >= 1 && verse <= 999, 'verse out of range: $verse');
  return book * 1000000 + chapter * 1000 + verse;
}

class VerseRef {
  final int book;
  final int chapter;
  final int verse;

  const VerseRef(this.book, this.chapter, this.verse);

  int get id => encodeVerseId(book: book, chapter: chapter, verse: verse);
}

VerseRef decodeVerseId(int id) {
  final book = id ~/ 1000000;
  final remainder = id % 1000000;
  final chapter = remainder ~/ 1000;
  final verse = remainder % 1000;
  return VerseRef(book, chapter, verse);
}
