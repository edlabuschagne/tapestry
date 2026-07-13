import 'package:flutter/material.dart';
import 'package:tapestry/data/local_store.dart';
import 'package:tapestry/domain/book_index.dart';
import 'package:tapestry/domain/verse_id.dart';
import 'package:tapestry/ui/reader_screen.dart';

class BookScreen extends StatelessWidget {
  final LocalStore store;
  final BookInfo book;

  const BookScreen({super.key, required this.store, required this.book});

  Future<void> _openChapter(BuildContext context, int chapter) async {
    final verseId = encodeVerseId(book: book.order, chapter: chapter, verse: 1);
    final passage = await store.passageContainingVerse(book.order, verseId);
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReaderScreen(store: store, passageId: passage.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(book.name)),
      body: FutureBuilder<int>(
        future: store.maxChapterForBook(book.order),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final chapterCount = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: chapterCount,
            itemBuilder: (context, index) {
              final chapter = index + 1;
              return OutlinedButton(
                onPressed: () => _openChapter(context, chapter),
                child: Text('$chapter'),
              );
            },
          );
        },
      ),
    );
  }
}
