import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_notes/features/notes/bloc/search/search_bloc.dart';
import 'package:mechanix_notes/features/notes/bloc/search/search_event.dart';
import 'package:mechanix_notes/features/notes/bloc/search/search_state.dart';
import 'package:mechanix_notes/features/notes/data/models/note_metadata.dart';
import 'package:mechanix_notes/features/notes/data/repository/search_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockSearchRepository extends Mock implements SearchRepository {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

NoteMetaData makeNote({required String id, String title = 'Note'}) =>
    NoteMetaData(
      id: id,
      title: title,
      updatedAt: DateTime(2024, 6, 1),
      height: 0,
      createdAt: DateTime(2024, 1, 1),
      previewText: 'Preview $id',
    );

List<NoteMetaData> buildNoteList(int count) =>
    List.generate(count, (i) => makeNote(id: 'note_$i', title: 'Note $i'));

Matcher stateMatching({
  SearchStatus? status,
  String? query,
  int? resultsLength,
  int? allFilteredLength,
  bool? hasMore,
  int? currentPage,
  bool? isLoadingMore,
}) {
  return predicate<SearchState>((s) {
    if (status != null && s.status != status) return false;
    if (query != null && s.query != query) return false;
    if (resultsLength != null && s.results.length != resultsLength) {
      return false;
    }
    if (allFilteredLength != null &&
        s.allFilteredNotes.length != allFilteredLength) {
      return false;
    }
    if (hasMore != null && s.hasMore != hasMore) return false;
    if (currentPage != null && s.currentPage != currentPage) return false;
    if (isLoadingMore != null && s.isLoadingMore != isLoadingMore) return false;
    return true;
  }, 'SearchState matches expected fields');
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockSearchRepository mockRepo;

  setUp(() {
    mockRepo = MockSearchRepository();
  });

  SearchBloc buildBloc() => SearchBloc(searchRepository: mockRepo);

  // ── Constructor ──────────────────────────────────────────────────────────

  group('SearchBloc – constructor', () {
    test('initial state is default SearchState', () {
      final bloc = buildBloc();
      expect(bloc.state, const SearchState());
      bloc.close();
    });

    test('initial state has SearchStatus.initial', () {
      final bloc = buildBloc();
      expect(bloc.state.status, SearchStatus.initial);
      bloc.close();
    });
  });

  // ── Search events ────────────────────────────────────────────────────────

  group('SearchEvent', () {
    test('SearchQueryChanged stores query', () {
      final event = SearchQueryChanged(query: 'flutter');
      expect(event.query, 'flutter');
    });

    test('LoadMoreSearchResults is instantiable', () {
      expect(LoadMoreSearchResults(), isA<LoadMoreSearchResults>());
    });

    test('ClearSearch is instantiable', () {
      expect(ClearSearch(), isA<ClearSearch>());
    });
  });

  // ── SearchQueryChanged – empty query ─────────────────────────────────────

  group('SearchQueryChanged – empty query', () {
    blocTest<SearchBloc, SearchState>(
      'resets to initial state when query is empty',
      build: buildBloc,
      act: (bloc) => bloc.add(SearchQueryChanged(query: '')),
      expect: () => [const SearchState()],
      verify: (_) {
        verifyNever(() => mockRepo.searchNotes(any()));
      },
    );

    blocTest<SearchBloc, SearchState>(
      'resets to initial state when query is only whitespace',
      build: buildBloc,
      act: (bloc) => bloc.add(SearchQueryChanged(query: '   ')),
      expect: () => [const SearchState()],
      verify: (_) {
        verifyNever(() => mockRepo.searchNotes(any()));
      },
    );

    blocTest<SearchBloc, SearchState>(
      'resets to initial state when query is tabs and newlines only',
      build: buildBloc,
      act: (bloc) => bloc.add(SearchQueryChanged(query: '\t\n  \n')),
      expect: () => [const SearchState()],
      verify: (_) {
        verifyNever(() => mockRepo.searchNotes(any()));
      },
    );

    blocTest<SearchBloc, SearchState>(
      'clears previous success state when query becomes empty',
      build: buildBloc,
      seed: () => SearchState(
        status: SearchStatus.success,
        query: 'old',
        results: buildNoteList(5),
        allFilteredNotes: buildNoteList(5),
        hasMore: true,
        currentPage: 2,
        isLoadingMore: false,
      ),
      act: (bloc) => bloc.add(SearchQueryChanged(query: '')),
      expect: () => [const SearchState()],
    );

    blocTest<SearchBloc, SearchState>(
      'clears failure state when query becomes empty',
      build: buildBloc,
      seed: () =>
          const SearchState(status: SearchStatus.failure, query: 'failed'),
      act: (bloc) => bloc.add(SearchQueryChanged(query: '')),
      expect: () => [const SearchState()],
    );
  });

  // ── SearchQueryChanged – success ─────────────────────────────────────────

  group('SearchQueryChanged – success', () {
    blocTest<SearchBloc, SearchState>(
      'emits [loading, success] with matching results',
      build: () {
        final notes = buildNoteList(3);
        when(() => mockRepo.searchNotes('test')).thenAnswer((_) async => notes);
        return buildBloc();
      },
      act: (bloc) => bloc.add(SearchQueryChanged(query: 'test')),
      expect: () => [
        stateMatching(
          status: SearchStatus.loading,
          query: 'test',
          resultsLength: 0,
          allFilteredLength: 0,
        ),
        stateMatching(
          status: SearchStatus.success,
          query: 'test',
          resultsLength: 3,
          allFilteredLength: 3,
          hasMore: false,
          currentPage: 0,
          isLoadingMore: false,
        ),
      ],
      verify: (_) {
        verify(() => mockRepo.searchNotes('test')).called(1);
      },
    );

    blocTest<SearchBloc, SearchState>(
      'emits success with empty results when repository returns nothing',
      build: () {
        when(() => mockRepo.searchNotes('none')).thenAnswer((_) async => []);
        return buildBloc();
      },
      act: (bloc) => bloc.add(SearchQueryChanged(query: 'none')),
      expect: () => [
        stateMatching(status: SearchStatus.loading, query: 'none'),
        stateMatching(
          status: SearchStatus.success,
          query: 'none',
          resultsLength: 0,
          allFilteredLength: 0,
          hasMore: false,
          currentPage: 0,
        ),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'trims query before calling repository',
      build: () {
        when(() => mockRepo.searchNotes('hello')).thenAnswer((_) async => []);
        return buildBloc();
      },
      act: (bloc) => bloc.add(SearchQueryChanged(query: '  hello  ')),
      expect: () => [
        stateMatching(status: SearchStatus.loading, query: 'hello'),
        stateMatching(status: SearchStatus.success, query: 'hello'),
      ],
      verify: (_) {
        verify(() => mockRepo.searchNotes('hello')).called(1);
      },
    );

    blocTest<SearchBloc, SearchState>(
      'sets hasMore=false when results equal pageSize exactly',
      build: () {
        final notes = buildNoteList(SearchState.pageSize);
        when(
          () => mockRepo.searchNotes('exact'),
        ).thenAnswer((_) async => notes);
        return buildBloc();
      },
      act: (bloc) => bloc.add(SearchQueryChanged(query: 'exact')),
      expect: () => [
        isA<SearchState>(),
        stateMatching(
          status: SearchStatus.success,
          resultsLength: SearchState.pageSize,
          allFilteredLength: SearchState.pageSize,
          hasMore: false,
        ),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'sets hasMore=true when results are exactly pageSize + 1',
      build: () {
        final notes = buildNoteList(SearchState.pageSize + 1);
        when(
          () => mockRepo.searchNotes('plusone'),
        ).thenAnswer((_) async => notes);
        return buildBloc();
      },
      act: (bloc) => bloc.add(SearchQueryChanged(query: 'plusone')),
      expect: () => [
        isA<SearchState>(),
        stateMatching(
          status: SearchStatus.success,
          resultsLength: SearchState.pageSize,
          allFilteredLength: SearchState.pageSize + 1,
          hasMore: true,
        ),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'sets hasMore=true when total results exceed pageSize',
      build: () {
        final notes = buildNoteList(SearchState.pageSize + 5);
        when(() => mockRepo.searchNotes('q')).thenAnswer((_) async => notes);
        return buildBloc();
      },
      act: (bloc) => bloc.add(SearchQueryChanged(query: 'q')),
      expect: () => [
        isA<SearchState>(),
        stateMatching(
          status: SearchStatus.success,
          resultsLength: SearchState.pageSize,
          allFilteredLength: SearchState.pageSize + 5,
          hasMore: true,
        ),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'first page contains the first pageSize notes from repository',
      build: () {
        final notes = buildNoteList(SearchState.pageSize + 2);
        when(() => mockRepo.searchNotes('ids')).thenAnswer((_) async => notes);
        return buildBloc();
      },
      act: (bloc) => bloc.add(SearchQueryChanged(query: 'ids')),
      verify: (bloc) {
        final ids = bloc.state.results.map((n) => n.id).toList();
        expect(ids.first, 'note_0');
        expect(ids.last, 'note_${SearchState.pageSize - 1}');
        expect(ids.length, SearchState.pageSize);
      },
    );

    blocTest<SearchBloc, SearchState>(
      'replaces previous search results on a new successful query',
      build: () {
        when(
          () => mockRepo.searchNotes('new'),
        ).thenAnswer((_) async => [makeNote(id: 'fresh')]);
        return buildBloc();
      },
      seed: () => SearchState(
        status: SearchStatus.success,
        query: 'old',
        results: buildNoteList(3),
        allFilteredNotes: buildNoteList(3),
        hasMore: false,
        currentPage: 1,
      ),
      act: (bloc) => bloc.add(SearchQueryChanged(query: 'new')),
      verify: (bloc) {
        expect(bloc.state.results.single.id, 'fresh');
        expect(bloc.state.allFilteredNotes.single.id, 'fresh');
        expect(bloc.state.query, 'new');
      },
    );

    blocTest<SearchBloc, SearchState>(
      'resets currentPage to 0 on a fresh search',
      build: () {
        when(() => mockRepo.searchNotes('new')).thenAnswer((_) async => []);
        return buildBloc();
      },
      seed: () => const SearchState(
        status: SearchStatus.success,
        query: 'old',
        currentPage: 3,
        hasMore: true,
      ),
      act: (bloc) => bloc.add(SearchQueryChanged(query: 'new')),
      expect: () => [isA<SearchState>(), stateMatching(currentPage: 0)],
    );

    blocTest<SearchBloc, SearchState>(
      'emits loading before repository returns',
      build: () {
        when(() => mockRepo.searchNotes('slow')).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return buildNoteList(1);
        });
        return buildBloc();
      },
      act: (bloc) => bloc.add(SearchQueryChanged(query: 'slow')),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        stateMatching(status: SearchStatus.loading, query: 'slow'),
        stateMatching(status: SearchStatus.success, resultsLength: 1),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'recovers to success after a previous failure',
      build: () {
        when(
          () => mockRepo.searchNotes('ok'),
        ).thenAnswer((_) async => buildNoteList(2));
        return buildBloc();
      },
      seed: () =>
          const SearchState(status: SearchStatus.failure, query: 'fail'),
      act: (bloc) => bloc.add(SearchQueryChanged(query: 'ok')),
      expect: () => [
        stateMatching(status: SearchStatus.loading, query: 'ok'),
        stateMatching(
          status: SearchStatus.success,
          query: 'ok',
          resultsLength: 2,
        ),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'resets isLoadingMore on a fresh search',
      build: () {
        when(() => mockRepo.searchNotes('q')).thenAnswer((_) async => []);
        return buildBloc();
      },
      seed: () =>
          const SearchState(status: SearchStatus.success, isLoadingMore: true),
      act: (bloc) => bloc.add(SearchQueryChanged(query: 'q')),
      expect: () => [
        stateMatching(status: SearchStatus.loading, isLoadingMore: false),
        stateMatching(status: SearchStatus.success, isLoadingMore: false),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'resets isLoadingMore when search fails',
      build: () {
        when(
          () => mockRepo.searchNotes('fail'),
        ).thenThrow(Exception('db error'));
        return buildBloc();
      },
      seed: () =>
          const SearchState(status: SearchStatus.success, isLoadingMore: true),
      act: (bloc) => bloc.add(SearchQueryChanged(query: 'fail')),
      expect: () => [
        stateMatching(status: SearchStatus.loading, isLoadingMore: false),
        stateMatching(status: SearchStatus.failure, isLoadingMore: false),
      ],
    );
  });

  // ── SearchQueryChanged – failure ─────────────────────────────────────────

  group('SearchQueryChanged – failure', () {
    blocTest<SearchBloc, SearchState>(
      'emits [loading, failure] when repository throws',
      build: () {
        when(
          () => mockRepo.searchNotes('fail'),
        ).thenThrow(Exception('db error'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(SearchQueryChanged(query: 'fail')),
      expect: () => [
        stateMatching(status: SearchStatus.loading, query: 'fail'),
        stateMatching(status: SearchStatus.failure, query: 'fail'),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'keeps query from the failed search attempt',
      build: () {
        when(
          () => mockRepo.searchNotes('fail'),
        ).thenThrow(Exception('db error'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(SearchQueryChanged(query: 'fail')),
      verify: (bloc) {
        expect(bloc.state.query, 'fail');
      },
    );

    blocTest<SearchBloc, SearchState>(
      'preserves stale results from prior success when new search fails',
      build: () {
        when(
          () => mockRepo.searchNotes('fail'),
        ).thenThrow(Exception('db error'));
        return buildBloc();
      },
      seed: () => SearchState(
        status: SearchStatus.success,
        query: 'old',
        results: buildNoteList(4),
        allFilteredNotes: buildNoteList(4),
      ),
      act: (bloc) => bloc.add(SearchQueryChanged(query: 'fail')),
      verify: (bloc) {
        expect(bloc.state.status, SearchStatus.failure);
        expect(bloc.state.results.length, 4);
        expect(bloc.state.query, 'fail');
      },
    );

    blocTest<SearchBloc, SearchState>(
      'does not call repository again after failure without a new event',
      build: () {
        when(
          () => mockRepo.searchNotes('fail'),
        ).thenThrow(Exception('db error'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(SearchQueryChanged(query: 'fail')),
      verify: (_) {
        verify(() => mockRepo.searchNotes('fail')).called(1);
      },
    );
  });

  // ── LoadMoreSearchResults – success ──────────────────────────────────────

  group('LoadMoreSearchResults – success', () {
    blocTest<SearchBloc, SearchState>(
      'emits isLoadingMore true then false while appending',
      build: buildBloc,
      seed: () {
        final all = buildNoteList(SearchState.pageSize + 5);
        return SearchState(
          status: SearchStatus.success,
          query: 'q',
          results: all.take(SearchState.pageSize).toList(),
          allFilteredNotes: all,
          hasMore: true,
        );
      },
      act: (bloc) => bloc.add(LoadMoreSearchResults()),
      expect: () => [
        stateMatching(isLoadingMore: true),
        stateMatching(
          isLoadingMore: false,
          resultsLength: SearchState.pageSize + 5,
          currentPage: 1,
          hasMore: false,
        ),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'appends the correct next batch of note ids',
      build: buildBloc,
      seed: () {
        final all = buildNoteList(SearchState.pageSize + 3);
        return SearchState(
          status: SearchStatus.success,
          query: 'q',
          results: all.take(SearchState.pageSize).toList(),
          allFilteredNotes: all,
          hasMore: true,
        );
      },
      act: (bloc) => bloc.add(LoadMoreSearchResults()),
      verify: (bloc) {
        final ids = bloc.state.results.map((n) => n.id).toList();
        expect(ids[SearchState.pageSize], 'note_${SearchState.pageSize}');
        expect(ids.last, 'note_${SearchState.pageSize + 2}');
        expect(ids.first, 'note_0');
      },
    );

    blocTest<SearchBloc, SearchState>(
      'sets hasMore=false when last batch is smaller than pageSize',
      build: buildBloc,
      seed: () {
        final all = buildNoteList(SearchState.pageSize + 3);
        return SearchState(
          status: SearchStatus.success,
          query: 'q',
          results: all.take(SearchState.pageSize).toList(),
          allFilteredNotes: all,
          hasMore: true,
        );
      },
      act: (bloc) => bloc.add(LoadMoreSearchResults()),
      verify: (bloc) {
        expect(bloc.state.results.length, SearchState.pageSize + 3);
        expect(bloc.state.hasMore, isFalse);
      },
    );

    blocTest<SearchBloc, SearchState>(
      'keeps hasMore=true when another full page remains',
      build: buildBloc,
      seed: () {
        final all = buildNoteList(SearchState.pageSize * 3);
        return SearchState(
          status: SearchStatus.success,
          query: 'q',
          results: all.take(SearchState.pageSize).toList(),
          allFilteredNotes: all,
          hasMore: true,
        );
      },
      act: (bloc) => bloc.add(LoadMoreSearchResults()),
      expect: () => [
        isA<SearchState>(),
        stateMatching(
          resultsLength: SearchState.pageSize * 2,
          currentPage: 1,
          hasMore: true,
        ),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'loads all pages when LoadMoreSearchResults is dispatched repeatedly',
      build: buildBloc,
      seed: () {
        final all = buildNoteList(SearchState.pageSize * 3);
        return SearchState(
          status: SearchStatus.success,
          query: 'q',
          results: all.take(SearchState.pageSize).toList(),
          allFilteredNotes: all,
          hasMore: true,
        );
      },
      act: (bloc) async {
        bloc.add(LoadMoreSearchResults());
        await bloc.stream.firstWhere((s) => !s.isLoadingMore);
        bloc.add(LoadMoreSearchResults());
      },
      verify: (bloc) {
        expect(bloc.state.results.length, SearchState.pageSize * 3);
        expect(bloc.state.currentPage, 2);
        expect(bloc.state.hasMore, isFalse);
        expect(bloc.state.isLoadingMore, isFalse);
      },
    );

    blocTest<SearchBloc, SearchState>(
      'handles pageSize + 1 notes across two load-more dispatches',
      build: buildBloc,
      seed: () {
        final all = buildNoteList(SearchState.pageSize + 1);
        return SearchState(
          status: SearchStatus.success,
          query: 'q',
          results: all.take(SearchState.pageSize).toList(),
          allFilteredNotes: all,
          hasMore: true,
        );
      },
      act: (bloc) => bloc.add(LoadMoreSearchResults()),
      verify: (bloc) {
        expect(bloc.state.results.length, SearchState.pageSize + 1);
        expect(bloc.state.hasMore, isFalse);
        expect(bloc.state.results.last.id, 'note_${SearchState.pageSize}');
      },
    );
  });

  // ── LoadMoreSearchResults – empty batch ──────────────────────────────────

  group('LoadMoreSearchResults – empty batch', () {
    blocTest<SearchBloc, SearchState>(
      'sets hasMore=false when newBatch is empty despite hasMore being true',
      build: buildBloc,
      seed: () {
        final all = buildNoteList(SearchState.pageSize);
        return SearchState(
          status: SearchStatus.success,
          query: 'q',
          results: all,
          allFilteredNotes: all,
          hasMore: true,
        );
      },
      act: (bloc) => bloc.add(LoadMoreSearchResults()),
      expect: () => [
        stateMatching(isLoadingMore: true),
        stateMatching(
          isLoadingMore: false,
          hasMore: false,
          resultsLength: SearchState.pageSize,
        ),
      ],
    );
  });

  // ── LoadMoreSearchResults – no-op ────────────────────────────────────────

  group('LoadMoreSearchResults – no-op', () {
    blocTest<SearchBloc, SearchState>(
      'does nothing from initial state',
      build: buildBloc,
      act: (bloc) => bloc.add(LoadMoreSearchResults()),
      expect: () => [],
    );

    blocTest<SearchBloc, SearchState>(
      'does nothing when hasMore is false',
      build: buildBloc,
      seed: () => SearchState(
        status: SearchStatus.success,
        query: 'q',
        results: buildNoteList(3),
        allFilteredNotes: buildNoteList(3),
        hasMore: false,
      ),
      act: (bloc) => bloc.add(LoadMoreSearchResults()),
      expect: () => [],
    );

    blocTest<SearchBloc, SearchState>(
      'does nothing when already loading more',
      build: buildBloc,
      seed: () => SearchState(
        status: SearchStatus.success,
        query: 'q',
        results: buildNoteList(SearchState.pageSize + 5),
        allFilteredNotes: buildNoteList(SearchState.pageSize + 5),
        hasMore: true,
        isLoadingMore: true,
      ),
      act: (bloc) => bloc.add(LoadMoreSearchResults()),
      expect: () => [],
    );

    blocTest<SearchBloc, SearchState>(
      'does nothing after all results are already loaded',
      build: buildBloc,
      seed: () {
        final all = buildNoteList(SearchState.pageSize + 2);
        return SearchState(
          status: SearchStatus.success,
          query: 'q',
          results: all,
          allFilteredNotes: all,
          hasMore: false,
        );
      },
      act: (bloc) => bloc.add(LoadMoreSearchResults()),
      expect: () => [],
    );
  });

  // ── ClearSearch ──────────────────────────────────────────────────────────

  group('ClearSearch', () {
    blocTest<SearchBloc, SearchState>(
      'resets success state to initial',
      build: buildBloc,
      seed: () => SearchState(
        status: SearchStatus.success,
        query: 'test',
        results: buildNoteList(5),
        allFilteredNotes: buildNoteList(5),
        hasMore: true,
        currentPage: 1,
      ),
      act: (bloc) => bloc.add(ClearSearch()),
      expect: () => [const SearchState()],
    );

    blocTest<SearchBloc, SearchState>(
      'resets failure state to initial',
      build: buildBloc,
      seed: () =>
          const SearchState(status: SearchStatus.failure, query: 'fail'),
      act: (bloc) => bloc.add(ClearSearch()),
      expect: () => [const SearchState()],
    );

    blocTest<SearchBloc, SearchState>(
      'resets loading state to initial',
      build: buildBloc,
      seed: () =>
          const SearchState(status: SearchStatus.loading, query: 'pending'),
      act: (bloc) => bloc.add(ClearSearch()),
      expect: () => [const SearchState()],
    );

    blocTest<SearchBloc, SearchState>(
      'resets state when isLoadingMore is true',
      build: buildBloc,
      seed: () => SearchState(
        status: SearchStatus.success,
        query: 'q',
        results: buildNoteList(25),
        allFilteredNotes: buildNoteList(25),
        hasMore: true,
        isLoadingMore: true,
      ),
      act: (bloc) => bloc.add(ClearSearch()),
      expect: () => [const SearchState()],
    );

    blocTest<SearchBloc, SearchState>(
      'second ClearSearch from initial emits nothing (Equatable dedup)',
      build: buildBloc,
      act: (bloc) {
        bloc.add(ClearSearch());
        bloc.add(ClearSearch());
      },
      expect: () => [const SearchState()],
      verify: (bloc) {
        expect(bloc.state, const SearchState());
      },
    );
  });

  // ── Integration-style flows ──────────────────────────────────────────────

  group('SearchBloc – event sequences', () {
    blocTest<SearchBloc, SearchState>(
      'search → load more → clear returns to initial',
      build: () {
        final all = buildNoteList(SearchState.pageSize + 2);
        when(() => mockRepo.searchNotes('flow')).thenAnswer((_) async => all);
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(SearchQueryChanged(query: 'flow'));
        await bloc.stream.firstWhere((s) => s.status == SearchStatus.success);
        bloc.add(LoadMoreSearchResults());
        await bloc.stream.firstWhere(
          (s) => !s.isLoadingMore && s.hasMore == false,
        );
        bloc.add(ClearSearch());
      },
      verify: (bloc) {
        expect(bloc.state, const SearchState());
      },
    );

    blocTest<SearchBloc, SearchState>(
      'search → clear → empty query keeps initial state',
      build: () {
        when(
          () => mockRepo.searchNotes('a'),
        ).thenAnswer((_) async => buildNoteList(1));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(SearchQueryChanged(query: 'a'));
        await bloc.stream.firstWhere((s) => s.status == SearchStatus.success);
        bloc.add(ClearSearch());
        bloc.add(SearchQueryChanged(query: ''));
      },
      verify: (bloc) {
        expect(bloc.state, const SearchState());
      },
    );
  });

  // ── SearchState ──────────────────────────────────────────────────────────

  group('SearchState', () {
    test('pageSize constant is 20', () {
      expect(SearchState.pageSize, 20);
    });

    test('default constructor values', () {
      const state = SearchState();
      expect(state.status, SearchStatus.initial);
      expect(state.results, isEmpty);
      expect(state.allFilteredNotes, isEmpty);
      expect(state.query, isEmpty);
      expect(state.hasMore, isFalse);
      expect(state.currentPage, 0);
      expect(state.isLoadingMore, isFalse);
    });

    test('SearchStatus contains all expected values', () {
      expect(SearchStatus.values, containsAll(SearchStatus.values));
      expect(SearchStatus.values.length, 4);
    });

    test('copyWith updates each field independently', () {
      const original = SearchState();
      final note = makeNote(id: 'x');

      expect(
        original.copyWith(status: SearchStatus.loading).status,
        SearchStatus.loading,
      );
      expect(original.copyWith(results: [note]).results, [note]);
      expect(original.copyWith(allFilteredNotes: [note]).allFilteredNotes, [
        note,
      ]);
      expect(original.copyWith(query: 'q').query, 'q');
      expect(original.copyWith(hasMore: true).hasMore, isTrue);
      expect(original.copyWith(currentPage: 2).currentPage, 2);
      expect(original.copyWith(isLoadingMore: true).isLoadingMore, isTrue);
    });

    test('copyWith preserves unspecified fields', () {
      const original = SearchState(
        status: SearchStatus.success,
        query: 'keep',
        currentPage: 2,
      );
      final copy = original.copyWith(hasMore: true);
      expect(copy.status, SearchStatus.success);
      expect(copy.query, 'keep');
      expect(copy.currentPage, 2);
      expect(copy.hasMore, isTrue);
    });

    test('two states with same values are equal (Equatable)', () {
      const a = SearchState(status: SearchStatus.success, query: 'q');
      const b = SearchState(status: SearchStatus.success, query: 'q');
      expect(a, equals(b));
    });

    test('states differ when status differs', () {
      const a = SearchState(status: SearchStatus.initial);
      const b = SearchState(status: SearchStatus.loading);
      expect(a, isNot(equals(b)));
    });

    test('states differ when results differ', () {
      final a = SearchState(results: [makeNote(id: '1')]);
      final b = SearchState(results: [makeNote(id: '2')]);
      expect(a, isNot(equals(b)));
    });

    test('states differ when allFilteredNotes differ', () {
      final a = SearchState(allFilteredNotes: [makeNote(id: '1')]);
      final b = SearchState(allFilteredNotes: [makeNote(id: '2')]);
      expect(a, isNot(equals(b)));
    });

    test('states differ when query differs', () {
      const a = SearchState(query: 'a');
      const b = SearchState(query: 'b');
      expect(a, isNot(equals(b)));
    });

    test('states differ when hasMore differs', () {
      const a = SearchState(hasMore: false);
      const b = SearchState(hasMore: true);
      expect(a, isNot(equals(b)));
    });

    test('states differ when currentPage differs', () {
      const a = SearchState(currentPage: 0);
      const b = SearchState(currentPage: 1);
      expect(a, isNot(equals(b)));
    });

    test('states differ when isLoadingMore differs', () {
      const a = SearchState(isLoadingMore: false);
      const b = SearchState(isLoadingMore: true);
      expect(a, isNot(equals(b)));
    });

    test('props includes all fields', () {
      final note = makeNote(id: '1');
      final state = SearchState(
        status: SearchStatus.success,
        results: [note],
        allFilteredNotes: [note],
        query: 'q',
        hasMore: true,
        currentPage: 1,
        isLoadingMore: true,
      );
      expect(state.props.length, 7);
    });
  });
}
