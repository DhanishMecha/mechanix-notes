import 'package:mechanix_notes/features/notes/data/models/note_model.dart';

abstract class EditorRepository {
  Future<NoteModel?> getNoteById(String id);

  Future<void> createNote(NoteModel note);

  Future<void> updateNote(NoteModel note);

}
