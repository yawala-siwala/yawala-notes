import 'package:flutter/services.dart';

import 'package:yawala_core/yawala_core.dart';

/// Native contract for Yawala Notes.
///
/// Channel: `com.yawalasiwala/notes`
///
/// | Method | Purpose | Android | iOS | Desktop |
/// | --- | --- | --- | --- | --- |
/// | `exportNote` | Secure local file export (user-chosen destination) | SAF ACTION_CREATE_DOCUMENT | UIDocumentPicker (export) | NSSavePanel / IFileSaveDialog / portal |
/// | `importNoteFile` | Secure local file import (user-chosen source) | SAF ACTION_OPEN_DOCUMENT | UIDocumentPicker (import) | NSOpenPanel / IFileOpenDialog / portal |
/// | `renderMarkdown` | Native markdown rendering bridge (attributed strings) | Spannable/Markwon-class | NSAttributedString | platform text stack |
///
/// Every call goes through [NativeChannelGateway] and therefore resolves to
/// safe fallbacks instead of throwing on platforms without a handler.
const MethodChannel notesChannel = MethodChannel('com.yawalasiwala/notes');

/// A markdown source imported from the host platform.
class ImportedFile {
  const ImportedFile({
    required this.fileName,
    required this.content,
  });

  factory ImportedFile.fromMap(Map<Object?, Object?>? map) {
    return ImportedFile(
      fileName: (map?['fileName'] as String?) ?? 'imported.md',
      content: (map?['content'] as String?) ?? '',
    );
  }

  final String fileName;
  final String content;
}

/// Result of a native markdown render bridge.
class MarkdownPreview {
  const MarkdownPreview({
    required this.html,
    required this.usedNativeRenderer,
  });

  /// Dart-side fallback used when the platform has no renderer: a minimal
  /// escaped paragraph so no input is ever rendered as raw HTML.
  static MarkdownPreview fallback(String source) {
    return MarkdownPreview(
      html: '<p>${escapeHtml(source)}</p>',
      usedNativeRenderer: false,
    );
  }

  final String html;
  final bool usedNativeRenderer;
}

/// Escapes HTML-sensitive characters for the fallback renderer.
String escapeHtml(String input) {
  return input
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}

/// Contract every platform host implements for Yawala Notes.
abstract interface class NotesNativeBinding {
  /// Exports [content] to a user-chosen destination; returns the chosen
  /// file path or `null` when the user cancelled the dialog.
  Future<String?> exportNote({
    required String fileName,
    required String content,
  });

  /// Imports a note file chosen by the user; returns `null` when cancelled
  /// or unsupported.
  Future<ImportedFile?> importNoteFile();

  /// Renders [source] through the platform markdown bridge; falls back to
  /// an escaped Dart-side paragraph on unsupported platforms.
  Future<MarkdownPreview> renderMarkdown(String source);
}

/// Real implementation that speaks to the host platform over
/// [notesChannel], mapping failures to safe fallbacks.
class MethodChannelNotesBinding implements NotesNativeBinding {
  MethodChannelNotesBinding({MethodChannel? channel})
      : _gateway = NativeChannelGateway(
          channel: channel ?? notesChannel,
          context: 'notes.native',
        );

  final NativeChannelGateway _gateway;

  @override
  Future<String?> exportNote({
    required String fileName,
    required String content,
  }) async {
    final result = await _gateway.invoke<String>('exportNote',
        <String, Object?>{'fileName': fileName, 'content': content});
    return result.fold(
      ok: (path) => path,
      err: (_, __) => null,
    );
  }

  @override
  Future<ImportedFile?> importNoteFile() async {
    final result = await _gateway.invoke<Map<Object?, Object?>>(
      'importNoteFile',
    );
    return result.fold(
      ok: (data) => data == null ? null : ImportedFile.fromMap(data),
      err: (_, __) => null,
    );
  }

  @override
  Future<MarkdownPreview> renderMarkdown(String source) async {
    final result = await _gateway.invoke<Map<Object?, Object?>>(
      'renderMarkdown',
      <String, Object?>{'source': source},
    );
    return result.fold(
      ok: (data) => MarkdownPreview(
        html: (data?['html'] as String?) ??
            '<p>${escapeHtml(source)}</p>',
        usedNativeRenderer: (data?['usedNativeRenderer'] as bool?) ?? false,
      ),
      err: (_, __) => MarkdownPreview.fallback(source),
    );
  }
}

/// No-op implementation for tests and platforms without any native host.
class FallbackNotesBinding implements NotesNativeBinding {
  const FallbackNotesBinding();

  @override
  Future<String?> exportNote({
    required String fileName,
    required String content,
  }) async =>
      null;

  @override
  Future<ImportedFile?> importNoteFile() async => null;

  @override
  Future<MarkdownPreview> renderMarkdown(String source) async =>
      MarkdownPreview.fallback(source);
}

/// Boots the platform binding for the current OS.
NotesNativeBinding bootNotesNative() => MethodChannelNotesBinding();
