import 'package:flutter/material.dart';

import 'src/controller.dart';
import 'src/theme.dart';
import 'src/screens/editor_screen.dart';

void main() => runApp(const ComicsEditorApp());

class ComicsEditorApp extends StatefulWidget {
  const ComicsEditorApp({super.key});

  @override
  State<ComicsEditorApp> createState() => _ComicsEditorAppState();
}

class _ComicsEditorAppState extends State<ComicsEditorApp> {
  final EditorController controller = EditorController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Comics Editor',
      debugShowCheckedModeBanner: false,
      theme: buildHolySpotsTheme(),
      // EditorScope makes the single source of truth available to every widget
      // and rebuilds listeners when the document / selection changes.
      home: EditorScope(
        controller: controller,
        child: const EditorScreen(),
      ),
    );
  }
}
