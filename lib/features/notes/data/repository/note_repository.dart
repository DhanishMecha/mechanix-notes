import 'package:mechanix_notes/features/notes/data/models/note_metadata.dart';

abstract class NoteRepository {
  Future<List<NoteMetaData>> getAllNotes();
}
