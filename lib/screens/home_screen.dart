import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../state/format.dart';
import '../state/scope.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import '../widgets/icons.dart';
import '../widgets/illustrations.dart';
import 'add_kid_screen.dart';
import 'create_jar_screen.dart';
import 'jar_detail_screen.dart';
import 'notifications_screen.dart';
import 'sheets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final kid = state.selectedKid;
    if (kid == null) return const SizedBox.shrink();
    final jar = state.activeJar(kid);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(TT.gutter, 16, TT.gutter, 120),
        children: [
          Row(
            children: [
              Expanded(child: KidHeader(state: state, kid: kid)),
              const SizedBox(width: 8),
              CircleIconButton(
                TTIcons.bell,
                showDot: state.hasUnread,
                semanticLabel: 'Notifications',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
              ),
            ],
          ),
          const SizedBox(height: 22),
          BalanceCard(state: state, kid: kid),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: PrimaryButton('Expense', leadingPlus: true, onPressed: () => showAddEntrySheet(context, expense: true))),
              const SizedBox(width: 12),
              Expanded(child: SecondaryButton('Money', leadingPlus: true, onPressed: () => showAddEntrySheet(context, expense: false))),
            ],
          ),
          const SizedBox(height: 28),
          Text('Investment jars', style: TT.display(19)),
          const SizedBox(height: 12),
          if (jar == null)
            const StartJarCard()
          else
            ActiveJarCard(
              kid: kid,
              jar: jar,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => JarDetailScreen(jarId: jar.id))),
            ),
        ],
      ),
    );
  }
}

/// Kid switcher wired to state (Home and Settings).
class KidHeader extends StatelessWidget {
  final AppState state;
  final Kid kid;
  final String addLabel;
  const KidHeader({super.key, required this.state, required this.kid, this.addLabel = 'Kid'});

  @override
  Widget build(BuildContext context) {
    return KidSwitcher(
      kids: state.kids,
      selected: kid,
      addLabel: addLabel,
      onSelect: (k) => state.selectKid(k.id),
      onAdd: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddKidScreen())),
    );
  }
}

class BalanceCard extends StatelessWidget {
  final AppState state;
  final Kid kid;
  const BalanceCard({super.key, required this.state, required this.kid});

  @override
  Widget build(BuildContext context) {
    final balance = state.balanceOf(kid);
    final spent = state.spentInMonth(kid, DateTime.now());
    final toJar = state.jarContributionPerCycle(kid);
    final next = state.nextPocketMoney(kid);
    return Container(
      decoration: BoxDecoration(
        color: TT.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: TT.alpha(TT.ink, 0.08), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      padding: const EdgeInsets.all(22),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(right: -8, top: 4, child: Illustration(coinStackSvg, width: 96, height: 90)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 96),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${kid.name}'s balance", style: TT.body(14, color: TT.muted)),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(money(balance, kid.currency), style: TT.display(44, color: TT.coralStrong, height: 1.1)),
                    ),
                    const SizedBox(height: 4),
                    Text('${money(spent, kid.currency)} spent this month', style: TT.body(13, color: TT.muted)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Pill(
                'Next pocket money: ${money(next, kid.currency)} on ${shortDate(kid.nextPayDate)}',
                background: TT.coralSoft,
                color: TT.ink,
                leading: const TTIcon(TTIcons.calendar, color: TT.iconCoral, size: 14, strokeWidth: 2.4),
              ),
              if (toJar > 0) ...[
                const SizedBox(height: 6),
                Text(
                  '${money(kid.pocketMoney, kid.currency)} pocket money − ${money(toJar, kid.currency)} to your jar',
                  style: TT.body(11, color: TT.muted),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class StartJarCard extends StatelessWidget {
  const StartJarCard({super.key});

  @override
  Widget build(BuildContext context) {
    void open() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateJarScreen()));
    return SoftCard(
      color: TT.purpleSoft,
      radius: 26,
      onTap: open,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Illustration(sproutTileSvg, width: 52, height: 52),
              const Spacer(),
              Semantics(
                button: true,
                label: 'Create an investment jar',
                child: Material(
                  color: TT.purple,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: open,
                    child: const SizedBox(
                      width: 52,
                      height: 52,
                      child: Center(child: TTIcon(TTIcons.plus, color: TT.surface, size: 24, strokeWidth: 3)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Start an investment jar', style: TT.display(18)),
          const SizedBox(height: 6),
          Text(
            'Set aside a little from every pocket money. Pick 3, 6 or 12 months and get it back with interest.',
            style: TT.body(13, color: TT.muted, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class ActiveJarCard extends StatelessWidget {
  final Kid kid;
  final Jar jar;
  final VoidCallback onTap;
  const ActiveJarCard({super.key, required this.kid, required this.jar, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final unit = kid.frequency == Frequency.monthly ? 'Month' : 'Week';
    final progress = jar.totalCycles == 0 ? 0.0 : jar.cyclesPaid / jar.totalCycles;
    final step = jar.cyclesPaid == 0
        ? 'Starts ${shortDate(kid.nextPayDate)}'
        : '$unit ${jar.cyclesPaid} of ${jar.totalCycles}';
    return SoftCard(
      color: TT.purpleSoft,
      radius: 26,
      padding: const EdgeInsets.all(18),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Illustration(jarTileSvg, width: 44, height: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${jar.months}-month jar', style: TT.display(17)),
                  Text('Opens ${longDate(jar.opensOn)}', style: TT.body(12, color: TT.muted)),
                ]),
              ),
              Pill(step, background: TT.surface, color: TT.purple, fontSize: 11),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(money(jar.saved, kid.currency), style: TT.display(30)),
              const SizedBox(width: 6),
              Text('saved of ${money(jar.target, kid.currency)}', style: TT.body(13, color: TT.muted)),
            ],
          ),
          const SizedBox(height: 8),
          ProgressBar(value: progress, track: TT.surface, fill: TT.purple),
          const SizedBox(height: 10),
          Row(children: [
            const TTIcon(TTIcons.grow, color: TT.tealDark, size: 16, strokeWidth: 2.6),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                "You'll get back ${money(jar.payout, kid.currency)} (+${money(jar.bonusAmount, kid.currency)} bonus)",
                style: TT.body(13, color: TT.tealDark),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class ProgressBar extends StatelessWidget {
  final double value;
  final Color track;
  final Color fill;
  const ProgressBar({super.key, required this.value, required this.track, required this.fill});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: SizedBox(
        height: 10,
        child: Stack(children: [
          Positioned.fill(child: ColoredBox(color: track)),
          FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0).toDouble(),
            child: Container(decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(5))),
          ),
        ]),
      ),
    );
  }
}
