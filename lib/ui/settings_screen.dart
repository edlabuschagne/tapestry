import 'package:flutter/material.dart';

/// "Settings entry for key presence" (docs/MILESTONES.md M4 deliverables) —
/// deliberately minimal: this app has no account system and no other
/// settings yet (DO-NOT-BUILD).
class SettingsScreen extends StatelessWidget {
  final bool apiKeyConfigured;

  const SettingsScreen({super.key, required this.apiKeyConfigured});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('API.Bible key', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(
              apiKeyConfigured
                  ? 'Configured — NIV and NKJV parallel views are available.'
                  : 'Not configured — Tapestry runs in Berean Standard Bible-only '
                        'mode. This is fully offline and complete on its own; the '
                        'key only unlocks the optional NIV/NKJV parallel view.',
            ),
          ],
        ),
      ),
    );
  }
}
