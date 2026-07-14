import 'package:flutter/material.dart';
import 'package:tapestry/data/local_store.dart';
import 'package:tapestry/data/translation_service.dart';
import 'package:tapestry/domain/book_index.dart';
import 'package:tapestry/domain/verse_status.dart';

/// BSB alongside a licensed online translation (NIV or NKJV, switchable),
/// aligned verse-by-verse. If no API key is configured (or the selected
/// translation can't be resolved), falls back to a plain BSB-only
/// explanation — never a crash, never a blank pane (docs/MILESTONES.md
/// M4-03).
class ParallelScreen extends StatefulWidget {
  static const availableTranslations = ['NIV', 'NKJV'];

  final LocalStore store;
  final TranslationService? translationService;
  final int book;
  final int chapter;
  final String initialTranslationAbbreviation;

  const ParallelScreen({
    super.key,
    required this.store,
    required this.translationService,
    required this.book,
    required this.chapter,
    this.initialTranslationAbbreviation = 'NIV',
  });

  @override
  State<ParallelScreen> createState() => _ParallelScreenState();
}

class _ParallelScreenState extends State<ParallelScreen> {
  late String _selectedAbbreviation;
  late Future<_ParallelContent> _future;

  @override
  void initState() {
    super.initState();
    _selectedAbbreviation = widget.initialTranslationAbbreviation;
    _future = _load();
  }

  Future<_ParallelContent> _load() async {
    final bsbVerses = await widget.store.versesForChapter(widget.book, widget.chapter);

    final service = widget.translationService;
    if (service == null) {
      return _ParallelContent(bsbVerses: bsbVerses, otherStatuses: null);
    }

    final bibleId = await service.resolveBibleId(_selectedAbbreviation);
    if (bibleId == null) {
      return _ParallelContent(bsbVerses: bsbVerses, otherStatuses: null);
    }

    final statuses = await service.fetchVerses(
      bibleId: bibleId,
      verseIds: bsbVerses.map((v) => v.id).toList(),
    );
    return _ParallelContent(bsbVerses: bsbVerses, otherStatuses: statuses);
  }

  void _selectTranslation(String abbreviation) {
    if (abbreviation == _selectedAbbreviation) return;
    setState(() {
      _selectedAbbreviation = abbreviation;
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final book = booksByOrder[widget.book]!;
    return Scaffold(
      appBar: AppBar(
        title: Text('${book.name} ${widget.chapter} — Parallel'),
        actions: [
          if (widget.translationService != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: SegmentedButton<String>(
                  segments: [
                    for (final abbreviation in ParallelScreen.availableTranslations)
                      ButtonSegment(value: abbreviation, label: Text(abbreviation)),
                  ],
                  selected: {_selectedAbbreviation},
                  onSelectionChanged: (selection) => _selectTranslation(selection.first),
                ),
              ),
            ),
        ],
      ),
      body: FutureBuilder<_ParallelContent>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final content = snapshot.data!;
          if (content.otherStatuses == null) {
            return _BsbOnlyNotice(
              translationAbbreviation: _selectedAbbreviation,
              bsbVerses: content.bsbVerses,
            );
          }
          return _AlignedVerseList(
            bsbVerses: content.bsbVerses,
            otherStatuses: content.otherStatuses!,
            translationAbbreviation: _selectedAbbreviation,
          );
        },
      ),
    );
  }
}

class _BsbOnlyNotice extends StatelessWidget {
  final String translationAbbreviation;
  final List<Verse> bsbVerses;

  const _BsbOnlyNotice({required this.translationAbbreviation, required this.bsbVerses});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'No API.Bible key is configured, so $translationAbbreviation isn\'t '
              'available — showing the Berean Standard Bible only. Tapestry is '
              'fully usable offline without a key.',
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (final verse in bsbVerses)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${verse.verse} ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
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

class _AlignedVerseList extends StatelessWidget {
  final List<Verse> bsbVerses;
  final Map<int, VerseStatus> otherStatuses;
  final String translationAbbreviation;

  const _AlignedVerseList({
    required this.bsbVerses,
    required this.otherStatuses,
    required this.translationAbbreviation,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bsbVerses.length,
      itemBuilder: (context, index) {
        final verse = bsbVerses[index];
        final status = otherStatuses[verse.id];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${verse.verse}', style: Theme.of(context).textTheme.labelLarge),
              Text.rich(TextSpan(children: [const TextSpan(text: 'BSB  '), TextSpan(text: verse.content)])),
              const SizedBox(height: 4),
              _OtherVerseLine(abbreviation: translationAbbreviation, status: status, verseNumber: verse.verse),
            ],
          ),
        );
      },
    );
  }
}

class _OtherVerseLine extends StatelessWidget {
  final String abbreviation;
  final VerseStatus? status;
  final int verseNumber;

  const _OtherVerseLine({required this.abbreviation, required this.status, required this.verseNumber});

  @override
  Widget build(BuildContext context) {
    if (status is VersePresent) {
      final text = (status! as VersePresent).text;
      return Text.rich(TextSpan(children: [TextSpan(text: '$abbreviation  '), TextSpan(text: text)]));
    }

    final note = status is VerseFootnoted
        ? (status! as VerseFootnoted).note
        : 'This verse does not appear in this translation.';
    // Fixed-height tap area, not just the inline text glyphs: the text
    // alone (~20 logical px tall) falls well under the project's 44dp
    // accessibility floor (see kNodeRadius in constellation_view.dart for
    // the equivalent floor on the graph's own tap targets).
    return SizedBox(
      height: 44,
      child: InkWell(
        onTap: () => showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('$abbreviation $verseNumber'),
            content: Text(note),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
            ],
          ),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '$abbreviation  '),
                TextSpan(
                  text: '[footnote]',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.underline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ParallelContent {
  final List<Verse> bsbVerses;
  final Map<int, VerseStatus>? otherStatuses;

  const _ParallelContent({required this.bsbVerses, required this.otherStatuses});
}
