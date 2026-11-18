import 'package:flutter_test/flutter_test.dart';

import 'package:yawala_core/yawala_core.dart';

import 'package:yawala_notes/domain/model.dart';
import 'package:yawala_notes/native/platform_bindings.dart';
import 'package:yawala_notes/state/notes_state.dart';

/// Scriptable native binding for state tests.
class FakeNotesBinding implements NotesNativeBinding {
  ImportedFile? nextImport;
  String? nextExportPath = '/tmp/export.md';

  @override
  Future<String?> exportNote({
    required String fileName,
    required String content,
  }) async =>
      nextExportPath;

  @override
  Future<ImportedFile?> importNoteFile() async => nextImport;

  @override
  Future<MarkdownPreview> renderMarkdown(String source) async {
    return MarkdownPreview(html: '<p>native</p>', usedNativeRenderer: true);
  }
}

NotesState buildState({FakeNotesBinding? native, SecureStorage? storage}) {
  return NotesState(
    native: native ?? FakeNotesBinding(),
    storage: storage ?? InMemorySecureStorage(),
  );
}

void main() {
  group('NotesState persistence', () {
    test('seeds the sample library on first run', () async {
      final state = buildState();
      await state.load();

      expect(state.isLoading, isFalse);
      expect(state.allNotes, isNotEmpty);
      expect(state.noteById('note-1'), isNotNull);
    });

    test('round-trips mutations through secure storage', () async {
      final storage = InMemorySecureStorage();
      final state = buildState(storage: storage);
      await state.load();

      final note = state.createNote(title: 'Scratch');
      state.updateContent(note.id, body: 'hello **world**');
      await pumpEventQueue(); // persistence is fire-and-forget

      final raw = await storage.read(yawalaStorageKey('notes.repo.v1'));
      expect(raw, contains('hello **world**'));

      // A fresh state over the same storage restores the edits.
      final restored = buildState(storage: storage);
      await restored.load();
      final restoredNote = restored.noteById(note.id);
      expect(restoredNote?.title, 'Scratch');
      expect(restoredNote?.body, 'hello **world**');
    });

    test('corrupt payloads fall back to an empty store', () async {
      final storage = InMemorySecureStorage();
      await storage.write(
        yawalaStorageKey('notes.repo.v1'),
        'not-json-at-all',
      );

      final state = buildState(storage: storage);
      await state.load();

      expect(state.allNotes, isEmpty);
    });

    test('deleteNote removes it and clears the selection', () async {
      final state = buildState();
      await state.load();

      final note = state.createNote(title: 'Doomed');
      expect(state.selectedNote?.id, note.id);

      state.deleteNote(note.id);

      expect(state.noteById(note.id), isNull);
      expect(state.selectedNote, isNull);
    });
  });

  group('NotesState filtering and lookup', () {
    test('setFilter matches titles, sorted newest first', () async {
      final state = buildState();
      await state.load();

      state.setFilter('WELCOME');
      final results = state.notes;

      expect(results, hasLength(1));
      expect(results.single.id, 'note-1');

      // Sorted newest first across the unfiltered set.
      state.setFilter('');
      final all = state.notes;
      for (var i = 0; i < all.length - 1; i++) {
        expect(
          all[i].updatedAt.isAfter(all[i + 1].updatedAt) ||
              all[i].updatedAt.isAtSameMomentAs(all[i + 1].updatedAt),
          isTrue,
        );
      }
    });

    test('noteById returns null for unknown ids', () async {
      final state = buildState();
      await state.load();

      expect(state.noteById('nope'), isNull);
    });
  });

  group('NotesState native bridge', () {
    test('exportSelected delegates to the bridge', () async {
      final native = FakeNotesBinding();
      final state = buildState(native: native);
      await state.load();

      final note = state.createNote(title: 'Standup Notes');
      state.updateContent(note.id, body: 'shipped the layout pass');

      final path = await state.exportSelected();

      expect(path, '/tmp/export.md');
    });

    test('exportSelected returns null when nothing is selected', () async {
      final state = buildState();
      await state.load();

      expect(await state.exportSelected(), isNull);
    });

    test('importNote stores the imported file as a new note', () async {
      final native = FakeNotesBinding()
        ..nextImport = const ImportedFile(
          fileName: 'groceries.md',
          content: '- oat milk',
        );
      final state = buildState(native: native);
      await state.load();

      final file = await state.importNote();

      expect(file, isNotNull);
      final imported = state.selectedNote;
      expect(imported?.title, 'groceries');
      expect(imported?.body, '- oat milk');
    });

    test('importNote returns null when the bridge cancels', () async {
      final native = FakeNotesBinding()..nextImport = null;
      final state = buildState(native: native);
      await state.load();

      expect(await state.importNote(), isNull);
    });

    test('renderPreview routes through the markdown bridge', () async {
      final state = buildState();
      await state.load();

      final preview = await state.renderPreview('# heading');

      expect(preview.usedNativeRenderer, isTrue);
      expect(preview.html, '<p>native</p>');
    });
  });

  group('NotesState fallback bridge', () {
    test('export/import degrade to null; preview escapes HTML', () async {
      final state = NotesState(
        native: const FallbackNotesBinding(),
        storage: InMemorySecureStorage(),
      );
      await state.load();
      state.createNote(title: 'Plain');

      expect(await state.exportSelected(), isNull);
      expect(await state.importNote(), isNull);

      final preview = await state.renderPreview('<b>bold</b>');
      expect(preview.usedNativeRenderer, isFalse);
      expect(preview.html, '<p>&lt;b&gt;bold&lt;/b&gt;</p>');
    });
  });

  group('Note model compatibility', () {
    test('seed library remains available for first-run seeding', () {
      expect(Note.seedLibrary, isNotEmpty);
    });
  });
}
