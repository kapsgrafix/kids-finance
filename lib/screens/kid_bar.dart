import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../state/scope.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import '../widgets/icons.dart';
import 'add_kid_screen.dart';
import 'notifications_screen.dart';

/// The kid switcher wired to state. The selected kid is shared by every tab.
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

/// Top of every tab: kid switcher on the left, notifications bell on the right.
class KidTopBar extends StatelessWidget {
  const KidTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final kid = state.selectedKid;
    if (kid == null) return const SizedBox(height: 52);
    return Row(
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
    );
  }
}

/// Cross-fades a tab's content when the selected kid changes.
class KidFade extends StatelessWidget {
  final String kidId;
  final Widget child;
  const KidFade({super.key, required this.kidId, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Motion.medium,
      switchInCurve: Motion.curve,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: [...previous, if (current != null) current],
      ),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.03, 0), end: Offset.zero).animate(anim),
          child: child,
        ),
      ),
      child: KeyedSubtree(key: ValueKey(kidId), child: child),
    );
  }
}
