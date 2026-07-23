import 'package:flutter/material.dart';

import '../controller.dart';
import '../models.dart';
import '../theme.dart';
import 'common.dart';

/// The center stage. Renders the page (comics strip or puzzle board), lets you
/// drag the selected layer (Translate), draws selection handles, and hosts the
/// zoom control (puzzle Scale slider / comics fit) + Preview toggle.
class CanvasView extends StatelessWidget {
  const CanvasView({super.key, this.showPreviewToggle = true});
  final bool showPreviewToggle;

  @override
  Widget build(BuildContext context) {
    final c = EditorScope.of(context);
    return PanelCard(
      child: Stack(
        children: [
          Positioned.fill(child: _Stage(c)),
          Positioned(left: 14, bottom: 14, child: _ZoomControl(c)),
          if (showPreviewToggle)
            Positioned(right: 14, bottom: 14, child: _PreviewToggle(c)),
        ],
      ),
    );
  }
}

class _Stage extends StatelessWidget {
  const _Stage(this.c);
  final EditorController c;

  @override
  Widget build(BuildContext context) {
    final doc = c.doc!;
    final aspect = doc.width / doc.height;
    return Container(
      color: Hs.surfaceCloud,
      child: LayoutBuilder(builder: (context, box) {
        // Fit the page into the viewport, then apply puzzle zoom.
        final maxH = box.maxHeight - 40;
        final maxW = box.maxWidth - 40;
        double pageH = maxH, pageW = pageH * aspect;
        if (pageW > maxW) {
          pageW = maxW;
          pageH = pageW / aspect;
        }
        final scale = c.isPuzzle ? doc.scale : 1.0;
        pageW *= scale;
        pageH *= scale;
        return Center(
          child: SizedBox(
            width: pageW,
            height: pageH,
            child: _Page(c, Size(pageW, pageH)),
          ),
        );
      }),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page(this.c, this.size);
  final EditorController c;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final doc = c.doc!;
    // page-space uses the design width as reference; scale positions to px
    final k = size.width / doc.width;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFF0F1114),
        boxShadow: [
          BoxShadow(color: Color(0x59000000), blurRadius: 40, offset: Offset(0, 10))
        ],
      ),
      child: ClipRect(
        child: Stack(
          children: [
            for (var i = 0; i < doc.layers.length; i++)
              _LayerItem(c, i, k),
          ],
        ),
      ),
    );
  }
}

class _LayerItem extends StatelessWidget {
  const _LayerItem(this.c, this.i, this.k);
  final EditorController c;
  final int i;
  final double k; // page-units -> px
  @override
  Widget build(BuildContext context) {
    final doc = c.doc!;
    final l = doc.layers[i];
    if (!l.visible) return const SizedBox.shrink();
    final selected = c.selKind == SelKind.layer && c.selIndex == i;

    final w = doc.width * l.size * k;
    final h = w * 1.3;

    Widget swatch = SizedBox(
      width: w,
      height: h,
      child: Stack(children: [
        Positioned.fill(child: HatchSwatch(l.swatch, size: w, radius: 0)),
        Positioned(
          left: 8,
          top: 8,
          child: Text(l.name,
              style: TextStyle(
                  fontFamily: Hs.serifData.first,
                  fontSize: 11,
                  color: Colors.white.withOpacity(.75))),
        ),
        if (selected)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(border: Border.all(color: Hs.blue500, width: 1.5)),
            ),
          ),
      ]),
    );

    final left = l.translate.dx * k;
    final top = l.translate.dy * k;

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => c.selectLayer(i),
        onPanStart: (_) => c.selectLayer(i),
        onPanUpdate: (d) => c.dragSelected(Offset(d.delta.dx / k, d.delta.dy / k)),
        child: selected ? _WithHandles(child: swatch) : swatch,
      ),
    );
  }
}

/// 8 resize squares + a rotate stem — matches the WPF Scale/Rotate handles.
class _WithHandles extends StatelessWidget {
  const _WithHandles({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    const s = 10.0;
    Widget dot() => Container(
          width: s,
          height: s,
          decoration: BoxDecoration(
            color: Hs.white,
            border: Border.all(color: Hs.blue500, width: 1.5),
            borderRadius: BorderRadius.circular(2),
          ),
        );
    return Stack(clipBehavior: Clip.none, children: [
      child,
      Positioned(left: -s / 2, top: -s / 2, child: dot()),
      Positioned(right: -s / 2, top: -s / 2, child: dot()),
      Positioned(left: -s / 2, bottom: -s / 2, child: dot()),
      Positioned(right: -s / 2, bottom: -s / 2, child: dot()),
      Positioned(left: 0, right: 0, top: -s / 2, child: Center(child: dot())),
      Positioned(left: 0, right: 0, bottom: -s / 2, child: Center(child: dot())),
      Positioned(top: 0, bottom: 0, left: -s / 2, child: Center(child: dot())),
      Positioned(top: 0, bottom: 0, right: -s / 2, child: Center(child: dot())),
      // rotate stem
      Positioned(
        left: 0,
        right: 0,
        top: -34,
        child: Center(
          child: Column(children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Hs.white,
                shape: BoxShape.circle,
                border: Border.all(color: Hs.blue500, width: 1.5),
              ),
            ),
            Container(width: 2, height: 22, color: Hs.blue500),
          ]),
        ),
      ),
    ]);
  }
}

class _ZoomControl extends StatelessWidget {
  const _ZoomControl(this.c);
  final EditorController c;
  @override
  Widget build(BuildContext context) {
    final pct = ((c.isPuzzle ? c.doc!.scale : 1.0) * 100).round();
    return Container(
      decoration: BoxDecoration(
        color: Hs.white,
        borderRadius: BorderRadius.circular(Hs.rBtn),
        boxShadow: Hs.cardShadow,
      ),
      padding: const EdgeInsets.all(4),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _zoomBtn('−', () => _bump(c, -.1)),
        SizedBox(
            width: 50,
            child: Text('$pct%',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        _zoomBtn('+', () => _bump(c, .1)),
        Container(width: 1, height: 20, color: Hs.divider, margin: const EdgeInsets.symmetric(horizontal: 2)),
        IconButton(
          onPressed: () => c.setScale(1),
          icon: const Icon(Icons.crop_free, size: 18, color: Hs.textSecondary),
          tooltip: 'Fit',
          visualDensity: VisualDensity.compact,
        ),
      ]),
    );
  }

  void _bump(EditorController c, double d) {
    if (!c.isPuzzle) return; // comics is fixed-fit like the original
    c.setScale((c.doc!.scale + d).clamp(0.125, 1));
  }

  Widget _zoomBtn(String t, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 30,
          height: 30,
          child: Center(
              child: Text(t, style: const TextStyle(fontSize: 18, color: Hs.textBody))),
        ),
      );
}

class _PreviewToggle extends StatelessWidget {
  const _PreviewToggle(this.c);
  final EditorController c;
  @override
  Widget build(BuildContext context) {
    final on = c.selectedLayer?.preview ?? false;
    return Container(
      decoration: BoxDecoration(
        color: Hs.white,
        borderRadius: BorderRadius.circular(Hs.rBtn),
        boxShadow: Hs.cardShadow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Text('Preview', style: TextStyle(fontSize: 13)),
        const SizedBox(width: 8),
        HsToggle(
            value: on,
            onTap: c.selectedLayer == null ? () {} : c.togglePreview),
      ]),
    );
  }
}
