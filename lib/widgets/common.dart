import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import 'icons.dart';

// ------------------------------------------------------------------ motion helpers

/// Gives anything a soft "squish" while a finger is down, so taps never feel abrupt.
/// Uses a Listener, so it works alongside InkWell / GestureDetector children.
class Pressable extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final double scale;
  const Pressable({super.key, required this.child, this.enabled = true, this.scale = 0.96});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (!widget.enabled || _down == v) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: Motion.fast,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Text that cross-fades and slides when its value changes (balances, amounts).
class AnimatedValueText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final TextAlign? textAlign;
  const AnimatedValueText(this.text, {super.key, required this.style, this.textAlign});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Motion.medium,
      switchInCurve: Motion.curve,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.centerLeft,
        children: [...previous, if (current != null) current],
      ),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(anim),
          child: child,
        ),
      ),
      child: Text(text, key: ValueKey(text), style: style, textAlign: textAlign),
    );
  }
}

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
    return Pressable(
      enabled: enabled,
      child: AnimatedOpacity(
      duration: Motion.fast,
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
      child: Pressable(
        scale: 0.9,
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
                Positioned(
                  top: size * 0.22,
                  right: size * 0.24,
                  child: AnimatedScale(
                    scale: showDot ? 1 : 0,
                    duration: Motion.medium,
                    curve: Curves.easeOutBack,
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
                ),
              ],
            ),
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
/// The teal pill glides to the chosen option.
class Segmented<T> extends StatelessWidget {
  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;
  const Segmented({super.key, required this.options, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final n = options.length;
    var index = options.indexWhere((o) => o.$1 == value);
    if (index < 0) index = 0;
    return Container(
      height: 54,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: TT.track, borderRadius: BorderRadius.circular(18)),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: Motion.medium,
            curve: Motion.curve,
            alignment: Alignment(n == 1 ? 0 : -1 + 2 * index / (n - 1), 0),
            child: FractionallySizedBox(
              widthFactor: 1 / n,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: TT.tealDark,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: TT.alpha(TT.tealDark, 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < n; i++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: i == index,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (i != index) HapticFeedback.selectionClick();
                        onChanged(options[i].$1);
                      },
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: Motion.medium,
                          curve: Motion.curve,
                          style: TT.body(14, color: i == index ? TT.surface : TT.muted),
                          child: Text(options[i].$2),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
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
    return Pressable(
      scale: 0.98,
      child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: box),
    );
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
    return AnimatedContainer(
      duration: Motion.medium,
      curve: Motion.curve,
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: p.bg, shape: BoxShape.circle),
      child: AnimatedDefaultTextStyle(
        duration: Motion.medium,
        style: TT.display(size * 0.45, color: p.fg),
        child: Text(initial),
      ),
    );
  }
}

/// Kid switcher: the selected kid shows avatar + name in a teal chip; other kids
/// collapse to avatars when there are several; "+" adds a kid. Switching animates
/// the chip open on the new kid and closed on the old one.
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
    final items = <Widget>[
      for (final k in kids)
        _KidItem(
          kid: k,
          selected: k.id == selected.id,
          compact: compact,
          onTap: () {
            if (k.id != selected.id) HapticFeedback.selectionClick();
            onSelect(k);
          },
        ),
      _AddKidItem(compact: compact, label: addLabel, onTap: onAdd),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) SizedBox(width: compact ? 8 : 10),
          items[i],
        ]
      ]),
    );
  }
}

class _KidItem extends StatelessWidget {
  final Kid kid;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;
  const _KidItem({required this.kid, required this.selected, required this.compact, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pad = compact ? 4.0 : 6.0;
    return Semantics(
      button: true,
      selected: selected,
      label: selected ? kid.name : 'Switch to ${kid.name}',
      child: Pressable(
        scale: 0.93,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: Motion.medium,
            curve: Motion.curve,
            padding: selected ? EdgeInsets.fromLTRB(pad, pad, compact ? 14 : 16, pad) : EdgeInsets.zero,
            decoration: BoxDecoration(
              color: selected ? TT.tealDark : TT.alpha(TT.tealDark, 0),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              KidAvatar(kid, size: selected ? (compact ? 36 : 40) : 44),
              AnimatedSize(
                duration: Motion.medium,
                curve: Motion.curve,
                child: selected
                    ? Padding(
                        padding: EdgeInsets.only(left: compact ? 8 : 10),
                        child: Text(kid.name, style: TT.body(compact ? 14 : 15, color: TT.surface)),
                      )
                    : const SizedBox.shrink(),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _AddKidItem extends StatelessWidget {
  final bool compact;
  final String label;
  final VoidCallback onTap;
  const _AddKidItem({required this.compact, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final plus = Container(
      width: compact ? 44 : 40,
      height: compact ? 44 : 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: compact ? TT.surface : TT.track, shape: BoxShape.circle),
      child: const TTIcon(TTIcons.plus, color: TT.tealDark, size: 20, strokeWidth: 2.8),
    );
    return Semantics(
      button: true,
      label: 'Add a kid',
      child: Pressable(
        scale: 0.93,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: Motion.medium,
            curve: Motion.curve,
            padding: compact ? EdgeInsets.zero : const EdgeInsets.fromLTRB(6, 6, 16, 6),
            decoration: BoxDecoration(
              color: compact ? TT.alpha(TT.surface, 0) : TT.surface,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              plus,
              if (!compact) ...[const SizedBox(width: 10), Text(label, style: TT.body(15))],
            ]),
          ),
        ),
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
