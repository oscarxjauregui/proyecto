import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:proyecto/screens/login_screen.dart';
import 'package:proyecto/settings/app_value_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDphfMeG_caDwuJJFlOL3HOY7Tq0ktc-Rw",
      appId: "com.example.proyecto",
      messagingSenderId: "57362494447",
      projectId: "proyecto-pmsn-2024",
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: AppValueNotifier.banTheme,
      builder: ((context, value, child) {
        return const MaterialApp(
          debugShowCheckedModeBanner: false,
          // theme: value
          //     ? ThemeApp.darkTheme(context)
          //     : ThemeApp.lightTheme(context),
          home: LoginScreen(),
        );
      }),
    );
  }
}
