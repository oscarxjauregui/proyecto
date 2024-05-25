import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:proyecto/screens/calificaciones_screen.dart';
import 'package:proyecto/screens/class_screen.dart';
import 'package:proyecto/screens/groups_screen.dart';
import 'package:proyecto/screens/message_list_screen.dart';
import 'package:proyecto/screens/myuser_screen.dart';
import 'package:proyecto/screens/search_screen.dart';
import 'package:proyecto/services/avatar_firebase.dart';
import 'package:proyecto/services/publication_firebase.dart';
import 'package:proyecto/services/user_firebase.dart';

class HomeClienteScreen extends StatefulWidget {
  final String myIdUser;

  const HomeClienteScreen({required this.myIdUser, Key? key}) : super(key: key);

  @override
  State<HomeClienteScreen> createState() => _HomeClienteScreenState();
}

class _HomeClienteScreenState extends State<HomeClienteScreen> {
  String? userName;
  String? userEmail;
  String? avatarUrl;
  String? userRole;
  File? _image;
  final picker = ImagePicker();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final userSnapshot = await UsersFirebase().consultarPorId(widget.myIdUser);
    if (userSnapshot.exists) {
      final userData = userSnapshot.data() as Map<String, dynamic>;
      setState(() {
        userName = userData['nombre'];
        userEmail = userData['email'];
        userRole = userData['rol'];
      });
      final avatarSnapshot =
          await AvatarFirebase().consultarAvatar(widget.myIdUser);
      if (avatarSnapshot.exists) {
        final avatarData = avatarSnapshot.data() as Map<String, dynamic>;
        setState(() {
          avatarUrl = avatarData['imageUrl'];
        });
      }
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
            'Por favor, selecciona una imagen o ingresa una descripción antes de publicar.',
          ),
        ),
      );
      return;
    }
    final storage = FirebaseStorage.instance;
    final Reference storageReference =
        storage.ref().child('publicaciones/${DateTime.now()}.png');
    String? imageUrl;
    if (_image != null) {
      final UploadTask uploadTask = storageReference.putFile(_image!);
      await uploadTask.whenComplete(() async {
        imageUrl = await storageReference.getDownloadURL();
      });
    }
    final now = DateTime.now();
    final publicationData = {
      'idUser': widget.myIdUser,
      'descripcion': description ?? '',
      'fecha': now.toIso8601String(),
      'imageUrl': imageUrl,
    };

    await PublicationFirebase().guardar(publicationData);
    _refreshPage();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Publicación realizada con éxito')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SocialLynx',
          style: GoogleFonts.lobster(
            // Usando la fuente 'Lobster' para el título
            color: Colors.black,
            fontSize: 35,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.search,
              color: Color.fromARGB(255, 8, 50, 85),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchScreen(
                    myIdUser: widget.myIdUser,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            UserAccountsDrawerHeader(
              currentAccountPicture: avatarUrl != null
                  ? CircleAvatar(
                      backgroundImage: NetworkImage(avatarUrl!),
                    )
                  : CircleAvatar(
                      child: Icon(
                        Icons.person,
                        size: 50,
                      ),
                    ),
              accountName: Text(userName ?? 'Cargando...'),
              accountEmail: Text(userEmail ?? 'Cargando...'),
            ),
            ListTile(
              leading: const Icon(Icons.person_outlined,
                  color: Color.fromARGB(255, 160, 148, 57)),
              title: Text(
                'Mi perfil',
                style: GoogleFonts.comicNeue(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Ver mi perfil',
                style: GoogleFonts.comicNeue(
                    color: Color.fromARGB(255, 54, 53, 53)),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MyUserScreen(
                      userId: widget.myIdUser,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.message_outlined, color: Colors.blue),
              title: Text(
                'Mensajes',
                style: GoogleFonts.comicNeue(
                  // Usando Google Fonts
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Ver los mensajes',
                style: GoogleFonts.comicNeue(
                    color: Color.fromARGB(255, 54, 53, 53)),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MessageListScreen(
                      myUserId: widget.myIdUser,
                    ),
                  ),
                );
              },
            ),
            if (userRole == 'Estudiante')
              ListTile(
                leading: const Icon(
                  Icons.date_range_outlined,
                  color: Colors.green,
                ),
                title: Text(
                  'Calificaciones',
                  style: GoogleFonts.comicNeue(
                    // Usando Google Fonts
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text('Ver mis calificaciones'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CalificacionesScreen(
                        myUserId: widget.myIdUser,
                      ),
                    ),
                  );
                },
              ),
            ListTile(
              leading: const Icon(
                Icons.groups_2_outlined,
                color: Colors.purple,
              ),
              title: Text(
                'Grupos',
                style: GoogleFonts.comicNeue(
                  // Usando Google Fonts
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Ver mis grupos',
                style: GoogleFonts.comicNeue(
                    color: const Color.fromARGB(255, 31, 31, 31)),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupsScreen(
                      userId: widget.myIdUser,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.class_outlined,
                color: Color.fromARGB(255, 159, 112, 40),
              ),
              title: Text(
                'Clases',
                style: GoogleFonts.comicNeue(
                  // Usando Google Fonts
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Ver mis clases',
                style: GoogleFonts.comicNeue(
                    color: Color.fromARGB(255, 54, 53, 53)),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ClassScreen(
                      userId: widget.myIdUser,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.exit_to_app,
                color: Colors.red,
              ),
              title: Text(
                'Salir',
                style: GoogleFonts.comicNeue(
                  // Usando Google Fonts
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Cerrar sesion',
                style: GoogleFonts.comicNeue(
                    color: Color.fromARGB(255, 54, 53, 53)),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            )
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildCreatePostSection(),
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
        builder: (context) => HomeClienteScreen(
          myIdUser: widget.myIdUser,
        ),
      ),
    );
  }

  Widget _buildPostsList() {
    return FutureBuilder(
      future: PublicationFirebase().obtenerPublicaciones(),
      builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error al cargar las publicaciones'));
        } else {
          List<Map<String, dynamic>> publicaciones = snapshot.data ?? [];
          publicaciones.sort((a, b) {
            // Ordena por fecha descendente
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
              return _buildPost(publicacion);
            },
          );
        }
      },
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
          // Verificar si snapshot.data es nulo
          if (snapshot.data == null || snapshot.data!.isEmpty) {
            return Text('Datos nulos');
          }

          final userData =
              snapshot.data![0] as DocumentSnapshot; // Corrección aquí
          final avatarData =
              snapshot.data![1] as DocumentSnapshot; // Corrección aquí

          final nombreUsuario = userData['nombre'] ?? 'Usuario desconocido';
          final rolUsuario = userData['rol'] ?? 'Rol desconocido';
          final avatarUrl = avatarData['imageUrl'];

          // Formatea la fecha
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
