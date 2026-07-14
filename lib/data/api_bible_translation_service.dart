import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tapestry/data/translation_service.dart';
import 'package:tapestry/domain/book_index.dart';
import 'package:tapestry/domain/verse_id.dart';
import 'package:tapestry/domain/verse_status.dart';

/// Real API.Bible client. Never calls the live service in any test or gate
/// step (docs/MILESTONES.md M4-04) — `_splitIntoVerses`'s parsing is tested
/// via an injected mock http.Client shaped like the real response captured
/// during the human's live-key verification, not a live call.
class ApiBibleTranslationService implements TranslationService {
  static const _baseUrl = 'https://api.scripture.api.bible/v1';

  final String apiKey;
  final http.Client _client;
  final Map<String, String?> _bibleIdCache = {};

  ApiBibleTranslationService({required this.apiKey, http.Client? client})
    : _client = client ?? http.Client();

  @override
  Future<String?> resolveBibleId(String abbreviation) async {
    if (_bibleIdCache.containsKey(abbreviation)) return _bibleIdCache[abbreviation];

    final uri = Uri.parse(
      '$_baseUrl/bibles',
    ).replace(queryParameters: {'abbreviation': abbreviation});
    final response = await _client.get(uri, headers: {'api-key': apiKey});

    String? id;
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'] as List;
      if (data.isNotEmpty) id = data.first['id'] as String;
    }
    _bibleIdCache[abbreviation] = id;
    return id;
  }

  @override
  Future<Map<int, VerseStatus>> fetchVerses({
    required String bibleId,
    required List<int> verseIds,
  }) async {
    if (verseIds.isEmpty) return {};

    // All of [verseIds] are assumed to fall within a single chapter (that's
    // how ParallelScreen calls this) — fetch the whole chapter in one call
    // rather than one call per verse, to conserve API.Bible's fair-use quota
    // (docs/DATA_SOURCES.md: never burn the request quota).
    final first = decodeVerseId(verseIds.first);
    final book = booksByOrder[first.book]!;
    final chapterId = '${book.bsbId}.${first.chapter}';

    final uri = Uri.parse('$_baseUrl/bibles/$bibleId/chapters/$chapterId').replace(
      queryParameters: {'content-type': 'text', 'include-verse-numbers': 'true'},
    );
    final response = await _client.get(uri, headers: {'api-key': apiKey});

    if (response.statusCode != 200) {
      return {
        for (final id in verseIds)
          id: const VerseFootnoted('This translation could not be loaded right now.'),
      };
    }

    final content = jsonDecode(response.body)['data']['content'] as String;
    final byVerseNumber = _splitIntoVerses(content);

    return {
      for (final id in verseIds)
        id: byVerseNumber.containsKey(decodeVerseId(id).verse)
            ? VersePresent(byVerseNumber[decodeVerseId(id).verse]!)
            : const VerseFootnoted('This verse does not appear in this translation.'),
    };
  }

  // Splits chapter content of the form "...[1] In the beginning...[2] Now
  // the earth..." into verse number -> text. Confirmed against a real
  // content-type=text&include-verse-numbers=true response during the
  // human's live-key verification (docs/MILESTONES.md M4,
  // needs-human-check) — verse numbers are wrapped in square brackets, not
  // a bare number followed by whitespace as first assumed. Internal
  // whitespace (the response has line breaks for poetic formatting) is
  // collapsed to single spaces, matching how BSB verses are already stored.
  Map<int, String> _splitIntoVerses(String content) {
    final matches = RegExp(r'\[(\d{1,3})\]').allMatches(content).toList();
    final result = <int, String>{};
    for (var i = 0; i < matches.length; i++) {
      final verseNum = int.parse(matches[i].group(1)!);
      final start = matches[i].end;
      final end = i + 1 < matches.length ? matches[i + 1].start : content.length;
      result[verseNum] = content
          .substring(start, end)
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }
    return result;
  }
}
