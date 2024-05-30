import 'dart:io';
import 'package:advance_pdf_viewer_fork/advance_pdf_viewer_fork.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity/connectivity.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
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
import 'package:video_player/video_player.dart';

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
  String? userColor;
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
        userColor = userData['color']; // Obtén el color del usuario
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

  Future<void> _pickFile(String type) async {
    XFile? pickedFile;
    if (type == 'image') {
      pickedFile = await picker.pickImage(source: ImageSource.gallery);
    } else if (type == 'camera') {
      pickedFile = await picker.pickImage(source: ImageSource.camera);
    } else if (type == 'video') {
      pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    } else if (type == 'pdf') {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null) {
        pickedFile = XFile(result.files.single.path!);
      }
    }

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path); // Almacena el archivo seleccionado.
      } else {
        print('No se seleccionó ningún archivo.');
      }
    });
  }

  Future<void> _uploadAndSavePublication({String? description}) async {
    if (_image == null && (description == null || description.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Por favor, selecciona una imagen, video, PDF o ingresa una descripción antes de publicar.',
          ),
        ),
      );
      return;
    }

    // Muestra el diálogo de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text('Publicando...')
            ],
          ),
        );
      },
    );

    final storage = FirebaseStorage.instance;
    String? fileType;
    if (_image != null) {
      final extension = _image!.path.split('.').last.toLowerCase();
      if (['mp4', 'avi', 'mov', 'wmv', 'flv', 'mkv'].contains(extension)) {
        fileType = 'videos';
      } else if (extension == 'pdf') {
        fileType = 'pdfs';
      } else {
        fileType = 'images';
      }
    }

    final Reference storageReference = storage.ref().child(
        '$fileType/${DateTime.now()}.${fileType == 'videos' ? 'mp4' : fileType == 'pdfs' ? 'pdf' : 'png'}');

    // final Reference storageReference = storage.ref().child(
    //     '$fileType/${DateTime.now()}.${fileType == 'videos' ? 'mp4' : fileType == 'pdfs' ? 'pdf' : 'png'}');
    String? fileUrl;
    if (_image != null) {
      final UploadTask uploadTask = storageReference.putFile(_image!);
      await uploadTask.whenComplete(() async {
        fileUrl = await storageReference.getDownloadURL();
      });
    }

    final now = DateTime.now();
    final publicationData = {
      'idUser': widget.myIdUser,
      'descripcion': description ?? '',
      'fecha': now.toIso8601String(),
      'fileUrl': fileUrl,
      'fileType': fileType,
    };

    await PublicationFirebase().guardar(publicationData);

    // Oculta el diálogo de carga
    Navigator.pop(context);

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
            // color: Theme.of(context).primaryColor,
            color: userColor != null
                ? _convertColorStringToColor(userColor!)
                : Theme.of(context).primaryColor,
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
                  // ? CircleAvatar(
                  //     backgroundImage: NetworkImage(avatarUrl!),
                  //   )
                  ? CachedNetworkImage(
                      imageUrl: avatarUrl!,
                      placeholder: (context, url) => CircleAvatar(
                        child: Icon(Icons.person, size: 40),
                      ),
                      errorWidget: (context, url, error) => CircleAvatar(
                        child: Icon(
                          Icons.error,
                          size: 40,
                        ),
                      ),
                    )
                  : CircleAvatar(
                      child: Icon(
                        Icons.person,
                        size: 50,
                      ),
                    ),
              accountName: Text(userName ?? 'Cargando...'),
              accountEmail: Text(userEmail ?? 'Cargando...'),
              decoration: BoxDecoration(
                color: userColor != null
                    ? _convertColorStringToColor(userColor!)
                    : Theme.of(context).primaryColor,
              ),
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
      body: FutureBuilder(
        future: _checkInternetConnection(),
        builder: (context, AsyncSnapshot<bool> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            if (snapshot.data!) {
              // Hay conexión a internet
              return Column(
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
              );
            } else {
              // No hay conexión a internet
              return Center(
                child: Text(
                  'No estás conectado a internet',
                  style: TextStyle(fontSize: 20),
                ),
              );
            }
          }
        },
      ),
    );
  }

  Future<bool> _checkInternetConnection() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult != ConnectivityResult.none;
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
                    _pickFile('image');
                  },
                  icon: Icon(Icons.photo_library),
                ),
                IconButton(
                    onPressed: () {
                      _pickFile('camera');
                    },
                    icon: Icon(Icons.camera_alt)),
                IconButton(
                    onPressed: () {
                      _pickFile('video');
                    },
                    icon: Icon(Icons.video_library)),
                IconButton(
                    onPressed: () {
                      _pickFile('pdf');
                    },
                    icon: Icon(Icons.picture_as_pdf)),
                // IconButton(
                //   onPressed: () {
                //     _showBottomSheet(context);
                //   },
                //   icon: Icon(Icons.add),
                // ),
                ElevatedButton(
                  onPressed: () {
                    _uploadAndSavePublication(
                      description: _descriptionController.text.trim(),
                    );
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
          final fileType = publicacion['fileType'];
          final fileUrl = publicacion['fileUrl'];

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
                  if (fileUrl != null) ...[
                    if (fileType == 'images')
                      Image.network(fileUrl)
                    else if (fileType == 'videos')
                      VideoPlayerWidget(
                          fileUrl:
                              fileUrl) // Reemplaza Text(fileUrl) por VideoPlayerWidget
                    else if (fileType == 'pdfs')
                      InkWell(
                        onTap: () {
                          _showPdf(context, fileUrl);
                        },
                        child: const Text(
                          'Ver archivo',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue, // Color del enlace
                            fontSize: 16,
                          ),
                        ),
                      )
                  ]
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Color _convertColorStringToColor(String colorString) {
    switch (colorString.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'yellow':
        return Colors.yellow;
      // Agrega más colores según sea necesario
      default:
        return Colors.black; // Color por defecto
    }
  }

  Future<void> _showPdf(BuildContext context, String pdfUrl) async {
    // Agrega el parámetro de contexto aquí
    try {
      PDFDocument document = await PDFDocument.fromURL(pdfUrl);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PDFViewer(document: document),
        ),
      );
    } catch (e) {
      print("Error al mostrar el PDF: $e");
    }
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String fileUrl;

  const VideoPlayerWidget({required this.fileUrl, Key? key}) : super(key: key);

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.fileUrl))
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? Column(
            children: [
              AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPlaying ? _controller.pause() : _controller.play();
                        _isPlaying = !_isPlaying;
                      });
                    },
                  ),
                ],
              ),
            ],
          )
        : Center(child: CircularProgressIndicator());
  }
}
