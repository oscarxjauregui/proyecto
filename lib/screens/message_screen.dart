import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ImageController extends ChangeNotifier {
  File? _imageFile;
  File? get imageFile => _imageFile;

  void setImageFile(File? imageFile) {
    _imageFile = imageFile;
    notifyListeners();
  }
}

class MessageScreen extends StatefulWidget {
  final String userId;
  final String myUserId;

  const MessageScreen({Key? key, required this.userId, required this.myUserId})
      : super(key: key);

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  late ImageController imageController;
  late String _userName = 'Cargando...';
  late String _userEmail = 'Cargando...';
  late String _myUserName = 'Cargando...';
  late String _myUserEmail = 'Cargando...';
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController callIdController = TextEditingController();
  final String callID = '';

  Future<String?> _getUserAvatarUrl(String userId) async {
    try {
      final avatarSnapshot = await FirebaseFirestore.instance
          .collection('avatars')
          .doc(userId)
          .get();
      if (avatarSnapshot.exists) {
        return avatarSnapshot.get('imageUrl');
      }
    } catch (e) {
      print('Error obteniendo avatar del usuario: $e');
    }
    return null;
  }

  Future<void> _selectImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          imageController.setImageFile(File(pickedFile.path));
          // Subir la imagen al almacenamiento de Firebase
          _uploadImage(File(pickedFile.path));
        });
      }
    } catch (e) {
      print("Error al seleccionar la imagen: $e");
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    try {
      // Nombre del archivo en el almacenamiento de Firebase
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();

      // Referencia al directorio en el almacenamiento de Firebase
      Reference firebaseStorageRef =
          FirebaseStorage.instance.ref().child('images/$fileName.jpg');

      // Subir el archivo al almacenamiento de Firebase
      UploadTask uploadTask = firebaseStorageRef.putFile(imageFile);

      // Obtener la URL de descarga una vez que se complete la carga
      TaskSnapshot taskSnapshot = await uploadTask;
      String url = await taskSnapshot.ref.getDownloadURL();

      // Mostrar mensaje en consola para confirmar que la imagen se subió correctamente
      print('Imagen subida correctamente. URL: $url');

      // Guardar el enlace de la imagen en Firestore
      await FirebaseFirestore.instance.collection('messages').add({
        'ids': [widget.myUserId, widget.userId], // Almacenar IDs en una lista
        'message': '',
        'imageUrl':
            url, // Guardar el enlace de la imagen en la propiedad 'imageUrl'
        'timestamp': DateTime.now(),
      });
    } catch (e) {
      print("Error al subir la imagen al almacenamiento de Firebase: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    imageController = ImageController();
    _getUserData();
    _getMyUserData();
  }

  Future<void> _getMyUserData() async {
    try {
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.myUserId)
          .get();
      if (userSnapshot.exists) {
        final userData = userSnapshot.data() as Map<String, dynamic>;
        setState(() {
          _myUserName = userData['nombre'] ?? 'Usuario';
          _myUserEmail = userData['email'] ?? 'No proporcionado';
        });
      }
    } catch (e) {
      print('Error obteniendo datos del usuario: $e');
    }
  }

  Future<void> _getUserData() async {
    try {
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      if (userSnapshot.exists) {
        final userData = userSnapshot.data() as Map<String, dynamic>;
        setState(() {
          _userName = userData['nombre'] ?? 'Usuario';
          _userEmail = userData['email'] ?? 'No proporcionado';
        });
      }
    } catch (e) {
      print('Error obteniendo datos del usuario: $e');
    }
  }

  Future<void> _sendMessage(String message) async {
    try {
      await FirebaseFirestore.instance.collection('messages').add({
        'ids': [widget.myUserId, widget.userId], // Almacenar IDs en una lista
        'message': message,
        'timestamp': DateTime.now(),
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> _selectVideo() async {
    try {
      final pickedFile =
          await ImagePicker().pickVideo(source: ImageSource.gallery);
      if (pickedFile != null) {
        // Aquí puedes implementar la lógica para subir el video seleccionado
        // _uploadVideo(File(pickedFile.path));
      }
    } catch (e) {
      print("Error al seleccionar el video: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            FutureBuilder<String?>(
              future: _getUserAvatarUrl(widget.userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }
                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data == null) {
                  // Si hay un error o no hay avatar, mostrar icono de usuario
                  return CircleAvatar(
                    child: Icon(Icons.person),
                  );
                }
                // Mostrar el avatar del usuario en un círculo
                return CircleAvatar(
                  backgroundImage: NetworkImage(snapshot.data!),
                );
              },
            ),
            SizedBox(width: 10),
            Text(_userName),
          ],
        ),
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          // IconButton(
          // icon: Icon(Icons.call),
          // onPressed: () {
          // Navigator.of(context).push(
          //   MaterialPageRoute(
          //     builder: (context) => CallPage(
          //       userName: _userName, callID: '3354653',
          //     ),
          //   ),
          // );
          //   },
          // ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .orderBy('timestamp', descending: true) // Ordenar por fecha
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  print('${snapshot.error}');
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }
                final messages = snapshot.data?.docs ?? [];
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageData =
                        messages[index].data() as Map<String, dynamic>;
                    final ids = List<String>.from(messageData['ids'] ?? []);
                    if (ids.contains(widget.myUserId) &&
                        ids.contains(widget.userId)) {
                      final message = messageData['message'];
                      final isMyMessage = ids.indexOf(widget.myUserId) == 0;

                      final timestamp =
                          '${messageData['timestamp']?.toDate().day}-${messageData['timestamp']?.toDate().month}-${messageData['timestamp']?.toDate().year} ${messageData['timestamp']?.toDate().hour}:${messageData['timestamp']?.toDate().minute}';

                      if (messageData.containsKey('imageUrl')) {
                        return Align(
                          alignment: isMyMessage
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width *
                                  0.8, // Ancho máximo del contenedor
                            ),
                            margin: EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isMyMessage
                                  ? Colors.blue[200]
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                                bottomLeft: isMyMessage
                                    ? Radius.circular(16)
                                    : Radius.zero,
                                bottomRight: isMyMessage
                                    ? Radius.zero
                                    : Radius.circular(16),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Mostramos el texto del mensaje
                                if (messageData.containsKey('message'))
                                  Text(messageData['message'],
                                      style: TextStyle(fontSize: 16)),
                                // Mostramos la imagen
                                Image.network(messageData['imageUrl']),
                                SizedBox(height: 4),
                                Text('Enviado: $timestamp'),
                              ],
                            ),
                          ),
                        );
                      } else {
                        return Align(
                          alignment: isMyMessage
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width *
                                  0.8, // Ancho máximo del contenedor
                            ),
                            margin: EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 16), // Margen adicional
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isMyMessage
                                  ? Colors.blue[200]
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(
                                    24), // Bordes más redondeados
                                topRight: Radius.circular(
                                    24), // Bordes más redondeados
                                bottomLeft: isMyMessage
                                    ? Radius.circular(24)
                                    : Radius.zero, // Bordes más redondeados
                                bottomRight: isMyMessage
                                    ? Radius.zero
                                    : Radius.circular(
                                        24), // Bordes más redondeados
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Mostramos solo el texto del mensaje
                                Text(messageData['message'],
                                    style: TextStyle(fontSize: 16)),
                                SizedBox(height: 4),
                                Text('Enviado: $timestamp'),
                              ],
                            ),
                          ),
                        );
                      }
                    } else {
                      // Si el mensaje no es para esta conversación, no lo mostramos
                      return SizedBox.shrink();
                    }
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Escribe tu mensaje...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.image),
                  onPressed: () {
                    // Mostrar el BottomSheet para seleccionar la imagen
                    showModalBottomSheet(
                      context: context,
                      builder: (BuildContext context) {
                        return SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              ListTile(
                                leading: Icon(Icons.camera),
                                title: Text('Desde la cámara'),
                                onTap: () {
                                  _selectImage(ImageSource.camera);
                                  Navigator.pop(context);
                                },
                              ),
                              ListTile(
                                leading: Icon(Icons.photo_library),
                                title: Text('Desde la galería'),
                                onTap: () {
                                  _selectImage(ImageSource.gallery);
                                  Navigator.pop(context);
                                },
                              ),
                              ListTile(
                                leading: Icon(Icons.videocam),
                                title: Text('Subir video'),
                                onTap: () {
                                  _selectVideo();
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    final message = _messageController.text;
                    _sendMessage(message);
                    _messageController.clear();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: MessageScreen(userId: 'user_id', myUserId: 'my_user_id'),
  ));
}
