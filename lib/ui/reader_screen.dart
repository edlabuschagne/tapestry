import 'package:flutter/material.dart';
import 'package:tapestry/data/local_store.dart';
import 'package:tapestry/ui/constellation_screen.dart';
import 'package:tapestry/ui/passage_body.dart';

class ReaderScreen extends StatefulWidget {
  final LocalStore store;
  final int passageId;

  const ReaderScreen({super.key, required this.store, required this.passageId});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late Future<_PassageContent> _future;

  @override
  void initState() {
    super.initState();
    _future = _load(widget.passageId);
  }

  @override
  void didUpdateWidget(covariant ReaderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.passageId != widget.passageId) {
      final next = _load(widget.passageId);
      setState(() {
        _future = next;
      });
    }
  }

  Future<_PassageContent> _load(int passageId) async {
    final passage = await widget.store.passageById(passageId);
    final verses = await widget.store.versesForPassage(passageId);
    final maxId = await widget.store.maxPassageId();
    return _PassageContent(passage: passage, verses: verses, maxPassageId: maxId);
  }

  void _goTo(int passageId) {
    final next = _load(passageId);
    setState(() {
      _future = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_book),
          tooltip: 'Books',
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
        actions: [
          FutureBuilder<_PassageContent>(
            future: _future,
            builder: (context, snapshot) {
              final passageId = snapshot.data?.passage.id;
              return IconButton(
                icon: const Icon(Icons.hub_outlined),
                tooltip: 'Constellation',
                onPressed: passageId == null
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ConstellationScreen(store: widget.store, passageId: passageId),
                          ),
                        ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<_PassageContent>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final content = snapshot.data!;
          final canGoPrev = content.passage.id > 1;
          final canGoNext = content.passage.id < content.maxPassageId;

          return Column(
            children: [
              Expanded(child: PassageBody(passage: content.passage, verses: content.verses)),
              SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: canGoPrev ? () => _goTo(content.passage.id - 1) : null,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Previous'),
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: canGoNext ? () => _goTo(content.passage.id + 1) : null,
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Next'),
                        iconAlignment: IconAlignment.end,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PassageContent {
  final Passage passage;
  final List<Verse> verses;
  final int maxPassageId;

  const _PassageContent({required this.passage, required this.verses, required this.maxPassageId});
}
