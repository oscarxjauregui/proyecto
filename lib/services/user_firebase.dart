import 'package:cloud_firestore/cloud_firestore.dart';

class UsersFirebase {
  final util = FirebaseFirestore.instance;
  CollectionReference? _usersCollection;
  UsersFirebase() {
    _usersCollection = util.collection('users');
  }

  Stream<QuerySnapshot> consultar() {
    return _usersCollection!.snapshots();
  }

  Future<void> insertar(Map<String, dynamic> data) async {
    return _usersCollection!.doc().set(data);
  }

  Future<void> actualizar(Map<String, dynamic> data, String id) async {
    return _usersCollection!.doc(id).update(data);
  }

  Future<void> eliminar(String id) async {
    return _usersCollection!.doc(id).delete();
  }

  Future<QuerySnapshot> consultarPorEmail(String email) async {
    // Realiza la consulta filtrando los documentos por el campo 'email'
    final querySnapshot =
        await _usersCollection!.where('email', isEqualTo: email).get();
    return querySnapshot;
  }
}
