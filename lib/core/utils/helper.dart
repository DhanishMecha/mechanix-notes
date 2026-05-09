import 'package:flutter/material.dart';
import 'package:mechanix_notes/l10n/notes_localizations.dart';

String getLocalizedLabelForTimeNotes(BuildContext context, String label) {
  switch (label) {
    case "Recent":
      return AppLocalizations.of(context)!.recent;
    case "Today":
      return AppLocalizations.of(context)!.today;
    case "Yesterday":
      return AppLocalizations.of(context)!.yesterday;
    case "This Week":
      return AppLocalizations.of(context)!.thisWeek;
    case "Last Week":
      return AppLocalizations.of(context)!.lastWeek;
    case "This Month":
      return AppLocalizations.of(context)!.thisMonth;
    case "Last Month":
      return AppLocalizations.of(context)!.lastMonth;
    default:
      return label;
  }
}
