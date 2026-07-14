// Regresses the real bug found during M4's needs-human-check live-key
// verification: the verse-splitting parser assumed a bare "1 " prefix, but
// API.Bible's real content-type=text response wraps verse numbers in square
// brackets ("[1] In the beginning..."), so every verse silently fell back
// to "does not appear in this translation." Uses an injected MockClient —
// never a live call (docs/MILESTONES.md M4-04).
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tapestry/data/api_bible_translation_service.dart';
import 'package:tapestry/domain/book_index.dart';
import 'package:tapestry/domain/verse_id.dart';
import 'package:tapestry/domain/verse_status.dart';

void main() {
  test('resolveBibleId parses the bibleId from the real /bibles response shape', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/v1/bibles');
      expect(request.url.queryParameters['abbreviation'], 'NIV');
      return http.Response(
        jsonEncode({
          'data': [
            {'id': '78a9f6124f344018-01'},
          ],
        }),
        200,
      );
    });
    final service = ApiBibleTranslationService(apiKey: 'test-key', client: client);

    expect(await service.resolveBibleId('NIV'), '78a9f6124f344018-01');
  });

  test('fetchVerses splits bracket-numbered, poetically-wrapped content correctly', () async {
    // Trimmed excerpt shaped exactly like a real captured Genesis 1 response
    // (square-bracket verse markers; verse 27 wraps across lines like real
    // poetic-format verses do).
    const content =
        'The Beginning\n     [1] In the beginning God created the heavens '
        'and the earth.  [2] Now the earth was formless and empty.\n    \n'
        '     [27] So God created mankind in his own image,\n'
        '    in the image of God he created them;\n'
        '    male and female he created them.\n'
        '     [28] God blessed them.\n';

    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'data': {'content': content},
        }),
        200,
      );
    });
    final service = ApiBibleTranslationService(apiKey: 'test-key', client: client);

    final genesis = booksByOrder.values.firstWhere((b) => b.name == 'Genesis');
    final verseIds = [1, 2, 27].map((v) => encodeVerseId(book: genesis.order, chapter: 1, verse: v)).toList();

    final statuses = await service.fetchVerses(bibleId: 'fake-id', verseIds: verseIds);

    expect(
      (statuses[verseIds[0]]! as VersePresent).text,
      'In the beginning God created the heavens and the earth.',
    );
    expect((statuses[verseIds[1]]! as VersePresent).text, 'Now the earth was formless and empty.');
    // Internal line breaks (poetic formatting) collapse to single spaces.
    expect(
      (statuses[verseIds[2]]! as VersePresent).text,
      'So God created mankind in his own image, in the image of God he created them; '
      'male and female he created them.',
    );
  });

  test('fetchVerses reports a verse absent from the response as footnoted, not missing', () async {
    const content = 'The Beginning\n     [1] In the beginning God created the heavens and the earth.\n';

    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'data': {'content': content},
        }),
        200,
      );
    });
    final service = ApiBibleTranslationService(apiKey: 'test-key', client: client);

    final genesis = booksByOrder.values.firstWhere((b) => b.name == 'Genesis');
    final verse2Id = encodeVerseId(book: genesis.order, chapter: 1, verse: 2);

    final statuses = await service.fetchVerses(bibleId: 'fake-id', verseIds: [verse2Id]);

    expect(statuses[verse2Id], isA<VerseFootnoted>());
  });
}
