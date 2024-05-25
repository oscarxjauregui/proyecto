import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TemaProvider extends GetxController {
  void temaClaro() {
    Get.changeTheme(ThemeData.light());
  }

  void temaOscuro() {
    Get.changeTheme(ThemeData.dark());
  }

  void temaLynx() {
    Get.changeTheme(ThemeData(
        primaryColor: Colors.greenAccent,
        appBarTheme: const AppBarTheme(color: Colors.green)));
  }
}
