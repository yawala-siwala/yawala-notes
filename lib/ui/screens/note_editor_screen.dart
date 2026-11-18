import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:yawala_core/yawala_core.dart';

import '../../native/platform_bindings.dart';
import '../../state/notes_state.dart';

/// Markdown editor with a split (desktop) or tabbed (phone) live preview
/// rendered through the platform markdown bridge.
class NoteEditorScreen extends StatefulWidget {
  const NoteEditorScreen({
    super.key,
    required this.state,
    required this.noteId,
  });

  final NotesState state;
  final String noteId;

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final TextEditingController _title;
  late final TextEditingController _body;

  @override
  void initState() {
    super.initState();
    final note = widget.state.noteById(widget.noteId);
    _title = TextEditingController(text: note?.title ?? '');
    _body = TextEditingController(text: note?.body ?? '');
    _title.addListener(_onChanged);
    _body.addListener(_onChanged);
  }

  void _onChanged() {
    widget.state.updateContent(
      widget.noteId,
      title: _title.text,
      body: _body.text,
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit note'),
          actions: [
            IconButton(
              tooltip: 'Export via platform bridge',
              icon: const Icon(Icons.ios_share),
              onPressed: () => unawaited(widget.state.exportSelected()),
            ),
            IconButton(
              tooltip: 'Delete note',
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                widget.state.deleteNote(widget.noteId);
                Navigator.of(context).pop();
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [Tab(text: 'Editor'), Tab(text: 'Preview')],
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final editor = _buildEditor(context);
            final preview = _buildPreview(context);
            if (constraints.maxWidth >= 800) {
              return Row(
                children: [
                  Expanded(child: editor),
                  const VerticalDivider(width: 1),
                  Expanded(child: preview),
                ],
              );
            }
            return TabBarView(children: [editor, preview]);
          },
        ),
      ),
    );
  }

  Widget _buildEditor(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            YawalaSpacing.lg,
            YawalaSpacing.md,
            YawalaSpacing.lg,
            0,
          ),
          child: TextField(
            controller: _title,
            style: Theme.of(context).textTheme.titleLarge,
            decoration: const InputDecoration(
              hintText: 'Title',
              border: InputBorder.none,
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: TextField(
            controller: _body,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            keyboardType: TextInputType.multiline,
            decoration: const InputDecoration(
              hintText: 'Write markdown here...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(YawalaSpacing.lg),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreview(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        final note = widget.state.noteById(widget.noteId);
        final body = note?.body ?? '';
        if (body.trim().isEmpty) {
          return const Center(
            child: Text('Nothing to preview yet - start typing.'),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(YawalaSpacing.lg),
          child: FutureBuilder<MarkdownPreview>(
            key: ValueKey(body),
            future: widget.state.renderPreview(body),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final preview =
                  snapshot.data ?? MarkdownPreview.fallback(body);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    preview.html,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: YawalaSpacing.md),
                  Chip(
                    label: Text(
                      preview.usedNativeRenderer
                          ? 'Rendered by the native bridge'
                          : 'Rendered by the Dart fallback',
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
