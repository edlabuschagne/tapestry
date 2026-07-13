/// A BSB section — the graph's node unit. Boundaries come from BSB section
/// headings (public domain), never from raw verse numbers.
class Passage {
  final int id;
  final int book;
  final int startVerseId;
  final int endVerseId;
  final String heading;

  const Passage({
    required this.id,
    required this.book,
    required this.startVerseId,
    required this.endVerseId,
    required this.heading,
  });
}
