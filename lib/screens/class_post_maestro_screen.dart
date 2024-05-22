import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:proyecto/screens/class_post_detail_screen.dart';
import 'package:proyecto/services/avatar_firebase.dart';
import 'package:proyecto/services/user_firebase.dart';
import 'package:advance_pdf_viewer_fork/advance_pdf_viewer_fork.dart';

class ClassPostMaestroScreen extends StatefulWidget {
  final String classId;
  final String myUserId;
  final Map<String, dynamic> publicacion;

  const ClassPostMaestroScreen({
    required this.myUserId,
    required this.classId,
    required this.publicacion,
    Key? key,
  }) : super(key: key);

  @override
  State<ClassPostMaestroScreen> createState() => _ClassPostMaestroScreenState();
}

class _ClassPostMaestroScreenState extends State<ClassPostMaestroScreen> {
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
          final userIds = <String>{};
          final uniqueTasks =
              tasks.where((task) => userIds.add(task['userId'])).toList();

          return ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: uniqueTasks.length,
            itemBuilder: (context, index) {
              final task = uniqueTasks[index];
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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ClassPostDetailScreen(
                              classId: widget.classId,
                              userId: task['userId'],
                            ),
                          ),
                        );
                      },
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
