import 'package:flutter/material.dart';
import 'package:mechanix_notes/features/notes/presentation/widgets/home/home_floating_bar.dart';
import 'package:mechanix_notes/features/notes/presentation/widgets/home/home_title_bar.dart';
import 'package:mechanix_notes/features/notes/presentation/widgets/home/home_notes_view.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      appBar: PreferredSize(preferredSize: Size(60, 60), child: HomeTitleBar()),
      floatingActionButton: HomeFloatingBar(),
      body: HomeNotesView(),
    );
  }
}
