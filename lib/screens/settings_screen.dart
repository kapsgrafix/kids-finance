import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/format.dart';
import '../state/scope.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import '../widgets/icons.dart';
import 'home_screen.dart';
import 'sheets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final kid = state.selectedKid;
    if (kid == null) return const SizedBox.shrink();
    final cur = Currency.of(kid.currency);
    final b = kid.jarBonus;

    Future<void> editName() async {
      final v = await showTextEditSheet(context, title: "Kid's name", initial: kid.name, hint: 'e.g. Aarav');
      if (v != null) state.updateKid(kid, name: v);
    }

    Future<void> editPocket() async {
      final v = await showTextEditSheet(context,
          title: 'Pocket money', initial: '${kid.pocketMoney}', hint: 'e.g. 500', numeric: true, prefix: cur.symbol.trim());
      if (v != null) state.updateKid(kid, pocketMoney: int.tryParse(v));
    }

    Future<void> editFrequency() async {
      final v = await showChoiceSheet<Frequency>(context, title: 'Frequency', value: kid.frequency, options: const [
        (Frequency.weekly, 'Weekly', 'Every 7 days'),
        (Frequency.monthly, 'Monthly', 'On the 1st of every month'),
      ]);
      if (v != null) state.updateKid(kid, frequency: v);
    }

    Future<void> editCurrency() async {
      final v = await showChoiceSheet<String>(context,
          title: 'Currency',
          value: kid.currency,
          options: [for (final c in Currency.all) (c.code, '${c.symbol.trim()}  ${c.code}', c.label)]);
      if (v != null) state.updateKid(kid, currency: v);
    }

    Future<void> editInterest() async {
      final v = await showStepperSheet(context,
          title: 'Savings interest',
          caption: 'Paid on the money ${kid.name} still has on every pocket-money day.',
          initial: kid.interestPct,
          min: 0,
          max: 20);
      if (v != null) state.updateKid(kid, interestPct: v);
    }

    Future<void> editBonus() async {
      final v = await showJarBonusSheet(context, kid.jarBonus);
      if (v != null) state.updateKid(kid, jarBonus: v);
    }

    final payDay = kid.frequency == Frequency.monthly ? '1st of month' : 'Every ${weekdayName(kid.nextPayDate)}';

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(TT.gutter, 16, TT.gutter, 120),
        children: [
          Text('Settings', style: TT.display(26)),
          const SizedBox(height: 16),
          KidHeader(state: state, kid: kid, addLabel: 'Add a kid'),
          const SizedBox(height: 22),
          _Group(title: "${kid.name}'s profile", rows: [
            _Row("Kid's name", TTIcons.smile, TT.purpleSoft, TT.purple, value: kid.name, onTap: editName),
            _Row('Pocket money', TTIcons.coins, TT.goldSoft, TT.iconGold, value: money(kid.pocketMoney, kid.currency), onTap: editPocket),
            _Row('Frequency', TTIcons.calendar, TT.coralSoft, TT.iconCoral,
                value: kid.frequency == Frequency.monthly ? 'Monthly' : 'Weekly', onTap: editFrequency),
            _Row('Currency', TTIcons.globe, TT.skySoft, TT.iconSky, value: '${cur.symbol.trim()} ${cur.code}', onTap: editCurrency),
          ]),
          const SizedBox(height: 20),
          _Group(title: 'Rewards', rows: [
            _Row('Savings interest', TTIcons.grow, TT.tealSoft, TT.tealDark,
                value: '${kid.interestPct}%', sub: 'Paid on money left at review time', onTap: editInterest),
            _Row('Jar bonus', TTIcons.jar, TT.purpleSoft, TT.purple,
                sub: '3 mo ${b[3] ?? 0}% · 6 mo ${b[6] ?? 0}% · 12 mo ${b[12] ?? 0}%', onTap: editBonus),
            _Row('Review together', TTIcons.chat, TT.coralSoft, TT.iconCoral,
                value: payDay,
                sub: 'Next: ${shortDate(kid.nextPayDate)}',
                onTap: () => showToast(context, 'Review day follows the pocket-money day. Change it with Frequency.')),
          ]),
        ],
      ),
    );
  }
}

class _Row {
  final String label;
  final TTIcons icon;
  final Color tint, color;
  final String? value, sub;
  final VoidCallback onTap;
  const _Row(this.label, this.icon, this.tint, this.color, {this.value, this.sub, required this.onTap});
}

class _Group extends StatelessWidget {
  final String title;
  final List<_Row> rows;
  const _Group({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TT.body(13, color: TT.muted)),
      const SizedBox(height: 8),
      SoftCard(
        radius: 22,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Column(children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const ThinDivider(),
            InkWell(
              onTap: rows[i].onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Row(children: [
                  IconTile(icon: rows[i].icon, tint: rows[i].tint, color: rows[i].color, size: 34, radius: 11, iconSize: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(rows[i].label, style: TT.body(15)),
                      if (rows[i].sub != null) Text(rows[i].sub!, style: TT.body(11, color: TT.muted)),
                    ]),
                  ),
                  if (rows[i].value != null) ...[
                    const SizedBox(width: 8),
                    Text(rows[i].value!, style: TT.body(14, color: TT.muted)),
                  ],
                  const SizedBox(width: 6),
                  const TTIcon(TTIcons.chevronRight, color: TT.muted, size: 16, strokeWidth: 2.4),
                ]),
              ),
            ),
          ],
        ]),
      ),
    ]);
  }
}
