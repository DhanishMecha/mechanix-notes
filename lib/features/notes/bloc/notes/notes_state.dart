import 'package:equatable/equatable.dart';
import 'package:mechanix_notes/features/notes/data/models/note_metadata.dart';
import 'package:mechanix_notes/core/utils/enums.dart';

class NotesState extends Equatable {
  final List<NoteMetaData> notes;
  final List<Object> groupedNotes;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final ErrorCategory? error;
  final String localized;
  final bool isRefreshed;
  final bool isSelectionMode;
  final List<String> selectedNotes;

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
    this.isRefreshed = false,
    this.isSelectionMode = false,
    this.selectedNotes = const [],
  });

  NotesState copyWith({
    List<NoteMetaData>? notes,
    List<Object>? groupedNotes,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    ErrorCategory? error,
    String? localized,
    bool? isRefreshed,
    bool? isSelectionMode,
    List<String>? selectedNotes,
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
      isRefreshed: isRefreshed ?? false,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      selectedNotes: selectedNotes ?? this.selectedNotes,
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
    isRefreshed,
    isSelectionMode,
    selectedNotes,
  ];
}
