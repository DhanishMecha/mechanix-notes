import 'package:flutter/material.dart';
import 'package:mechanix_notes/core/utils/helper.dart';
import 'package:mechanix_notes/features/notes/data/models/time_group.dart';

class HomeGroupHeader extends StatelessWidget {
  const HomeGroupHeader({super.key, required this.group});

  final TimeGroup group;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 26.0),
          child: Text(
            getLocalizedLabelForTimeNotes(context, group),
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
