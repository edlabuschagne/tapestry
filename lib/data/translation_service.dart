import 'package:tapestry/domain/verse_status.dart';

/// A licensed online translation layer (API.Bible). Always mockable — tests
/// and the gate battery never call the live service (docs/MILESTONES.md M4).
abstract class TranslationService {
  /// Looks up the bibleId for a translation abbreviation (e.g. "NIV").
  /// Returns null if this API key doesn't have access to a matching Bible.
  Future<String?> resolveBibleId(String abbreviation);

  /// Fetches this translation's content for [verseIds] (already known from
  /// BSB — the caller decides which verses to ask about). Every id in
  /// [verseIds] gets an entry: present with text, or footnoted with an
  /// explanatory note — never a silent gap.
  Future<Map<int, VerseStatus>> fetchVerses({
    required String bibleId,
    required List<int> verseIds,
  });
}
