import 'package:flutter/material.dart';

import '../controller.dart';
import '../models.dart';
import '../theme.dart';
import 'common.dart';

/// Right "Properties" pane — Layer editor (localized artwork + animations)
/// or Sound editor, plus the per-animation parameter card.
class PropertiesPanel extends StatelessWidget {
  const PropertiesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final c = EditorScope.of(context);
    Widget body;
    if (c.selectedLayer != null) {
      body = _LayerEditor(c);
    } else if (c.selectedSound != null) {
      body = _SoundEditor(c);
    } else {
      body = const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Select a layer or sound',
              textAlign: TextAlign.center,
              style: TextStyle(color: Hs.textTertiary, fontSize: 14)),
        ),
      );
    }
    return PanelCard(child: body);
  }
}

class _EditorHeader extends StatelessWidget {
  const _EditorHeader(this.swatch, this.name, this.kind);
  final Color? swatch;
  final String name;
  final String kind;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Hs.divider))),
      child: Row(children: [
        if (swatch != null) ...[
          HatchSwatch(swatch!, size: 28),
          const SizedBox(width: 10),
        ] else ...[
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
                color: Hs.coral500, borderRadius: BorderRadius.circular(4)),
            child: const Icon(Icons.graphic_eq, size: 15, color: Hs.white),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
            child: Text(name,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis)),
        Text(kind.toUpperCase(),
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: .5,
                color: Hs.textSecondary)),
      ]),
    );
  }
}

class _LayerEditor extends StatelessWidget {
  const _LayerEditor(this.c);
  final EditorController c;
  @override
  Widget build(BuildContext context) {
    final l = c.selectedLayer!;
    final img = l.images[c.lang.index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EditorHeader(l.swatch, l.name, 'Layer'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(14),
            children: [
              const Text('ARTWORK · PER LANGUAGE', style: kSectionLabel),
              const SizedBox(height: 10),
              HsSegmented<Lang>(
                values: kLangs,
                labelOf: (x) => x.label,
                selected: c.lang,
                height: 32,
                onChanged: c.setLanguage,
              ),
              const SizedBox(height: 12),
              _FileField('File', img.file.isEmpty ? '— none —' : img.file,
                  onPick: () => c.setImageFile(c.lang.index, 'picked_${c.lang.label}.png')),
              const SizedBox(height: 10),
              _FileField('Popup', img.popup.isEmpty ? '— none —' : img.popup,
                  onPick: () => c.setImagePopup(c.lang.index, 'popup_${c.lang.label}.png')),
              const SizedBox(height: 14),
              InkWell(
                onTap: c.togglePreview,
                child: Row(children: [
                  _Check(l.preview),
                  const SizedBox(width: 8),
                  const Text('Preview this layer', style: TextStyle(fontSize: 14)),
                ]),
              ),
              const SizedBox(height: 18),
              _AnimSection(c, sound: false),
            ],
          ),
        ),
      ],
    );
  }
}

class _SoundEditor extends StatelessWidget {
  const _SoundEditor(this.c);
  final EditorController c;
  @override
  Widget build(BuildContext context) {
    final s = c.selectedSound!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EditorHeader(null, s.file, 'Sound'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(14),
            children: [
              const Text('SOUND FILE', style: kSectionLabel),
              const SizedBox(height: 10),
              _FileField('File', s.file, onPick: () {}),
              const SizedBox(height: 18),
              _AnimSection(c, sound: true),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnimSection extends StatelessWidget {
  const _AnimSection(this.c, {required this.sound});
  final EditorController c;
  final bool sound;
  @override
  Widget build(BuildContext context) {
    final anims = c.selectedAnims;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('ANIMATIONS', style: kSectionLabel),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var i = 0; i < anims.length; i++)
              _AnimChip(anims[i].title, i == c.selAnim, () => c.selectAnim(i)),
          ],
        ),
        const SizedBox(height: 10),
        if (sound)
          Row(children: [
            Expanded(
                child: _AddChip('+ Sound cue', () => c.addAnim(AnimType.sound))),
          ])
        else
          Row(children: [
            Expanded(child: _AddChip('+ Translate', () => c.addAnim(AnimType.translate))),
            const SizedBox(width: 6),
            Expanded(child: _AddChip('+ Rotate', () => c.addAnim(AnimType.rotate))),
            const SizedBox(width: 6),
            Expanded(child: _AddChip('+ Scale', () => c.addAnim(AnimType.scale))),
            const SizedBox(width: 6),
            Expanded(child: _AddChip('+ Alpha', () => c.addAnim(AnimType.alpha))),
          ]),
        const SizedBox(height: 14),
        if (c.currentAnim != null) _AnimParams(c, c.currentAnim!),
      ],
    );
  }
}

