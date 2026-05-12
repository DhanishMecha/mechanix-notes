abstract class NotesEvent {}

class LoadNotes extends NotesEvent {}

class LoadMoreNotes extends NotesEvent {}

class RefreshNote extends NotesEvent {
  final String noteId;
  RefreshNote({required this.noteId});
}

class DeleteNote extends NotesEvent {
  final String noteId;
  DeleteNote({required this.noteId});
}
