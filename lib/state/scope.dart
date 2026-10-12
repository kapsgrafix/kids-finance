import 'package:flutter/widgets.dart';

import 'app_state.dart';

/// Makes [AppState] available to the widget tree and rebuilds dependants on change.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  /// Watch: rebuilds the caller when state changes.
  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Read once, without subscribing (use in callbacks).
  static AppState read(BuildContext context) =>
      (context.getElementForInheritedWidgetOfExactType<AppScope>()!.widget as AppScope).notifier!;
}
