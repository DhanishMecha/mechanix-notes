part of 'editor_bloc.dart';

enum EditorToolbar { none, textStyle, menu, options }

sealed class EditorState {}

final class EditorInitial extends EditorState {}

final class EditorLoading extends EditorState {}

final class EditorLoaded extends EditorState {
  final String noteId;
  final String title;
  final Document? quillDocument;
  final bool isContentLoading;
  final bool isSaving;
  final EditorToolbar activeToolbar;
  final bool isNewNote;
  final bool isDirty;

  EditorLoaded({
    required this.noteId,
    required this.title,
    this.quillDocument,
    this.isContentLoading = false,
    this.isSaving = false,
    this.activeToolbar = EditorToolbar.none,
    this.isNewNote = false,
    this.isDirty = false,
  });

  EditorLoaded copyWith({
    String? noteId,
    String? title,
    Document? quillDocument,
    bool? isContentLoading,
    bool? isSaving,
    EditorToolbar? activeToolbar,
    bool? isNewNote,
    bool? isDirty,
  }) {
    return EditorLoaded(
      noteId: noteId ?? this.noteId,
      title: title ?? this.title,
      quillDocument: quillDocument ?? this.quillDocument,
      isContentLoading: isContentLoading ?? this.isContentLoading,
      isSaving: isSaving ?? this.isSaving,
      activeToolbar: activeToolbar ?? this.activeToolbar,
      isNewNote: isNewNote ?? this.isNewNote,
      isDirty: isDirty ?? this.isDirty,
    );
  }
}

final class EditorFailure extends EditorState {
  final String message;
  EditorFailure(this.message);
}

final class EditorSaveSuccess extends EditorState {
  final String noteId;
  EditorSaveSuccess(this.noteId);
}

final class EditorDeleteRequest extends EditorState {
  final String noteId;
  EditorDeleteRequest(this.noteId);
}

final class EditorDiscarded extends EditorState {
  final String? noteId;
  EditorDiscarded({this.noteId});
}
