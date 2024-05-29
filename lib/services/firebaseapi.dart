import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_app_installations/firebase_app_installations.dart';

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    await Firebase.initializeApp(); // Initialize Firebase

    await _firebaseMessaging.requestPermission();
    final fCMToken = await _firebaseMessaging.getToken();
    print('Token: $fCMToken');

    // Get the Firebase App Installation ID
    try {
      final String installationID =
          await FirebaseInstallations.instance.getId();
      print('Installation ID: $installationID');
    } catch (e) {
      print('Error al obtener el Installation ID: $e');
    }
  }
}
