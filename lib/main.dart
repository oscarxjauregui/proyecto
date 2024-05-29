import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyecto/screens/login_screen.dart';
import 'package:proyecto/services/firebaseapi.dart';
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
  await FirebaseApi().initNotifications();

  // Load theme color from Firestore
  String userId = 'yourUserIdHere';
  try {
    Color? themeColor = await _loadThemeColorFromFirestore(userId);
    if (themeColor != null) {
      AppValueNotifier.setTheme(themeColor);
    }
  } catch (e) {
    print('Error loading theme color: $e');
    // Handle error loading theme color
  }

  runApp(const MyApp());
}

Future<Color?> _loadThemeColorFromFirestore(String userId) async {
  final userSnapshot =
      await FirebaseFirestore.instance.collection('users').doc(userId).get();
  if (userSnapshot.exists) {
    final userData = userSnapshot.data() as Map<String, dynamic>;
    return AppValueNotifier.getColorFromString(userData['color'] ?? 'blue');
  } else {
    throw Exception('User not found');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: AppValueNotifier.themeNotifier,
      builder: (context, ThemeData themeData, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: themeData,
          home: const LoginScreen(),
        );
      },
    );
  }
}
