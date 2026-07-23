import 'package:flutter/material.dart';

import '../controller.dart';
import '../models.dart';
import '../theme.dart';
import 'common.dart';

/// Left "Scene" column: canvas settings + Layers + Sounds
/// (LayersListControl + SoundsListControl + SettingsControl in the original).
class ScenePanel extends StatelessWidget {
  const ScenePanel({super.key, this.showSettings = true});
  final bool showSettings;

  @override
  Widget build(BuildContext context) {
    final c = EditorScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showSettings) ...[
          PanelCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CANVAS', style: kSectionLabel),
                const SizedBox(height: 10),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Expanded(
                    child: NumberField(
                      label: 'Width',
                      value: c.doc!.width,
                      height: 38,
                      onChanged: (v) => c.setCanvasSize(v.toInt(), null),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: NumberField(
                      label: 'Height',
                      value: c.doc!.height,
                      height: 38,
                      onChanged: (v) => c.setCanvasSize(null, v.toInt()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  HsButton('Convert',
                      variant: HsVariant.secondary,
                      height: 38,
                      onTap: () => _convertToast(context)),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        Expanded(
          child: PanelCard(
            child: Column(
              children: [
                Expanded(child: _LayersSection(c)),
                const Divider(height: 1, color: Hs.divider),
                _SoundsSection(c),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _convertToast(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Hs.gray800,
      content: Text('Converting artwork to canvas size…'),
    ));
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, this.actions);
  final String title;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Row(children: [
        Expanded(child: Text(title, style: kSectionLabel)),
        ...actions,
      ]),
    );
  }
}

class _LayersSection extends StatelessWidget {
  const _LayersSection(this.c);
  final EditorController c;
  @override
  Widget build(BuildContext context) {
    final layers = c.doc!.layers;
    return Column(
      children: [
        _SectionHeader('LAYERS', [
          HsIconButton(Icons.add, tooltip: 'Add', onTap: c.addLayer),
          const SizedBox(width: 6),
          HsIconButton(Icons.arrow_upward, tooltip: 'Up', onTap: () => c.moveLayer(-1)),
          const SizedBox(width: 6),
          HsIconButton(Icons.arrow_downward, tooltip: 'Down', onTap: () => c.moveLayer(1)),
          const SizedBox(width: 6),
          HsIconButton(Icons.close, filled: true, tooltip: 'Delete', onTap: c.deleteSelected),
        ]),
        Expanded(
          child: layers.isEmpty
              ? const _Empty('No layers yet')
              : ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: layers.length,
                  itemBuilder: (_, i) => _LayerRow(c, i),
                ),
        ),
      ],
    );
  }
}

class _LayerRow extends StatelessWidget {
  const _LayerRow(this.c, this.i);
  final EditorController c;
  final int i;
  @override
  Widget build(BuildContext context) {
    final l = c.doc!.layers[i];
    final selected = c.selKind == SelKind.layer && c.selIndex == i;
    return InkWell(
      onTap: () => c.selectLayer(i),
      child: Container(
        decoration: BoxDecoration(
          color: selected ? Hs.blue100 : Hs.white,
          border: Border(
            left: BorderSide(
                color: selected ? Hs.blue500 : Colors.transparent, width: 3),
            top: const BorderSide(color: Hs.dividerLight),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(9, 8, 12, 8),
        child: Row(children: [
          HsToggle(value: l.visible, onTap: () => c.toggleVisible(i)),
          const SizedBox(width: 10),
          Opacity(opacity: l.visible ? 1 : .4, child: HatchSwatch(l.swatch)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(l.name,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                    color: l.visible ? Hs.textBody : Hs.textSecondary),
                overflow: TextOverflow.ellipsis),
          ),
        ]),
      ),
    );
  }
}

class _SoundsSection extends StatelessWidget {
  const _SoundsSection(this.c);
  final EditorController c;
  @override
  Widget build(BuildContext context) {
    final sounds = c.doc!.sounds;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SectionHeader('SOUNDS', [
          HsIconButton(Icons.add, tooltip: 'Add', onTap: c.addSound),
          const SizedBox(width: 6),
          HsIconButton(c.muted ? Icons.volume_off : Icons.volume_up,
              filled: c.muted, tooltip: 'Mute', onTap: c.toggleMute),
          const SizedBox(width: 6),
          HsIconButton(Icons.close, filled: true, tooltip: 'Delete', onTap: c.deleteSelected),
        ]),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 140),
          child: sounds.isEmpty
              ? const Padding(
                  padding: EdgeInsets.only(bottom: 12), child: _Empty('No sounds'))
              : ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 6),
                  itemCount: sounds.length,
                  itemBuilder: (_, i) {
                    final s = sounds[i];
                    final sel = c.selKind == SelKind.sound && c.selIndex == i;
                    return InkWell(
                      onTap: () => c.selectSound(i),
                      child: Container(
                        color: sel ? Hs.blue100 : null,
                        padding: const EdgeInsets.fromLTRB(12, 7, 12, 7),
                        child: Row(children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                                color: Hs.coral500,
                                borderRadius: BorderRadius.circular(5)),
                            child: Icon(c.muted ? Icons.volume_off : Icons.graphic_eq,
                                size: 12, color: Hs.white),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(s.file,
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: c.muted ? Hs.textTertiary : Hs.textBody))),
                        ]),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(text,
              style: const TextStyle(color: Hs.textTertiary, fontSize: 13)),
        ),
      );
}
