import 'package:flutter_test/flutter_test.dart';
import 'package:tapestry/domain/short_reference.dart';
import 'package:tapestry/domain/verse_id.dart';

void main() {
  test('single-chapter passage shows just the chapter', () {
    final label = shortReference(
      book: 23, // Isaiah
      startVerseId: encodeVerseId(book: 23, chapter: 53, verse: 1),
      endVerseId: encodeVerseId(book: 23, chapter: 53, verse: 8),
    );
    expect(label, 'Isaiah 53');
  });

  test('passage spanning multiple chapters shows a chapter range', () {
    final label = shortReference(
      book: 1, // Genesis
      startVerseId: encodeVerseId(book: 1, chapter: 1, verse: 1),
      endVerseId: encodeVerseId(book: 1, chapter: 2, verse: 3),
    );
    expect(label, 'Genesis 1-2');
  });
}
