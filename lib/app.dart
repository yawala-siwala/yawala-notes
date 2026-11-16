import 'package:material_ui/material_ui.dart';

import 'package:yawala_core/yawala_core.dart';

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
      theme: buildYawalaTheme(seedColor: YawalaColors.notes),
      darkTheme: buildYawalaTheme(
        brightness: Brightness.dark,
        seedColor: YawalaColors.notes,
      ),
      themeMode: ThemeMode.system,
      home: NotesHomeScreen(state: state),
    );
  }
}
