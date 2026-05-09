import 'package:flutter/material.dart';
import 'package:mechanix_notes/core/utils/colors.dart';
import 'package:mechanix_notes/core/utils/icons.dart';
import 'package:mechanix_notes/core/widgets/clickable_region.dart';
import 'package:mechanix_notes/l10n/notes_localizations.dart';

class HomeTitleBar extends StatelessWidget {
  const HomeTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 20, top: 16, bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppLocalizations.of(context)!.notes,
            style: const TextStyle(
              color: NotesColors.appTitleColor,
              fontSize: 24,
            ),
          ),
          ClickableRegion(
            child: Image.asset(NotesIcon.gridIcon, width: 24, height: 24),
          ),
        ],
      ),
    );
  }
}
