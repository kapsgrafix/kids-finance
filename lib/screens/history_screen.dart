import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/format.dart';
import '../state/scope.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import '../widgets/icons.dart';
import 'sheets.dart';

enum _Filter { all, expenses, deposits }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  _Filter _filter = _Filter.all;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final kid = state.selectedKid;
    if (kid == null) return const SizedBox.shrink();
    final now = DateTime.now();

    final monthEntries = state
        .entriesFor(kid)
        .where((e) => e.date.year == _month.year && e.date.month == _month.month)
        .where((e) => switch (_filter) {
              _Filter.all => true,
              _Filter.expenses => e.isExpense,
              _Filter.deposits => !e.isExpense,
            })
        .toList();

    // Group by calendar day, newest first.
    final groups = <DateTime, List<Entry>>{};
    for (final e in monthEntries) {
      groups.putIfAbsent(dateOnly(e.date), () => []).add(e);
    }

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(TT.gutter, 16, TT.gutter, 120),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('History', style: TT.display(26)),
                  if (state.kids.length > 1) Text(kid.name, style: TT.body(13, color: TT.muted)),
                ]),
              ),
              GestureDetector(
                onTap: () async {
                  final months = state.activeMonths(kid);
                  final picked = await showChoiceSheet<DateTime>(
                    context,
                    title: 'Pick a month',
                    value: _month,
                    options: [for (final m in months) (m, monthYear(m), null)],
                  );
                  if (picked != null) setState(() => _month = picked);
                },
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
                  decoration: BoxDecoration(color: TT.surface, borderRadius: BorderRadius.circular(999)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(
                      _month.year == now.year ? monthName(_month.month) : monthYear(_month),
                      style: TT.body(14),
                    ),
                    const SizedBox(width: 4),
                    const TTIcon(TTIcons.chevronDown, color: TT.ink, size: 16, strokeWidth: 2.6),
                  ]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Segmented<_Filter>(
            options: const [(_Filter.all, 'All'), (_Filter.expenses, 'Expenses'), (_Filter.deposits, 'Deposits')],
            value: _filter,
            onChanged: (f) => setState(() => _filter = f),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: _Stat(
                label: 'Money in',
                value: money(state.inInMonth(kid, _month), kid.currency, signed: true),
                tint: TT.tealSoft,
                color: TT.tealDark,
                icon: TTIcons.arrowDown,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Stat(
                label: 'Spent',
                value: money(state.spentInMonth(kid, _month), kid.currency, signed: true, negative: true),
                tint: TT.coralSoft,
                color: TT.coralStrong,
                icon: TTIcons.arrowUp,
              ),
            ),
          ]),
          const SizedBox(height: 22),
          if (groups.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Column(children: [
                Text('Nothing here yet', style: TT.display(18)),
                const SizedBox(height: 6),
                Text(
                  'Expenses and money added this month will show up here.',
                  textAlign: TextAlign.center,
                  style: TT.body(13, color: TT.muted),
                ),
              ]),
            ),
          for (final day in groups.keys) ...[
            Text(dayLabel(day, now), style: TT.body(13, color: TT.muted)),
            const SizedBox(height: 8),
            SoftCard(
              radius: 22,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Column(children: [
                for (var i = 0; i < groups[day]!.length; i++) ...[
                  if (i > 0) const ThinDivider(),
                  EntryRow(entry: groups[day]![i], currency: kid.currency),
                ],
              ]),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color tint;
  final Color color;
  final TTIcons icon;
  const _Stat({required this.label, required this.value, required this.tint, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: TT.surface, shape: BoxShape.circle),
          child: TTIcon(icon, color: color, size: 18, strokeWidth: 2.6),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TT.body(12, color: TT.muted)),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: TT.display(18, color: color)),
            ),
          ]),
        ),
      ]),
    );
  }
}

class EntryRow extends StatelessWidget {
  final Entry entry;
  final String currency;
  const EntryRow({super.key, required this.entry, required this.currency});

  @override
  Widget build(BuildContext context) {
    final s = CategoryStyle.forEntry(entry);
    final title = entry.note.isEmpty ? s.label : entry.note;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        IconTile(icon: s.icon, tint: s.tint, color: s.color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TT.body(15)),
            const SizedBox(height: 2),
            Text(entryMeta(entry, timeOfDay(entry.date)), style: TT.body(12, color: TT.muted)),
          ]),
        ),
        const SizedBox(width: 8),
        Text(
          money(entry.amount, currency, signed: true, negative: entry.isExpense),
          style: TT.display(17, color: entry.isExpense ? TT.coralStrong : TT.tealDark),
        ),
      ]),
    );
  }
}
