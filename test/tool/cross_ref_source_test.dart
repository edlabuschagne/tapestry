import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapestry/domain/verse_id.dart';

import '../../tool/src/cross_ref_source.dart';

void main() {
  late Directory tempDir;

  setUp(() => tempDir = Directory.systemTemp.createTempSync('cross_ref_test'));
  tearDown(() => tempDir.deleteSync(recursive: true));

  File writeFixture(String contents) {
    final file = File('${tempDir.path}/fixture.txt');
    file.writeAsStringSync(contents);
    return file;
  }

  test('parses simple verse-to-verse rows', () {
    final file = writeFixture(
      'From Verse\tTo Verse\tVotes\t#www.openbible.info CC-BY 2026-07-13\n'
      'Gen.1.1\tPs.8.3\t73\n',
    );
    final result = parseCrossReferences(file);

    expect(result.rows, hasLength(1));
    expect(result.rows.single.fromVerseId, encodeVerseId(book: 1, chapter: 1, verse: 1));
    expect(result.rows.single.toVerseId, encodeVerseId(book: 19, chapter: 8, verse: 3));
    expect(result.rows.single.votes, 73);
    expect(result.malformedRowCount, 0);
  });

  test('resolves a range reference to its start verse', () {
    final file = writeFixture(
      'From Verse\tTo Verse\tVotes\n'
      'Gen.1.1\tProv.8.22-Prov.8.30\t76\n',
    );
    final result = parseCrossReferences(file);

    expect(result.rows.single.toVerseId, encodeVerseId(book: 20, chapter: 8, verse: 22));
  });

  test('accepts negative votes (community downvotes)', () {
    final file = writeFixture(
      'From Verse\tTo Verse\tVotes\n'
      'Gen.22.10\tIsa.53.6\t-1\n',
    );
    final result = parseCrossReferences(file);

    expect(result.rows.single.votes, -1);
  });

  test('rejects and counts rows with an unknown book abbreviation', () {
    final file = writeFixture(
      'From Verse\tTo Verse\tVotes\n'
      'Xyz.1.1\tGen.1.1\t5\n',
    );
    final result = parseCrossReferences(file);

    expect(result.rows, isEmpty);
    expect(result.malformedRowCount, 1);
  });

  test('rejects and counts rows with a non-numeric vote count', () {
    final file = writeFixture(
      'From Verse\tTo Verse\tVotes\n'
      'Gen.1.1\tPs.8.3\tabc\n',
    );
    final result = parseCrossReferences(file);

    expect(result.rows, isEmpty);
    expect(result.malformedRowCount, 1);
  });

  test('rejects and counts rows with too few fields, without crashing', () {
    final file = writeFixture(
      'From Verse\tTo Verse\tVotes\n'
      'Gen.1.1\tPs.8.3\n',
    );
    final result = parseCrossReferences(file);

    expect(result.rows, isEmpty);
    expect(result.malformedRowCount, 1);
  });
}
