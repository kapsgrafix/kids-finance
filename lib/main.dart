import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/splash_screen.dart';
import 'state/app_state.dart';
import 'state/scope.dart';
import 'theme/tokens.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));
  runApp(TinyTreasuryApp(state: AppState()));
}

class TinyTreasuryApp extends StatelessWidget {
  final AppState state;
  const TinyTreasuryApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: MaterialApp(
        title: 'Tiny Treasury',
        debugShowCheckedModeBanner: false,
        theme: TT.theme(),
        home: const SplashScreen(),
      ),
    );
  }
}
