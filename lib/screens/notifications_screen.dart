import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/format.dart';
import '../state/scope.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import '../widgets/icons.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final now = DateTime.now();
    final all = state.sortedNotices;
    final fresh = all.where((n) => !n.read).toList();
    final earlier = all.where((n) => n.read).take(50).toList();

    return Scaffold(
      backgroundColor: TT.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(TT.gutter, 16, TT.gutter, 32),
          children: [
            TopBar(
              'Notifications',
              trailing: fresh.isEmpty
                  ? null
                  : GestureDetector(
                      onTap: state.markAllRead,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('Mark all read', style: TT.body(13, color: TT.tealDark)),
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            if (all.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Column(children: [
                  Text('All caught up', style: TT.display(18)),
                  const SizedBox(height: 6),
                  Text('Pocket-money days, interest and jar news will show up here.',
                      textAlign: TextAlign.center, style: TT.body(13, color: TT.muted)),
                ]),
              ),
            if (fresh.isNotEmpty) _group('New', fresh, now),
            if (earlier.isNotEmpty) _group('Earlier', earlier, now),
          ],
        ),
      ),
    );
  }

  Widget _group(String title, List<Notice> items, DateTime now) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TT.body(13, color: TT.muted)),
        const SizedBox(height: 8),
        SoftCard(
          radius: 22,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Column(children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const ThinDivider(),
              _NoticeRow(n: items[i], now: now),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _NoticeRow extends StatelessWidget {
  final Notice n;
  final DateTime now;
  const _NoticeRow({required this.n, required this.now});

  static (TTIcons, Color, Color) _style(NoticeKind k) => switch (k) {
        NoticeKind.pocketMoney => (TTIcons.coins, TT.goldSoft, TT.iconGold),
        NoticeKind.interest => (TTIcons.grow, TT.tealSoft, TT.tealDark),
        NoticeKind.review => (TTIcons.chat, TT.coralSoft, TT.iconCoral),
        NoticeKind.jarProgress || NoticeKind.jarOpened || NoticeKind.jarSettled => (TTIcons.jar, TT.purpleSoft, TT.purple),
        NoticeKind.expense => (TTIcons.food, TT.coralSoft, TT.iconCoral),
        NoticeKind.deposit => (TTIcons.coins, TT.tealSoft, TT.tealDark),
      };

  @override
  Widget build(BuildContext context) {
    final (icon, tint, color) = _style(n.kind);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        IconTile(icon: icon, tint: tint, color: color, size: 40, radius: 13),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(n.title, style: TT.body(15, color: n.read ? TT.muted : TT.ink))),
              Text(ago(n.date, now), style: TT.body(11, color: TT.muted)),
              if (!n.read) ...[
                const SizedBox(width: 8),
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: TT.coralStrong, shape: BoxShape.circle)),
              ],
            ]),
            const SizedBox(height: 3),
            Text(n.body, style: TT.body(13, color: n.read ? TT.muted : TT.ink, height: 1.4)),
          ]),
        ),
      ]),
    );
  }
}
