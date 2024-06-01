import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'package:proyecto/screens/onboarding.dart';
import 'package:proyecto/services/firebaseapi.dart';

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
  await FirebaseApi().initNotifications();

  AwesomeNotifications().initialize(
    'resource://drawable/res_app_icon', // Reemplaza esto con el icono correcto
    [
      NotificationChannel(
        channelKey: 'key1',
        channelName: 'Basic notifications',
        channelDescription: 'Notification channel for basic tests',
        defaultColor: const Color(0xFF9D50DD),
        ledColor: Colors.white,
      ),
    ],
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeColorProvider(),
      child: const MyApp(),
    ),
  );
}

class ThemeColorProvider with ChangeNotifier {
  Color _themeColor = Colors.blue;

  Color get themeColor => _themeColor;

  Future<void> loadThemeColorFromFirestore(String userId) async {
    final userSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userSnapshot.exists) {
      final userData = userSnapshot.data() as Map<String, dynamic>;
      _themeColor =
          getColorFromString(userData['color'] ?? 'blue') ?? Colors.blue;
      notifyListeners();
    } else {
      throw Exception('User not found');
    }
  }

  Color? getColorFromString(String colorString) {
    return null;

    // Implementar lógica para convertir una cadena en Color
    // Retorna null si no se puede convertir
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeColorProvider>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primaryColor: themeProvider.themeColor),
      home: Builder(
        builder: (BuildContext context) {
          final screenHeight = MediaQuery.of(context).size.height;
          return Onboarding(screenHeight: screenHeight);
        },
      ),
    );
  }
}
