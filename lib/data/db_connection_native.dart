import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// The bundled `assets/bible.db` ships inside the app package, which Android
/// can't open a SQLite connection directly against — it has to be a real
/// file on disk. Copied once to the app's support directory on first launch.
Future<QueryExecutor> openConnection() async {
  final dir = await getApplicationSupportDirectory();
  final dbFile = File(p.join(dir.path, 'bible.db'));

  if (!await dbFile.exists()) {
    final data = await rootBundle.load('assets/bible.db');
    await dbFile.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      flush: true,
    );
  }

  return NativeDatabase.createInBackground(dbFile);
}
