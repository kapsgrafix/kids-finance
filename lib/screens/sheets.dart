import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../state/format.dart';
import '../state/scope.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import '../widgets/icons.dart';

/// Opens a white bottom sheet over a dimmed screen, lifted above the keyboard.
Future<T?> showTTSheet<T>(BuildContext context, {required String title, required WidgetBuilder builder}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    barrierColor: TT.alpha(TT.ink, 0.45),
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: SheetFrame(title: title, child: Builder(builder: builder)),
    ),
  );
}

class SheetFrame extends StatelessWidget {
  final String title;
  final Widget child;
  const SheetFrame({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: TT.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 10, 24, 16 + MediaQuery.of(context).padding.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(color: TT.track, borderRadius: BorderRadius.circular(3)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Text(title, style: TT.display(20))),
                CircleIconButton(TTIcons.close,
                    size: 36, background: TT.track, onTap: () => Navigator.of(context).pop(), semanticLabel: 'Close'),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ add expense / money

/// Add expense (with category) or add money (without).
Future<void> showAddEntrySheet(BuildContext context, {required bool expense}) async {
  final state = AppScope.read(context);
  final kid = state.selectedKid;
  if (kid == null) return;
  final result = await showTTSheet<String>(
    context,
    title: expense ? 'What did you buy?' : 'Money coming in!',
    builder: (_) => _AddEntryForm(kid: kid, expense: expense),
  );
  if (result != null && context.mounted) showToast(context, result);
}

class _AddEntryForm extends StatefulWidget {
  final Kid kid;
  final bool expense;
  const _AddEntryForm({required this.kid, required this.expense});

  @override
  State<_AddEntryForm> createState() => _AddEntryFormState();
}

class _AddEntryFormState extends State<_AddEntryForm> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  Category _category = Category.food;
  String? _error;

  @override
  void initState() {
    super.initState();
    _amount.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  int get _value => int.tryParse(_amount.text) ?? 0;

  void _submit() {
    final state = AppScope.read(context);
    final kid = widget.kid;
    final err = widget.expense
        ? state.addExpense(kid, _value, _category, _note.text)
        : state.addMoney(kid, _value, _note.text);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    final amt = money(_value, kid.currency);
    final cheer = switch (_category) {
      Category.food => 'Yum!',
      Category.travel => 'Vroom!',
      Category.fun => 'Woohoo!',
    };
    Navigator.of(context).pop(widget.expense ? '$cheer $amt spend saved' : 'Ka-ching! $amt added to ${kid.name}\'s treasure');
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final kid = widget.kid;
    final cur = Currency.of(kid.currency);
    final balance = state.balanceOf(kid);
    final after = widget.expense ? balance - _value : balance + _value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Amount
        Container(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
          decoration: BoxDecoration(color: TT.bg, borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(cur.symbol.trim(), style: TT.display(32, color: TT.muted)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _amount,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                      style: TT.display(40, height: 1.2),
                      cursorColor: TT.coralStrong,
                      cursorWidth: 2.5,
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: '0',
                        hintStyle: TT.display(40, color: TT.alpha(TT.muted, 0.4), height: 1.2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                _error ?? (widget.expense ? 'Left after this: ${money(after, kid.currency)}' : 'Treasure after this: ${money(after, kid.currency)}'),
                style: TT.body(12, color: _error != null || after < 0 ? TT.coralStrong : TT.muted),
              ),
            ],
          ),
        ),
        if (widget.expense) ...[
          const SizedBox(height: 14),
          Text('What was it for?', style: TT.body(13, color: TT.muted)),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final c in Category.values) ...[
                if (c != Category.values.first) const SizedBox(width: 10),
                Expanded(child: _CategoryChip(category: c, selected: c == _category, onTap: () => setState(() => _category = c))),
              ],
            ],
          ),
        ],
        const SizedBox(height: 14),
        SoftField(
          controller: _note,
          hint: widget.expense ? 'What was it? Ice cream, comics…' : 'Who gave it? Nani, birthday…',
          fill: TT.bg,
          shadow: false,
          maxLength: 40,
          action: TextInputAction.done,
        ),
        const SizedBox(height: 16),
        PrimaryButton(widget.expense ? 'Add expense' : 'Add money', onPressed: _value > 0 ? _submit : null),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final Category category;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip({required this.category, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = CategoryStyle.of(category);
    return Semantics(
      button: true,
      selected: selected,
      child: Pressable(
        scale: 0.94,
        child: GestureDetector(
        onTap: () {
          if (!selected) HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: Motion.medium,
          curve: Motion.curve,
          height: 48,
          decoration: BoxDecoration(
            color: selected ? TT.tealDark : s.tint,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<Color?>(
                tween: ColorTween(end: selected ? TT.surface : s.color),
                duration: Motion.medium,
                builder: (_, c, __) => TTIcon(s.icon, color: c ?? s.color, size: 20),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: AnimatedDefaultTextStyle(
                  duration: Motion.medium,
                  style: TT.body(15, color: selected ? TT.surface : TT.ink),
                  child: Text(s.label),
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

// ------------------------------------------------------------------ settings editors

/// A list of options with a check on the current one.
Future<T?> showChoiceSheet<T>(
  BuildContext context, {
  required String title,
  required T value,
  required List<(T, String, String?)> options,
}) {
  return showTTSheet<T>(
    context,
    title: title,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final o in options)
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.of(ctx).pop(o.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: o.$1 == value ? TT.tealSoft : TT.bg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(o.$2, style: TT.body(15)),
                    if (o.$3 != null) Text(o.$3!, style: TT.body(12, color: TT.muted)),
                  ]),
                ),
                if (o.$1 == value) const TTIcon(TTIcons.check, color: TT.tealDark, size: 20, strokeWidth: 2.8),
              ]),
            ),
          ),
      ],
    ),
  );
}

/// Single text or number field with a Save button.
Future<String?> showTextEditSheet(
  BuildContext context, {
  required String title,
  required String initial,
  required String hint,
  bool numeric = false,
  String? prefix,
}) {
  final controller = TextEditingController(text: initial);
  return showTTSheet<String>(
    context,
    title: title,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          if (prefix != null) ...[Text(prefix, style: TT.display(24, color: TT.muted)), const SizedBox(width: 8)],
          Expanded(
            child: SoftField(
              controller: controller,
              hint: hint,
              numeric: numeric,
              autofocus: true,
              fill: TT.bg,
              shadow: false,
              maxLength: numeric ? 6 : 20,
              capitalization: TextCapitalization.words,
            ),
          ),
        ]),
        const SizedBox(height: 16),
        PrimaryButton('Save', onPressed: () {
          final v = controller.text.trim();
          if (v.isEmpty || (numeric && (int.tryParse(v) ?? 0) <= 0)) return;
          Navigator.of(ctx).pop(v);
        }),
      ],
    ),
  );
}

