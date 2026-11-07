import 'package:flutter/material.dart';
import '../../media/presentation/media_section_screen.dart';

/// Onglet « Chansons & Dialogues » : remplace l'ancienne liste de phrases par une
/// interface exclusivement dédiée aux dialogues parlés de Conrad & Katja et aux chansons.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MediaSectionScreen(isEmbeddedInTab: true);
  }
}
