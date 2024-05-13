import 'package:flutter/material.dart';

class AppValueNotifier {
  static ValueNotifier banTheme = ValueNotifier(false);
  static ValueNotifier<bool> themeNotifier =
      ValueNotifier(false); // Para controlar el tema (oscuro/claro)

  // static ValueNotifier banProducts = ValueNotifier(false);
}
