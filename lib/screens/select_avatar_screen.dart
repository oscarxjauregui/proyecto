import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyecto/screens/home_cliente_screen.dart';

class ImageController extends ChangeNotifier {
  File? _imageFile;

  File? get imageFile => _imageFile;

  void setImageFile(File? imageFile) {
    _imageFile = imageFile;
    notifyListeners();
  }
}

class SelectAvatarScreen extends StatefulWidget {
  final String userId;

  const SelectAvatarScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<SelectAvatarScreen> createState() => _SelectAvatarScreenState();
}

class _SelectAvatarScreenState extends State<SelectAvatarScreen> {
  late ImageController imageController = ImageController();

  @override
  void initState() {
    super.initState();
    imageController = ImageController();
    // Initialize the variable here
  }

  Future<void> _selectImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          imageController.setImageFile(File(pickedFile.path));
        });
      }
    } catch (e) {
      print("Error al seleccionar la imagen: $e");
    }
  }

  Future<void> _saveImageToStorage() async {
    final imageFile = imageController.imageFile;
    final userId = widget.userId;

    if (imageFile != null && userId != null) {
      try {
        // Verificar si ya existe un avatar para este usuario
        final firebase_storage.Reference oldAvatarRef = firebase_storage
            .FirebaseStorage.instance
            .ref()
            .child('avatars/$userId.png');
        final oldAvatarExists = await oldAvatarRef
            .getMetadata()
            .then((value) => true)
            .catchError((_) => false);

        // Eliminar el avatar anterior si existe
        if (oldAvatarExists) {
          await oldAvatarRef.delete();
        }

        // Subir el nuevo avatar
        final firebase_storage.Reference ref = firebase_storage
            .FirebaseStorage.instance
            .ref()
            .child('avatars/$userId.png');

        final firebase_storage.UploadTask uploadTask = ref.putFile(imageFile);
        await uploadTask.whenComplete(() async {
          final imageUrl = await ref.getDownloadURL();
          // Guardar la URL de la imagen en Firestore
          await FirebaseFirestore.instance
              .collection('avatars')
              .doc(userId)
              .set({
            'userId': userId,
            'imageUrl': imageUrl,
          });
          print('Imagen subida a storage y URL guardada en Firestore');
        });
      } catch (e) {
        print(e);
      }
    }
  }

  // Ejemplo de consulta para obtener la información del usuario a partir de su ID
  Future<String?> _getUserEmail(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        return userDoc['email']; // Retorna el email del usuario
      }
    } catch (e) {
      print('Error al obtener el email del usuario: $e');
    }
    return null; // Si ocurre algún error, retorna null
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Seleccionar foto'),
      ),
      body: ChangeNotifierProvider<ImageController>.value(
        value: imageController,
        child: Container(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 80, // Ajuste vertical
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  child: Consumer<ImageController>(
                    builder: (context, imageController, _) {
                      return CircleAvatar(
                        radius: 100,
                        backgroundColor: Colors.grey[200],
                        child: IconButton(
                          icon: Icon(Icons.camera_alt),
                          onPressed: () {
                            final snackBar = SnackBar(
                              content: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      _selectImage(ImageSource.camera);
                                    },
                                    child: Text('Desde la camara'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      _selectImage(ImageSource.gallery);
                                    },
                                    child: Text('Desde la galeria'),
                                  ),
                                ],
                              ),
                            );
                            ScaffoldMessenger.of(context)
                                .showSnackBar(snackBar);
                          },
                        ),
                        backgroundImage: imageController.imageFile != null
                            ? FileImage(imageController.imageFile!)
                            : null,
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: 280, // Ajuste vertical
                child: Container(
                  height: 100,
                  width: MediaQuery.of(context).size.width * .9,
                  child: Center(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () async {
                            final userId = widget.userId;
                            if (userId != null) {
                              final userEmail = await _getUserEmail(userId);
                              if (userEmail != null) {
                                _saveImageToStorage();
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HomeClienteScreen(
                                        myIdUser: widget.userId),
                                  ),
                                );
                              } else {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Error'),
                                    content: Text(
                                        'No se pudo obtener el email del usuario.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            } else {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Error'),
                                  content: Text('Ingrese el ID del usuario'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          child: Text('Guardar'),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
