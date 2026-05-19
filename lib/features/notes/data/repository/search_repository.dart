import 'package:mechanix_notes/features/notes/data/models/note_metadata.dart';

abstract class SearchRepository {
  Future<List<NoteMetaData>> searchNotes(String query);
}
