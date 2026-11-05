import 'model.dart';

/// Data access for stored notes.
///
/// The boilerplate keeps notes in memory off [Note.seedLibrary]; the real
/// store is app-private storage per platform through
/// `platform_bindings.dart`.
class NotesService {
  const NotesService();

  Future<List<Note>> list() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    // Sort most recently updated first.
    final notes = [...Note.seedLibrary]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List.unmodifiable(notes);
  }
}