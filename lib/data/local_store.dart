import 'package:drift/drift.dart';

part 'local_store.g.dart';

/// Mirrors the physical schema `tool/src/sqlite_writer.dart` writes into the
/// bundled `assets/bible.db` — this app never creates or migrates that
/// schema, only reads it (see [LocalStore.migration]).
class Books extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get bsbId => text().named('bsb_id')();

  @override
  Set<Column> get primaryKey => {id};
}

class Passages extends Table {
  IntColumn get id => integer()();
  IntColumn get book => integer()();
  IntColumn get startVerseId => integer().named('start_verse_id')();
  IntColumn get endVerseId => integer().named('end_verse_id')();
  TextColumn get heading => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class Verses extends Table {
  IntColumn get id => integer()();
  IntColumn get book => integer()();
  IntColumn get chapter => integer()();
  IntColumn get verse => integer()();
  TextColumn get content => text().named('text')();
  IntColumn get passageId => integer().named('passage_id')();

  @override
  Set<Column> get primaryKey => {id};
}

class Edges extends Table {
  IntColumn get fromPassageId => integer().named('from_passage_id')();
  IntColumn get toPassageId => integer().named('to_passage_id')();
  IntColumn get weight => integer()();

  @override
  Set<Column> get primaryKey => {fromPassageId, toPassageId};
}

@DataClassName('MetaRow')
class MetaEntries extends Table {
  @override
  String get tableName => 'meta';

  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Books, Passages, Verses, Edges, MetaEntries])
class LocalStore extends _$LocalStore {
  LocalStore(super.executor);

  @override
  int get schemaVersion => 1;

  // The bundled database is pre-built by tool/build_db.dart and shipped
  // read-only; this app never creates or migrates its schema.
  @override
  MigrationStrategy get migration => MigrationStrategy();

  Future<Passage> passageById(int id) => (select(
    passages,
  )..where((p) => p.id.equals(id))).getSingle();

  Future<List<Verse>> versesForPassage(int passageId) =>
      (select(verses)
            ..where((v) => v.passageId.equals(passageId))
            ..orderBy([(v) => OrderingTerm.asc(v.id)]))
          .get();

  Future<Book> bookById(int id) =>
      (select(books)..where((b) => b.id.equals(id))).getSingle();

  Future<List<Book>> allBooks() =>
      (select(books)..orderBy([(b) => OrderingTerm.asc(b.id)])).get();

  /// The passage whose verse range contains [verseId] — how chapter
  /// navigation jumps in: a chapter's first verse may belong to a passage
  /// that actually started in an earlier chapter (headings don't always
  /// align with chapter boundaries), and this is the correct passage to
  /// land on either way.
  Future<Passage> passageContainingVerse(int book, int verseId) => (select(passages)
        ..where(
          (p) =>
              p.book.equals(book) & p.startVerseId.isSmallerOrEqualValue(verseId) & p.endVerseId.isBiggerOrEqualValue(verseId),
        ))
      .getSingle();

  Future<int> maxChapterForBook(int book) => (selectOnly(verses)
        ..addColumns([verses.chapter.max()])
        ..where(verses.book.equals(book)))
      .map((row) => row.read(verses.chapter.max())!)
      .getSingle();

  /// Passage ids are assigned sequentially in canonical reading order by the
  /// pipeline (Genesis 1 = id 1 ... Revelation 22 = the highest id), so
  /// prev/next is just id-1 / id+1 with a bounds check — no query needed to
  /// determine adjacency.
  Future<int> maxPassageId() =>
      (selectOnly(passages)..addColumns([passages.id.max()]))
          .map((row) => row.read(passages.id.max())!)
          .getSingle();
}
