import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_notes/core/utils/icons.dart';
import 'package:mechanix_notes/features/notes/bloc/editor/editor_bloc.dart';
import 'package:mechanix_notes/features/notes/presentation/widgets/editor/editor_button.dart';
import 'package:mechanix_notes/features/notes/presentation/widgets/editor/quill_controller_provider.dart';
import 'package:mechanix_notes/features/notes/presentation/widgets/editor/toolbar/optiontoolbar/option_toolbar_delete_sheet.dart';
import 'package:mechanix_notes/features/notes/presentation/widgets/editor/toolbar/optiontoolbar/option_toolbar_row.dart';
import 'package:mechanix_notes/l10n/notes_localizations.dart';

class OptionsToolbar extends StatelessWidget {
  const OptionsToolbar({super.key});

  void _save(BuildContext context) {
    try {
      final controller = QuillControllerProvider.of(context).controller;
      final delta = controller.document.toDelta().toJson();
      final plainText = controller.document.toPlainText().trim();

      context.read<EditorBloc>().add(
        EditorSaveRequested(content: delta, plainText: plainText),
      );
    } catch (e) {}
  }

  void _showDeleteSheet(BuildContext context) {
    final editorBloc = context.read<EditorBloc>();
    final state = editorBloc.state;
    if (state is! EditorLoaded) return;
    editorBloc.add(EditorToolbarToggled(EditorToolbar.none));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: editorBloc,
        child: OptionToolbarDeleteSheet(
          noteTitle: state.title,
          onDelete: () {
            editorBloc.add(EditorDeleteRequested());
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF212121),
        border: Border(top: BorderSide(color: Color(0xFF2D2D2D), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              alignment: Alignment.centerRight,
              child: EditorButton(
                onPress: () {
                  context.read<EditorBloc>().add(
                    EditorToolbarToggled(EditorToolbar.none),
                  );
                },
                size: 24,
                asset: NotesIcon.closeIcon,
              ),
            ),

            OptionToolbarRow(
              onTap: () => _save(context),
              icon: NotesIcon.saveIcon,
              label: AppLocalizations.of(context)!.saveChanges,
            ),

            OptionToolbarRow(
              onTap: () => _showDeleteSheet(context),
              icon: NotesIcon.deleteIcon,
              label: AppLocalizations.of(context)!.delete,
            ),
          ],
        ),
      ),
    );
  }
}
