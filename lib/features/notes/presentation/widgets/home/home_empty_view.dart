import 'package:flutter/material.dart';
import 'package:mechanix_notes/l10n/notes_localizations.dart';

class HomeEmptyView extends StatelessWidget {
  const HomeEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        AppLocalizations.of(context)!.noNotesFound,
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }
}
