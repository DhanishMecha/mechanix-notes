import 'package:flutter/material.dart';
import 'package:mechanix_notes/core/utils/colors.dart';
import 'package:mechanix_notes/core/utils/icons.dart';
import 'package:mechanix_notes/features/notes/data/models/note_metadata.dart';

import 'package:mechanix_notes/core/widgets/clickable_region.dart';

class HomeNoteCard extends StatelessWidget {
  final NoteMetaData note;

  const HomeNoteCard({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    return ClickableRegion(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          Navigator.pushNamed(
            context,
            '/note-editor',
            arguments: {'noteId': note.id, 'noteTitle': note.title},
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: NotesColors.borderColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.center,
                child: Image.asset(NotesIcon.editIcon, width: 16, height: 16),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return "Just now";
    } else if (difference.inMinutes < 60) {
      return "${difference.inMinutes} m ago";
    } else if (difference.inHours < 24) {
      if (date.day == now.day) {
        return "${difference.inHours} h ago";
      } else {
        return "${date.hour}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'pm' : 'am'}";
      }
    } else {
      return "${date.hour}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'pm' : 'am'}";
    }
  }
}
