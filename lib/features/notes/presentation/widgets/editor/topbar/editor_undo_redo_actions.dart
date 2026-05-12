import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:mechanix_notes/core/utils/icons.dart';
import 'package:mechanix_notes/l10n/notes_localizations.dart';

class EditorUndoRedoActions extends StatelessWidget {
  const EditorUndoRedoActions({required this.quillController});

  final QuillController quillController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: quillController,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _UndoRedoButton(
            iconAsset: NotesIcon.undoIcon,
            tooltip: AppLocalizations.of(context)!.undo,
            isEnabled: quillController.hasUndo,
            onPressed: quillController.hasUndo ? quillController.undo : null,
          ),
          _UndoRedoButton(
            iconAsset: NotesIcon.redoIcon,
            tooltip: AppLocalizations.of(context)!.redo,
            isEnabled: quillController.hasRedo,
            onPressed: quillController.hasRedo ? quillController.redo : null,
          ),
        ],
      ),
    );
  }
}

class _UndoRedoButton extends StatelessWidget {
  const _UndoRedoButton({
    required this.iconAsset,
    required this.tooltip,
    required this.isEnabled,
    required this.onPressed,
  });

  final String iconAsset;
  final String tooltip;
  final bool isEnabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      mouseCursor: isEnabled ? SystemMouseCursors.click : MouseCursor.defer,
      icon: Image.asset(
        iconAsset,
        width: 22,
        height: 22,
        color: isEnabled ? Colors.white : Colors.white30,
      ),
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }
}
