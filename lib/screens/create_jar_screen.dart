import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../state/format.dart';
import '../state/app_state.dart';
import '../state/scope.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';

/// Create a jar: 2–10% of pocket money on a slider, then a 3 / 6 / 12 month plan.
class CreateJarScreen extends StatefulWidget {
  const CreateJarScreen({super.key});
  @override
  State<CreateJarScreen> createState() => _CreateJarScreenState();
}

class _CreateJarScreenState extends State<CreateJarScreen> {
  static const _minPct = AppState.minJarPct;
  int? _pct;
  int _months = 6;

  void _start(Kid kid, int pct) {
    final state = AppScope.read(context);
    final jar = state.createJar(kid, percent: pct, months: _months);
    if (jar == null) return;
    showToast(context, 'Yay! Your jar is growing');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final kid = state.selectedKid;
    if (kid == null) return const SizedBox.shrink();
    final maxPct = state.availableJarPercent(kid);
    final canStart = maxPct >= _minPct;
    final pct = (_pct ?? 5).clamp(_minPct, maxPct < _minPct ? _minPct : maxPct).toInt();
    final amount = state.jarAmountForPercent(kid, pct);
    final unit = cycleWord(kid.frequency);
    final used = state.usedJarPercent(kid);

    return Scaffold(
      backgroundColor: TT.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(TT.gutter, 16, TT.gutter, 16),
                children: [
                  const TopBar('Make a jar'),
                  const SizedBox(height: 24),
                  SoftCard(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                    child: Column(children: [
                      Text('Drop in every $unit', style: TT.body(13, color: TT.muted)),
                      AnimatedValueText(money(amount, kid.currency), style: TT.display(48, height: 1.15)),
                      Pill('$pct% of pocket money', background: TT.tealSoft, color: TT.tealDark),
                      const SizedBox(height: 22),
                      if (maxPct > _minPct) ...[
                        StepSlider(
                          min: _minPct,
                          max: maxPct,
                          value: pct,
                          onChanged: (v) => setState(() => _pct = v),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(money(state.jarAmountForPercent(kid, _minPct), kid.currency), style: TT.body(12, color: TT.muted)),
                            Text(money(state.jarAmountForPercent(kid, maxPct), kid.currency), style: TT.body(12, color: TT.muted)),
                          ],
                        ),
                      ],
                      if (used > 0) ...[
                        const SizedBox(height: 10),
                        Text(
                          canStart
                              ? 'Your other jars use $used%, so this one can take up to $maxPct%.'
                              : 'Your jars already use the full 10%. Wait for one to pop open!',
                          textAlign: TextAlign.center,
                          style: TT.body(12, color: TT.muted),
                        ),
                      ],
                    ]),
                  ),
                  const SizedBox(height: 26),
                  Text('How long should it grow?', style: TT.display(18)),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final m in const [3, 6, 12]) ...[
                        if (m != 3) const SizedBox(width: 10),
                        Expanded(
                          child: _PlanCard(
                            months: m,
                            put: amount * cyclesForMonths(m, kid.frequency),
                            bonusPct: kid.jarBonus[m] ?? 0,
                            currency: kid.currency,
                            selected: _months == m,
                            onTap: () => setState(() => _months = m),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(TT.gutter, 0, TT.gutter, 24),
              child: PrimaryButton('Start investing', onPressed: canStart && amount > 0 ? () => _start(kid, pct) : null),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final int months;
  final int put;
  final int bonusPct;
  final String currency;
  final bool selected;
  final VoidCallback onTap;
  const _PlanCard({
    required this.months,
    required this.put,
    required this.bonusPct,
    required this.currency,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final payback = put + (put * bonusPct / 100).round();
    final soft = selected ? TT.alpha(TT.surface, 0.8) : TT.muted;
    return Semantics(
      button: true,
      selected: selected,
      child: Pressable(
        child: GestureDetector(
        onTap: () {
          if (!selected) HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: Motion.medium,
          curve: Motion.curve,
          padding: const EdgeInsets.fromLTRB(6, 14, 6, 16),
          decoration: BoxDecoration(
            color: selected ? TT.tealDark : TT.surface,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: selected ? TT.alpha(TT.surface, 0.18) : TT.track,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('$months months', style: TT.body(12, color: selected ? TT.surface : TT.ink)),
            ),
            const SizedBox(height: 12),
            Text('You put ${money(put, currency)}', textAlign: TextAlign.center, style: TT.body(11, color: soft)),
            const SizedBox(height: 8),
            Text('You get', style: TT.body(11, color: soft)),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: AnimatedValueText(money(payback, currency),
                  style: TT.display(28, color: selected ? TT.surface : TT.tealDark, height: 1.15)),
            ),
            Text('+$bonusPct% bonus', style: TT.body(11, color: soft)),
          ]),
        ),
      ),
      ),
    );
  }
}

/// Snapping slider: teal fill, white thumb with a teal dot, a dot for every step.
class StepSlider extends StatelessWidget {
  final int min, max, value;
  final ValueChanged<int> onChanged;
  const StepSlider({super.key, required this.min, required this.max, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      const thumb = 28.0;
      final steps = max - min <= 0 ? 1 : max - min;
      double xFor(int v) => (v - min) / steps * (w - thumb) + thumb / 2;
      void update(double dx) {
        final v = ((dx - thumb / 2) / (w - thumb) * steps).round() + min;
        final clamped = v < min ? min : (v > max ? max : v);
        if (clamped != value) {
          HapticFeedback.selectionClick();
          onChanged(clamped);
        }
      }

      final x = xFor(value);
      return Semantics(
        slider: true,
        value: '$value%',
        increasedValue: value < max ? '${value + 1}%' : null,
        decreasedValue: value > min ? '${value - 1}%' : null,
        onIncrease: value < max ? () => onChanged(value + 1) : null,
        onDecrease: value > min ? () => onChanged(value - 1) : null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => update(d.localPosition.dx),
          onHorizontalDragUpdate: (d) => update(d.localPosition.dx),
          child: SizedBox(
            height: 36,
            width: w,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 13,
                  child: Container(height: 10, decoration: BoxDecoration(color: TT.track, borderRadius: BorderRadius.circular(5))),
                ),
                for (var v = min; v <= max; v++)
                  Positioned(
                    left: xFor(v) - 2,
                    top: 16,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(color: Color(0xFFB9D5DB), shape: BoxShape.circle),
                    ),
                  ),
                AnimatedPositioned(
                  duration: Motion.fast,
                  curve: Curves.easeOut,
                  left: 0,
                  top: 13,
                  width: x + 6,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(color: TT.tealDark, borderRadius: BorderRadius.circular(5)),
                  ),
                ),
                AnimatedPositioned(
                  duration: Motion.fast,
                  curve: Curves.easeOut,
                  left: x - thumb / 2,
                  top: 4,
                  child: Container(
                    width: thumb,
                    height: thumb,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: TT.surface,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: TT.alpha(TT.ink, 0.18), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(color: TT.tealDark, shape: BoxShape.circle),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
