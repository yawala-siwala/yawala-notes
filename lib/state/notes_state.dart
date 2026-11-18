import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:yawala_core/yawala_core.dart';

import '../domain/model.dart';
import '../native/platform_bindings.dart';

/// Reactive state machine for Yawala Notes.
///
/// Local CRUD with JSON persistence through core's [SecureStorage],
/// platform export/import through the notes native bridge, and on-demand
/// markdown rendering. Mutations are synchronous so the UI can navigate
/// immediately; persistence runs fire-and-forget (the gateway never
/// throws and storage failures are logged by core).
class NotesState extends ChangeNotifier {
  NotesState({
    required NotesNativeBinding native,
    required SecureStorage storage,
  })  : _native = native,
        _storage = storage;

  static String get _repoKey => yawalaStorageKey('notes.repo.v1');

  final NotesNativeBinding _native;
  final SecureStorage _storage;

  List<Note> _notes = const <Note>[];
  String _filter = '';
  String? _selectedId;
  bool _isLoading = false;

  /// Every stored note, in insertion order.
  List<Note> get allNotes => List.unmodifiable(_notes);

  /// Notes matching the current filter, newest first.
  List<Note> get notes {
    final filtered = _filter.isEmpty
        ? _notes
        : _notes.where((note) => note.matches(_filter)).toList(growable: false);
    final sorted = [...filtered]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List.unmodifiable(sorted);
  }

  Note? get selectedNote => _selectedId == null ? null : noteById(_selectedId!);
  bool get isLoading => _isLoading;
  String get filter => _filter;

  /// Looks a note up by id.
  Note? noteById(String id) {
    for (final note in _notes) {
      if (note.id == id) {
        return note;
      }
    }
    return null;
  }

  /// Marks [id] as the note shown in the editor.
  void select(String? id) {
    _selectedId = id;
    notifyListeners();
  }

  /// Loads the repository from secure storage; on first run (or after a
  /// corrupt payload) the sample library seeds the store.
  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    final raw = await _storage.read(_repoKey);
    if (raw == null) {
      _notes = List.of(Note.seedLibrary);
      await _persist();
    } else {
      _notes = _decode(raw);
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Creates an empty note, selects it and returns it.
  Note createNote({String title = 'Untitled note'}) {
    final note = Note(
      id: 'note-${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      body: '',
      updatedAt: DateTime.now(),
    );
    _notes = [note, ..._notes];
    _selectedId = note.id;
    unawaited(_persist());
    notifyListeners();
    return note;
  }

  /// Updates title and/or body, bumping the note's timestamp.
  void updateContent(String id, {String? title, String? body}) {
    _notes = [
      for (final note in _notes)
        if (note.id == id)
          note.copyWith(
            title: title,
            body: body,
            updatedAt: DateTime.now(),
          )
        else
          note,
    ];
    unawaited(_persist());
    notifyListeners();
  }

  /// Removes a note and clears the selection when needed.
  void deleteNote(String id) {
    _notes = _notes.where((note) => note.id != id).toList(growable: false);
    if (_selectedId == id) {
      _selectedId = null;
    }
    unawaited(_persist());
    notifyListeners();
  }

  /// Updates the search filter applied to [notes].
  void setFilter(String value) {
    _filter = value.trim().toLowerCase();
    notifyListeners();
  }

  /// Exports the selected note through the native bridge; returns the
  /// chosen destination path or null when cancelled/unsupported.
  Future<String?> exportSelected() async {
    final note = selectedNote;
    if (note == null) {
      return null;
    }
    return _native.exportNote(
      fileName: '${_slug(note.title)}.md',
      content: note.body,
    );
  }

  /// Imports a note file through the native bridge and stores it as a new
  /// note. Returns null when cancelled/unsupported.
  Future<ImportedFile?> importNote() async {
    final file = await _native.importNoteFile();
    if (file == null) {
      return null;
    }
    final title = file.fileName.endsWith('.md')
        ? file.fileName.substring(0, file.fileName.length - 3)
        : file.fileName;
    final note = Note(
      id: 'note-${DateTime.now().microsecondsSinceEpoch}',
      title: title.isEmpty ? 'Imported note' : title,
      body: file.content,
      updatedAt: DateTime.now(),
    );
    _notes = [note, ..._notes];
    _selectedId = note.id;
    unawaited(_persist());
    notifyListeners();
    return file;
  }

  /// Renders [body] through the platform markdown bridge (falls back to an
  /// escaped Dart paragraph on unsupported platforms).
  Future<MarkdownPreview> renderPreview(String body) =>
      _native.renderMarkdown(body);

  Future<void> _persist() {
    return _storage.write(
      _repoKey,
      jsonEncode([
        for (final note in _notes)
          {
            'id': note.id,
            'title': note.title,
            'body': note.body,
            'updatedAt': note.updatedAt.toIso8601String(),
          },
      ]),
    );
  }

  List<Note> _decode(String raw) {
    try {
      final data = jsonDecode(raw) as List<dynamic>;
      return [
        for (final item in data)
          Note(
            id: (item as Map<String, dynamic>)['id'] as String,
            title: item['title'] as String? ?? 'Untitled note',
            body: item['body'] as String? ?? '',
            updatedAt:
                DateTime.tryParse(item['updatedAt'] as String? ?? '') ??
                    DateTime.now(),
          ),
      ];
    } on FormatException catch (error, stackTrace) {
      YawalaLog.warning(
        'corrupt notes payload - starting from an empty store',
        context: 'notes.state',
        error: error,
        stackTrace: stackTrace,
      );
      return const <Note>[];
    } on TypeError catch (error, stackTrace) {
      YawalaLog.warning(
        'corrupt notes payload - starting from an empty store',
        context: 'notes.state',
        error: error,
        stackTrace: stackTrace,
      );
      return const <Note>[];
    }
  }

  String _slug(String input) {
    final slug = input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.isEmpty ? 'note' : slug;
  }
}
