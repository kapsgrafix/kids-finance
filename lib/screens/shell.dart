import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/scope.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import '../widgets/icons.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'jars_screen.dart';
import 'settings_screen.dart';

/// The four main tabs behind a soft bottom navigation bar.
class Shell extends StatefulWidget {
  const Shell({super.key});

  /// Current tab. Other screens can switch tabs, e.g. Home → Jars.
  static final ValueNotifier<int> tab = ValueNotifier<int>(0);
  static const home = 0, history = 1, jars = 2, settings = 3;

  static void goTo(BuildContext context, int index) {
    Navigator.of(context).popUntil((r) => r.isFirst);
    tab.value = index;
  }

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> with WidgetsBindingObserver {
  static const _tabs = [HomeScreen(), HistoryScreen(), JarsScreen(), SettingsScreen()];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Shell.tab.value = Shell.home;
    Shell.tab.addListener(_onTab);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    Shell.tab.removeListener(_onTab);
    super.dispose();
  }

  void _onTab() => setState(() {});

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    // A pocket-money day may have passed while the app was in the background.
    if (s == AppLifecycleState.resumed) AppScope.read(context).processDueCycles(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final current = Shell.tab.value;
    return Scaffold(
      backgroundColor: TT.bg,
      extendBody: true,
      body: Stack(
        children: [
          for (var i = 0; i < _tabs.length; i++)
            // Fade-through between tabs; every tab keeps its scroll position and state.
            Positioned.fill(
              child: IgnorePointer(
              ignoring: i != current,
              child: ExcludeSemantics(
                excluding: i != current,
                child: AnimatedOpacity(
                  opacity: i == current ? 1 : 0,
                  duration: Motion.medium,
                  curve: Motion.curve,
                  child: AnimatedSlide(
                    offset: i == current ? Offset.zero : const Offset(0, 0.015),
                    duration: Motion.medium,
                    curve: Motion.curve,
                    child: TickerMode(enabled: i == current, child: _tabs[i]),
                  ),
                ),
              ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        index: current,
        onTap: (i) {
          if (i != current) HapticFeedback.selectionClick();
          Shell.tab.value = i;
        },
      ),
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
      // White all the way down, behind the Android gesture/buttons bar too.
      padding: EdgeInsets.fromLTRB(28, 10, 28, 10 + (bottom > 0 ? bottom - 4 : 6)),
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
              child: Pressable(
                scale: 0.92,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: AnimatedContainer(
                    duration: Motion.medium,
                    curve: Motion.curve,
                    padding: EdgeInsets.symmetric(horizontal: i == index ? 14 : 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: i == index ? TT.tealSoft : TT.alpha(TT.tealSoft, 0),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      TweenAnimationBuilder<Color?>(
                        tween: ColorTween(end: i == index ? TT.tealDark : TT.muted),
                        duration: Motion.medium,
                        builder: (_, c, __) => TTIcon(_items[i].$1, color: c ?? TT.muted, size: 22),
                      ),
                      AnimatedSize(
                        duration: Motion.medium,
                        curve: Motion.curve,
                        child: i == index
                            ? Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Text(_items[i].$2, style: TT.body(13, color: TT.tealDark)),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
