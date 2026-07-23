import 'package:flutter/material.dart';

import '../theme.dart';

/// Shared HolySpots-styled controls used across the editor.

enum HsVariant { primary, save, secondary, cancel, delete }

class HsButton extends StatefulWidget {
  const HsButton(
    this.label, {
    super.key,
    this.onTap,
    this.variant = HsVariant.primary,
    this.icon,
    this.height = 40,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onTap;
  final HsVariant variant;
  final IconData? icon;
  final double height;
  final bool expand;

  @override
  State<HsButton> createState() => _HsButtonState();
}

class _HsButtonState extends State<HsButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    late Color bg, fg;
    Border? border;
    switch (widget.variant) {
      case HsVariant.primary:
        bg = Hs.blue500;
        fg = Hs.white;
      case HsVariant.save:
        bg = Hs.blue400;
        fg = Hs.white;
      case HsVariant.secondary:
        bg = Hs.white;
        fg = Hs.primary;
        border = Border.all(color: Hs.cloud200);
      case HsVariant.cancel:
        bg = Hs.cloud200;
        fg = Hs.coral500;
      case HsVariant.delete:
        bg = Hs.coral500;
        fg = Hs.white;
    }
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: Hs.durFast,
          height: widget.height,
          width: widget.expand ? double.infinity : null,
          padding: EdgeInsets.symmetric(horizontal: widget.icon != null ? 14 : 18),
          decoration: BoxDecoration(
            color: _hover ? Color.alphaBlend(const Color(0x14000000), bg) : bg,
            border: border,
            borderRadius: BorderRadius.circular(Hs.rBtn),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 17, color: fg),
                const SizedBox(width: 8),
              ],
              Text(widget.label,
                  style: TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 14, color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small square icon button (add / up / down / delete in panels).
class HsIconButton extends StatelessWidget {
  const HsIconButton(this.icon,
      {super.key, this.onTap, this.filled = false, this.size = 30, this.tooltip});
  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;
  final double size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final btn = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Hs.rChip),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: filled ? Hs.cloud200 : Hs.white,
          border: filled ? null : Border.all(color: Hs.cloud200),
          borderRadius: BorderRadius.circular(Hs.rChip),
        ),
        child: Icon(icon, size: size * .48, color: Hs.primary),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}

/// The En/Ru/Hi (or any) segmented control.
class HsSegmented<T> extends StatelessWidget {
  const HsSegmented({
    super.key,
    required this.values,
    required this.labelOf,
    required this.selected,
    required this.onChanged,
    this.height = 38,
  });

  final List<T> values;
  final String Function(T) labelOf;
  final T selected;
  final ValueChanged<T> onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: Hs.cloud200),
        borderRadius: BorderRadius.circular(Hs.rChip),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < values.length; i++)
            GestureDetector(
              onTap: () => onChanged(values[i]),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: values[i] == selected ? Hs.blue500 : Hs.white,
                  border: i == 0
                      ? null
                      : const Border(left: BorderSide(color: Hs.cloud200)),
                ),
                child: Text(
                  labelOf(values[i]),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: values[i] == selected
                        ? FontWeight.w500
                        : FontWeight.w400,
                    color: values[i] == selected ? Hs.white : Hs.textBody,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// iOS-style visibility toggle used on layer rows / preview.
class HsToggle extends StatelessWidget {
  const HsToggle({super.key, required this.value, required this.onTap});
  final bool value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Hs.durFast,
        width: 38,
        height: 22,
        padding: const EdgeInsets.all(2),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(
          color: value ? Hs.blue500 : Hs.gray400,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(color: Hs.white, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

/// Numeric value field set in serif (the admin data-entry quirk).
class NumberField extends StatefulWidget {
  const NumberField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.decimals = false,
    this.height = 34,
  });
  final String label;
  final num value;
  final ValueChanged<num> onChanged;
  final bool decimals;
  final double height;

  @override
  State<NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<NumberField> {
  late final TextEditingController _c =
      TextEditingController(text: _fmt(widget.value));

  String _fmt(num v) =>
      widget.decimals ? v.toString() : v.toInt().toString();

  @override
  void didUpdateWidget(NumberField old) {
    super.didUpdateWidget(old);
    final incoming = _fmt(widget.value);
    if (incoming != _c.text && !_focused) _c.text = incoming;
  }

  bool _focused = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label,
            style: const TextStyle(
                fontSize: 11, color: Hs.textSecondary, height: 1.4)),
        const SizedBox(height: 3),
        Focus(
          onFocusChange: (f) => _focused = f,
          child: Container(
            height: widget.height,
            decoration: BoxDecoration(
              color: Hs.white,
              border: Border.all(color: Hs.cloud200, width: 2),
              borderRadius: BorderRadius.circular(Hs.rChip),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextField(
              controller: _c,
              keyboardType: TextInputType.numberWithOptions(
                  decimal: widget.decimals, signed: true),
              style: serifValue(),
              cursorColor: Hs.blue500,
              decoration: const InputDecoration(
                  isCollapsed: true, border: InputBorder.none),
              onChanged: (t) {
                final v = widget.decimals
                    ? double.tryParse(t)
                    : int.tryParse(t);
                if (v != null) widget.onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// A titled white panel card (radius 5, hairline / subtle shadow).
class PanelCard extends StatelessWidget {
  const PanelCard({super.key, required this.child, this.padding});
  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Hs.white,
        borderRadius: BorderRadius.circular(Hs.rCard),
        boxShadow: Hs.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

/// Hatched placeholder swatch that stands in for user artwork.
class HatchSwatch extends StatelessWidget {
  const HatchSwatch(this.color, {super.key, this.size = 34, this.radius = 4});
  final Color color;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CustomPaint(
        size: Size.square(size),
        painter: _HatchPainter(color),
      ),
    );
  }
}

class _HatchPainter extends CustomPainter {
  _HatchPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = color;
    canvas.drawRect(Offset.zero & size, bg);
    final line = Paint()
      ..color = Colors.white.withOpacity(.12)
      ..strokeWidth = 6;
    for (double d = -size.height; d < size.width; d += 12) {
      canvas.drawLine(Offset(d, size.height), Offset(d + size.height, 0), line);
    }
  }

  @override
  bool shouldRepaint(_HatchPainter old) => old.color != color;
}
