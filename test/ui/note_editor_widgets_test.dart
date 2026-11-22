import 'package:flutter_test/flutter_test.dart';

import 'package:material_ui/material_ui.dart';

import 'package:yawala_core/yawala_core.dart';

import 'package:yawala_notes/domain/model.dart';
import 'package:yawala_notes/native/platform_bindings.dart';
import 'package:yawala_notes/state/notes_state.dart';
import 'package:yawala_notes/ui/screens/home_screen.dart';
import 'package:yawala_notes/ui/screens/note_editor_screen.dart';

NotesState buildState() {
  return NotesState(
    native: const FallbackNotesBinding(),
    storage: InMemorySecureStorage(),
  );
}

void main() {
  testWidgets('wide editor splits editor and live preview side by side',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = buildState();
    await state.load();
    final note = state.allNotes.first;

    await tester.pumpWidget(
      MaterialApp(home: NoteEditorScreen(state: state, noteId: note.id)),
    );
    await tester.pumpAndSettle(); // advances the 250ms preview debounce

    // Split layout: a vertical divider separates editor from preview.
    expect(find.byType(VerticalDivider), findsOneWidget);
    // The fallback binding renders an escaped Dart paragraph.
    expect(find.text('Rendered by the Dart fallback'), findsOneWidget);

    // Typing updates the preview once the debounce settles.
    await tester.enterText(find.byType(TextField).last, 'fresh markdown');
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.textContaining('fresh markdown'), findsWidgets);
  });

  testWidgets('narrow editor uses tabs and shows the preview on demand',
      (tester) async {
    tester.view.physicalSize = const Size(500, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = buildState();
    await state.load();
    final note = state.allNotes.first;

    await tester.pumpWidget(
      MaterialApp(home: NoteEditorScreen(state: state, noteId: note.id)),
    );
    await tester.pumpAndSettle();

    // Tabbed layout: no divider, and the lazy preview page is not built.
    expect(find.byType(VerticalDivider), findsNothing);
    expect(find.textContaining('<p>'), findsNothing);

    await tester.tap(find.text('Preview'));
    await tester.pumpAndSettle(); // tab switch + debounce + render

    expect(find.textContaining('<p>'), findsOneWidget);
    expect(find.text('Rendered by the Dart fallback'), findsOneWidget);
  });

  testWidgets('empty note shows the preview placeholder, not a crash',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = buildState();
    await state.load();
    final note = state.createNote(); // empty body

    await tester.pumpWidget(
      MaterialApp(home: NoteEditorScreen(state: state, noteId: note.id)),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Nothing to preview yet - start typing.'),
      findsOneWidget,
    );
  });

  testWidgets('home journey: create via FAB, edit, delete from the editor',
      (tester) async {
    tester.view.physicalSize = const Size(500, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = buildState();
    await state.load();

    await tester.pumpWidget(MaterialApp(home: NotesHomeScreen(state: state)));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Yawala Notes'), findsOneWidget);
    expect(find.text('5 notes'), findsOneWidget);

    // FAB creates a note and opens the editor for it.
    await tester.tap(find.byTooltip('New note'));
    await tester.pumpAndSettle();
    expect(find.text('Edit note'), findsOneWidget);
    expect(state.selectedNote?.title, 'Untitled note');

    // Type a title and a body; state persists fire-and-forget.
    await tester.enterText(find.byType(TextField).first, 'Scratch pad');
    await tester.enterText(find.byType(TextField).last, 'idea one');
    await tester.pumpAndSettle();
    expect(state.selectedNote?.title, 'Scratch pad');
    expect(state.selectedNote?.body, 'idea one');

    // Delete from the editor pops back to the home list.
    await tester.tap(find.byTooltip('Delete note'));
    await tester.pumpAndSettle();

    expect(find.text('Edit note'), findsNothing);
    expect(state.noteById(state.selectedNote?.id ?? ''), isNull);
    expect(state.allNotes, hasLength(Note.seedLibrary.length));
    expect(find.text('5 notes'), findsOneWidget);
  });

  testWidgets('home search filters the visible cards and the counter',
      (tester) async {
    tester.view.physicalSize = const Size(500, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = buildState();
    await state.load();

    await tester.pumpWidget(MaterialApp(home: NotesHomeScreen(state: state)));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'groceries');
    await tester.pump();

    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('Welcome to Yawala Notes'), findsNothing);
    expect(find.text('1 notes'), findsOneWidget);
  });
}
