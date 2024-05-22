import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:proyecto/services/avatar_firebase.dart';
import 'package:proyecto/services/user_firebase.dart';

class ClassPostScreen extends StatefulWidget {
  final String classId;
  final String myUserId;
  final Map<String, dynamic> publicacion;

  const ClassPostScreen({
    required this.myUserId,
    required this.classId,
    required this.publicacion,
    Key? key,
  }) : super(key: key);

  @override
  State<ClassPostScreen> createState() => _ClassPostScreenState();
}

class _ClassPostScreenState extends State<ClassPostScreen> {
  File? _imageFile;
  final picker = ImagePicker();

  Future<void> _selectImage(ImageSource source) async {
    try {
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      print("Error al seleccionar la imagen: $e");
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    try {
      final classId = widget.classId;
      final userId = widget.myUserId;
      final postId = widget.publicacion['id'];

      final ref = firebase_storage.FirebaseStorage.instance.ref().child(
          'tareas/$classId/${userId}_${DateTime.now().millisecondsSinceEpoch}.png');

      final uploadTask = ref.putFile(_imageFile!);
      await uploadTask.whenComplete(() async {
        final imageUrl = await ref.getDownloadURL();

        await FirebaseFirestore.instance.collection('class-tarea').add({
          'userId': userId,
          'classId': classId,
          'postId': postId,
          'imageUrl': imageUrl,
          'timestamp': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imagen subida y URL guardada en Firestore')),
        );

        // Limpiar la imagen seleccionada después de subirla
        setState(() {
          _imageFile = null;
        });
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Publicación'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: _buildPost(widget.publicacion),
            ),
          ),
          if (_imageFile != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.file(_imageFile!),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _selectImage(ImageSource.gallery);
                  },
                  child: Text('Subir Imagen (Galería)'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _selectImage(ImageSource.camera);
                  },
                  child: Text('Subir Imagen (Cámara)'),
                ),
                ElevatedButton(
                  onPressed: _uploadImage,
                  child: Text('Guardar Imagen'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPost(Map<String, dynamic> publicacion) {
    return FutureBuilder(
      future: Future.wait([
        UsersFirebase().consultarPorId(publicacion['idUser']),
        AvatarFirebase().consultarAvatar(publicacion['idUser']),
      ]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error al cargar el usuario o el avatar');
        } else {
          if (snapshot.data == null || snapshot.data!.isEmpty) {
            return Text('Datos nulos');
          }

          final userData = snapshot.data![0] as DocumentSnapshot;
          final avatarData = snapshot.data![1] as DocumentSnapshot;

          final nombreUsuario = userData['nombre'] ?? 'Usuario desconocido';
          final rolUsuario = userData['rol'] ?? 'Rol desconocido';
          final avatarUrl = avatarData['imageUrl'];

          final fecha = DateTime.parse(publicacion['fecha']);
          final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(fecha);

          return Card(
            margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage:
                            avatarUrl != null ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl == null
                            ? Icon(
                                Icons.person,
                                size: 40,
                              )
                            : null,
                      ),
                      SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                nombreUsuario,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(width: 5),
                              Text(
                                rolUsuario,
                                style: TextStyle(
                                    fontStyle: FontStyle.normal, fontSize: 12),
                              ),
                            ],
                          ),
                          Text(
                            formattedDate,
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(publicacion['descripcion']),
                  SizedBox(height: 10),
                  publicacion['imageUrl'] != null
                      ? Image.network(publicacion['imageUrl'])
                      : SizedBox.shrink(),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
