import 'package:flutter/material.dart';

import '../rights_data.dart';
import '../sos_actions.dart';
import '../theme.dart';

class RightsPage extends StatelessWidget {
  const RightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Your rights')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: AppColors.warningBg,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'General information, not legal advice. For your own case, '
                'talk to a lawyer. Call 15100 for free legal aid.',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Helplines (tap to call)', style: text.titleLarge),
          for (final h in helplines)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(child: Icon(Icons.call)),
              title: Text('${h.number}  ${h.name}'),
              subtitle: Text(h.note),
              onTap: () => callNumber(h.number),
            ),
          const Divider(height: 32),
          Text('Know your rights', style: text.titleLarge),
          const SizedBox(height: 8),
          for (final t in rightsTopics)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(t.title),
              childrenPadding: const EdgeInsets.only(bottom: 12),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.summary),
                const SizedBox(height: 8),
                for (final p in t.points)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('•  '),
                        Expanded(child: Text(p)),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
