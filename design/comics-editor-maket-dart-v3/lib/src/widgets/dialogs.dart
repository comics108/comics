import 'package:flutter/material.dart';

import '../controller.dart';
import '../models.dart';
import '../theme.dart';
import 'common.dart';

/// New / Open / Error dialogs — same actions as the WPF menu, no new features.

Future<void> showNewDialog(BuildContext context) async {
  final c = EditorScope.of(context);
  DocType choice = DocType.comics;
  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => _DialogShell(
        title: 'New document',
        width: 560,
        actions: [
          HsButton('Cancel',
              variant: HsVariant.cancel, onTap: () => Navigator.pop(ctx)),
          const SizedBox(width: 10),
          HsButton('Create', onTap: () {
            c.newDoc(choice);
            Navigator.pop(ctx);
          }),
        ],
        child: Row(children: [
          Expanded(
            child: _TypeCard(
              title: 'Comics',
              subtitle: 'Scrolling strip with timed layers & sound.',
              selected: choice == DocType.comics,
              preview: _stripPreview(),
              onTap: () => setState(() => choice = DocType.comics),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _TypeCard(
              title: 'Puzzle',
              subtitle: 'Zoomable board of draggable pieces.',
              selected: choice == DocType.puzzle,
              preview: _boardPreview(),
              onTap: () => setState(() => choice = DocType.puzzle),
            ),
          ),
        ]),
      ),
    ),
  );
}

Future<void> showOpenDialog(BuildContext context) async {
  final c = EditorScope.of(context);
  int sel = 0;
  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => _DialogShell(
        title: 'Open',
        width: 480,
        actions: [
          HsButton('Browse…',
              variant: HsVariant.secondary, onTap: () => Navigator.pop(ctx)),
          const Spacer(),
          HsButton('Open', onTap: () {
            c.openRecent(EditorController.recents[sel]);
            Navigator.pop(ctx);
          }),
        ],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Hs.cloud200, width: 2),
                borderRadius: BorderRadius.circular(Hs.rChip),
              ),
              child: const Row(children: [
                Icon(Icons.search, size: 16, color: Hs.textSecondary),
                SizedBox(width: 10),
                Text('Search…',
                    style: TextStyle(color: Hs.textTertiary, fontSize: 15)),
              ]),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < EditorController.recents.length; i++)
              _RecentRow(
                file: EditorController.recents[i],
                selected: i == sel,
                onTap: () => setState(() => sel = i),
              ),
          ],
        ),
      ),
    ),
  );
}

Future<void> showDuplicateError(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => _DialogShell(
      title: null,
      width: 380,
      actions: [
        const Spacer(),
        HsButton('OK', onTap: () => Navigator.pop(ctx)),
      ],
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
              color: Hs.coral500, shape: BoxShape.circle),
          child: const Icon(Icons.close, color: Hs.white, size: 18),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('File already exists',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              SizedBox(height: 4),
              Text('A file with this name already exists. Choose a different name.',
                  style: TextStyle(fontSize: 14, height: 1.5, color: Hs.textBody)),
            ],
          ),
        ),
      ]),
    ),
  );
}

// ---------------- shared shell ----------------

class _DialogShell extends StatelessWidget {
  const _DialogShell({
    required this.title,
    required this.width,
    required this.child,
    required this.actions,
  });
  final String? title;
  final double width;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Hs.white,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Hs.rCard)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
                decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Hs.divider))),
                child: Row(children: [
                  Expanded(
                      child: Text(title!,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w500))),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 18, color: Hs.textSecondary),
                  ),
                ]),
              ),
            Padding(padding: const EdgeInsets.all(20), child: child),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(children: actions),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.preview,
    required this.onTap,
  });
  final String title, subtitle;
  final bool selected;
  final Widget preview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
              color: selected ? Hs.blue500 : Hs.divider,
              width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(Hs.rCard),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 120, child: preview),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 13, color: Hs.textSecondary, height: 1.35)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow(
      {required this.file, required this.selected, required this.onTap});
  final RecentFile file;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final puzzle = file.type == DocType.puzzle;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Hs.blue100 : null,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
                color: selected ? Hs.blue500 : Hs.cloud200,
                borderRadius: BorderRadius.circular(5)),
            child: Icon(puzzle ? Icons.grid_view : Icons.image_outlined,
                size: 15, color: selected ? Hs.white : Hs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(file.name, style: const TextStyle(fontSize: 15)),
                Text(file.meta,
                    style:
                        const TextStyle(fontSize: 12, color: Hs.textSecondary)),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

Widget _stripPreview() => CustomPaint(painter: _StripPainter(), child: const SizedBox.expand());
Widget _boardPreview() => CustomPaint(painter: _BoardPainter(), child: const SizedBox.expand());

class _StripPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    for (double y = 0; y < size.height; y += 22) {
      p.color = (y / 22).floor().isEven
          ? const Color(0xFF26384D)
          : const Color(0xFF2C4256);
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 22), p);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _BoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cell = 22.0;
    final p = Paint();
    for (double y = 0; y < size.height; y += cell) {
      for (double x = 0; x < size.width; x += cell) {
        final even = (((x / cell) + (y / cell)).floor()).isEven;
        p.color = even ? const Color(0xFF3A4A58) : const Color(0xFF455663);
        canvas.drawRect(Rect.fromLTWH(x, y, cell, cell), p);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
