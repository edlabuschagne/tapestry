import 'package:flutter/material.dart';
import 'package:tapestry/data/local_store.dart';
import 'package:tapestry/data/translation_service.dart';
import 'package:tapestry/domain/book_index.dart';
import 'package:tapestry/ui/book_screen.dart';
import 'package:tapestry/ui/settings_screen.dart';

class HomeScreen extends StatelessWidget {
  final LocalStore store;
  final TranslationService? translationService;

  const HomeScreen({super.key, required this.store, required this.translationService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tapestry'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SettingsScreen(apiKeyConfigured: translationService != null),
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: kBooks.length,
        itemBuilder: (context, index) {
          final book = kBooks[index];
          return ListTile(
            title: Text(book.name),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      BookScreen(store: store, translationService: translationService, book: book),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
