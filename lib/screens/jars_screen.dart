import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/format.dart';
import '../state/scope.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import '../widgets/icons.dart';
import '../widgets/illustrations.dart';
import 'create_jar_screen.dart';
import 'home_screen.dart';
import 'jar_detail_screen.dart';

class JarsScreen extends StatelessWidget {
  const JarsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final kid = state.selectedKid;
    if (kid == null) return const SizedBox.shrink();
    final jar = state.activeJar(kid);
    final past = state.pastJars(kid);

    void openDetail(Jar j) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => JarDetailScreen(jarId: j.id)));

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(TT.gutter, 16, TT.gutter, 120),
        children: [
          Text('Investment jars', style: TT.display(26)),
          if (state.kids.length > 1) Text(kid.name, style: TT.body(13, color: TT.muted)),
          const SizedBox(height: 10),
          if (jar != null) ...[
            const SizedBox(height: 6),
            ActiveJarCard(kid: kid, jar: jar, onTap: () => openDetail(jar)),
          ] else
            _EmptyJars(kid: kid),
          if (past.isNotEmpty) ...[
            const SizedBox(height: 26),
            Text('Past jars', style: TT.body(13, color: TT.muted)),
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
      ),
    );
  }
}

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
          'Put a little aside from every pocket money. Leave it in a jar, and get it all back with a bonus.',
          textAlign: TextAlign.center,
          style: TT.body(14, color: TT.muted, height: 1.45),
        ),
        const SizedBox(height: 18),
        SoftCard(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            _Step('1', 'Pick an amount',
                'Like ${money((kid.pocketMoney * 0.1).round(), kid.currency)} from each pocket money', TT.purpleSoft, TT.purple),
            const SizedBox(height: 14),
            const _Step('2', 'Choose a plan', '3, 6 or 12 months. Longer grows more', TT.skySoft, TT.ink),
            const SizedBox(height: 14),
            const _Step('3', 'Get a bonus', 'Your jar comes back with interest', TT.goldSoft, TT.ink),
          ]),
        ),
        const SizedBox(height: 18),
        PrimaryButton(
          'Start my first jar',
          leadingPlus: true,
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateJarScreen())),
        ),
      ],
    );
  }
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
    return GestureDetector(
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
                '${matured ? 'Opened' : 'Settled early'} · ${shortDate(jar.closedOn ?? jar.opensOn)}',
                style: TT.body(12, color: TT.muted),
              ),
            ]),
          ),
          Text(money(amount, currency), style: TT.display(17, color: matured ? TT.tealDark : TT.muted)),
        ]),
      ),
    );
  }
}
