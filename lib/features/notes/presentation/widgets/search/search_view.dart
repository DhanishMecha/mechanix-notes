import 'package:flutter/material.dart' hide SearchBar;
import 'package:mechanix_notes/features/notes/presentation/widgets/search/search_bar.dart';

import 'package:mechanix_notes/features/notes/presentation/widgets/search/search_list.dart';

class SearchView extends StatelessWidget {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Column(
        children: [
          SearchBar(),
          Expanded(child: SearchList()),
        ],
      ),
    );
  }
}
