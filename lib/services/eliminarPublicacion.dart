import 'package:cloud_firestore/cloud_firestore.dart';

void _deletePost(String postId) async {
  try {
    // Obtén una referencia al documento de la publicación que deseas eliminar
    DocumentReference postRef =
        FirebaseFirestore.instance.collection('publicaciones').doc(postId);

    // Elimina el documento
    await postRef.delete();

    // Imprime un mensaje de éxito
    print('Publicación eliminada correctamente');
  } catch (e) {
    // Maneja cualquier error que pueda ocurrir durante la eliminación
    print('Error al eliminar la publicación: $e');
  }
}
