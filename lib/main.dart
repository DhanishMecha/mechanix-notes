import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hive/hive.dart';
import 'package:mechanix_notes/core/utils/app_routes.dart';
import 'package:mechanix_notes/core/utils/colors.dart';
import 'package:mechanix_notes/features/notes/bloc/notes/notes_bloc.dart';
import 'package:mechanix_notes/features/notes/data/models/note_model.dart';
import 'package:mechanix_notes/features/notes/data/repository/note_repository.dart';
import 'package:mechanix_notes/features/notes/data/repository/note_repository_impl.dart';
import 'package:mechanix_notes/features/notes/data/repository/editor_repository.dart';
import 'package:mechanix_notes/features/notes/data/repository/editor_repository_impl.dart';
import 'package:mechanix_notes/features/notes/presentation/screens/editor.dart';
import 'package:mechanix_notes/features/notes/presentation/screens/home.dart';
import 'package:mechanix_notes/l10n/notes_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Hive.registerAdapter(NoteModelAdapter());

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<NoteRepository>(create: (_) => NoteRepositoryImpl()),
        RepositoryProvider<EditorRepository>(
          create: (_) => EditorRepositoryImpl(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                NotesBloc(noteRepository: context.read<NoteRepository>()),
          ),
        ],
        child: const NotesApp(),
      ),
    ),
  );
}

class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {TargetPlatform.linux: CupertinoPageTransitionsBuilder()},
        ),
        scrollbarTheme: const ScrollbarThemeData(
          radius: Radius.circular(4),
          thickness: WidgetStatePropertyAll(4),
          thumbColor: WidgetStatePropertyAll(NotesColors.timeLabelColor),
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.white,
        ),
      ),
      theme: ThemeData.light(useMaterial3: true),
      home: const HomeScreen(),
      locale: const Locale('en'),
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routes: {AppRoutes.noteEditor: (context) => const EditorScreen()},
    );
  }
}
