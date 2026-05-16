import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mechanix_notes/core/utils/app_logger.dart';
import 'package:mechanix_notes/features/notes/bloc/notes/notes_event.dart';
import 'package:mechanix_notes/features/notes/bloc/notes/notes_state.dart';
import 'package:mechanix_notes/features/notes/data/models/note_metadata.dart';
import 'package:mechanix_notes/features/notes/data/repository/note_repository.dart';

class NotesBloc extends Bloc<NotesEvent, NotesState> {
  final NoteRepository noteRepository;

  NotesBloc({required this.noteRepository}) : super(const NotesState()) {
    on<LoadNotes>(_loadNotes);
    on<LoadMoreNotes>(_loadMoreNotes);
    on<RefreshNote>(_refreshNote);
    on<DeleteNotes>(_deleteNotes);
    on<ToggleSelectionMode>(_toggleSelectionMode);
    on<ToggleNoteSelection>(_toggleNoteSelection);
    on<SelectAllNotes>(_selectAllNotes);
    on<ClearSelection>(_clearSelection);

    add(LoadNotes());
  }

  Future<void> _loadNotes(LoadNotes event, Emitter<NotesState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    AppLogger.i("Loading notes");

    try {
      final allNotes = await noteRepository.getAllNotes();
      final firstPage = allNotes.take(NotesState.pageSize).toList();
      final flattened = _buildFlattenedNotes(firstPage);
      final hasMore = allNotes.length > NotesState.pageSize;

      AppLogger.i(
        "Notes loaded — ${allNotes.length} total, showing ${firstPage.length}",
      );
      emit(
        state.copyWith(
          notes: allNotes,
          groupedNotes: flattened,
          isLoading: false,
          hasMore: hasMore,
          currentPage: 0,
        ),
      );
    } catch (e) {
      AppLogger.e("Error loading notes: $e");
      emit(
        state.copyWith(
          isLoading: false,
          error: "Failed to load notes. Please try again.",
        ),
      );
    }
  }

