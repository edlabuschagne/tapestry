/// The canonical 66-book Protestant-canon order, keyed the way both of the
/// pipeline's data sources refer to books: HelloAO's BSB API uses 3/4-letter
/// USFM-style ids (e.g. "GEN"); OpenBible.info's cross-reference file uses its
/// own abbreviations (e.g. "Gen"). [order] is the canonical book number (1-66)
/// used as the "BB" field of a VerseId.
class BookInfo {
  final int order;
  final String bsbId;
  final String name;
  final String crossRefAbbrev;

  const BookInfo({
    required this.order,
    required this.bsbId,
    required this.name,
    required this.crossRefAbbrev,
  });
}

const List<BookInfo> kBooks = [
  BookInfo(order: 1, bsbId: 'GEN', name: 'Genesis', crossRefAbbrev: 'Gen'),
  BookInfo(order: 2, bsbId: 'EXO', name: 'Exodus', crossRefAbbrev: 'Exod'),
  BookInfo(order: 3, bsbId: 'LEV', name: 'Leviticus', crossRefAbbrev: 'Lev'),
  BookInfo(order: 4, bsbId: 'NUM', name: 'Numbers', crossRefAbbrev: 'Num'),
  BookInfo(order: 5, bsbId: 'DEU', name: 'Deuteronomy', crossRefAbbrev: 'Deut'),
  BookInfo(order: 6, bsbId: 'JOS', name: 'Joshua', crossRefAbbrev: 'Josh'),
  BookInfo(order: 7, bsbId: 'JDG', name: 'Judges', crossRefAbbrev: 'Judg'),
  BookInfo(order: 8, bsbId: 'RUT', name: 'Ruth', crossRefAbbrev: 'Ruth'),
  BookInfo(order: 9, bsbId: '1SA', name: '1 Samuel', crossRefAbbrev: '1Sam'),
  BookInfo(order: 10, bsbId: '2SA', name: '2 Samuel', crossRefAbbrev: '2Sam'),
  BookInfo(order: 11, bsbId: '1KI', name: '1 Kings', crossRefAbbrev: '1Kgs'),
  BookInfo(order: 12, bsbId: '2KI', name: '2 Kings', crossRefAbbrev: '2Kgs'),
  BookInfo(order: 13, bsbId: '1CH', name: '1 Chronicles', crossRefAbbrev: '1Chr'),
  BookInfo(order: 14, bsbId: '2CH', name: '2 Chronicles', crossRefAbbrev: '2Chr'),
  BookInfo(order: 15, bsbId: 'EZR', name: 'Ezra', crossRefAbbrev: 'Ezra'),
  BookInfo(order: 16, bsbId: 'NEH', name: 'Nehemiah', crossRefAbbrev: 'Neh'),
  BookInfo(order: 17, bsbId: 'EST', name: 'Esther', crossRefAbbrev: 'Esth'),
  BookInfo(order: 18, bsbId: 'JOB', name: 'Job', crossRefAbbrev: 'Job'),
  BookInfo(order: 19, bsbId: 'PSA', name: 'Psalms', crossRefAbbrev: 'Ps'),
  BookInfo(order: 20, bsbId: 'PRO', name: 'Proverbs', crossRefAbbrev: 'Prov'),
  BookInfo(order: 21, bsbId: 'ECC', name: 'Ecclesiastes', crossRefAbbrev: 'Eccl'),
  BookInfo(order: 22, bsbId: 'SNG', name: 'Song of Solomon', crossRefAbbrev: 'Song'),
  BookInfo(order: 23, bsbId: 'ISA', name: 'Isaiah', crossRefAbbrev: 'Isa'),
  BookInfo(order: 24, bsbId: 'JER', name: 'Jeremiah', crossRefAbbrev: 'Jer'),
  BookInfo(order: 25, bsbId: 'LAM', name: 'Lamentations', crossRefAbbrev: 'Lam'),
  BookInfo(order: 26, bsbId: 'EZK', name: 'Ezekiel', crossRefAbbrev: 'Ezek'),
  BookInfo(order: 27, bsbId: 'DAN', name: 'Daniel', crossRefAbbrev: 'Dan'),
  BookInfo(order: 28, bsbId: 'HOS', name: 'Hosea', crossRefAbbrev: 'Hos'),
  BookInfo(order: 29, bsbId: 'JOL', name: 'Joel', crossRefAbbrev: 'Joel'),
  BookInfo(order: 30, bsbId: 'AMO', name: 'Amos', crossRefAbbrev: 'Amos'),
  BookInfo(order: 31, bsbId: 'OBA', name: 'Obadiah', crossRefAbbrev: 'Obad'),
  BookInfo(order: 32, bsbId: 'JON', name: 'Jonah', crossRefAbbrev: 'Jonah'),
  BookInfo(order: 33, bsbId: 'MIC', name: 'Micah', crossRefAbbrev: 'Mic'),
  BookInfo(order: 34, bsbId: 'NAM', name: 'Nahum', crossRefAbbrev: 'Nah'),
  BookInfo(order: 35, bsbId: 'HAB', name: 'Habakkuk', crossRefAbbrev: 'Hab'),
  BookInfo(order: 36, bsbId: 'ZEP', name: 'Zephaniah', crossRefAbbrev: 'Zeph'),
  BookInfo(order: 37, bsbId: 'HAG', name: 'Haggai', crossRefAbbrev: 'Hag'),
  BookInfo(order: 38, bsbId: 'ZEC', name: 'Zechariah', crossRefAbbrev: 'Zech'),
  BookInfo(order: 39, bsbId: 'MAL', name: 'Malachi', crossRefAbbrev: 'Mal'),
  BookInfo(order: 40, bsbId: 'MAT', name: 'Matthew', crossRefAbbrev: 'Matt'),
  BookInfo(order: 41, bsbId: 'MRK', name: 'Mark', crossRefAbbrev: 'Mark'),
  BookInfo(order: 42, bsbId: 'LUK', name: 'Luke', crossRefAbbrev: 'Luke'),
  BookInfo(order: 43, bsbId: 'JHN', name: 'John', crossRefAbbrev: 'John'),
  BookInfo(order: 44, bsbId: 'ACT', name: 'Acts', crossRefAbbrev: 'Acts'),
  BookInfo(order: 45, bsbId: 'ROM', name: 'Romans', crossRefAbbrev: 'Rom'),
  BookInfo(order: 46, bsbId: '1CO', name: '1 Corinthians', crossRefAbbrev: '1Cor'),
  BookInfo(order: 47, bsbId: '2CO', name: '2 Corinthians', crossRefAbbrev: '2Cor'),
  BookInfo(order: 48, bsbId: 'GAL', name: 'Galatians', crossRefAbbrev: 'Gal'),
  BookInfo(order: 49, bsbId: 'EPH', name: 'Ephesians', crossRefAbbrev: 'Eph'),
  BookInfo(order: 50, bsbId: 'PHP', name: 'Philippians', crossRefAbbrev: 'Phil'),
  BookInfo(order: 51, bsbId: 'COL', name: 'Colossians', crossRefAbbrev: 'Col'),
  BookInfo(order: 52, bsbId: '1TH', name: '1 Thessalonians', crossRefAbbrev: '1Thess'),
  BookInfo(order: 53, bsbId: '2TH', name: '2 Thessalonians', crossRefAbbrev: '2Thess'),
  BookInfo(order: 54, bsbId: '1TI', name: '1 Timothy', crossRefAbbrev: '1Tim'),
  BookInfo(order: 55, bsbId: '2TI', name: '2 Timothy', crossRefAbbrev: '2Tim'),
  BookInfo(order: 56, bsbId: 'TIT', name: 'Titus', crossRefAbbrev: 'Titus'),
  BookInfo(order: 57, bsbId: 'PHM', name: 'Philemon', crossRefAbbrev: 'Phlm'),
  BookInfo(order: 58, bsbId: 'HEB', name: 'Hebrews', crossRefAbbrev: 'Heb'),
  BookInfo(order: 59, bsbId: 'JAS', name: 'James', crossRefAbbrev: 'Jas'),
  BookInfo(order: 60, bsbId: '1PE', name: '1 Peter', crossRefAbbrev: '1Pet'),
  BookInfo(order: 61, bsbId: '2PE', name: '2 Peter', crossRefAbbrev: '2Pet'),
  BookInfo(order: 62, bsbId: '1JN', name: '1 John', crossRefAbbrev: '1John'),
  BookInfo(order: 63, bsbId: '2JN', name: '2 John', crossRefAbbrev: '2John'),
  BookInfo(order: 64, bsbId: '3JN', name: '3 John', crossRefAbbrev: '3John'),
  BookInfo(order: 65, bsbId: 'JUD', name: 'Jude', crossRefAbbrev: 'Jude'),
  BookInfo(order: 66, bsbId: 'REV', name: 'Revelation', crossRefAbbrev: 'Rev'),
];

final Map<String, BookInfo> booksByBsbId = {for (final b in kBooks) b.bsbId: b};
final Map<String, BookInfo> booksByCrossRefAbbrev = {
  for (final b in kBooks) b.crossRefAbbrev: b,
};
final Map<int, BookInfo> booksByOrder = {for (final b in kBooks) b.order: b};

/// New Testament starts at Matthew, book order 40.
const int kFirstNewTestamentBookOrder = 40;
