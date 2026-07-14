import 'package:tapestry/data/translation_service.dart';
import 'package:tapestry/domain/verse_status.dart';

/// A canned TranslationService for tests — never touches the network
/// (docs/MILESTONES.md M4-04 requires the full test/gate battery to run
/// offline). Duplicated from test/support/fake_translation_service.dart:
/// integration_test is compiled as its own root and can't reach into test/.
class FakeTranslationService implements TranslationService {
  final Map<String, String> bibleIds;
  final Map<String, Map<int, VerseStatus>> versesByBibleId;

  const FakeTranslationService({this.bibleIds = const {}, this.versesByBibleId = const {}});

  @override
  Future<String?> resolveBibleId(String abbreviation) async => bibleIds[abbreviation];

  @override
  Future<Map<int, VerseStatus>> fetchVerses({
    required String bibleId,
    required List<int> verseIds,
  }) async {
    final known = versesByBibleId[bibleId] ?? const {};
    return {
      for (final id in verseIds)
        id: known[id] ?? const VerseFootnoted('This verse does not appear in this translation.'),
    };
  }
}
