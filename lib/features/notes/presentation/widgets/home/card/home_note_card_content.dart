import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mechanix_notes/core/utils/app_logger.dart';
import 'package:mechanix_notes/core/utils/colors.dart';
import 'package:mechanix_notes/core/widgets/clickable_region.dart';
import 'package:mechanix_notes/features/notes/data/models/note_metadata.dart';
import 'package:mechanix_notes/features/notes/presentation/widgets/home/card/home_card_icon.dart';
import 'package:mechanix_notes/features/notes/presentation/widgets/home/card/home_card_selection_icon.dart';

class HomeNoteCardContent extends StatelessWidget {
  final NoteMetaData note;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const HomeNoteCardContent({
    super.key,
    required this.note,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return ClickableRegion(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onLongPress: isSelectionMode ? null : onLongPress,
        onTap: onTap,
        child: Container(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HomeNoteCardLeadingIcon(
                isSelectionMode: isSelectionMode,
                isSelected: isSelected,
              ),
              const SizedBox(width: 16),
              Expanded(child: _HomeNoteCardText(note: note)),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeNoteCardLeadingIcon extends StatelessWidget {
  final bool isSelectionMode;
  final bool isSelected;

  const _HomeNoteCardLeadingIcon({
    required this.isSelectionMode,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return isSelectionMode
        ? HomeCardSelectionIcon(isSelected: isSelected)
        : const HomeCardIcon();
  }
}

class _HomeNoteCardText extends StatelessWidget {
  final NoteMetaData note;

  const _HomeNoteCardText({required this.note});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          note.title.isNotEmpty ? note.title : note.previewText,
          style: const TextStyle(
            color: NotesColors.titleColor,
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Text(
          _formatDate(note.updatedAt),
          style: const TextStyle(
            color: NotesColors.timeLabelColor,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    AppLogger.i(
      "Format date for note ${note.title.isNotEmpty ? note.title : note.previewText}: $difference, Current: $now, Note: $date",
    );

    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;

    if (isToday) {
      if (difference.inMinutes < 1) {
        return "Just now";
      } else if (difference.inMinutes < 60) {
        return "${difference.inMinutes} m ago";
      } else {
        return "${difference.inHours} h ago";
      }
    }

    return DateFormat("d MMM yyyy").format(date);
  }
}
