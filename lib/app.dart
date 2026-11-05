import 'package:flutter/material.dart';

import 'state/app_state.dart';
import 'ui/screens/home_screen.dart';

/// Root widget for Yawala Notes.
class YawalaApp extends StatelessWidget {
  const YawalaApp({super.key, required this.state});

  final NotesState state;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yawala Notes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8A6D3B),
        ),
      ),
      home: NotesHomeScreen(state: state),
    );
  }
}