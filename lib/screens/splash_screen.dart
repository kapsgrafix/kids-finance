import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../state/scope.dart';
import '../theme/tokens.dart';
import '../widgets/illustrations.dart';
import 'add_kid_screen.dart';
import 'shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final state = AppScope.read(context);
    await Future.wait([state.load(), Future<void>.delayed(const Duration(milliseconds: 1600))]);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) => state.hasKids ? const Shell() : const AddKidScreen(isFirst: true),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TT.bg,
      body: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth, h = c.maxHeight;
        // Positions are expressed as fractions of the 360×720 Figma frame.
        double x(double v) => v / 360 * w;
        double y(double v) => v / 720 * h;
        return Stack(
          children: [
            _blob(x(190), y(-110), x(280), const Color(0xFFFFF0C2)),
            _blob(x(-70), y(90), x(150), TT.purpleSoft),
            _blob(x(-140), y(560), x(320), const Color(0xFFD2F1EC)),
            _blob(x(290), y(590), x(120), TT.coralSoft),
            Positioned(
              left: w / 2 - x(165),
              top: h / 2 - x(165),
              child: Container(
                width: x(330),
                height: x(330),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [TT.alpha(Colors.white, 0.9), TT.alpha(Colors.white, 0)]),
                ),
              ),
            ),
            _coin(x(276), y(150), 30, 0.25, 0.55),
            _coin(x(52), y(500), 22, -0.17, 0.45),
            _coin(x(296), y(470), 18, 0.35, 0.4),
            _coin(x(78), y(196), 16, -0.3, 0.35),
            _sparkle(x(40), y(300), 16, '#FF5FA2', 0.55),
            _sparkle(x(318), y(250), 12, '#8E5BE8', 0.55),
            _sparkle(x(250), y(560), 14, '#4FC3F7', 0.6),
            _sparkle(x(120), y(610), 10, '#FFC83D', 0.8),
            _sparkle(x(220), y(120), 10, '#4FC3F7', 0.5),
            Center(
              child: Semantics(
                label: 'Tiny Treasury',
                child: Image.asset('assets/images/logo.png', width: x(240)),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _blob(double left, double top, double size, Color color) => Positioned(
        left: left,
        top: top,
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        ),
      );

  Widget _coin(double left, double top, double size, double turns, double opacity) => Positioned(
        left: left,
        top: top,
        child: Opacity(
          opacity: opacity,
          child: Transform.rotate(angle: turns, child: SvgPicture.string(coinSvg(), width: size, height: size)),
        ),
      );

  Widget _sparkle(double left, double top, double size, String color, double opacity) => Positioned(
        left: left,
        top: top,
        child: Opacity(opacity: opacity, child: SvgPicture.string(sparkleSvg(color), width: size, height: size)),
      );
}
