import 'package:flutter/material.dart';
import 'package:tapestry/data/local_store.dart';
import 'package:tapestry/domain/constellation.dart';
import 'package:tapestry/domain/short_reference.dart';
import 'package:tapestry/ui/constellation_view.dart';
import 'package:tapestry/ui/passage_body.dart';

class ConstellationScreen extends StatefulWidget {
  final LocalStore store;
  final int passageId;

  const ConstellationScreen({super.key, required this.store, required this.passageId});

  @override
  State<ConstellationScreen> createState() => _ConstellationScreenState();
}

class _ConstellationScreenState extends State<ConstellationScreen> {
  late int _centerPassageId;
  late Future<_ConstellationContent> _future;

  @override
  void initState() {
    super.initState();
    _centerPassageId = widget.passageId;
    _future = _load(_centerPassageId);
  }

  Future<_ConstellationContent> _load(int passageId) async {
    final passage = await widget.store.passageById(passageId);
    final verses = await widget.store.versesForPassage(passageId);
    final neighbourEdges = await widget.store.topNeighbours(passageId);
    final layout = layoutConstellation(neighbourEdges);

    final labels = <int, String>{};
    for (final node in layout) {
      final neighbourPassage = await widget.store.passageById(node.passageId);
      labels[node.passageId] = shortReference(
        book: neighbourPassage.book,
        startVerseId: neighbourPassage.startVerseId,
        endVerseId: neighbourPassage.endVerseId,
      );
    }

    return _ConstellationContent(
      passage: passage,
      verses: verses,
      layout: layout,
      neighbourLabels: labels,
      centerLabel: shortReference(
        book: passage.book,
        startVerseId: passage.startVerseId,
        endVerseId: passage.endVerseId,
      ),
    );
  }

  void _recenter(int passageId) {
    final next = _load(passageId);
    setState(() {
      _centerPassageId = passageId;
      _future = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Constellation')),
      body: FutureBuilder<_ConstellationContent>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final content = snapshot.data!;
          return Column(
            children: [
              SizedBox(
                height: 380,
                child: ConstellationView(
                  centerLabel: content.centerLabel,
                  neighbours: content.layout,
                  neighbourLabels: content.neighbourLabels,
                  onTapNeighbour: _recenter,
                ),
              ),
              const Divider(height: 1),
              Expanded(child: PassageBody(passage: content.passage, verses: content.verses)),
            ],
          );
        },
      ),
    );
  }
}

class _ConstellationContent {
  final Passage passage;
  final List<Verse> verses;
  final List<ConstellationNode> layout;
  final Map<int, String> neighbourLabels;
  final String centerLabel;

  const _ConstellationContent({
    required this.passage,
    required this.verses,
    required this.layout,
    required this.neighbourLabels,
    required this.centerLabel,
  });
}
