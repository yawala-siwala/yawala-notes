import 'package:material_ui/material_ui.dart';

import '../../domain/model.dart';

/// List row for a single Note.
class NoteCard extends StatelessWidget {
  const NoteCard({super.key, required this.item, this.onTap});

  final Note item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.sticky_note_2),
        title: Text(item.displayName),
        subtitle: Text(item.subtitle),
        trailing: Text(item.meta),
        onTap: onTap,
      ),
    );
  }
}