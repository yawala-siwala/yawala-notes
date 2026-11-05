import 'package:flutter/material.dart';

import '../../state/app_state.dart';

/// Search / filter bar shown above the notes list.
class NotesToolbar extends StatelessWidget {
  const NotesToolbar({super.key, required this.state});

  final NotesState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 10, 6),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
                hintText: 'Search your notes',
              ),
              onChanged: state.setFilter,
            ),
          ),
          ListenableBuilder(
            listenable: state,
            builder: (context, _) => Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Chip(label: Text('${state.items.length} notes')),
            ),
          ),
        ],
      ),
    );
  }
}