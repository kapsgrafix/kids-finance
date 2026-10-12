import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../state/format.dart';
import '../state/scope.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import '../widgets/icons.dart';
import '../widgets/illustrations.dart';
import 'create_jar_screen.dart';
import 'jar_detail_screen.dart';
import 'kid_bar.dart';
import 'sheets.dart';
import 'shell.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final kid = state.selectedKid;
    if (kid == null) return const SizedBox.shrink();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(TT.gutter, 16, TT.gutter, 120),
        children: [
          const KidTopBar(),
          const SizedBox(height: 22),
          KidFade(
            kidId: kid.id,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BalanceCard(state: state, kid: kid),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton('Expense',
                          leadingPlus: true, onPressed: () => showAddEntrySheet(context, expense: true)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SecondaryButton('Money',
                          leadingPlus: true, onPressed: () => showAddEntrySheet(context, expense: false)),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text('My jars', style: TT.display(19)),
                const SizedBox(height: 12),
                JarSection(state: state, kid: kid),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Home's jar area: start a jar, the one jar, or a summary of several.
class JarSection extends StatelessWidget {
  final AppState state;
  final Kid kid;
  const JarSection({super.key, required this.state, required this.kid});

  @override
  Widget build(BuildContext context) {
    final active = state.activeJars(kid);
    final Widget child;
    if (active.isEmpty) {
      child = StartJarCard(first: !state.hasAnyJar(kid));
    } else if (active.length == 1) {
      // The first and only jar opens straight into its details.
      final jar = active.first;
      child = ActiveJarCard(
        kid: kid,
        jar: jar,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => JarDetailScreen(jarId: jar.id))),
      );
    } else {
      // Two or more: show a summary that leads to the list.
      child = JarsSummaryCard(kid: kid, jars: active, onTap: () => Shell.goTo(context, Shell.jars));
    }
    return AnimatedSwitcher(duration: Motion.medium, child: KeyedSubtree(key: ValueKey(active.length), child: child));
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
                    Text("${kid.name}'s treasure", style: TT.body(14, color: TT.muted)),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: AnimatedValueText(
                        money(balance, kid.currency),
                        style: TT.display(44, color: TT.coralStrong, height: 1.1),
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedValueText(
                      spent == 0 ? 'Nothing spent yet. Super saver!' : '${money(spent, kid.currency)} spent this month',
                      style: TT.body(13, color: TT.muted),
                    ),
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
              AnimatedSize(
                duration: Motion.medium,
                curve: Motion.curve,
                child: toJar > 0
                    ? Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '${money(toJar, kid.currency)} of your ${money(kid.pocketMoney, kid.currency)} hops into your jars',
                          style: TT.body(11, color: TT.muted),
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StartJarCard extends StatelessWidget {
  final bool first;
  const StartJarCard({super.key, required this.first});

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
                label: 'Start a jar',
                child: Pressable(
                  scale: 0.9,
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
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(first ? 'Start your first jar' : 'Start a new jar', style: TT.display(18)),
          const SizedBox(height: 6),
          Text(
            first
                ? 'Drop in a little from every pocket money. Pick 3, 6 or 12 months and it comes back with a bonus!'
                : 'Your last jar is done. Ready to grow another one?',
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
                  Text('Pops open ${longDate(jar.opensOn)}', style: TT.body(12, color: TT.muted)),
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
              AnimatedValueText(money(jar.saved, kid.currency), style: TT.display(30)),
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
                'Grows into ${money(jar.payout, kid.currency)} (+${money(jar.bonusAmount, kid.currency)} bonus)!',
                style: TT.body(13, color: TT.tealDark),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

/// Shown on Home when two or more jars are growing.
class JarsSummaryCard extends StatelessWidget {
  final Kid kid;
  final List<Jar> jars;
  final VoidCallback onTap;
  const JarsSummaryCard({super.key, required this.kid, required this.jars, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final saved = jars.fold<int>(0, (s, j) => s + j.saved);
    final payout = jars.fold<int>(0, (s, j) => s + j.payout);
    final target = jars.fold<int>(0, (s, j) => s + j.target);
    return SoftCard(
      color: TT.purpleSoft,
      radius: 26,
      padding: const EdgeInsets.all(18),
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Illustration(jarTileSvg, width: 44, height: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${jars.length} jars growing', style: TT.display(17)),
              Text('Tap to peek inside', style: TT.body(12, color: TT.muted)),
            ]),
          ),
          const TTIcon(TTIcons.chevronRight, color: TT.purple, size: 20, strokeWidth: 2.6),
        ]),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            AnimatedValueText(money(saved, kid.currency), style: TT.display(30)),
            const SizedBox(width: 6),
            Text('saved so far', style: TT.body(13, color: TT.muted)),
          ],
        ),
        const SizedBox(height: 8),
        ProgressBar(value: target == 0 ? 0 : saved / target, track: TT.surface, fill: TT.purple),
        const SizedBox(height: 10),
        Row(children: [
          const TTIcon(TTIcons.grow, color: TT.tealDark, size: 16, strokeWidth: 2.6),
          const SizedBox(width: 6),
          Expanded(
            child: Text('All together they grow into ${money(payout, kid.currency)}!',
                style: TT.body(13, color: TT.tealDark)),
          ),
        ]),
      ]),
    );
  }
}

/// Rounded progress bar whose fill glides to its new value.
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
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: value.clamp(0.0, 1.0).toDouble()),
            duration: Motion.slow,
            curve: Motion.curve,
            builder: (_, v, __) => FractionallySizedBox(
              widthFactor: v,
              child: Container(decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(5))),
            ),
          ),
        ]),
      ),
    );
  }
}
