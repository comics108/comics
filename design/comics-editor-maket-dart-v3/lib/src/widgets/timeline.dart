import 'package:flutter/material.dart';

import '../controller.dart';
import '../models.dart';
import '../theme.dart';

/// Bottom timeline — the modernization of the original's scroll-as-time model.
/// Left gutter lists tracks (layers + sounds); the right area shows each
/// animation as a bar spanning Start→End, with a draggable playhead.
class Timeline extends StatelessWidget {
  const Timeline({super.key, this.compact = false});
  final bool compact;

  static const double pxPerFrame = 1.2; // 600 frames -> 720px
  static const double gutter = 170;
  static const double rowH = 30;
  static const double rulerH = 34;

  @override
  Widget build(BuildContext context) {
    final c = EditorScope.of(context);
    if (compact) return _CompactStrip(c);

    final doc = c.doc!;
    return Container(
      decoration: BoxDecoration(
        color: Hs.white,
        borderRadius: BorderRadius.circular(Hs.rCard),
        boxShadow: Hs.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          // gutter
          SizedBox(
            width: gutter,
            child: Column(children: [
              _GutterHead(c),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    for (var i = 0; i < doc.layers.length; i++)
                      _GutterRow(doc.layers[i].name,
                          selected: c.selKind == SelKind.layer && c.selIndex == i,
                          onTap: () => c.selectLayer(i)),
                    for (var i = 0; i < doc.sounds.length; i++)
                      _GutterRow(doc.sounds[i].file,
                          sound: true,
                          selected: c.selKind == SelKind.sound && c.selIndex == i,
                          onTap: () => c.selectSound(i)),
                  ],
                ),
              ),
            ]),
          ),
          const VerticalDivider(width: 1, color: Hs.divider),
          Expanded(child: _Tracks(c)),
        ],
      ),
    );
  }
}

class _GutterHead extends StatelessWidget {
  const _GutterHead(this.c);
  final EditorController c;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: Timeline.rulerH,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Hs.divider))),
      child: Row(children: [
        _PlayButton(size: 26),
        const SizedBox(width: 8),
        Text('frame ${c.playhead}',
            style: TextStyle(
                fontFamily: Hs.serifData.first,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Hs.textBody)),
      ]),
    );
  }
}

class _GutterRow extends StatelessWidget {
  const _GutterRow(this.name,
      {this.sound = false, this.selected = false, required this.onTap});
  final String name;
  final bool sound;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: Timeline.rowH,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? Hs.blue100 : null,
          border: const Border(bottom: BorderSide(color: Hs.dividerLight)),
        ),
        child: Text(name,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                color: sound ? Hs.coral500 : Hs.textBody)),
      ),
    );
  }
}

class _Tracks extends StatelessWidget {
  const _Tracks(this.c);
  final EditorController c;
  @override
  Widget build(BuildContext context) {
    final doc = c.doc!;
    final contentW = c.totalFrames * Timeline.pxPerFrame;
    return Container(
      color: Hs.gray50,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: contentW,
          child: Stack(children: [
            Column(children: [
              _Ruler(contentW),
              for (var i = 0; i < doc.layers.length; i++)
                _TrackRow(anims: doc.layers[i].anims),
              for (var i = 0; i < doc.sounds.length; i++)
                _TrackRow(anims: doc.sounds[i].anims),
            ]),
            // playhead (draggable)
            Positioned(
              left: c.playhead * Timeline.pxPerFrame - 7,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragUpdate: (d) => c.setPlayhead(
                    ((c.playhead * Timeline.pxPerFrame + d.delta.dx) /
                            Timeline.pxPerFrame)
                        .round()),
                child: SizedBox(
                  width: 16,
                  child: Column(children: [
                    Container(
                      width: 14,
                      height: 12,
                      decoration: const BoxDecoration(color: Hs.blue600),
                    ),
                    Expanded(
                      child: Center(
                        child: Container(width: 2, color: Hs.blue600),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Ruler extends StatelessWidget {
  const _Ruler(this.width);
  final double width;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: Timeline.rulerH,
      width: width,
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Hs.divider))),
      child: Stack(children: [
        for (var f = 0; f <= 600; f += 100)
          Positioned(
            left: f * Timeline.pxPerFrame,
            top: 0,
            bottom: 0,
            child: Row(children: [
              Container(width: 1, color: Hs.divider),
              Padding(
                padding: const EdgeInsets.only(left: 5, top: 11),
                child: Text('$f',
                    style: const TextStyle(fontSize: 9, color: Hs.textTertiary)),
              ),
            ]),
          ),
      ]),
    );
  }
}

class _TrackRow extends StatelessWidget {
  const _TrackRow({required this.anims});
  final List<Anim> anims;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: Timeline.rowH,
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Hs.dividerLight))),
      child: Stack(children: [
        for (final a in anims)
          Positioned(
            left: a.start * Timeline.pxPerFrame,
            top: 6,
            width: (a.end - a.start) * Timeline.pxPerFrame,
            height: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: Hs.animColor(a.title),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(a.title,
                  overflow: TextOverflow.clip,
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w500, color: Hs.white)),
            ),
          ),
      ]),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({this.size = 44});
  final double size;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(color: Hs.blue500, shape: BoxShape.circle),
      child: Icon(Icons.play_arrow, color: Hs.white, size: size * .55),
    );
  }
}

/// Phone / tablet condensed timeline: one merged track + playhead + expand.
class _CompactStrip extends StatelessWidget {
  const _CompactStrip(this.c);
  final EditorController c;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Hs.white,
        borderRadius: BorderRadius.circular(Hs.rCard),
        boxShadow: Hs.cardShadow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(children: [
        _PlayButton(size: 40),
        const SizedBox(width: 12),
        Text('frame ${c.playhead}',
            style: TextStyle(
                fontFamily: Hs.serifData.first,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Hs.textBody)),
        const SizedBox(width: 12),
        Expanded(
          child: LayoutBuilder(builder: (context, box) {
            final w = box.maxWidth;
            return GestureDetector(
              onTapDown: (d) =>
                  c.setPlayhead((d.localPosition.dx / w * c.totalFrames).round()),
              onHorizontalDragUpdate: (d) =>
                  c.setPlayhead((d.localPosition.dx / w * c.totalFrames).round()),
              child: Container(
                height: 26,
                decoration: BoxDecoration(
                    color: Hs.gray50, borderRadius: BorderRadius.circular(6)),
                clipBehavior: Clip.antiAlias,
                child: Stack(children: [
                  for (final a in _allAnims(c))
                    Positioned(
                      left: a.start / c.totalFrames * w,
                      width: (a.end - a.start) / c.totalFrames * w,
                      top: 5,
                      height: 16,
                      child: Container(
                        decoration: BoxDecoration(
                            color: Hs.animColor(a.title),
                            borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                  Positioned(
                    left: c.playhead / c.totalFrames * w - 1,
                    top: 0,
                    bottom: 0,
                    child: Container(width: 2, color: Hs.blue600),
                  ),
                ]),
              ),
            );
          }),
        ),
      ]),
    );
  }

  List<Anim> _allAnims(EditorController c) => [
        for (final l in c.doc!.layers) ...l.anims,
        for (final s in c.doc!.sounds) ...s.anims,
      ];
}