class _AnimParams extends StatelessWidget {
  const _AnimParams(this.c, this.a);
  final EditorController c;
  final Anim a;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Hs.gray50,
        border: Border.all(color: Hs.divider),
        borderRadius: BorderRadius.circular(Hs.rChip),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                    color: Hs.animColor(a.title),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Expanded(
                child: Text(a.title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500))),
            InkWell(
              onTap: c.deleteAnim,
              child: const Icon(Icons.close, size: 16, color: Hs.textSecondary),
            ),
          ]),
          const SizedBox(height: 12),
          // every anim shares Start / End
          _Row2(
            NumberField(label: 'Start', value: a.start, onChanged: (v) => c.editAnim((x) => x.start = v.toInt())),
            NumberField(label: 'End', value: a.end, onChanged: (v) => c.editAnim((x) => x.end = v.toInt())),
          ),
          ..._typeFields(),
        ],
      ),
    );
  }

  List<Widget> _typeFields() {
    switch (a.type) {
      case AnimType.translate:
        return [
          const SizedBox(height: 8),
          _Row2(
            NumberField(label: 'X', value: a.x, decimals: true, onChanged: (v) => c.editAnim((x) => x.x = v.toDouble())),
            NumberField(label: 'Y', value: a.y, decimals: true, onChanged: (v) => c.editAnim((x) => x.y = v.toDouble())),
          ),
        ];
      case AnimType.rotate:
        return [
          const SizedBox(height: 8),
          _Row2(
            NumberField(label: 'Center X', value: a.pivotX, decimals: true, onChanged: (v) => c.editAnim((x) => x.pivotX = v.toDouble())),
            NumberField(label: 'Center Y', value: a.pivotY, decimals: true, onChanged: (v) => c.editAnim((x) => x.pivotY = v.toDouble())),
          ),
          const SizedBox(height: 8),
          NumberField(label: 'Angle', value: a.angle, decimals: true, onChanged: (v) => c.editAnim((x) => x.angle = v.toDouble())),
        ];
      case AnimType.scale:
        return [
          const SizedBox(height: 8),
          _Row2(
            NumberField(label: 'Center X', value: a.pivotX, decimals: true, onChanged: (v) => c.editAnim((x) => x.pivotX = v.toDouble())),
            NumberField(label: 'Center Y', value: a.pivotY, decimals: true, onChanged: (v) => c.editAnim((x) => x.pivotY = v.toDouble())),
          ),
          const SizedBox(height: 8),
          _Row2(
            NumberField(label: 'Scale X', value: a.scaleX, decimals: true, onChanged: (v) => c.editAnim((x) => x.scaleX = v.toDouble())),
            NumberField(label: 'Scale Y', value: a.scaleY, decimals: true, onChanged: (v) => c.editAnim((x) => x.scaleY = v.toDouble())),
          ),
        ];
      case AnimType.alpha:
        return [
          const SizedBox(height: 8),
          NumberField(label: 'Alpha', value: a.alpha, decimals: true, onChanged: (v) => c.editAnim((x) => x.alpha = v.toDouble().clamp(0, 1))),
        ];
      case AnimType.sound:
        return const [];
    }
  }
}

class _Row2 extends StatelessWidget {
  const _Row2(this.a, this.b);
  final Widget a, b;
  @override
  Widget build(BuildContext context) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: a),
        const SizedBox(width: 8),
        Expanded(child: b),
      ]);
}

class _AnimChip extends StatelessWidget {
  const _AnimChip(this.label, this.selected, this.onTap);
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Hs.blue500 : Hs.cloud200,
          borderRadius: BorderRadius.circular(Hs.rChip),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                color: selected ? Hs.white : Hs.primary)),
      ),
    );
  }
}

class _AddChip extends StatelessWidget {
  const _AddChip(this.label, this.onTap);
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Hs.rChip),
          border: Border.all(color: Hs.gray400, style: BorderStyle.solid),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 12, color: Hs.textSecondary)),
      ),
    );
  }
}

class _FileField extends StatelessWidget {
  const _FileField(this.label, this.value, {required this.onPick});
  final String label;
  final String value;
  final VoidCallback onPick;
  @override
  Widget build(BuildContext context) {
    final empty = value.startsWith('—');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Hs.textSecondary)),
        const SizedBox(height: 4),
        Row(children: [
          Expanded(
            child: Container(
              height: 38,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Hs.cloud200, width: 2),
                borderRadius: BorderRadius.circular(Hs.rChip),
              ),
              child: Text(value,
                  overflow: TextOverflow.ellipsis,
                  style: serifValue(empty ? Hs.textTertiary : Hs.primary)),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onPick,
            child: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Hs.cloud200,
                borderRadius: BorderRadius.circular(Hs.rBtn),
              ),
              child: const Text('…',
                  style: TextStyle(fontSize: 16, color: Hs.primary)),
            ),
          ),
        ]),
      ],
    );
  }
}

class _Check extends StatelessWidget {
  const _Check(this.on);
  final bool on;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: on ? Hs.blue500 : Hs.white,
        border: Border.all(color: on ? Hs.blue500 : Hs.cloud200, width: 2),
        borderRadius: BorderRadius.circular(5),
      ),
      child: on ? const Icon(Icons.check, size: 14, color: Hs.white) : null,
    );
  }
}
