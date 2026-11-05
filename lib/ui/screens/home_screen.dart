import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../widgets/notes_card.dart';
import '../widgets/notes_toolbar.dart';

/// Main screen of Yawala Notes: toolbar, notes list and primary action.
class NotesHomeScreen extends StatelessWidget {
  const NotesHomeScreen({super.key, required this.state});

  final NotesState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yawala Notes')),
      body: Column(
        children: [
          NotesToolbar(state: state),
          Expanded(
            child: ListenableBuilder(
              listenable: state,
              builder: (context, _) {
                if (state.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = state.items.toList(growable: false);
                if (items.isEmpty) {
                  return const Center(
                    child: Text('Nothing found - try a different search.'),
                  );
                }
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) =>
                      NoteCard(item: items[index]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'New note (editor TODO)',
        onPressed: () {}, // TODO(mvp): open the note editor route.
        child: const Icon(Icons.add),
      ),
    );
  }
}