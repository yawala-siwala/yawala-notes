import 'package:flutter_test/flutter_test.dart';

import 'package:yawala_notes/domain/model.dart';

void main() {
  group('Note', () {
    test('sample data is not empty', () {
      expect(Note.seedLibrary, isNotEmpty);
    });

    test('matches humanised labels', () {
      for (final item in Note.seedLibrary) {
        expect(item.matches(item.displayName.toLowerCase()), isTrue);
      }
    });
  });
}