/// Whole-number stepper with a Save button.
Future<int?> showStepperSheet(
  BuildContext context, {
  required String title,
  required String caption,
  required int initial,
  required int min,
  required int max,
  String suffix = '%',
}) {
  return showTTSheet<int>(
    context,
    title: title,
    builder: (_) => _StepperBody(caption: caption, initial: initial, min: min, max: max, suffix: suffix),
  );
}

class _StepperBody extends StatefulWidget {
  final String caption;
  final int initial, min, max;
  final String suffix;
  const _StepperBody({required this.caption, required this.initial, required this.min, required this.max, required this.suffix});
  @override
  State<_StepperBody> createState() => _StepperBodyState();
}

class _StepperBodyState extends State<_StepperBody> {
  late int v = widget.initial;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.caption, style: TT.body(13, color: TT.muted)),
        const SizedBox(height: 14),
        NumberStepper(
          value: v,
          suffix: widget.suffix,
          onMinus: v > widget.min ? () => setState(() => v--) : null,
          onPlus: v < widget.max ? () => setState(() => v++) : null,
        ),
        const SizedBox(height: 16),
        PrimaryButton('Save', onPressed: () => Navigator.of(context).pop(v)),
      ],
    );
  }
}

class NumberStepper extends StatelessWidget {
  final int value;
  final String suffix;
  final String? label;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;
  const NumberStepper({super.key, required this.value, this.suffix = '%', this.label, this.onMinus, this.onPlus});

  @override
  Widget build(BuildContext context) {
    Widget btn(String t, VoidCallback? f) => Opacity(
          opacity: f == null ? 0.35 : 1,
          child: Material(
            color: TT.surface,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: f,
              child: SizedBox(width: 40, height: 40, child: Center(child: Text(t, style: TT.display(22)))),
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: TT.bg, borderRadius: BorderRadius.circular(18)),
      child: Row(children: [
        if (label != null) ...[const SizedBox(width: 6), Expanded(child: Text(label!, style: TT.body(15)))],
        if (label == null) const Spacer(),
        btn('−', onMinus),
        SizedBox(width: 72, child: Text('$value$suffix', textAlign: TextAlign.center, style: TT.display(24))),
        btn('+', onPlus),
        if (label == null) const Spacer(),
      ]),
    );
  }
}

