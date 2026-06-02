import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_notes/features/notes/bloc/search/search_bloc.dart';
import 'package:mechanix_notes/features/notes/bloc/search/search_event.dart';
import 'package:mechanix_notes/features/notes/bloc/search/search_state.dart';
import 'package:mechanix_notes/features/notes/data/models/note_metadata.dart';
import 'package:mechanix_notes/features/notes/presentation/widgets/home/card/home_note_card_content.dart';

class SearchListView extends StatefulWidget {
  const SearchListView({super.key});

  @override
  State<SearchListView> createState() => _SearchListViewState();
}

class _SearchListViewState extends State<SearchListView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      final state = context.read<SearchBloc>().state;
      if (!state.isLoadingMore && state.hasMore) {
        context.read<SearchBloc>().add(LoadMoreSearchResults());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<SearchBloc, SearchState, List<NoteMetaData>>(
      selector: (state) => state.results,
      builder: (context, results) {
        return Scrollbar(
          controller: _scrollController,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
            ),
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 20, bottom: 40.0),
              itemCount: results.length,
              itemBuilder: (context, index) {
                final note = results[index];
                return HomeNoteCardContent(
                  note: note,
                  isSelectionMode: false,
                  isSelected: false,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/note-editor',
                      arguments: {'noteId': note.id, 'noteTitle': note.title},
                    ).then((_) {
                      if (context.mounted) {
                        final searchBloc = context.read<SearchBloc>();
                        searchBloc.add(
                          SearchQueryChanged(query: searchBloc.state.query),
                        );
                      }
                    });
                  },
                  onLongPress: () {},
                );
              },
            ),
          ),
        );
      },
    );
  }
}
