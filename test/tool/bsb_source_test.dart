import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapestry/domain/verse_id.dart';

import '../../tool/src/bsb_source.dart';

void main() {
  late Directory tempDir;

  setUp(() => tempDir = Directory.systemTemp.createTempSync('bsb_source_test'));
  tearDown(() => tempDir.deleteSync(recursive: true));

  File writeFixture(Map<String, dynamic> json) {
    final file = File('${tempDir.path}/bsb.json');
    file.writeAsStringSync(jsonEncode(json));
    return file;
  }

  test('a heading starts a new passage; verses accumulate until the next one', () {
    final file = writeFixture({
      'books': [
        {
          'id': 'GEN',
          'chapters': [
            {
              'chapter': {
                'number': 1,
                'content': [
                  {
                    'type': 'heading',
                    'content': ['The Creation'],
                  },
                  {
                    'type': 'verse',
                    'number': 1,
                    'content': ['In the beginning God created the heavens and the earth.'],
                  },
                  {
                    'type': 'verse',
                    'number': 2,
                    'content': ['Now the earth was formless and void.'],
                  },
                  {
                    'type': 'heading',
                    'content': ['The First Day'],
                  },
                  {
                    'type': 'verse',
                    'number': 3,
                    'content': ['And God said, let there be light.'],
                  },
                ],
              },
            },
          ],
        },
      ],
    });

    final parsed = parseBsb(file);

    expect(parsed.verses, hasLength(3));
    expect(parsed.passages, hasLength(2));
    expect(parsed.passages[0].heading, 'The Creation');
    expect(parsed.passages[1].heading, 'The First Day');

    final v1 = parsed.verses[0];
    final v2 = parsed.verses[1];
    final v3 = parsed.verses[2];
    expect(v1.passageId, parsed.passages[0].id);
    expect(v2.passageId, parsed.passages[0].id);
    expect(v3.passageId, parsed.passages[1].id);
  });

  test('a heading at the start of a later chapter continues correctly', () {
    final file = writeFixture({
      'books': [
        {
          'id': 'GEN',
          'chapters': [
            {
              'chapter': {
                'number': 1,
                'content': [
                  {
                    'type': 'heading',
                    'content': ['Chapter One Heading'],
                  },
                  {
                    'type': 'verse',
                    'number': 1,
                    'content': ['verse one'],
                  },
                ],
              },
            },
            {
              'chapter': {
                'number': 2,
                'content': [
                  {
                    'type': 'verse',
                    'number': 1,
                    'content': ['still in chapter one heading'],
                  },
                  {
                    'type': 'heading',
                    'content': ['Chapter Two Heading'],
                  },
                  {
                    'type': 'verse',
                    'number': 2,
                    'content': ['a new passage now'],
                  },
                ],
              },
            },
          ],
        },
      ],
    });

    final parsed = parseBsb(file);
    expect(parsed.passages, hasLength(2));
    // The first passage spans across the chapter 1/2 boundary, ending at 2:1.
    expect(parsed.passages[0].endVerseId, encodeVerseId(book: 1, chapter: 2, verse: 1));
    expect(parsed.passages[1].startVerseId, encodeVerseId(book: 1, chapter: 2, verse: 2));
  });

  test('footnote markers are dropped; text pieces are joined with a single space', () {
    final file = writeFixture({
      'books': [
        {
          'id': 'JHN',
          'chapters': [
            {
              'chapter': {
                'number': 3,
                'content': [
                  {
                    'type': 'heading',
                    'content': ['Test'],
                  },
                  {
                    'type': 'verse',
                    'number': 16,
                    'content': [
                      'For God so loved the world that He gave His one and only',
                      {'noteId': 17},
                      'Son, that everyone who believes in Him shall not perish but have eternal life.',
                    ],
                  },
                ],
              },
            },
          ],
        },
      ],
    });

    final parsed = parseBsb(file);
    expect(
      parsed.verses.single.text,
      'For God so loved the world that He gave His one and only '
      'Son, that everyone who believes in Him shall not perish but have eternal life.',
    );
  });

  test('poem-marked text objects are extracted correctly', () {
    final file = writeFixture({
      'books': [
        {
          'id': 'ISA',
          'chapters': [
            {
              'chapter': {
                'number': 53,
                'content': [
                  {
                    'type': 'heading',
                    'content': ['The Suffering Servant'],
                  },
                  {
                    'type': 'verse',
                    'number': 1,
                    'content': [
                      {'text': 'Who has believed our message?', 'poem': 1},
                      {'text': 'And to whom has the arm of the LORD been revealed?', 'poem': 2},
                      {'noteId': 186},
                    ],
                  },
                ],
              },
            },
          ],
        },
      ],
    });

    final parsed = parseBsb(file);
    expect(
      parsed.verses.single.text,
      'Who has believed our message? And to whom has the arm of the LORD been revealed?',
    );
  });

  test('a book with no heading before its first verse falls back to the book name', () {
    final file = writeFixture({
      'books': [
        {
          'id': 'GEN',
          'chapters': [
            {
              'chapter': {
                'number': 1,
                'content': [
                  {
                    'type': 'verse',
                    'number': 1,
                    'content': ['no heading precedes this verse'],
                  },
                ],
              },
            },
          ],
        },
      ],
    });

    final parsed = parseBsb(file);
    expect(parsed.passages.single.heading, 'Genesis');
  });

  test('rejects an unknown book id rather than silently skipping it', () {
    final file = writeFixture({
      'books': [
        {
          'id': 'XYZ',
          'chapters': <Map<String, dynamic>>[],
        },
      ],
    });

    expect(() => parseBsb(file), throwsFormatException);
  });
}
