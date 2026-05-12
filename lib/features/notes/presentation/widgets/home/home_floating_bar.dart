import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_notes/core/utils/colors.dart';
import 'package:mechanix_notes/core/utils/icons.dart';
import 'package:mechanix_notes/features/notes/bloc/notes/notes_bloc.dart';
import 'package:mechanix_notes/features/notes/bloc/notes/notes_state.dart';

class HomeFloatingBar extends StatelessWidget {
  const HomeFloatingBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        BlocSelector<NotesBloc, NotesState, bool>(
          selector: (state) => state.notes.isNotEmpty,
          builder: (context, state) {
            return FloatingActionButton.small(
              mouseCursor: SystemMouseCursors.basic,
              heroTag: 'search',
              onPressed: null,
              backgroundColor: NotesColors.bottomBarBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: const BorderSide(
                  color: NotesColors.borderColor,
                  width: 0.5,
                ),
              ),
              child: Image.asset(
                NotesIcon.searchIcon,
                width: 20,
                height: 20,
                color: Colors.white30,
              ),
            );
          },
        ),

        const SizedBox(height: 12),

        FloatingActionButton(
          mouseCursor: SystemMouseCursors.click,
          heroTag: 'create',
          onPressed: () {
            Navigator.pushNamed(context, '/note-editor');
          },
          backgroundColor: NotesColors.borderColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          child: Image.asset(
            NotesIcon.createIcon,
            width: 28,
            height: 28,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
