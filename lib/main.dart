import 'package:flutter/material.dart';
import 'package:tapestry/data/db_connection.dart';
import 'package:tapestry/data/local_store.dart';
import 'package:tapestry/ui/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await openLocalStore();
  runApp(TapestryApp(store: store));
}

class TapestryApp extends StatelessWidget {
  final LocalStore store;

  const TapestryApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tapestry',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: HomeScreen(store: store),
    );
  }
}
