import 'package:mechanix_notes/features/notes/data/models/note_metadata.dart';

class GroupedNotes {
  final String label; // e.g. "This Month", "August 2025"
  final List<NoteMetaData> notes; // Notes in the group
  final double height; // Height of the group
  GroupedNotes({
    required this.label,
    required this.notes,
    required this.height,
  });
}
