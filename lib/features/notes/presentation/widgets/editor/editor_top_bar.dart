import 'package:flutter/material.dart';
import 'package:mechanix_notes/features/notes/presentation/widgets/editor/topbar/editor_title_input.dart';
import 'package:mechanix_notes/features/notes/presentation/widgets/editor/topbar/editor_undo_redo_actions.dart';
import 'package:mechanix_notes/features/notes/presentation/widgets/editor/quill_controller_provider.dart';

class EditorTopBar extends StatelessWidget {
  const EditorTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final quillController = QuillControllerProvider.maybeOf(
      context,
    )?.controller;

    return SafeArea(
      bottom: false,
      child: Container(
        height: 60,
        color: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const Expanded(child: EditorTitleInput()),

            const SizedBox(width: 8),

            if (quillController != null) ...[
              EditorUndoRedoActions(quillController: quillController),
            ],
          ],
        ),
      ),
    );
  }
}
