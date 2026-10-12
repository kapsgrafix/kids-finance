import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import 'icons.dart';

// ------------------------------------------------------------------ buttons

/// Coral pill — the main action on a screen.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool leadingPlus;
  final bool trailingArrow;
  const PrimaryButton(this.label, {super.key, this.onPressed, this.leadingPlus = false, this.trailingArrow = false});

  @override
  Widget build(BuildContext context) => _PillButton(
        label: label,
        onPressed: onPressed,
        background: TT.coralStrong,
        foreground: TT.surface,
        leadingPlus: leadingPlus,
        trailingArrow: trailingArrow,
      );
}

/// White pill — a secondary action next to a primary one.
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool leadingPlus;
  const SecondaryButton(this.label, {super.key, this.onPressed, this.leadingPlus = false});

  @override
  Widget build(BuildContext context) => _PillButton(
        label: label,
        onPressed: onPressed,
        background: TT.surface,
        foreground: TT.ink,
        iconColor: TT.tealDark,
        leadingPlus: leadingPlus,
      );
}

class _PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color background;
  final Color foreground;
  final Color? iconColor;
  final bool leadingPlus;
  final bool trailingArrow;

  const _PillButton({
    required this.label,
    required this.onPressed,
    required this.background,
    required this.foreground,
    this.iconColor,
    this.leadingPlus = false,
    this.trailingArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: background,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            height: 58,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (leadingPlus) ...[
                  TTIcon(TTIcons.plus, color: iconColor ?? foreground, size: 22, strokeWidth: 3),
                  const SizedBox(width: 10),
                ],
                Flexible(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TT.display(21, color: foreground)),
                ),
                if (trailingArrow) ...[
                  const SizedBox(width: 10),
                  TTIcon(TTIcons.arrowRight, color: iconColor ?? foreground, size: 22, strokeWidth: 3),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 44px white circle (back button, bell).
class CircleIconButton extends StatelessWidget {
  final TTIcons icon;
  final VoidCallback onTap;
  final bool showDot;
  final Color background;
  final double size;
  final String? semanticLabel;
  const CircleIconButton(this.icon,
      {super.key, required this.onTap, this.showDot = false, this.background = TT.surface, this.size = 44, this.semanticLabel});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                TTIcon(icon, color: TT.ink, size: size * 0.45, strokeWidth: 2.4),
                if (showDot)
                  Positioned(
                    top: size * 0.22,
                    right: size * 0.24,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: TT.coralStrong,
                        shape: BoxShape.circle,
                        border: Border.all(color: background, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BackCircle extends StatelessWidget {
  const BackCircle({super.key});
  @override
  Widget build(BuildContext context) =>
      CircleIconButton(TTIcons.back, onTap: () => Navigator.of(context).maybePop(), semanticLabel: 'Back');
}

/// Back button + title row used on pushed screens.
class TopBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const TopBar(this.title, {super.key, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const BackCircle(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TT.display(22)),
              if (subtitle != null) Text(subtitle!, style: TT.body(12, color: TT.muted)),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ------------------------------------------------------------------ inputs

/// Borderless white field with a soft shadow. Shows a teal ring while focused.
class SoftField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final bool numeric;
  final Color fill;
  final bool shadow;
  final bool autofocus;
  final TextInputAction? action;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final int? maxLength;
  final TextCapitalization capitalization;

  const SoftField({
    super.key,
    required this.controller,
    required this.hint,
    this.numeric = false,
    this.fill = TT.surface,
    this.shadow = true,
    this.autofocus = false,
    this.action,
    this.onChanged,
    this.focusNode,
    this.maxLength,
    this.capitalization = TextCapitalization.sentences,
  });

  @override
  State<SoftField> createState() => _SoftFieldState();
}

class _SoftFieldState extends State<SoftField> {
  late final FocusNode _focus = widget.focusNode ?? FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  void _onFocus() => setState(() {});

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: focused ? TT.surface : widget.fill,
        borderRadius: BorderRadius.circular(TT.rField),
        border: Border.all(color: focused ? TT.tealDark : Colors.transparent, width: 2),
        boxShadow: widget.shadow && !focused ? TT.softShadow() : null,
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focus,
        autofocus: widget.autofocus,
        textCapitalization: widget.numeric ? TextCapitalization.none : widget.capitalization,
        keyboardType: widget.numeric ? TextInputType.number : TextInputType.text,
        inputFormatters: [
          if (widget.numeric) FilteringTextInputFormatter.digitsOnly,
          if (widget.maxLength != null) LengthLimitingTextInputFormatter(widget.maxLength),
        ],
        textInputAction: widget.action,
        onChanged: widget.onChanged,
        style: TT.body(16),
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: widget.hint,
          hintStyle: TT.body(16, color: TT.muted),
        ),
      ),
    );
  }
}

/// Sliding segmented control on a soft track (Weekly | Monthly, All | Expenses | Deposits).
class Segmented<T> extends StatelessWidget {
  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;
  const Segmented({super.key, required this.options, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: TT.track, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(options[i].$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: options[i].$1 == value ? TT.tealDark : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    options[i].$2,
                    style: TT.body(14, color: options[i].$1 == value ? TT.surface : TT.muted),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Label with a pastel icon tile, used above form fields.
class FieldLabel extends StatelessWidget {
  final String text;
  final TTIcons icon;
  final Color tint;
  final Color iconColor;
  const FieldLabel(this.text, {super.key, required this.icon, required this.tint, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconTile(icon: icon, tint: tint, color: iconColor, size: 28, radius: 10, iconSize: 16),
        const SizedBox(width: 8),
        Text(text, style: TT.body(14)),
      ],
    );
  }
}

class IconTile extends StatelessWidget {
  final TTIcons icon;
  final Color tint;
  final Color color;
  final double size;
  final double radius;
  final double iconSize;
  const IconTile({
    super.key,
    required this.icon,
    required this.tint,
    required this.color,
    this.size = 42,
    this.radius = 14,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(radius)),
        child: TTIcon(icon, color: color, size: iconSize),
      );
}

// ------------------------------------------------------------------ cards

class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double radius;
  final bool shadow;
  final VoidCallback? onTap;
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color = TT.surface,
    this.radius = TT.rCard,
    this.shadow = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow ? TT.softShadow() : null,
      ),
      child: child,
    );
    if (onTap == null) return box;
    return GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: box);
  }
}

