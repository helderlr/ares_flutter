import 'package:flutter/material.dart';

class AppContext {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static int _protectedUiDepth = 0;

  static BuildContext? get currentContext => navigatorKey.currentContext;

  static bool get isProtectedUi => _protectedUiDepth > 0;

  static void beginProtectedUi() {
    _protectedUiDepth++;
  }

  static void endProtectedUi() {
    if (_protectedUiDepth > 0) {
      _protectedUiDepth--;
    }
  }
}





