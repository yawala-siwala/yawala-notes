import 'package:yawala_core/yawala_core.dart';

/// A note stored in the Yawala Notes repository.
class Note {
  const Note({
    required this.id,
    required this.title,
    required this.body,
    required this.updatedAt,
  });

  /// Sample notes used by the boilerplate service until the native storage
  /// layer is wired up through `platform_bindings.dart`.
  static const List<Note> seedLibrary = [
    Note(
      id: 'note-1',
      title: 'Welcome to Yawala Notes',
      body: 'Local-first notes that work across all five platforms.\n\n- one codebase\n- MIT licensed\n- part of the yawala-siwala ecosystem',
      updatedAt: DateTime(2026, 11, 4, 10, 15),
    ),
    Note(
      id: 'note-2',
      title: 'Roadmap',
      body: '1. rich text editing\n2. folders and tags\n3. optional end-to-end sync via yawala-core',
      updatedAt: DateTime(2026, 11, 3, 19, 40),
    ),
    Note(
      id: 'note-3',
      title: 'Groceries',
      body: 'oat milk, sourdough, coffee beans, tomatoes',
      updatedAt: DateTime(2026, 11, 2, 8, 55),
    ),
    Note(
      id: 'note-4',
      title: 'Standup notes',
      body: 'shipped the layout pass; review CI matrix; pair on the sync daemon',
      updatedAt: DateTime(2026, 10, 31, 9, 5),
    ),
    Note(
      id: 'note-5',
      title: 'Books to read',
      body: 'The Design of Everyday Things, Working in Public, A Philosophy of Software Design',
      updatedAt: DateTime(2026, 10, 29, 22, 30),
    ),
  ];

  final String id;
  final String title;
  final String body;
  final DateTime updatedAt;

  String get displayName => title;
  String get subtitle {
    final firstLine = body.isEmpty ? '' : body.split('\n').first;
    return firstLine.length <= 60
        ? firstLine
        : '${firstLine.substring(0, 57)}...';
  }
  String get meta => formatRelative(updatedAt);

  bool matches(String query) =>
      displayName.toLowerCase().contains(query) ||
      body.toLowerCase().contains(query);

  Note copyWith({String? title, String? body, DateTime? updatedAt}) => Note(
        id: id,
        title: title ?? this.title,
        body: body ?? this.body,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  String toString() => 'Note($id, $title)';
}