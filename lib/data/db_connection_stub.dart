import 'package:drift/drift.dart';

/// Never actually used — dart.library.io / dart.library.js_interop always
/// resolves to one of the two real implementations on this app's Android +
/// web targets. Exists only because a conditional import needs a fallback.
Future<QueryExecutor> openConnection() {
  throw UnsupportedError("Tapestry doesn't support this platform");
}
