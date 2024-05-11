import 'package:cloud_firestore/cloud_firestore.dart';

class PublicationFirebase {
  final CollectionReference _publicationCollection =
      FirebaseFirestore.instance.collection('publicaciones');

  Future<void> guardar(Map<String, dynamic> data) async {
    await _publicationCollection.add(data);
  }

  Future<List<Map<String, dynamic>>> obtenerPublicaciones() async {
    final querySnapshot = await _publicationCollection.get();
    final List<Map<String, dynamic>> publicaciones = [];
    querySnapshot.docs.forEach((doc) {
      final data = doc.data() as Map<String, dynamic>;
      publicaciones.add(data);
    });
    return publicaciones;
  }
}
