import 'package:flutter/material.dart';
import 'package:mechanix_notes/core/utils/colors.dart';
import 'package:mechanix_notes/core/utils/helper.dart';

class HomeGroupHeader extends StatelessWidget {
  const HomeGroupHeader({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 26.0),
          child: Text(
            getLocalizedLabelForTimeNotes(context, label),
            style: const TextStyle(
              color: NotesColors.timeLabelColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
