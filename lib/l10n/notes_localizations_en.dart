// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'notes_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get notes => 'Notes';

  @override
  String get noNotesFound => 'No notes found';

  @override
  String get recent => 'Recent';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get thisWeek => 'This Week';

  @override
  String get lastWeek => 'Last Week';

  @override
  String get thisMonth => 'This Month';

  @override
  String get lastMonth => 'Last Month';

  @override
  String get startWriting => 'Start writing…';

  @override
  String get title => 'Title';

  @override
  String get undo => 'Undo';

  @override
  String get redo => 'Redo';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get goBack => 'Go Back';

  @override
  String deleteNotePrompt(String noteTitle) {
    return 'Delete \'$noteTitle\'?';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get deleteNoteSubtitle =>
      'This note will be permanently deleted and cannot be recovered.';

  @override
  String get delete => 'Delete';
}
