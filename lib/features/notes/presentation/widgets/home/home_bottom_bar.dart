import 'package:flutter/material.dart';
import 'package:mechanix_notes/core/utils/colors.dart';
import 'package:mechanix_notes/core/utils/icons.dart';
import 'package:mechanix_notes/core/widgets/clickable_region.dart';

class HomeBottomBar extends StatelessWidget {
  const HomeBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: NotesColors.bottomBarBg,
            border: Border.all(color: NotesColors.borderColor, width: 0.5),
          ),
          width: 300,
          height: 60.5,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClickableRegion(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/note-editor');
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: NotesColors.borderColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: Image.asset(
                      NotesIcon.createIcon,
                      width: 28,
                      height: 28,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              ClickableRegion(
                child: GestureDetector(
                  onTap: () {},
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset(
                      NotesIcon.searchIcon,
                      width: 28,
                      height: 28,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