class Pill extends StatelessWidget {
  final String text;
  final Color background;
  final Color color;
  final Widget? leading;
  final double fontSize;
  const Pill(this.text,
      {super.key, required this.background, required this.color, this.leading, this.fontSize = 12});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
        child: leading == null
            ? Text(text, style: TT.body(fontSize, color: color))
            : Row(mainAxisSize: MainAxisSize.min, children: [
                leading!,
                const SizedBox(width: 6),
                Flexible(child: Text(text, style: TT.body(fontSize, color: color))),
              ]),
      );
}

class ThinDivider extends StatelessWidget {
  const ThinDivider({super.key});
  @override
  Widget build(BuildContext context) => Container(height: 1, color: TT.track);
}

// ------------------------------------------------------------------ kids

class KidAvatar extends StatelessWidget {
  final Kid kid;
  final double size;
  const KidAvatar(this.kid, {super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final p = KidPalette.of(kid.colorIndex);
    final initial = kid.name.isEmpty ? '?' : kid.name.characters.first.toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: p.bg, shape: BoxShape.circle),
      child: Text(initial, style: TT.display(size * 0.45, color: p.fg)),
    );
  }
}

/// Kid switcher: the selected kid shows avatar + name in a teal chip; other kids
/// collapse to avatars when there are several; "+" adds a kid.
class KidSwitcher extends StatelessWidget {
  final List<Kid> kids;
  final Kid selected;
  final ValueChanged<Kid> onSelect;
  final VoidCallback onAdd;
  final String addLabel;

