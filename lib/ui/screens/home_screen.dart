import 'package:material_ui/material_ui.dart';

import 'package:yawala_core/yawala_core.dart';

import '../../state/notes_state.dart';
import '../widgets/notes_card.dart';
import '../widgets/notes_toolbar.dart';
import 'note_editor_screen.dart';

/// Note list with search filtering and one-tap access to the editor.
class NotesHomeScreen extends StatelessWidget {
  const NotesHomeScreen({super.key, required this.state});

  final NotesState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yawala Notes')),
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final notes = state.notes.toList(growable: false);
          if (notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No notes match your search.'),
                  const SizedBox(height: YawalaSpacing.md),
                  FilledButton(
                    onPressed: () => _createAndOpen(context),
                    child: const Text('Create a note'),
                  ),
                ],
              ),
            );
          }
          return Column(
            children: [
              NotesToolbar(state: state),
              Expanded(
                child: ListView.builder(
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    return NoteCard(
                      item: notes[index],
                      onTap: () => _openEditor(context, notes[index].id),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'New note',
        onPressed: () => _createAndOpen(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _createAndOpen(BuildContext context) {
    final note = state.createNote();
    _openEditor(context, note.id);
  }

  void _openEditor(BuildContext context, String noteId) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => NoteEditorScreen(state: state, noteId: noteId),
    ));
  }
}
