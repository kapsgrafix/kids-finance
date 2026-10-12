import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/format.dart';
import '../state/scope.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import '../widgets/illustrations.dart';
import 'home_screen.dart';

class JarDetailScreen extends StatelessWidget {
  final String jarId;
  const JarDetailScreen({super.key, required this.jarId});

  Future<void> _confirmSettle(BuildContext context, Jar jar, Kid kid) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: TT.alpha(TT.ink, 0.45),
      builder: (ctx) => Dialog(
        backgroundColor: TT.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Cancel this jar?', style: TT.display(20)),
            const SizedBox(height: 8),
            Text(
              '${kid.name} gets back ${money(jar.saved, kid.currency)} now and misses the '
              '${money(jar.bonusAmount, kid.currency)} bonus.',
              style: TT.body(14, color: TT.muted, height: 1.4),
            ),
            const SizedBox(height: 20),
            SecondaryButton('Keep growing', onPressed: () => Navigator.of(ctx).pop(false)),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('Settle and cancel', style: TT.body(15, color: TT.coralStrong)),
            ),
          ]),
        ),
      ),
    );
    if (ok == true && context.mounted) {
      AppScope.read(context).settleJar(jar);
      showToast(context, '${money(jar.saved, kid.currency)} returned to ${kid.name}');
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final jar = state.jars.where((j) => j.id == jarId).firstOrNull;
    if (jar == null) return const Scaffold(backgroundColor: TT.bg);
    final kid = state.kids.firstWhere((k) => k.id == jar.kidId);
    final unit = kid.frequency == Frequency.monthly ? 'Month' : 'Week';
    final units = kid.frequency == Frequency.monthly ? 'months' : 'weeks';
    final left = jar.totalCycles - jar.cyclesPaid;
    final progress = jar.totalCycles == 0 ? 0.0 : jar.cyclesPaid / jar.totalCycles;

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
                SoftCard(
                  radius: 26,
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  child: Column(children: [
                    Illustration(moneyTreeJarSvg, width: 130, height: 112),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(money(jar.saved, kid.currency), style: TT.display(40)),
                        const SizedBox(width: 6),
                        Text('saved of ${money(jar.target, kid.currency)}', style: TT.body(14, color: TT.muted)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ProgressBar(value: progress, track: TT.purpleSoft, fill: TT.purple),
                    const SizedBox(height: 8),
                    Row(children: [
                      Text(
                        jar.cyclesPaid == 0 ? 'Starts ${shortDate(kid.nextPayDate)}' : '$unit ${jar.cyclesPaid} of ${jar.totalCycles}',
                        style: TT.body(12, color: TT.purple),
                      ),
                      const Spacer(),
                      Text(
                        jar.isActive ? (left == 1 ? '1 ${units.substring(0, units.length - 1)} to go' : '$left $units to go') : _statusText(jar),
                        style: TT.body(12, color: TT.muted),
                      ),
                    ]),
                  ]),
                ),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: _Stat('Each ${cycleWord(kid.frequency)}', money(jar.amountPerCycle, kid.currency))),
                  const SizedBox(width: 10),
                  Expanded(child: _Stat('Bonus', '+${jar.bonusPct}%')),
                  const SizedBox(width: 10),
                  Expanded(child: _Stat('Opens on', shortDate(jar.opensOn))),
                ]),
                const SizedBox(height: 14),
                SoftCard(
                  color: TT.tealSoft,
                  radius: 22,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      jar.status == JarStatus.matured ? 'Paid out on ${longDate(jar.closedOn ?? jar.opensOn)}' : 'On ${longDate(jar.opensOn)} you get back',
                      style: TT.body(13, color: TT.tealDark),
                    ),
                    Text(money(jar.payout, kid.currency), style: TT.display(30, color: TT.tealDark)),
                    Text(
                      '${money(jar.target, kid.currency)} saved + ${money(jar.bonusAmount, kid.currency)} bonus',
                      style: TT.body(12),
                    ),
                  ]),
                ),
              ],
            ),
          ),
          if (jar.isActive)
            Padding(
              padding: const EdgeInsets.fromLTRB(TT.gutter, 0, TT.gutter, 24),
              child: Column(children: [
                Text(
                  'Cancelling now returns ${money(jar.saved, kid.currency)}, without the bonus',
                  textAlign: TextAlign.center,
                  style: TT.body(11, color: TT.muted),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _confirmSettle(context, jar, kid),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    child: Text(
                      'Settle the amount and cancel',
                      style: TT.body(13, color: TT.coralStrong, decoration: TextDecoration.underline),
                    ),
                  ),
                ),
              ]),
            ),
        ]),
      ),
    );
  }

  String _statusText(Jar jar) => switch (jar.status) {
        JarStatus.matured => 'Opened',
        JarStatus.cancelled => 'Settled early',
        JarStatus.active => '',
      };
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
