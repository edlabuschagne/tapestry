import 'package:flutter/material.dart';
import 'package:tapestry/data/local_store.dart';
import 'package:tapestry/domain/book_index.dart';

/// The book name, heading, and full verse text for a passage — shared by
/// ReaderScreen and ConstellationScreen's reader pane so both render a
/// passage identically.
class PassageBody extends StatelessWidget {
  final Passage passage;
  final List<Verse> verses;

  const PassageBody({super.key, required this.passage, required this.verses});

  @override
  Widget build(BuildContext context) {
    final book = booksByOrder[passage.book]!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(book.name, style: Theme.of(context).textTheme.labelLarge),
        Text(passage.heading, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        for (final verse in verses)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${verse.verse} ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFeatures: [FontFeature.superscripts()],
                    ),
                  ),
                  TextSpan(text: verse.content),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
