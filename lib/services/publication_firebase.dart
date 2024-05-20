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

  // Método para guardar publicaciones en grupo-publicaciones
  Future<void> guardarEnGrupo(Map<String, dynamic> data) async {
    await FirebaseFirestore.instance
        .collection('grupo-publicaciones')
        .add(data);
  }

  Future<void> guardarEnClase(Map<String, dynamic> data) async {
    await FirebaseFirestore.instance
        .collection('clase-publicaciones')
        .add(data);
  }

  // Método para obtener publicaciones de un grupo específico
  Future<List<Map<String, dynamic>>> obtenerPublicacionesDeGrupo(
      String classId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('grupo-publicaciones')
        .where('classId', isEqualTo: classId)
        .get();

    return querySnapshot.docs
        .map((doc) => {
              ...doc.data(),
              'id': doc.id, // Incluye el ID del documento
            } as Map<String, dynamic>)
        .toList();
  }

  Future<List<Map<String, dynamic>>> obtenerPublicacionesDeClase(
      String classId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('clase-publicaciones')
        .where('classId', isEqualTo: classId)
        .get();

    return querySnapshot.docs
        .map((doc) => {
              ...doc.data(),
              'id': doc.id, // Incluye el ID del documento
            } as Map<String, dynamic>)
        .toList();
  }
}
