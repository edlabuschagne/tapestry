import 'package:flutter_test/flutter_test.dart';
import 'package:tapestry/domain/verse_id.dart';

void main() {
  test('encodes book/chapter/verse into BBCCCVVV', () {
    expect(encodeVerseId(book: 1, chapter: 1, verse: 1), 1001001);
    expect(encodeVerseId(book: 66, chapter: 22, verse: 21), 66022021);
    expect(encodeVerseId(book: 19, chapter: 119, verse: 176), 19119176);
  });

  test('decodes back to the original book/chapter/verse', () {
    for (final ref in [
      const VerseRef(1, 1, 1),
      const VerseRef(66, 22, 21),
      const VerseRef(19, 119, 176),
      const VerseRef(43, 3, 16),
    ]) {
      final decoded = decodeVerseId(ref.id);
      expect(decoded.book, ref.book);
      expect(decoded.chapter, ref.chapter);
      expect(decoded.verse, ref.verse);
    }
  });

  test('ordering matches canonical reading order', () {
    final genesis11 = encodeVerseId(book: 1, chapter: 1, verse: 1);
    final genesis12 = encodeVerseId(book: 1, chapter: 1, verse: 2);
    final genesis21 = encodeVerseId(book: 1, chapter: 2, verse: 1);
    final exodus11 = encodeVerseId(book: 2, chapter: 1, verse: 1);
    expect(genesis11 < genesis12, isTrue);
    expect(genesis12 < genesis21, isTrue);
    expect(genesis21 < exodus11, isTrue);
  });
}
