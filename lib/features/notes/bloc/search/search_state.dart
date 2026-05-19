import 'package:equatable/equatable.dart';
import 'package:mechanix_notes/features/notes/data/models/note_metadata.dart';

enum SearchStatus { initial, loading, success, failure }

class SearchState extends Equatable {
  final SearchStatus status;
  final List<NoteMetaData> results;
  final List<NoteMetaData> allFilteredNotes;
  final String query;
  final bool hasMore;
  final int currentPage;
  final bool isLoadingMore;

  static const int pageSize = 20;

  const SearchState({
    this.status = SearchStatus.initial,
    this.results = const [],
    this.allFilteredNotes = const [],
    this.query = '',
    this.hasMore = false,
    this.currentPage = 0,
    this.isLoadingMore = false,
  });

  SearchState copyWith({
    SearchStatus? status,
    List<NoteMetaData>? results,
    List<NoteMetaData>? allFilteredNotes,
    String? query,
    bool? hasMore,
    int? currentPage,
    bool? isLoadingMore,
  }) {
    return SearchState(
      status: status ?? this.status,
      results: results ?? this.results,
      allFilteredNotes: allFilteredNotes ?? this.allFilteredNotes,
      query: query ?? this.query,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [
    status,
    results,
    allFilteredNotes,
    query,
    hasMore,
    currentPage,
    isLoadingMore,
  ];
}
