import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_notes/core/utils/icons.dart';
import 'package:mechanix_notes/features/notes/bloc/editor/editor_bloc.dart';
import 'package:mechanix_notes/features/notes/presentation/widgets/editor/editor_button.dart';
import 'package:mechanix_notes/features/notes/presentation/widgets/editor/quill_controller_provider.dart';
import 'package:mechanix_notes/features/notes/presentation/widgets/editor/toolbar/menu_toolbar.dart';
import 'package:mechanix_notes/features/notes/presentation/widgets/editor/toolbar/options_toolbar.dart';
import 'package:mechanix_notes/features/notes/presentation/widgets/editor/toolbar/text_style_toolbar.dart';

class EditorBottomBar extends StatelessWidget {
  const EditorBottomBar({super.key});

  void _save(BuildContext context) {
    final controller = QuillControllerProvider.of(context).controller;
    final delta = controller.document.toDelta().toJson();
    final plainText = controller.document.toPlainText().trim();
    context.read<EditorBloc>().add(
      EditorSaveRequested(content: delta, plainText: plainText),
    );
  }

  void _toggle(BuildContext context, EditorToolbar toolbar) {
    context.read<EditorBloc>().add(EditorToolbarToggled(toolbar));
    if (toolbar == EditorToolbar.textStyle || toolbar == EditorToolbar.menu) {
      final provider = QuillControllerProvider.maybeOf(context);
      provider?.focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditorBloc, EditorState>(
      buildWhen: (prev, curr) =>
          curr is EditorLoaded &&
          prev is EditorLoaded &&
          prev.activeToolbar != curr.activeToolbar,
      builder: (context, state) {
        final activeToolbar = state is EditorLoaded
            ? state.activeToolbar
            : EditorToolbar.none;

        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (activeToolbar == EditorToolbar.textStyle)
                const TextStyleToolbar(),
              if (activeToolbar == EditorToolbar.menu) const MenuToolbar(),
              if (activeToolbar == EditorToolbar.options)
                const OptionsToolbar(),

              Container(
                height: 60,
                decoration: const BoxDecoration(color: Color(0xFF151515)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    EditorButton(
                      padding: const EdgeInsets.all(8),
                      size: 28,
                      asset: NotesIcon.backIcon,
                      onPress: () => _save(context),
                    ),
                    EditorButton(
                      size: 28,
                      padding: const EdgeInsets.all(8),
                      bgColor: activeToolbar == EditorToolbar.textStyle
                          ? const Color(0xFF2D2D2D)
                          : Colors.transparent,
                      asset: NotesIcon.textstyleIcon,
                      onPress: () => _toggle(context, EditorToolbar.textStyle),
                    ),
                    EditorButton(
                      size: 28,
                      padding: const EdgeInsets.all(8),
                      bgColor: activeToolbar == EditorToolbar.menu
                          ? const Color(0xFF2D2D2D)
                          : Colors.transparent,
                      asset: NotesIcon.menuIcon,
                      onPress: () => _toggle(context, EditorToolbar.menu),
                    ),
                    EditorButton(
                      size: 28,
                      padding: const EdgeInsets.all(8),
                      bgColor: activeToolbar == EditorToolbar.options
                          ? const Color(0xFF2D2D2D)
                          : Colors.transparent,
                      asset: NotesIcon.threedotIcon,
                      onPress: () => _toggle(context, EditorToolbar.options),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
