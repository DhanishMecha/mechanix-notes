import 'package:equatable/equatable.dart';
import 'package:mechanix_notes/features/notes/data/models/note_metadata.dart';

class NotesState extends Equatable {
  final List<NoteMetaData> notes;
  final List<Object> groupedNotes;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? error;
  final String localized;

  static const int pageSize = 20;

  const NotesState({
    this.notes = const [],
    this.groupedNotes = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.error,
    this.localized = 'en',
  });

  NotesState copyWith({
    List<NoteMetaData>? notes,
    List<Object>? groupedNotes,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? error,
    String? localized,
  }) {
    return NotesState(
      notes: notes ?? this.notes,
      groupedNotes: groupedNotes ?? this.groupedNotes,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
      localized: localized ?? this.localized,
    );
  }

  @override
  List<Object?> get props => [
    notes,
    groupedNotes,
    isLoading,
    isLoadingMore,
    hasMore,
    currentPage,
    error,
    localized,
  ];
}