/// Jar bonus for the 3, 6 and 12 month plans.
Future<Map<int, int>?> showJarBonusSheet(BuildContext context, Map<int, int> initial) {
  return showTTSheet<Map<int, int>>(context, title: 'Jar bonus', builder: (_) => _JarBonusBody(initial: initial));
}

class _JarBonusBody extends StatefulWidget {
  final Map<int, int> initial;
  const _JarBonusBody({required this.initial});
  @override
  State<_JarBonusBody> createState() => _JarBonusBodyState();
}

class _JarBonusBodyState extends State<_JarBonusBody> {
  late final Map<int, int> v = Map.of(widget.initial);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Longer jars should pay more, so waiting feels worth it.', style: TT.body(13, color: TT.muted)),
        const SizedBox(height: 14),
        for (final m in const [3, 6, 12]) ...[
          NumberStepper(
            label: '$m months',
            value: v[m] ?? 0,
            onMinus: (v[m] ?? 0) > 0 ? () => setState(() => v[m] = (v[m] ?? 0) - 1) : null,
            onPlus: (v[m] ?? 0) < 30 ? () => setState(() => v[m] = (v[m] ?? 0) + 1) : null,
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 8),
        PrimaryButton('Save', onPressed: () => Navigator.of(context).pop(v)),
      ],
    );
  }
}


// ------------------------------------------------------------------ review schedule

/// Day + time for the pocket-money day and money chat. Returns (payDay, hour, minute).
Future<(int, int, int)?> showReviewScheduleSheet(BuildContext context, Kid kid) {
  return showTTSheet<(int, int, int)>(
    context,
    title: 'Money chat time',
    builder: (_) => _ReviewScheduleBody(kid: kid),
  );
}

class _ReviewScheduleBody extends StatefulWidget {
  final Kid kid;
  const _ReviewScheduleBody({required this.kid});
  @override
  State<_ReviewScheduleBody> createState() => _ReviewScheduleBodyState();
}

class _ReviewScheduleBodyState extends State<_ReviewScheduleBody> {
  late int _day = widget.kid.payDay;
  late TimeOfDay _time = TimeOfDay(hour: widget.kid.reviewHour, minute: widget.kid.reviewMinute);

  bool get _monthly => widget.kid.frequency == Frequency.monthly;

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _time,
      helpText: 'Pick a time',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: TT.tealDark, onPrimary: TT.surface, surface: TT.surface),
        ),
        child: child!,
      ),
    );
    if (t != null) setState(() => _time = t);
  }

  Widget _dayChip(int value, String label, {double size = 38}) {
    final sel = value == _day;
    return Pressable(
      scale: 0.9,
      child: GestureDetector(
        onTap: () {
          if (!sel) HapticFeedback.selectionClick();
          setState(() => _day = value);
        },
        child: AnimatedContainer(
          duration: Motion.medium,
          curve: Motion.curve,
          width: size,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: sel ? TT.tealDark : TT.bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(label, style: TT.body(13, color: sel ? TT.surface : TT.ink)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Pocket money lands and you catch up on ${widget.kid.name}\'s spends together.',
          style: TT.body(13, color: TT.muted, height: 1.4),
        ),
        const SizedBox(height: 16),
        Text(_monthly ? 'Which day of the month?' : 'Which day of the week?', style: TT.body(14)),
        const SizedBox(height: 10),
        if (_monthly)
          LayoutBuilder(builder: (context, c) {
            final size = (c.maxWidth - 6 * 6) / 7;
            return Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (var d = 1; d <= 28; d++) _dayChip(d, '$d', size: size)],
            );
          })
        else
          Row(children: [
            for (var i = 1; i <= 7; i++) ...[
              if (i > 1) const SizedBox(width: 6),
              Expanded(child: _dayChip(i, weekdays[i - 1], size: double.infinity)),
            ],
          ]),
        const SizedBox(height: 18),
        Text('What time?', style: TT.body(14)),
        const SizedBox(height: 10),
        Pressable(
          scale: 0.98,
          child: GestureDetector(
            onTap: _pickTime,
            child: Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(color: TT.bg, borderRadius: BorderRadius.circular(TT.rField)),
              child: Row(children: [
                const TTIcon(TTIcons.calendar, color: TT.tealDark, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(clock(_time.hour, _time.minute), style: TT.body(16))),
                const TTIcon(TTIcons.chevronDown, color: TT.ink, size: 18, strokeWidth: 2.6),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 20),
        PrimaryButton('Save', onPressed: () => Navigator.of(context).pop((_day, _time.hour, _time.minute))),
      ],
    );
  }
}
