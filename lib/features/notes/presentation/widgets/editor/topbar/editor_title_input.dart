import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_notes/features/notes/bloc/editor/editor_bloc.dart';
import 'package:mechanix_notes/l10n/notes_localizations.dart';

class EditorTitleInput extends StatefulWidget {
  const EditorTitleInput();

  @override
  State<EditorTitleInput> createState() => EditorTitleInputState();
}

class EditorTitleInputState extends State<EditorTitleInput> {
  late final TextEditingController _titleController;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    final state = context.read<EditorBloc>().state;
    String initialTitle = '';
    if (state is EditorLoaded) {
      initialTitle = state.title;
    }
    _titleController = TextEditingController(text: initialTitle);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _titleController.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        context.read<EditorBloc>().add(EditorTitleChanged(value));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _titleController,
      maxLength: 50,
      maxLines: 1,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w400,
        color: Colors.white,
      ),
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.title,
        hintStyle: const TextStyle(color: Colors.white38),
        border: InputBorder.none,
        counterText: '',
        contentPadding: EdgeInsets.zero,
        isDense: true,
      ),
      onChanged: _onChanged,
    );
  }
}
