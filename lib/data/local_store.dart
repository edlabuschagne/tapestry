import 'package:drift/drift.dart';
import 'package:tapestry/domain/constellation.dart';

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

  /// Up to [limit] neighbours of [passageId], strongest edge first, ties
  /// broken by neighbour passage id — a fully deterministic order, which is
  /// what makes the constellation's layout reproducible (see
  /// lib/domain/constellation.dart). Edges are stored undirected (as
  /// (fromPassageId, toPassageId) with fromPassageId < toPassageId), so
  /// "the neighbour" is whichever end of the edge isn't [passageId].
  Future<List<NeighbourEdge>> topNeighbours(int passageId, {int limit = 12}) async {
    final rows = await customSelect(
      'SELECT CASE WHEN from_passage_id = :id THEN to_passage_id ELSE from_passage_id END AS neighbour_id, '
      'weight FROM edges WHERE from_passage_id = :id OR to_passage_id = :id '
      'ORDER BY weight DESC, neighbour_id ASC LIMIT :limit',
      variables: [Variable.withInt(passageId), Variable.withInt(limit)],
      readsFrom: {edges},
    ).get();
    return [
      for (final row in rows)
        NeighbourEdge(passageId: row.read<int>('neighbour_id'), weight: row.read<int>('weight')),
    ];
  }

  /// The [limit] passages with the most edges touching them (in either
  /// direction) — used to sweep "no dead taps" across the graph's most
  /// heavily-linked passages (M3-04) rather than the whole Bible.
  Future<List<int>> highestDegreePassageIds(int limit) async {
    final rows = await customSelect(
      'SELECT passage_id, COUNT(*) AS degree FROM ('
      '  SELECT from_passage_id AS passage_id FROM edges '
      '  UNION ALL '
      '  SELECT to_passage_id AS passage_id FROM edges'
      ') GROUP BY passage_id ORDER BY degree DESC, passage_id ASC LIMIT :limit',
      variables: [Variable.withInt(limit)],
      readsFrom: {edges},
    ).get();
    return [for (final row in rows) row.read<int>('passage_id')];
  }
}
