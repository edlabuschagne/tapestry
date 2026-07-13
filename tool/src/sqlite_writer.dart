import 'dart:io';

import 'package:sqlite3/sqlite3.dart';
import 'package:tapestry/domain/book_index.dart';
import 'package:tapestry/domain/edge.dart';
import 'package:tapestry/domain/passage.dart';

import 'bsb_source.dart';

const _schema = '''
CREATE TABLE books (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  bsb_id TEXT NOT NULL
);
CREATE TABLE passages (
  id INTEGER PRIMARY KEY,
  book INTEGER NOT NULL REFERENCES books(id),
  start_verse_id INTEGER NOT NULL,
  end_verse_id INTEGER NOT NULL,
  heading TEXT NOT NULL
);
CREATE TABLE verses (
  id INTEGER PRIMARY KEY,
  book INTEGER NOT NULL REFERENCES books(id),
  chapter INTEGER NOT NULL,
  verse INTEGER NOT NULL,
  text TEXT NOT NULL,
  passage_id INTEGER NOT NULL REFERENCES passages(id)
);
CREATE TABLE edges (
  from_passage_id INTEGER NOT NULL REFERENCES passages(id),
  to_passage_id INTEGER NOT NULL REFERENCES passages(id),
  weight INTEGER NOT NULL,
  PRIMARY KEY (from_passage_id, to_passage_id)
);
CREATE TABLE meta (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
CREATE INDEX idx_verses_passage ON verses(passage_id);
CREATE INDEX idx_edges_from ON edges(from_passage_id);
CREATE INDEX idx_edges_to ON edges(to_passage_id);
''';

/// Writes a fresh SQLite database at [outputPath] — temp file first, then
/// validated, then swapped in — so a failed build never overwrites a good
/// `bible.db` (Check 5: data-loss safety).
void writeDatabase({
  required String outputPath,
  required List<VerseRow> verses,
  required List<Passage> passages,
  required List<Edge> edges,
  required Map<String, String> meta,
}) {
  final tempPath = '$outputPath.tmp';
  final tempFile = File(tempPath);
  if (tempFile.existsSync()) tempFile.deleteSync();

  final db = sqlite3.open(tempPath);
  try {
    db.execute(_schema);
    db.execute('BEGIN');

    final bookStmt = db.prepare('INSERT INTO books (id, name, bsb_id) VALUES (?, ?, ?)');
    for (final b in kBooks) {
      bookStmt.execute([b.order, b.name, b.bsbId]);
    }
    bookStmt.dispose();

    final passageStmt = db.prepare(
      'INSERT INTO passages (id, book, start_verse_id, end_verse_id, heading) VALUES (?, ?, ?, ?, ?)',
    );
    for (final p in passages) {
      passageStmt.execute([p.id, p.book, p.startVerseId, p.endVerseId, p.heading]);
    }
    passageStmt.dispose();

    final verseStmt = db.prepare(
      'INSERT INTO verses (id, book, chapter, verse, text, passage_id) VALUES (?, ?, ?, ?, ?, ?)',
    );
    for (final v in verses) {
      verseStmt.execute([v.verseId, v.book, v.chapter, v.verse, v.text, v.passageId]);
    }
    verseStmt.dispose();

    final edgeStmt = db.prepare(
      'INSERT INTO edges (from_passage_id, to_passage_id, weight) VALUES (?, ?, ?)',
    );
    for (final e in edges) {
      edgeStmt.execute([e.fromPassageId, e.toPassageId, e.weight]);
    }
    edgeStmt.dispose();

    final metaStmt = db.prepare('INSERT INTO meta (key, value) VALUES (?, ?)');
    for (final entry in meta.entries) {
      metaStmt.execute([entry.key, entry.value]);
    }
    metaStmt.dispose();

    db.execute('COMMIT');
  } finally {
    db.dispose();
  }

  _validate(tempPath);

  final outFile = File(outputPath);
  if (outFile.existsSync()) outFile.deleteSync();
  tempFile.renameSync(outputPath);
}

/// Re-opens the just-written temp database and checks the invariants the
/// pipeline promises before letting it replace a good existing bible.db.
void _validate(String path) {
  final db = sqlite3.open(path, mode: OpenMode.readOnly);
  try {
    final bookCount = db.select('SELECT COUNT(*) AS n FROM books').first['n'] as int;
    if (bookCount != 66) {
      throw StateError('validation failed: expected 66 books, got $bookCount');
    }

    final verseCount = db.select('SELECT COUNT(*) AS n FROM verses').first['n'] as int;
    if (verseCount < 31000) {
      throw StateError('validation failed: expected >= 31000 verses, got $verseCount');
    }

    final orphanVerses = db
        .select(
          'SELECT COUNT(*) AS n FROM verses v LEFT JOIN passages p ON v.passage_id = p.id WHERE p.id IS NULL',
        )
        .first['n'] as int;
    if (orphanVerses != 0) {
      throw StateError('validation failed: $orphanVerses verses map to no passage');
    }

    final orphanEdges = db
        .select('''
          SELECT COUNT(*) AS n FROM edges e
          WHERE NOT EXISTS (SELECT 1 FROM passages p WHERE p.id = e.from_passage_id)
             OR NOT EXISTS (SELECT 1 FROM passages p WHERE p.id = e.to_passage_id)
        ''')
        .first['n'] as int;
    if (orphanEdges != 0) {
      throw StateError('validation failed: $orphanEdges edges reference a missing passage');
    }
  } finally {
    db.dispose();
  }
}
