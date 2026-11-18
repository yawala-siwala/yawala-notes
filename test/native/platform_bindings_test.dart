import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:yawala_notes/native/platform_bindings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final binding = MethodChannelNotesBinding();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(notesChannel, null);
  });

  group('MethodChannelNotesBinding with a live native handler', () {
    test('exportNote returns the chosen destination path', () async {
      messenger.setMockMethodCallHandler(notesChannel, (call) async {
        expect(call.method, 'exportNote');
        final args = call.arguments as Map<Object?, Object?>;
        expect(args['fileName'], 'standup.md');
        return '/home/yawala/exports/standup.md';
      });

      final path = await binding.exportNote(
        fileName: 'standup.md',
        content: '# standup\nshipped the layout pass',
      );

      expect(path, '/home/yawala/exports/standup.md');
    });

    test('importNoteFile maps the imported payload', () async {
      messenger.setMockMethodCallHandler(notesChannel, (call) async {
        return {'fileName': 'groceries.md', 'content': '- oat milk'};
      });

      final imported = await binding.importNoteFile();

      expect(imported?.fileName, 'groceries.md');
      expect(imported?.content, '- oat milk');
    });

    test('renderMarkdown maps the native renderer output', () async {
      messenger.setMockMethodCallHandler(notesChannel, (call) async {
        return {
          'html': '<h1>standup</h1>',
          'usedNativeRenderer': true,
        };
      });

      final preview = await binding.renderMarkdown('# standup');

      expect(preview.html, '<h1>standup</h1>');
      expect(preview.usedNativeRenderer, isTrue);
    });
  });

  group('channel invocation safety (no native handler registered)', () {
    test('export/import degrade to null (treated as cancelled)', () async {
      expect(
        await binding.exportNote(fileName: 'a.md', content: 'x'),
        isNull,
      );
      expect(await binding.importNoteFile(), isNull);
    });

    test('renderMarkdown falls back to an escaped Dart paragraph',
        () async {
      final preview = await binding.renderMarkdown('<b>bold</b> & more');

      expect(preview.usedNativeRenderer, isFalse);
      expect(
        preview.html,
        '<p>&lt;b&gt;bold&lt;/b&gt; &amp; more</p>',
      );
    });
  });

  group('FallbackNotesBinding', () {
    const fallback = FallbackNotesBinding();

    test('mirrors the safe fallbacks', () async {
      expect(
        await fallback.exportNote(fileName: 'a.md', content: 'x'),
        isNull,
      );
      expect(await fallback.importNoteFile(), isNull);

      final preview = await fallback.renderMarkdown('<i>hi</i>');
      expect(preview.usedNativeRenderer, isFalse);
      expect(preview.html, '<p>&lt;i&gt;hi&lt;/i&gt;</p>');
    });
  });
}
