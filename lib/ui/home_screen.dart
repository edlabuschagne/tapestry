import 'package:flutter/material.dart';
import 'package:tapestry/data/local_store.dart';
import 'package:tapestry/domain/book_index.dart';
import 'package:tapestry/ui/book_screen.dart';

class HomeScreen extends StatelessWidget {
  final LocalStore store;

  const HomeScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tapestry')),
      body: ListView.builder(
        itemCount: kBooks.length,
        itemBuilder: (context, index) {
          final book = kBooks[index];
          return ListTile(
            title: Text(book.name),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BookScreen(store: store, book: book),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
