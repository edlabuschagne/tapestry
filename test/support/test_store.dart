import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tapestry/data/local_store.dart';

/// Opens a [LocalStore] against a throwaway copy of the real, committed
/// `assets/bible.db` — tests read the actual pipeline output, never a mock.
///
/// Reads it via `rootBundle` (not a plain `File('assets/bible.db')`) so this
/// works identically in host `flutter test` widget tests *and* on-device
/// `integration_test` runs, where "assets/bible.db" isn't a real path on the
/// device filesystem — only an entry in the bundled asset manifest.
///
// forge-debt (low): the copy is written with writeAsBytesSync, not the more
// idiomatic async writeAsBytes. Deliberately — an async `File.copy()` of
// this ~16MB file executed before any widget pump reproducibly deadlocks
// flutter_test's pump loop on this machine (the sync variant does not; a
// tiny file's async copy does not either). Root cause not identified — looks
// like a flutter_test/dart:io interaction, not a drift or app bug. Revisit
// if a future drift/Flutter upgrade might have fixed the underlying issue.
///
/// `closeStreamsSynchronously: true` avoids a separate, documented drift
/// pitfall under flutter_test: without it, closing a query stream leaves a
/// timer open for one event-loop turn, which `pumpAndSettle()` can wait on.
Future<LocalStore> openTestStore() async {
  final data = await rootBundle.load('assets/bible.db');
  final tempDir = Directory.systemTemp.createTempSync('tapestry_test_db');
  final copy = File('${tempDir.path}/bible.db');
  copy.writeAsBytesSync(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  return LocalStore(
    DatabaseConnection(NativeDatabase(copy), closeStreamsSynchronously: true),
  );
}
