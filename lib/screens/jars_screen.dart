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
import 'home_screen.dart';
import 'jar_detail_screen.dart';
import 'kid_bar.dart';

/// Jars tab: an invitation when there are no jars, the jar itself when there's only one,
/// and a list from the second jar onwards.
class JarsScreen extends StatelessWidget {
  const JarsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final kid = state.selectedKid;
    if (kid == null) return const SizedBox.shrink();
    final active = state.activeJars(kid);
    final past = state.pastJars(kid);

    final Widget body;
    if (active.isEmpty && past.isEmpty) {
      body = _EmptyJars(kid: kid);
    } else if (active.length == 1 && past.isEmpty) {
      body = _SingleJar(state: state, kid: kid, jar: active.first);
    } else {
      body = _JarList(state: state, kid: kid, active: active, past: past);
    }

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(TT.gutter, 16, TT.gutter, 120),
        children: [
          const KidTopBar(),
          const SizedBox(height: 20),
          KidFade(
            kidId: kid.id,
            child: AnimatedSwitcher(
              duration: Motion.medium,
              child: KeyedSubtree(key: ValueKey('${active.length}-${past.length}'), child: body),
            ),
          ),
        ],
      ),
    );
  }
}

void _openCreate(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateJarScreen()));

class _EmptyJars extends StatelessWidget {
  final Kid kid;
  const _EmptyJars({required this.kid});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: Illustration(moneyTreeJarSvg, width: 210, height: 180)),
        const SizedBox(height: 14),
        Text('Watch your money grow!', textAlign: TextAlign.center, style: TT.display(26)),
        const SizedBox(height: 6),
        Text(
          'Drop a little from every pocket money into a jar. Leave it to grow, and it comes back with a bonus!',
          textAlign: TextAlign.center,
          style: TT.body(14, color: TT.muted, height: 1.45),
        ),
        const SizedBox(height: 18),
        SoftCard(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            _Step('1', 'Pick how much',
                'Like ${money((kid.pocketMoney * 0.05).round(), kid.currency)} from each pocket money', TT.purpleSoft, TT.purple),
            const SizedBox(height: 14),
            const _Step('2', 'Pick how long', '3, 6 or 12 months. Longer grows more!', TT.skySoft, TT.ink),
            const SizedBox(height: 14),
            const _Step('3', 'Get a bonus', 'Your jar pops open with extra money', TT.goldSoft, TT.ink),
          ]),
        ),
        const SizedBox(height: 18),
        PrimaryButton('Start my first jar', leadingPlus: true, onPressed: () => _openCreate(context)),
      ],
    );
  }
}

class _SingleJar extends StatelessWidget {
  final AppState state;
  final Kid kid;
  final Jar jar;
  const _SingleJar({required this.state, required this.kid, required this.jar});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('${jar.months}-month jar', style: TT.display(26)),
        Text('Started ${longDate(jar.startDate)}', style: TT.body(13, color: TT.muted)),
        const SizedBox(height: 16),
        JarDetailBody(jar: jar, kid: kid),
        const SizedBox(height: 18),
        if (state.canStartJar(kid))
          SecondaryButton('Start another jar', leadingPlus: true, onPressed: () => _openCreate(context))
        else
          const _FullNote(),
        const SizedBox(height: 18),
        SettleLink(jar: jar, kid: kid),
      ],
    );
  }
}

class _JarList extends StatelessWidget {
  final AppState state;
  final Kid kid;
  final List<Jar> active;
  final List<Jar> past;
  const _JarList({required this.state, required this.kid, required this.active, required this.past});

  @override
  Widget build(BuildContext context) {
    void openDetail(Jar j) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => JarDetailScreen(jarId: j.id)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('My jars', style: TT.display(26)),
        Text(
          active.isEmpty
              ? 'No jars growing right now'
              : active.length == 1
                  ? '1 jar growing'
                  : '${active.length} jars growing',
          style: TT.body(13, color: TT.muted),
        ),
        const SizedBox(height: 16),
        for (final j in active) ...[
          ActiveJarCard(kid: kid, jar: j, onTap: () => openDetail(j)),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 6),
        if (active.isEmpty)
          PrimaryButton('Start a new jar', leadingPlus: true, onPressed: () => _openCreate(context))
        else if (state.canStartJar(kid))
          SecondaryButton('Start another jar', leadingPlus: true, onPressed: () => _openCreate(context))
        else
          const _FullNote(),
        if (past.isNotEmpty) ...[
          const SizedBox(height: 26),
          Text('Jars that popped open', style: TT.body(13, color: TT.muted)),
          const SizedBox(height: 8),
          SoftCard(
            radius: 22,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Column(children: [
              for (var i = 0; i < past.length; i++) ...[
                if (i > 0) const ThinDivider(),
                _PastJarRow(jar: past[i], currency: kid.currency, onTap: () => openDetail(past[i])),
              ],
            ]),
          ),
        ],
      ],
    );
  }
}

class _FullNote extends StatelessWidget {
  const _FullNote();
  @override
  Widget build(BuildContext context) => Text(
        'Your jars already use the full 10% of pocket money. When one pops open, you can start another!',
        textAlign: TextAlign.center,
        style: TT.body(12, color: TT.muted, height: 1.4),
      );
}

class _Step extends StatelessWidget {
  final String n, title, sub;
  final Color tint, color;
  const _Step(this.n, this.title, this.sub, this.tint, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(12)),
        child: Text(n, style: TT.display(17, color: color)),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TT.body(15)),
          Text(sub, style: TT.body(12, color: TT.muted)),
        ]),
      ),
    ]);
  }
}

class _PastJarRow extends StatelessWidget {
  final Jar jar;
  final String currency;
  final VoidCallback onTap;
  const _PastJarRow({required this.jar, required this.currency, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final matured = jar.status == JarStatus.matured;
    final amount = matured ? jar.saved + (jar.saved * jar.bonusPct / 100).round() : jar.saved;
    return Pressable(
      scale: 0.98,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(children: [
            IconTile(icon: TTIcons.jar, tint: matured ? TT.tealSoft : TT.track, color: matured ? TT.tealDark : TT.muted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${jar.months}-month jar', style: TT.body(15)),
                Text(
                  '${matured ? 'Popped open' : 'Opened early'} · ${shortDate(jar.closedOn ?? jar.opensOn)}',
                  style: TT.body(12, color: TT.muted),
                ),
              ]),
            ),
            Text(money(amount, currency), style: TT.display(17, color: matured ? TT.tealDark : TT.muted)),
          ]),
        ),
      ),
    );
  }
}
