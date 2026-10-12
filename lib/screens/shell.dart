import 'package:flutter/material.dart';

import '../state/scope.dart';
import '../theme/tokens.dart';
import '../widgets/icons.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'jars_screen.dart';
import 'settings_screen.dart';

/// The four main tabs behind a soft bottom navigation bar.
class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> with WidgetsBindingObserver {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    // A pocket-money day may have passed while the app was in the background.
    if (s == AppLifecycleState.resumed) AppScope.read(context).processDueCycles(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TT.bg,
      extendBody: true,
      body: IndexedStack(
        index: _tab,
        children: const [HomeScreen(), HistoryScreen(), JarsScreen(), SettingsScreen()],
      ),
      bottomNavigationBar: _BottomNav(index: _tab, onTap: (i) => setState(() => _tab = i)),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.index, required this.onTap});

  static const _items = [
    (TTIcons.home, 'Home'),
    (TTIcons.history, 'History'),
    (TTIcons.jar, 'Jars'),
    (TTIcons.settings, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(28, 10, 28, 10 + (bottom > 0 ? bottom - 6 : 6)),
      decoration: BoxDecoration(
        color: TT.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [BoxShadow(color: TT.alpha(TT.ink, 0.07), blurRadius: 20, offset: const Offset(0, -6))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < _items.length; i++)
            Semantics(
              button: true,
              selected: i == index,
              label: _items[i].$2,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.symmetric(horizontal: i == index ? 14 : 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: i == index ? TT.tealSoft : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    TTIcon(_items[i].$1, color: i == index ? TT.tealDark : TT.muted, size: 22),
                    if (i == index) ...[
                      const SizedBox(width: 6),
                      Text(_items[i].$2, style: TT.body(13, color: TT.tealDark)),
                    ],
                  ]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
