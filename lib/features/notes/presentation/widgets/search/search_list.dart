import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_notes/features/notes/bloc/search/search_bloc.dart';
import 'package:mechanix_notes/features/notes/bloc/search/search_state.dart';
import 'package:mechanix_notes/features/notes/presentation/widgets/search/search_list_view.dart';
import 'package:mechanix_notes/features/notes/presentation/widgets/search/search_message_view.dart';

class SearchList extends StatelessWidget {
  const SearchList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        if (state.status == SearchStatus.initial || state.query.isEmpty) {
          return const SearchMessageView(message: 'Type to search');
        }

        if (state.status == SearchStatus.loading && state.results.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == SearchStatus.failure) {
          return const SearchMessageView(
            message: 'Failed to perform search',
            isError: true,
          );
        }

        if (state.results.isEmpty) {
          return const SearchMessageView(message: 'No notes found');
        }

        return const SearchListView();
      },
    );
  }
}
