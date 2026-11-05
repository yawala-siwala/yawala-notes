import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'state/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final state = NotesState(service: NotesService());
  unawaited(state.reload());
  runApp(YawalaApp(state: state));
}