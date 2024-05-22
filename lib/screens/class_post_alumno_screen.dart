import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:proyecto/services/avatar_firebase.dart';
import 'package:proyecto/services/user_firebase.dart';
import 'package:advance_pdf_viewer_fork/advance_pdf_viewer_fork.dart'; // Importa advance_pdf_viewer_fork

class ClassPostAlumnoScreen extends StatefulWidget {
  final String classId;
  final String myUserId;
  final Map<String, dynamic> publicacion;
  const ClassPostAlumnoScreen({
    required this.myUserId,
    required this.classId,
    required this.publicacion,
    Key? key,
  }) : super(key: key);

  @override
  State<ClassPostAlumnoScreen> createState() => _ClassPostAlumnoScreenState();
}

class _ClassPostAlumnoScreenState extends State<ClassPostAlumnoScreen> {
  File? _imageFile;
  File? _pdfFile; // Nuevo: Para almacenar el archivo PDF seleccionado
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

  // Nuevo: Función para seleccionar un archivo PDF
  Future<void> _selectPdf() async {
    try {
      print('Seleccionando archivo PDF...');
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        setState(() {
          _pdfFile = File(result.files.single.path!);
          print('PDF seleccionado: ${_pdfFile!.path}');
        });
      } else {
        print('No se seleccionó ningún archivo PDF.');
      }
    } catch (e) {
      print("Error al seleccionar el archivo PDF: $e");
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    try {
      final classId = widget.classId;
      final userId = widget.myUserId;
      final postId = widget.publicacion['id'];

      final ref = FirebaseStorage.instance.ref().child(
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
          'pdfUrl': '',
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

  // Nuevo: Función para subir un archivo PDF
  Future<void> _uploadPdf() async {
    if (_pdfFile == null) return;

    try {
      final classId = widget.classId;
      final userId = widget.myUserId; // Agregar el ID de usuario
      final postId = widget.publicacion['id'];

      final ref = FirebaseStorage.instance.ref().child(
          'tareas/$classId/${userId}_${DateTime.now().millisecondsSinceEpoch}.pdf');

      final uploadTask = ref.putFile(_pdfFile!);
      await uploadTask.whenComplete(() async {
        final pdfUrl = await ref.getDownloadURL();

        await FirebaseFirestore.instance.collection('class-tarea').add({
          'userId': userId, // Agregar el ID de usuario
          'classId': classId,
          'postId': postId,
          'pdfUrl': pdfUrl,
          'timestamp': Timestamp.now(),
          'imageUrl': '',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF subido y URL guardada en Firestore')),
        );

        // Limpiar el archivo PDF seleccionado después de subirlo
        setState(() {
          _pdfFile = null;
        });
      });
    } catch (e) {
      print(e);
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow bottom sheet to be larger
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              height:
                  MediaQuery.of(context).size.height * 0.5, // Increase height
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.photo_library),
                    title: Text('Desde la galería'),
                    onTap: () async {
                      await _selectImage(ImageSource.gallery);
                      setState(() {});
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.camera_alt),
                    title: Text('Desde la cámara'),
                    onTap: () async {
                      await _selectImage(ImageSource.camera);
                      setState(() {});
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.picture_as_pdf),
                    title: Text('Subir PDF'),
                    onTap: () async {
                      await _selectPdf();
                      setState(() {});
                    },
                  ),
                  if (_imageFile != null)
                    Container(
                      height: 100, // Smaller height for the image
                      padding: const EdgeInsets.all(8.0),
                      child: Image.file(_imageFile!),
                    ),
                  if (_pdfFile != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(_pdfFile!.path),
                    ),
                  if (_imageFile != null || _pdfFile != null)
                    ElevatedButton(
                      onPressed: () {
                        if (_imageFile != null) {
                          _uploadImage();
                        } else if (_pdfFile != null) {
                          _uploadPdf();
                        }
                        Navigator.pop(context); // Cerrar el BottomSheet
                      },
                      child: Text('Guardar Archivo'),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
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
              child: Column(
                children: [
                  _buildPost(widget.publicacion),
                  _buildTaskList(),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _showImagePickerOptions,
              child: Text('Subir Archivo'),
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

  Widget _buildTaskList() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('class-tarea')
          .where('classId', isEqualTo: widget.classId)
          .where('userId', isEqualTo: widget.myUserId) // Filtrar por myUserId
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error al cargar las tareas');
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Text('No hay tareas enviadas');
        } else {
          final tasks = snapshot.data!.docs;

          return ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return FutureBuilder<List<DocumentSnapshot>>(
                future: Future.wait([
                  UsersFirebase().consultarPorId(task['userId']),
                  AvatarFirebase().consultarAvatar(task['userId']),
                ]),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ListTile(
                      title: Text('Cargando...'),
                    );
                  } else if (snapshot.hasError) {
                    return ListTile(
                      title: Text('Error al cargar el usuario o el avatar'),
                    );
                  } else if (snapshot.hasData) {
                    final userData = snapshot.data![0];
                    final avatarData = snapshot.data![1];

                    final nombreUsuario =
                        userData['nombre'] ?? 'Usuario desconocido';
                    final avatarUrl = avatarData['imageUrl'];

                    final fecha = task['timestamp'].toDate();
                    final formattedDate =
                        DateFormat('dd MMM yyyy, HH:mm').format(fecha);

                    final imageUrl = task['imageUrl'];
                    final pdfUrl = task['pdfUrl'];

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            avatarUrl != null ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl == null ? Icon(Icons.person) : null,
                      ),
                      title: Text(nombreUsuario),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(formattedDate),
                          // Si hay una URL de PDF, muestra un enlace
                          if (pdfUrl != null && pdfUrl.isNotEmpty)
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PDFViewerScreen(
                                      pdfUrl: pdfUrl,
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                'Ver PDF',
                                style: TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),

                          // Si hay una URL de imagen, muestra la imagen
                          if (imageUrl != null && imageUrl.isNotEmpty)
                            Image.network(imageUrl),
                        ],
                      ),
                    );
                  } else {
                    return ListTile(
                      title: Text('Datos no disponibles'),
                    );
                  }
                },
              );
            },
          );
        }
      },
    );
  }
}

class PDFViewerScreen extends StatefulWidget {
  final String pdfUrl;

  const PDFViewerScreen({Key? key, required this.pdfUrl}) : super(key: key);

  @override
  _PDFViewerScreenState createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  PDFDocument? _pdfDocument;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      final pdfDocument = await PDFDocument.fromURL(widget.pdfUrl);
      setState(() {
        _pdfDocument = pdfDocument;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar el PDF: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF Viewer'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _pdfDocument != null
              ? PDFViewer(
                  document: _pdfDocument!,
                  indicatorBackground: Colors.red,
                  // Puedes personalizar las propiedades del visor de PDF aquí
                )
              : Center(child: Text('No se pudo cargar el PDF')),
    );
  }
}
