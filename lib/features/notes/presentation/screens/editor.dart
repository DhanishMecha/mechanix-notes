import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_notes/core/utils/app_logger.dart';
import 'package:mechanix_notes/features/notes/bloc/editor/editor_bloc.dart';
import 'package:mechanix_notes/features/notes/data/repository/editor_repository.dart';
import 'package:mechanix_notes/features/notes/presentation/widgets/editor/editor_view.dart';

class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final noteId = args?['noteId'] as String?;
    final noteTitle = args?['noteTitle'] as String?;

    AppLogger.i('EditorScreen noteId: $noteId, noteTitle: $noteTitle');

    return BlocProvider(
      create: (context) =>
          EditorBloc(context.read<EditorRepository>())
            ..add(EditorInitialised(noteId: noteId, noteTitle: noteTitle)),
      child: const EditorView(),
    );
  }
}
