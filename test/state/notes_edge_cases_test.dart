import 'package:flutter_test/flutter_test.dart';

import 'package:yawala_core/yawala_core.dart';

import 'package:yawala_notes/domain/model.dart';
import 'package:yawala_notes/native/platform_bindings.dart';
import 'package:yawala_notes/state/notes_state.dart';

/// Scriptable native binding for edge-case tests; records export payloads.
class RecordingNotesBinding implements NotesNativeBinding {
  String? nextExportPath = '/tmp/out.md';
  List<String> exportFileNames = <String>[];
  ImportedFile? nextImport;

  @override
  Future<String?> exportNote({
    required String fileName,
    required String content,
  }) async {
    exportFileNames.add(fileName);
    return nextExportPath;
  }

  @override
  Future<ImportedFile?> importNoteFile() async => nextImport;

  @override
  Future<MarkdownPreview> renderMarkdown(String source) async =>
      MarkdownPreview.fallback(source);
}

NotesState buildState({RecordingNotesBinding? native}) {
  return NotesState(
    native: native ?? RecordingNotesBinding(),
    storage: InMemorySecureStorage(),
  );
}

void main() {
  group('NotesState id generation', () {
    test('rapid creations never collide, even on coarse clocks', () async {
      final state = buildState();
      await state.load();

      // Back-to-back creations would share microsecondsSinceEpoch on
      // platforms with coarse clock granularity; the counter disambiguates.
      final ids = <String>{for (var i = 0; i < 25; i++) state.createNote().id};

      expect(ids, hasLength(25));
      expect(state.allNotes, hasLength(Note.seedLibrary.length + 25));
    });

    test('create + import in the same instant get distinct ids', () async {
      final native = RecordingNotesBinding()
        ..nextImport = const ImportedFile(fileName: 'a.md', content: 'a');
      final state = NotesState(
        native: native,
        storage: InMemorySecureStorage(),
      );
      await state.load();

      final created = state.createNote();
      await state.importNote();

      final ids = state.allNotes.map((note) => note.id).toSet();
      expect(ids.length, state.allNotes.length);
      expect(ids, contains(created.id));
    });
  });

  group('NotesState tolerant mutations', () {
    test('updateContent on an unknown id is a safe no-op', () async {
      final state = buildState();
      await state.load();
      final before = state.allNotes.length;

      state.updateContent('does-not-exist', title: 'ghost');

      expect(state.allNotes, hasLength(before));
      expect(state.noteById('does-not-exist'), isNull);
      expect(state.selectedNote, isNotNull); // selection untouched
    });

    test('deleteNote on an unknown id keeps every note', () async {
      final state = buildState();
      await state.load();
      final before = state.allNotes.length;

      state.deleteNote('does-not-exist');

      expect(state.allNotes, hasLength(before));
    });

    test('deleting the selected note keeps other notes selectable',
        () async {
      final state = buildState();
      await state.load();
      final other = state.allNotes.last;

      state.deleteNote(state.selectedNote!.id);

      expect(state.selectedNote, isNull);
      state.select(other.id);
      expect(state.selectedNote?.id, other.id);
    });
  });

  group('NotesState export and import edge cases', () {
    test('export slugs the title and rejects exotic characters', () async {
      final native = RecordingNotesBinding();
      final state = buildState(native: native);
      await state.load();

      final note = state.createNote(title: 'Äöü  --  Meeting!!!  ');
      state.updateContent(note.id, body: 'agenda');

      await state.exportSelected();

      expect(native.exportFileNames.single, 'meeting.md');
    });

    test('export of an all-symbol title falls back to note.md', () async {
      final native = RecordingNotesBinding();
      final state = buildState(native: native);
      await state.load();

      state.createNote(title: '!!!');

      await state.exportSelected();

      expect(native.exportFileNames.single, 'note.md');
    });

    test('import strips .md, keeps other extensions, guards empty names',
        () async {
      final native = RecordingNotesBinding();
      final state = buildState(native: native);
      await state.load();

      native.nextImport = const ImportedFile(
        fileName: 'recipes.txt',
        content: 'pancakes',
      );
      await state.importNote();
      expect(state.selectedNote?.title, 'recipes');

      native.nextImport = const ImportedFile(
        fileName: '.md',
        content: 'edge',
      );
      await state.importNote();
      // '.md'.substring(0, len-3) is empty -> 'Imported note'.
      expect(state.selectedNote?.title, 'Imported note');
    });
  });

  group('NotesState filtering', () {
    test('filter matches titles and bodies, case-insensitively', () async {
      final state = buildState();
      await state.load();

      state.setFilter('OAT MILK');
      expect(state.notes.single.id, 'note-3'); // body match

      state.setFilter('roadmap');
      expect(state.notes.single.id, 'note-2'); // title match

      state.setFilter('');
      expect(state.notes, hasLength(Note.seedLibrary.length));
    });
  });

  group('NotesState corrupt payloads', () {
    test('a JSON object (not a list) starts from an empty store', () async {
      final storage = InMemorySecureStorage();
      await storage.write(yawalaStorageKey('notes.repo.v1'), '{"id": "x"}');

      final state = NotesState(
        native: RecordingNotesBinding(),
        storage: storage,
      );
      await state.load();

      expect(state.allNotes, isEmpty);
      expect(state.isLoading, isFalse);
    });

    test('a broken entry inside the list drops the whole payload safely',
        () async {
      final storage = InMemorySecureStorage();
      await storage.write(
        yawalaStorageKey('notes.repo.v1'),
        '[{"id": "ok", "title": "t", "body": "b", "updatedAt": "bad-date"}]',
      );

      final state = NotesState(
        native: RecordingNotesBinding(),
        storage: storage,
      );
      await state.load();

      // 'bad-date' parses to null -> DateTime.now() fallback, so this
      // entry survives.
      expect(state.allNotes, hasLength(1));
    });
  });
}
