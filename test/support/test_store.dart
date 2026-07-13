import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:tapestry/data/local_store.dart';

/// Opens a [LocalStore] against a throwaway copy of the real, committed
/// `assets/bible.db` — tests read the actual pipeline output, never a mock,
/// and never touch the committed file itself (opening a database connection
/// can stamp header bytes, e.g. a journal-mode flag, even without any write
/// query — that showed up as a spurious `git diff` on the committed asset
/// before this used a copy).
///
// forge-debt (low): the copy is done with copySync, not the more idiomatic
// async File.copy. Deliberately — an `await File(...).copy(...)` of this
// ~16MB file executed before any widget pump reproducibly deadlocks
// flutter_test's pump loop on this machine (copySync does not; a tiny
// file's async copy does not either). Root cause not identified — looks
// like a flutter_test/dart:io interaction, not a drift or app bug. Revisit
// if a future drift/Flutter upgrade might have fixed the underlying issue.
///
/// `closeStreamsSynchronously: true` avoids a separate, documented drift
/// pitfall under flutter_test: without it, closing a query stream leaves a
/// timer open for one event-loop turn, which `pumpAndSettle()` can wait on.
Future<LocalStore> openTestStore() async {
  final tempDir = Directory.systemTemp.createTempSync('tapestry_test_db');
  final copy = File('${tempDir.path}/bible.db');
  File('assets/bible.db').copySync(copy.path);
  return LocalStore(
    DatabaseConnection(NativeDatabase(copy), closeStreamsSynchronously: true),
  );
}
