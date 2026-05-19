import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_notes/core/utils/app_logger.dart';
import 'package:mechanix_notes/features/notes/bloc/search/search_event.dart';
import 'package:mechanix_notes/features/notes/bloc/search/search_state.dart';
import 'package:mechanix_notes/features/notes/data/repository/search_repository.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchRepository searchRepository;

  SearchBloc({required this.searchRepository}) : super(const SearchState()) {
    on<SearchQueryChanged>(_onSearchQueryChanged);
    on<LoadMoreSearchResults>(_onLoadMoreSearchResults);
    on<ClearSearch>(_onClearSearch);
  }

  Future<void> _onSearchQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    final query = event.query.trim();
    if (query.isEmpty) {
      emit(const SearchState());
      return;
    }

    emit(state.copyWith(status: SearchStatus.loading, query: query));
    AppLogger.i("Searching notes for query: $query");

    try {
      final filteredNotes = await searchRepository.searchNotes(query);

      final firstPage = filteredNotes.take(SearchState.pageSize).toList();
      final hasMore = filteredNotes.length > SearchState.pageSize;

      AppLogger.i("Found ${filteredNotes.length} matching notes");

      emit(
        state.copyWith(
          status: SearchStatus.success,
          results: firstPage,
          allFilteredNotes: filteredNotes,
          hasMore: hasMore,
          currentPage: 0,
        ),
      );
    } catch (e) {
      AppLogger.e("Error searching notes: $e");
      emit(state.copyWith(status: SearchStatus.failure));
    }
  }

  Future<void> _onLoadMoreSearchResults(
    LoadMoreSearchResults event,
    Emitter<SearchState> emit,
  ) async {
    if (state.isLoadingMore || !state.hasMore) return;

    AppLogger.i("Loading more search results");
    emit(state.copyWith(isLoadingMore: true));

    try {
      final currentCount = state.results.length;
      final newBatch = state.allFilteredNotes
          .skip(currentCount)
          .take(SearchState.pageSize)
          .toList();

      if (newBatch.isEmpty) {
        emit(state.copyWith(isLoadingMore: false, hasMore: false));
        return;
      }

      emit(
        state.copyWith(
          results: [...state.results, ...newBatch],
          isLoadingMore: false,
          hasMore:
              (currentCount + newBatch.length) < state.allFilteredNotes.length,
          currentPage: state.currentPage + 1,
        ),
      );
    } catch (e) {
      AppLogger.e("Error loading more search results: $e");
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  void _onClearSearch(ClearSearch event, Emitter<SearchState> emit) {
    emit(const SearchState());
  }
}
