abstract class SearchEvent {}

class SearchQueryChanged extends SearchEvent {
  final String query;
  SearchQueryChanged({required this.query});
}

class LoadMoreSearchResults extends SearchEvent {}

class ClearSearch extends SearchEvent {}
