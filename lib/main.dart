import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:yawala_core/yawala_core.dart';

import 'app.dart';
import 'native/platform_bindings.dart';
import 'state/notes_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final state = NotesState(
    native: bootNotesNative(),
    storage: InMemorySecureStorage(),
  );
  unawaited(state.load());
  runApp(YawalaApp(state: state));
}