  const KidSwitcher({
    super.key,
    required this.kids,
    required this.selected,
    required this.onSelect,
    required this.onAdd,
    this.addLabel = 'Kid',
  });

  @override
  Widget build(BuildContext context) {
    final compact = kids.length > 1;
    final children = <Widget>[];
    for (final k in kids) {
      final isSel = k.id == selected.id;
      if (isSel) {
        children.add(_chip(
          color: TT.tealDark,
          avatar: KidAvatar(k, size: compact ? 36 : 40),
          label: Text(k.name, style: TT.body(compact ? 14 : 15, color: TT.surface)),
          onTap: () => onSelect(k),
          compact: compact,
        ));
      } else {
        children.add(GestureDetector(
          onTap: () => onSelect(k),
          child: Semantics(button: true, label: 'Switch to ${k.name}', child: KidAvatar(k, size: 44)),
        ));
      }
    }
    if (compact) {
      children.add(Semantics(
        button: true,
        label: 'Add a kid',
        child: GestureDetector(
          onTap: onAdd,
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: TT.surface, shape: BoxShape.circle),
            child: const TTIcon(TTIcons.plus, color: TT.tealDark, size: 20, strokeWidth: 2.8),
          ),
        ),
      ));
    } else {
      children.add(_chip(
        color: TT.surface,
        avatar: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: TT.track, shape: BoxShape.circle),
          child: const TTIcon(TTIcons.plus, color: TT.tealDark, size: 20, strokeWidth: 2.8),
        ),
        label: Text(addLabel, style: TT.body(15)),
        onTap: onAdd,
        compact: false,
      ));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(width: compact ? 8 : 10),
          children[i],
        ]
      ]),
    );
  }

  Widget _chip({
    required Color color,
    required Widget avatar,
    required Widget label,
    required VoidCallback onTap,
    required bool compact,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.fromLTRB(compact ? 4 : 6, compact ? 4 : 6, compact ? 14 : 16, compact ? 4 : 6),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [avatar, SizedBox(width: compact ? 8 : 10), label]),
      ),
    );
  }
}

// ------------------------------------------------------------------ categories

class CategoryStyle {
  final String label;
  final TTIcons icon;
  final Color tint;
  final Color color;
  const CategoryStyle(this.label, this.icon, this.tint, this.color);

  static CategoryStyle of(Category c) => switch (c) {
        Category.food => const CategoryStyle('Food', TTIcons.food, TT.coralSoft, TT.iconCoral),
        Category.travel => const CategoryStyle('Travel', TTIcons.travel, TT.skySoft, TT.iconSky),
        Category.fun => const CategoryStyle('Fun', TTIcons.fun, TT.purpleSoft, TT.purple),
      };

  static const deposit = CategoryStyle('Money in', TTIcons.coins, TT.tealSoft, TT.tealDark);
  static const jar = CategoryStyle('Jar', TTIcons.jar, TT.purpleSoft, TT.purple);
  static const interest = CategoryStyle('Interest', TTIcons.grow, TT.tealSoft, TT.tealDark);

  static CategoryStyle forEntry(Entry e) {
    if (e.isExpense) return of(e.category ?? Category.food);
    return switch (e.depositKind) {
      DepositKind.interest => interest,
      DepositKind.jarPayout || DepositKind.jarSettled => jar,
      _ => deposit,
    };
  }
}

String entryMeta(Entry e, String time) {
  if (e.isExpense) return '${categoryLabel(e.category ?? Category.food)} · $time';
  return switch (e.depositKind) {
    DepositKind.interest => 'Interest · $time',
    DepositKind.jarPayout || DepositKind.jarSettled => 'Jar · $time',
    _ => 'Money in · $time',
  };
}

void showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message, style: TT.body(14, color: TT.surface)),
      backgroundColor: TT.ink,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
    ));
}
