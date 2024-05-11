import 'package:cloud_firestore/cloud_firestore.dart';

class AvatarFirebase {
  final util = FirebaseFirestore.instance;
  CollectionReference? _avatarsCollection;

  AvatarFirebase() {
    _avatarsCollection = util.collection('avatars');
  }

  Future<DocumentSnapshot> consultarAvatar(String userId) async {
    // Realiza la consulta buscando el documento con el ID de usuario especificado
    return await _avatarsCollection!.doc(userId).get();
  }

  // Otros métodos de la clase UsersFirebase...
}
