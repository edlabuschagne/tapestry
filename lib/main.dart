import 'package:flutter/material.dart';
import 'package:tapestry/data/api_bible_translation_service.dart';
import 'package:tapestry/data/db_connection.dart';
import 'package:tapestry/data/local_store.dart';
import 'package:tapestry/data/translation_service.dart';
import 'package:tapestry/ui/home_screen.dart';

// Never hardcoded, never committed, never logged — enters the build only via
// --dart-define=BIBLE_API_KEY=... (docs/CLAUDE.md). Empty by default, which
// this app treats as "no key configured," not an error.
const String _apiKey = String.fromEnvironment('BIBLE_API_KEY');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await openLocalStore();
  final translationService = _apiKey.isEmpty
      ? null
      : ApiBibleTranslationService(apiKey: _apiKey);
  runApp(TapestryApp(store: store, translationService: translationService));
}

class TapestryApp extends StatelessWidget {
  final LocalStore store;
  final TranslationService? translationService;

  const TapestryApp({super.key, required this.store, required this.translationService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tapestry',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: HomeScreen(store: store, translationService: translationService),
    );
  }
}
