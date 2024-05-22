import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:proyecto/models/custom_drawer.dart';
import 'package:proyecto/screens/class_detail_screen.dart';
import 'package:proyecto/screens/class_post_alumno_screen.dart';
import 'package:proyecto/screens/class_post_maestro_screen.dart';
import 'package:proyecto/screens/group_detail_screen.dart';
import 'package:proyecto/screens/groups_screen.dart';
import 'package:proyecto/screens/login_screen.dart';
import 'package:proyecto/screens/message_list_screen.dart';
import 'package:proyecto/screens/myuser_screen.dart';
import 'package:proyecto/screens/search_screen.dart';
import 'package:proyecto/services/avatar_firebase.dart';
import 'package:proyecto/services/publication_firebase.dart';
import 'package:proyecto/services/user_firebase.dart';

import 'package:flutter/material.dart';

class ClassMainScreen extends StatefulWidget {
  final String classId;
  final String myUserId;

  const ClassMainScreen(
      {required this.myUserId, required this.classId, Key? key})
      : super(key: key);

  @override
  State<ClassMainScreen> createState() => _ClassMainScreenState();
}

class _ClassMainScreenState extends State<ClassMainScreen> {
  String? userName;
  String? userEmail;
  String? avatarUrl;
  String? className;
  File? _image;
  final picker = ImagePicker();
  final _descriptionController = TextEditingController();
  String? idAdmin;

  @override
  void initState() {
    super.initState();
    loadUserData();
    loadClassName();
  }

  Future<void> loadUserData() async {
    final userSnapshot = await UsersFirebase().consultarPorId(widget.myUserId);
    if (userSnapshot.exists) {
      final userData = userSnapshot.data() as Map<String, dynamic>;
      setState(() {
        userName = userData['nombre'];
        userEmail = userData['email'];
      });
      final avatarSnapshot =
          await AvatarFirebase().consultarAvatar(widget.myUserId);
      if (avatarSnapshot.exists) {
        final avatarData = avatarSnapshot.data() as Map<String, dynamic>;
        setState(() {
          avatarUrl = avatarData['imageUrl'];
        });
      }
    }
  }

  Future<void> loadClassName() async {
    final classSnapshot = await FirebaseFirestore.instance
        .collection('class')
        .doc(widget.classId)
        .get();
    if (classSnapshot.exists) {
      final classData = classSnapshot.data() as Map<String, dynamic>;
      setState(() {
        className = classData['nombre'];
        idAdmin = classData['idAdmin'];
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No se seleccionó ninguna imagen.');
      }
    });
  }

  Future<void> _uploadAndSavePublication({String? description}) async {
    if (_image == null && (description == null || description.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Por favor, selecciona una imagen o ingresa una descripción antes de publicar.'),
        ),
      );
      return;
    }
    final storage = FirebaseStorage.instance;
    final Reference storageReference =
        storage.ref().child('clase-publicaciones/${DateTime.now()}.png');
    String? imageUrl;
    if (_image != null) {
      final UploadTask uploadTask = storageReference.putFile(_image!);
      await uploadTask.whenComplete(() async {
        imageUrl = await storageReference.getDownloadURL();
      });
    }
    final now = DateTime.now();
    final publicationData = {
      'idUser': widget.myUserId,
      'classId': widget.classId,
      'descripcion': description ?? '',
      'fecha': now.toIso8601String(),
      'imageUrl': imageUrl,
    };

    await PublicationFirebase().guardarEnClase(publicationData);
    _refreshPage();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Publicación realizada con éxito')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(className ?? 'class'),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ClassDetailScreen(
                    idClass: widget.classId,
                    myUserId: widget.myUserId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (idAdmin == widget.myUserId) _buildCreatePostSection(),
                  SizedBox(height: 20),
                  _buildPostsList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatePostSection() {
    return Card(
      margin: EdgeInsets.all(10),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: avatarUrl != null && avatarUrl is String
                      ? NetworkImage(avatarUrl as String)
                      : null,
                  child: avatarUrl == null || !(avatarUrl is String)
                      ? Icon(Icons.person,
                          size: 40) // Icono de persona si no hay avatar
                      : null, // No hay child si hay avatar
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: TextField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        hintText: 'Agregar descripcion',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () {
                    _pickImage(ImageSource.gallery);
                  },
                  icon: Icon(Icons.photo_library),
                ),
                IconButton(
                  onPressed: () {
                    _pickImage(ImageSource.camera);
                  },
                  icon: Icon(Icons.camera_alt),
                ),
                ElevatedButton(
                  onPressed: () {
                    _uploadAndSavePublication(
                      description: _descriptionController.text.trim(),
                    );
                    //_refreshPage();
                  },
                  child: Text('Publicar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _refreshPage() async {
    await Future.delayed(Duration(seconds: 1));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ClassMainScreen(
          myUserId: widget.myUserId,
          classId: widget.classId,
        ),
      ),
    );
  }

  Widget _buildPostsList() {
    return FutureBuilder(
      future: PublicationFirebase().obtenerPublicacionesDeClase(widget.classId),
      builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error al cargar las publicaciones'));
        } else {
          List<Map<String, dynamic>> publicaciones = snapshot.data ?? [];
          publicaciones.sort((a, b) {
            DateTime dateA = DateTime.parse(a['fecha']);
            DateTime dateB = DateTime.parse(b['fecha']);
            return dateB.compareTo(dateA);
          });
          return ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: publicaciones.length,
            itemBuilder: (context, index) {
              final publicacion = publicaciones[index];
              return GestureDetector(
                onTap: () {
                  _navigateToPostScreen(publicacion);
                },
                child: _buildPost(publicacion),
              );
            },
          );
        }
      },
    );
  }

  Future<void> _navigateToPostScreen(Map<String, dynamic> publicacion) async {
    final classSnapshot = await FirebaseFirestore.instance
        .collection('class')
        .doc(widget.classId)
        .get();
    if (classSnapshot.exists) {
      final classData = classSnapshot.data() as Map<String, dynamic>;
      final isAdmin = classData['idAdmin'] == widget.myUserId;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => isAdmin
              ? ClassPostMaestroScreen(
                  myUserId: widget.myUserId,
                  classId: widget.classId,
                  publicacion: publicacion,
                )
              : ClassPostAlumnoScreen(
                  myUserId: widget.myUserId,
                  classId: widget.classId,
                  publicacion: publicacion,
                ),
        ),
      );
    }
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
