import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/format.dart';
import '../state/scope.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import '../widgets/icons.dart';
import 'add_kid_screen.dart';
import 'kid_bar.dart';
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
      final v = await showTextEditSheet(context, title: "What's the name?", initial: kid.name, hint: 'e.g. Aarav');
      if (v != null) state.updateKid(kid, name: v);
    }

    Future<void> editPocket() async {
      final v = await showTextEditSheet(context,
          title: 'Pocket money', initial: '${kid.pocketMoney}', hint: 'e.g. 500', numeric: true, prefix: cur.symbol.trim());
      if (v != null) state.updateKid(kid, pocketMoney: int.tryParse(v));
    }

    Future<void> editFrequency() async {
      final v = await showChoiceSheet<Frequency>(context, title: 'How often?', value: kid.frequency, options: const [
        (Frequency.weekly, 'Weekly', 'Pocket money every week'),
        (Frequency.monthly, 'Monthly', 'Pocket money every month'),
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
          title: 'Saving bonus',
          caption: 'Extra money on whatever ${kid.name} still has on pocket-money day. Saving pays!',
          initial: kid.interestPct,
          min: 0,
          max: 20);
      if (v != null) state.updateKid(kid, interestPct: v);
    }

    Future<void> editBonus() async {
      final v = await showJarBonusSheet(context, kid.jarBonus);
      if (v != null) state.updateKid(kid, jarBonus: v);
    }

    Future<void> editSchedule() async {
      final v = await showReviewScheduleSheet(context, kid);
      if (v != null) {
        state.setReviewSchedule(kid, payDay: v.$1, hour: v.$2, minute: v.$3);
        if (context.mounted) showToast(context, 'Next money chat: ${shortDate(kid.nextPayDate)}, ${clock(v.$2, v.$3)}');
      }
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
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Settings', style: TT.display(26)),
              const SizedBox(height: 16),
              _Group(title: "${kid.name}'s profile", rows: [
                _Row('Name', TTIcons.smile, TT.purpleSoft, TT.purple, value: kid.name, onTap: editName),
                _Row('Pocket money', TTIcons.coins, TT.goldSoft, TT.iconGold,
                    value: money(kid.pocketMoney, kid.currency), onTap: editPocket),
                _Row('How often', TTIcons.calendar, TT.coralSoft, TT.iconCoral,
                    value: kid.frequency == Frequency.monthly ? 'Monthly' : 'Weekly', onTap: editFrequency),
                _Row('Currency', TTIcons.globe, TT.skySoft, TT.iconSky,
                    value: '${cur.symbol.trim()} ${cur.code}', onTap: editCurrency),
              ]),
              const SizedBox(height: 20),
              _Group(title: 'Rewards', rows: [
                _Row('Saving bonus', TTIcons.grow, TT.tealSoft, TT.tealDark,
                    value: '${kid.interestPct}%', sub: 'Extra for money left on pocket-money day', onTap: editInterest),
                _Row('Jar bonus', TTIcons.jar, TT.purpleSoft, TT.purple,
                    sub: '3 mo ${b[3] ?? 0}% · 6 mo ${b[6] ?? 0}% · 12 mo ${b[12] ?? 0}%', onTap: editBonus),
              ]),
              const SizedBox(height: 20),
              _Group(title: 'Review together', rows: [
                _Row('Money chat', TTIcons.chat, TT.coralSoft, TT.iconCoral,
                    value: clock(kid.reviewHour, kid.reviewMinute),
                    sub: '${kid.frequency == Frequency.monthly ? '${ordinal(kid.payDay)} of every month' : 'Every ${weekdayOf(kid.payDay)}'} · next ${shortDate(kid.nextPayDate)}',
                    onTap: editSchedule),
              ]),
              const SizedBox(height: 28),
              Center(
                child: GestureDetector(
                  onTap: () => _confirmRemove(context, kid),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: Text(
                      "Remove ${kid.name}'s profile",
                      style: TT.body(14, color: TT.coralStrong, decoration: TextDecoration.underline),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context, Kid kid) async {
    final ok = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: TT.alpha(TT.ink, 0.45),
      transitionDuration: Motion.medium,
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
          child: child,
        ),
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
                Text("Remove ${kid.name}'s profile?", style: TT.display(20)),
                const SizedBox(height: 8),
                Text(
                  "This deletes ${kid.name}'s treasure, money history and jars from this phone. It can't be undone.",
                  style: TT.body(14, color: TT.muted, height: 1.4),
                ),
                const SizedBox(height: 20),
                SecondaryButton('Keep ${kid.name}', onPressed: () => Navigator.of(ctx).pop(false)),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text('Yes, remove profile', style: TT.body(15, color: TT.coralStrong)),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    final state = AppScope.read(context);
    state.removeKid(kid);
    if (!state.hasKids) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AddKidScreen(isFirst: true)),
        (_) => false,
      );
    } else {
      showToast(context, "${kid.name}'s profile was removed");
    }
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
            Pressable(
              scale: 0.98,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
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
                      AnimatedValueText(rows[i].value!, style: TT.body(14, color: TT.muted)),
                    ],
                    const SizedBox(width: 6),
                    const TTIcon(TTIcons.chevronRight, color: TT.muted, size: 16, strokeWidth: 2.4),
                  ]),
                ),
              ),
            ),
          ],
        ]),
      ),
    ]);
  }
}
