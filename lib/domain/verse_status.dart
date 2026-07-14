/// Per-translation status of a verse (see docs/ARCHITECTURE.md's data model).
/// A verse absent from a translation (e.g. Matthew 17:21 in NIV) is never a
/// silent gap — it always renders as a tappable footnote with an
/// explanatory note.
sealed class VerseStatus {
  const VerseStatus();
}

class VersePresent extends VerseStatus {
  final String text;
  const VersePresent(this.text);
}

class VerseFootnoted extends VerseStatus {
  final String note;
  const VerseFootnoted(this.note);
}
