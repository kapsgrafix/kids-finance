import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/format.dart';
import '../state/scope.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import '../widgets/illustrations.dart';
import 'home_screen.dart';

/// Full-page jar view, opened from Home (one jar) or the jar list (two or more).
class JarDetailScreen extends StatelessWidget {
  final String jarId;
  const JarDetailScreen({super.key, required this.jarId});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final jar = state.jars.where((j) => j.id == jarId).firstOrNull;
    if (jar == null) return const Scaffold(backgroundColor: TT.bg);
    final kid = state.kids.firstWhere((k) => k.id == jar.kidId);

    return Scaffold(
      backgroundColor: TT.bg,
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(TT.gutter, 16, TT.gutter, 16),
              children: [
                TopBar('${jar.months}-month jar', subtitle: 'Started ${longDate(jar.startDate)}'),
                const SizedBox(height: 18),
                JarDetailBody(jar: jar, kid: kid),
              ],
            ),
          ),
          if (jar.isActive)
            Padding(
              padding: const EdgeInsets.fromLTRB(TT.gutter, 0, TT.gutter, 24),
              child: SettleLink(jar: jar, kid: kid, popAfter: true),
            ),
        ]),
      ),
    );
  }
}

/// The jar's progress, numbers and payout (shared by the detail page and the Jars tab).
class JarDetailBody extends StatelessWidget {
  final Jar jar;
  final Kid kid;
  const JarDetailBody({super.key, required this.jar, required this.kid});

  @override
  Widget build(BuildContext context) {
    final unit = kid.frequency == Frequency.monthly ? 'Month' : 'Week';
    final units = kid.frequency == Frequency.monthly ? 'months' : 'weeks';
    final left = jar.totalCycles - jar.cyclesPaid;
    final progress = jar.totalCycles == 0 ? 0.0 : jar.cyclesPaid / jar.totalCycles;
    final toGo = switch (jar.status) {
      JarStatus.matured => 'Popped open!',
      JarStatus.cancelled => 'Opened early',
      JarStatus.active => left == 1 ? 'Just 1 ${units.substring(0, units.length - 1)} to go!' : '$left $units to go',
    };

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SoftCard(
        radius: 26,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(children: [
          _Wobble(child: Illustration(moneyTreeJarSvg, width: 130, height: 112)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              AnimatedValueText(money(jar.saved, kid.currency), style: TT.display(40)),
              const SizedBox(width: 6),
              Text('saved of ${money(jar.target, kid.currency)}', style: TT.body(14, color: TT.muted)),
            ],
          ),
          const SizedBox(height: 12),
          ProgressBar(value: progress, track: TT.purpleSoft, fill: TT.purple),
          const SizedBox(height: 8),
          Row(children: [
            Text(
              jar.cyclesPaid == 0 ? 'First drop on ${shortDate(kid.nextPayDate)}' : '$unit ${jar.cyclesPaid} of ${jar.totalCycles}',
              style: TT.body(12, color: TT.purple),
            ),
            const Spacer(),
            Text(toGo, style: TT.body(12, color: TT.muted)),
          ]),
        ]),
      ),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: _Stat('Each ${cycleWord(kid.frequency)}', money(jar.amountPerCycle, kid.currency))),
        const SizedBox(width: 10),
        Expanded(child: _Stat('Bonus', '+${jar.bonusPct}%')),
        const SizedBox(width: 10),
        Expanded(child: _Stat('Pops open', shortDate(jar.opensOn))),
      ]),
      const SizedBox(height: 14),
      SoftCard(
        color: TT.tealSoft,
        radius: 22,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            switch (jar.status) {
              JarStatus.matured => 'Popped open on ${longDate(jar.closedOn ?? jar.opensOn)} with',
              JarStatus.cancelled => 'Would have grown into',
              JarStatus.active => 'On ${longDate(jar.opensOn)} your jar pops open with',
            },
            style: TT.body(13, color: TT.tealDark),
          ),
          Text(money(jar.payout, kid.currency), style: TT.display(30, color: TT.tealDark)),
          Text('${money(jar.target, kid.currency)} saved + ${money(jar.bonusAmount, kid.currency)} bonus',
              style: TT.body(12)),
        ]),
      ),
    ]);
  }
}

/// "Settle the amount and cancel" — a small coral text link with a friendly check first.
class SettleLink extends StatelessWidget {
  final Jar jar;
  final Kid kid;
  final bool popAfter;
  const SettleLink({super.key, required this.jar, required this.kid, this.popAfter = false});

  Future<void> _confirm(BuildContext context) async {
    final ok = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: TT.alpha(TT.ink, 0.45),
      transitionDuration: Motion.medium,
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(scale: Tween<double>(begin: 0.92, end: 1).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)), child: child),
      ),
      pageBuilder: (ctx, _, __) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Material(
            color: TT.surface,
            borderRadius: BorderRadius.circular(28),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('Open the jar early?', style: TT.display(20)),
                const SizedBox(height: 8),
                Text(
                  '${kid.name} gets ${money(jar.saved, kid.currency)} back now, but the '
                  '${money(jar.bonusAmount, kid.currency)} bonus flies away. Waiting pays more!',
                  style: TT.body(14, color: TT.muted, height: 1.4),
                ),
                const SizedBox(height: 20),
                PrimaryButton('Keep it growing', onPressed: () => Navigator.of(ctx).pop(false)),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text('Yes, settle and cancel', style: TT.body(15, color: TT.coralStrong)),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
    if (ok == true && context.mounted) {
      AppScope.read(context).settleJar(jar);
      showToast(context, '${money(jar.saved, kid.currency)} is back in ${kid.name}\'s treasury');
      if (popAfter) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(
        'Opening early gives back ${money(jar.saved, kid.currency)}, without the bonus',
        textAlign: TextAlign.center,
        style: TT.body(11, color: TT.muted),
      ),
      const SizedBox(height: 4),
      GestureDetector(
        onTap: () => _confirm(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          child: Text(
            'Settle the amount and cancel',
            style: TT.body(13, color: TT.coralStrong, decoration: TextDecoration.underline),
          ),
        ),
      ),
    ]);
  }
}

/// The jar illustration gently bobs, like it's alive.
class _Wobble extends StatefulWidget {
  final Widget child;
  const _Wobble({required this.child});
  @override
  State<_Wobble> createState() => _WobbleState();
}

class _WobbleState extends State<_Wobble> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final t = Curves.easeInOut.transform(_c.value);
        return Transform.translate(offset: Offset(0, -4 * t), child: child);
      },
      child: widget.child,
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  const _Stat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      radius: 18,
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TT.body(11, color: TT.muted)),
        const SizedBox(height: 2),
        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: TT.display(18))),
      ]),
    );
  }
}
