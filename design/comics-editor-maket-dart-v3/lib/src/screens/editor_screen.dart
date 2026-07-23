import 'package:flutter/material.dart';

import '../controller.dart';
import '../responsive.dart';
import '../theme.dart';
import '../widgets/canvas_view.dart';
import '../widgets/dialogs.dart';
import '../widgets/properties_panel.dart';
import '../widgets/scene_panel.dart';
import '../widgets/timeline.dart';
import '../widgets/top_bar.dart';

/// Adaptive assembly of the editor:
///  • desktop  — Scene | Canvas | Properties, full timeline docked below
///  • tablet   — Scene | Canvas | Properties (narrower), compact timeline
///  • phone    — Canvas full-bleed; Scene / Properties / Timeline as sheets
class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = EditorScope.of(context);
    return AnimatedBuilder(
      animation: c,
      builder: (context, _) {
        if (!c.isOpen) return const _Welcome();
        final ff = formFactorOf(context);
        return Scaffold(
          backgroundColor: Hs.surfaceCloud,
          body: SafeArea(
            child: Column(
              children: [
                Material(
                  elevation: 0,
                  color: Hs.white,
                  child: const TopBar(),
                ),
                const Divider(height: 1, color: Hs.divider),
                Expanded(
                  child: switch (ff) {
                    FormFactor.desktop => const _DesktopBody(),
                    FormFactor.tablet => const _TabletBody(),
                    FormFactor.phone => const _PhoneBody(),
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------- desktop ----------------

class _DesktopBody extends StatelessWidget {
  const _DesktopBody();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(children: [
        Expanded(
          child: Row(children: const [
            SizedBox(width: 300, child: ScenePanel()),
            SizedBox(width: 10),
            Expanded(child: CanvasView()),
            SizedBox(width: 10),
            SizedBox(width: 330, child: PropertiesPanel()),
          ]),
        ),
        const SizedBox(height: 10),
        const SizedBox(height: 190, child: Timeline()),
      ]),
    );
  }
}

// ---------------- tablet (iPad / Android tablet) ----------------

class _TabletBody extends StatelessWidget {
  const _TabletBody();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(children: [
        Expanded(
          child: Row(children: const [
            SizedBox(width: 250, child: ScenePanel()),
            SizedBox(width: 8),
            Expanded(child: CanvasView()),
            SizedBox(width: 8),
            SizedBox(width: 290, child: PropertiesPanel()),
          ]),
        ),
        const SizedBox(height: 8),
        _ExpandableTimeline(),
      ]),
    );
  }
}

/// Tablet timeline: a compact strip that expands into the full timeline sheet.
class _ExpandableTimeline extends StatefulWidget {
  @override
  State<_ExpandableTimeline> createState() => _ExpandableTimelineState();
}

class _ExpandableTimelineState extends State<_ExpandableTimeline> {
  bool expanded = false;
  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: Hs.durBase,
      curve: Hs.easeStandard,
      child: SizedBox(
        height: expanded ? 220 : 64,
        child: Stack(children: [
          Positioned.fill(
              child: expanded ? const Timeline() : const Timeline(compact: true)),
          Positioned(
            right: 12,
            top: 12,
            child: IconButton(
              onPressed: () => setState(() => expanded = !expanded),
              icon: Icon(expanded ? Icons.expand_more : Icons.expand_less,
                  color: Hs.primary),
              tooltip: expanded ? 'Collapse timeline' : 'Expand timeline',
            ),
          ),
        ]),
      ),
    );
  }
}

// ---------------- phone ----------------

class _PhoneBody extends StatelessWidget {
  const _PhoneBody();
  @override
  Widget build(BuildContext context) {
    final c = EditorScope.of(context);
    return Stack(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
        child: Column(children: [
          const Expanded(child: CanvasView(showPreviewToggle: false)),
          const SizedBox(height: 8),
          const SizedBox(height: 60, child: Timeline(compact: true)),
        ]),
      ),
      // bottom sheet launcher bar
      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: _PhoneDock(c),
      ),
    ]);
  }
}

class _PhoneDock extends StatelessWidget {
  const _PhoneDock(this.c);
  final dynamic c;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Hs.white,
        border: Border(top: BorderSide(color: Hs.divider)),
      ),
      padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom + 6, top: 8, left: 8, right: 8),
      child: Row(children: [
        _DockBtn(Icons.layers_outlined, 'Scene',
            () => _sheet(context, const ScenePanelSheet())),
        _DockBtn(Icons.tune, 'Properties',
            () => _sheet(context, const PropertiesSheet())),
        _DockBtn(Icons.add, 'New', () => showNewDialog(context)),
        _DockBtn(Icons.folder_open_outlined, 'Open',
            () => showOpenDialog(context)),
      ]),
    );
  }

  static void _sheet(BuildContext context, Widget child) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Hs.surfaceCloud,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => FractionallySizedBox(heightFactor: .85, child: child),
    );
  }
}

class _DockBtn extends StatelessWidget {
  const _DockBtn(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 22, color: Hs.primary),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 11, color: Hs.textSecondary)),
          ]),
        ),
      ),
    );
  }
}

/// Sheet wrappers reuse the same panels with an EditorScope re-provided,
/// so ListenableBuilder inside them keeps working within the modal route.
class ScenePanelSheet extends StatelessWidget {
  const ScenePanelSheet({super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(10),
        child: Column(children: const [
          _SheetGrip('Scene'),
          Expanded(child: ScenePanel()),
        ]),
      );
}

class PropertiesSheet extends StatelessWidget {
  const PropertiesSheet({super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(10),
        child: Column(children: const [
          _SheetGrip('Properties'),
          Expanded(child: PropertiesPanel()),
        ]),
      );
}

class _SheetGrip extends StatelessWidget {
  const _SheetGrip(this.title);
  final String title;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(children: [
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
              color: Hs.gray400, borderRadius: BorderRadius.circular(2)),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ),
      ]),
    );
  }
}

// ---------------- welcome / empty ----------------

class _Welcome extends StatelessWidget {
  const _Welcome();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Hs.surfaceCloud,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandMark(size: 64),
              const SizedBox(height: 20),
              const Text('Comics Editor',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              const Text('Your workspace for comics & puzzles.',
                  style: TextStyle(fontSize: 16, color: Hs.textSecondary)),
              const SizedBox(height: 28),
              Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, children: [
                SizedBox(
                  width: 200,
                  child: _BigAction(
                    icon: Icons.add,
                    label: 'New document',
                    onTap: () => showNewDialog(context),
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: _BigAction(
                    icon: Icons.folder_open_outlined,
                    label: 'Open recent',
                    filled: false,
                    onTap: () => showOpenDialog(context),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _BigAction extends StatelessWidget {
  const _BigAction(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.filled = true});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          color: filled ? Hs.blue500 : Hs.white,
          border: filled ? null : Border.all(color: Hs.cloud200, width: 2),
          borderRadius: BorderRadius.circular(Hs.rCard),
          boxShadow: Hs.cardShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 26, color: filled ? Hs.white : Hs.primary),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: filled ? Hs.white : Hs.primary)),
          ],
        ),
      ),
    );
  }
}
