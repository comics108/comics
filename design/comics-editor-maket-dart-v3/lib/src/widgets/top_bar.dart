import 'package:flutter/material.dart';

import '../controller.dart';
import '../models.dart';
import '../responsive.dart';
import '../theme.dart';
import 'common.dart';
import 'dialogs.dart';

/// App brand mark — the stacked-layers glyph (not the HolySpots pin,
/// which is raster-only and must never be redrawn).
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 34});
  final double size;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Hs.blue500,
        borderRadius: BorderRadius.circular(size * .24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final o in [0.95, 0.7, 0.45])
            Container(
              width: size * .53,
              height: size * .12,
              margin: EdgeInsets.symmetric(vertical: size * .045),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(o),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}

class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final c = EditorScope.of(context);
    final ff = formFactorOf(context);
    final compact = ff.isPhone;

    return Container(
      height: compact ? 56 : 60,
      color: Hs.white,
      padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16),
      child: Row(
        children: [
          BrandMark(size: compact ? 30 : 34),
          const SizedBox(width: 10),
          if (!compact) ...[
            const Text('Comics Editor',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: Hs.blue100, borderRadius: BorderRadius.circular(20)),
              child: const Text('3.0',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Hs.blue500)),
            ),
            const SizedBox(width: 14),
            _DocPill(name: c.doc!.name),
          ] else
            Expanded(
              child: Text(c.doc!.name,
                  style:
                      const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis),
            ),
          if (!compact) const Spacer(),
          // actions
          HsIconButton(Icons.add, size: ff.iconBtn, onTap: () => showNewDialog(context)),
          const SizedBox(width: 8),
          HsIconButton(Icons.folder_open_outlined,
              size: ff.iconBtn, onTap: () => showOpenDialog(context)),
          const SizedBox(width: 8),
          HsButton('Save',
              icon: Icons.file_download_outlined,
              variant: HsVariant.save,
              height: ff.controlH,
              onTap: () => _saved(context)),
          if (!compact) ...[
            const SizedBox(width: 14),
            const _Divider(),
            const SizedBox(width: 14),
            HsSegmented<Lang>(
              values: kLangs,
              labelOf: (l) => l.label,
              selected: c.lang,
              height: ff.controlH,
              onChanged: c.setLanguage,
            ),
          ] else ...[
            const SizedBox(width: 8),
            PopupMenuButton<Lang>(
              tooltip: 'Language',
              initialValue: c.lang,
              onSelected: c.setLanguage,
              itemBuilder: (_) =>
                  kLangs.map((l) => PopupMenuItem(value: l, child: Text(l.label))).toList(),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    border: Border.all(color: Hs.cloud200),
                    borderRadius: BorderRadius.circular(Hs.rBtn)),
                child: Text(c.lang.label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, color: Hs.primary)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _saved(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Hs.gray800,
      content: Text('Saved ${EditorScope.of(context).doc!.name}'),
    ));
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 28, color: Hs.divider);
}

class _DocPill extends StatelessWidget {
  const _DocPill({required this.name});
  final String name;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Hs.gray50,
        border: Border.all(color: Hs.cloud200),
        borderRadius: BorderRadius.circular(Hs.rChip),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.image_outlined, size: 16, color: Hs.textSecondary),
        const SizedBox(width: 8),
        Text(name, style: const TextStyle(fontSize: 15, color: Hs.textBody)),
        const SizedBox(width: 6),
        const Icon(Icons.expand_more, size: 16, color: Hs.textSecondary),
      ]),
    );
  }
}
