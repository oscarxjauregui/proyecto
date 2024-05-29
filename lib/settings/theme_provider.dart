import 'package:flutter/material.dart';
import 'package:proyecto/settings/app_value_notifier.dart';

class ThemeProvider extends StatelessWidget {
  final Widget child;

  const ThemeProvider({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: AppValueNotifier.themeNotifier,
      builder: (context, ThemeData theme, child) {
        return MaterialApp(
          theme: theme,
          debugShowCheckedModeBanner: false,
          home: child,
        );
      },
      child: child,
    );
  }
}
