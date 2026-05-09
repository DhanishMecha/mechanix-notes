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

  String _getTimeLabelForNote(NoteMetaData note) {
    final now = DateTime.now();
    final updated = note.updatedAt;
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(updated.year, updated.month, updated.day);
    final daysAgo = today.difference(dateOnly).inDays;

    final thisWeekStart = today.subtract(Duration(days: now.weekday - 1));
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
    final thisMonthStart = DateTime(now.year, now.month);
    final lastMonthStart = DateTime(now.year, now.month - 1);

    return switch (true) {
      _ when now.difference(updated).inHours < 1 => "Recent",
      _ when daysAgo == 0 => "Today",
      _ when daysAgo == 1 => "Yesterday",
      _ when !dateOnly.isBefore(thisWeekStart) => "This Week",
      _ when !dateOnly.isBefore(lastWeekStart) => "Last Week",
      _ when !dateOnly.isBefore(thisMonthStart) => "This Month",
      _ when !dateOnly.isBefore(lastMonthStart) => "Last Month",
      _ => DateFormat("MMMM yyyy", state.localized).format(updated),
    };
  }
}