  Future<void> _loadMoreNotes(
    LoadMoreNotes event,
    Emitter<NotesState> emit,
  ) async {
    try {
      if (state.isLoadingMore || !state.hasMore) return;
      AppLogger.i("Loading more notes");
      emit(state.copyWith(isLoadingMore: true));
      // find currentCount of total notes
      final currentCount = state.groupedNotes.whereType<NoteMetaData>().length;

      final newBatch = state.notes
          .skip(currentCount)
          .take(NotesState.pageSize)
          .toList();

      if (newBatch.isEmpty) {
        emit(state.copyWith(isLoadingMore: false, hasMore: false));
        return;
      }

      final lastNote = state.groupedNotes.whereType<NoteMetaData>().last;
      final lastLabel = _getTimeLabelForNote(lastNote);
      final newEntries = _buildFlattenedNotes(
        newBatch,
        existingLabel: lastLabel,
      );

      emit(
        state.copyWith(
          groupedNotes: [...state.groupedNotes, ...newEntries],
          isLoadingMore: false,
          hasMore: newBatch.length == NotesState.pageSize,
          currentPage: state.currentPage + 1,
        ),
      );
    } catch (e) {
      AppLogger.e("Error loading more notes: $e");
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  List<Object> _buildFlattenedNotes(
    List<NoteMetaData> notes, {
    String? existingLabel,
  }) {
    if (notes.isEmpty) return [];

    final List<Object> flattened = [];
    String? currentLabel = existingLabel;

    for (final note in notes) {
      final label = _getTimeLabelForNote(note);
      if (label != currentLabel) {
        flattened.add(label);
        currentLabel = label;
      }
      flattened.add(note);
    }

    return flattened;
  }

  Future<void> _refreshNote(RefreshNote event, Emitter<NotesState> emit) async {
    try {
      AppLogger.i("Refreshing note ${event.noteId}");
      final updatedNote = await noteRepository.getNoteById(event.noteId);
      if (updatedNote == null) return;
      final label = _getTimeLabelForNote(updatedNote);

      if (label != "Recent") return;
      emit(state.copyWith(isRefreshed: false));

      // Remove old entry and insert updated note at top (most recently updated)
      final updatedNotes = [
        updatedNote,
        ...state.notes.where((n) => n.id != event.noteId),
      ];

      // Reset pagination to first page only
      final firstPage = updatedNotes.take(NotesState.pageSize).toList();
      final flattened = _buildFlattenedNotes(firstPage);
      final hasMore = updatedNotes.length > NotesState.pageSize;

      AppLogger.i("Refreshing note completed ");

      emit(
        state.copyWith(
          notes: updatedNotes,
          groupedNotes: flattened,
          hasMore: hasMore,
          currentPage: 0,
          isRefreshed: true,
        ),
      );
    } catch (e) {
      AppLogger.e("Error refreshing note: $e");
    }
  }

  Future<void> _deleteNotes(DeleteNotes event, Emitter<NotesState> emit) async {
    try {
      emit(state.copyWith(isRefreshed: false));

      final selectedNotes = state.isSelectionMode
          ? List<String>.from(state.selectedNotes)
          : event.noteIds ?? [];

      AppLogger.i("Deleting notes: total notes ${state.notes.length}");

      if (selectedNotes.isEmpty) return;

      await noteRepository.deleteNotes(selectedNotes);
      final updatedNotes = state.notes
          .where((n) => !selectedNotes.contains(n.id))
          .toList();

      final firstPage = updatedNotes.take(NotesState.pageSize).toList();
      final flattened = _buildFlattenedNotes(firstPage);
      final hasMore = updatedNotes.length > NotesState.pageSize;

      AppLogger.i("Notes deleted — ${updatedNotes.length} notes remaining");

      emit(
        state.copyWith(
          notes: updatedNotes,
          groupedNotes: flattened,
          hasMore: hasMore,
          currentPage: 0,
          selectedNotes: const [],
          isSelectionMode: false,
          isRefreshed: true,
        ),
      );
    } catch (e) {
      AppLogger.e("Error deleting notes: $e");
      emit(state.copyWith(error: "Failed to delete notes. Please try again."));
    }
  }

  void _toggleSelectionMode(
    ToggleSelectionMode event,
    Emitter<NotesState> emit,
  ) {
    emit(
      state.copyWith(
        isSelectionMode: !state.isSelectionMode,
        selectedNotes: state.isSelectionMode ? const [] : state.selectedNotes,
      ),
    );
  }

  void _toggleNoteSelection(
    ToggleNoteSelection event,
    Emitter<NotesState> emit,
  ) {
    final selected = List<String>.from(state.selectedNotes);
    if (selected.contains(event.noteId)) {
      selected.remove(event.noteId);
    } else {
      selected.add(event.noteId);
    }

    final isSelectionMode = state.isSelectionMode || selected.isNotEmpty;

    emit(
      state.copyWith(selectedNotes: selected, isSelectionMode: isSelectionMode),
    );
  }

  void _selectAllNotes(SelectAllNotes event, Emitter<NotesState> emit) {
    final paginatedNoteIds = state.groupedNotes
        .whereType<NoteMetaData>()
        .map((n) => n.id)
        .toList();
    if (state.selectedNotes.length == paginatedNoteIds.length) {
      emit(state.copyWith(selectedNotes: const [], isSelectionMode: false));
    } else {
      emit(
        state.copyWith(selectedNotes: paginatedNoteIds, isSelectionMode: true),
      );
    }
  }

  void _clearSelection(ClearSelection event, Emitter<NotesState> emit) {
    emit(state.copyWith(selectedNotes: const [], isSelectionMode: false));
  }

  String _getTimeLabelForNote(NoteMetaData note) {
    final now = DateTime.now();
    final updated = note.updatedAt;
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(updated.year, updated.month, updated.day);
    final daysAgo = today.difference(dateOnly).inDays;
    final hoursAgo = now.difference(updated).inHours;

    final time = switch (true) {
      _ when hoursAgo < 2 => "Recent",
      _ when daysAgo == 0 => "Today",
      _ when daysAgo <= 7 => "Last 7 Days",
      _ when daysAgo <= 30 => "Last Month",
      _ => DateFormat("MMMM yyyy", state.localized).format(updated),
    };

    AppLogger.i("Time label for note ${note.id}: $time $updated");
    return time;
  }
}
