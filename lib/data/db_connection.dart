import 'db_connection_stub.dart'
    if (dart.library.io) 'db_connection_native.dart'
    if (dart.library.js_interop) 'db_connection_web.dart'
    as impl;
import 'local_store.dart';

Future<LocalStore> openLocalStore() async {
  final executor = await impl.openConnection();
  return LocalStore(executor);
}
