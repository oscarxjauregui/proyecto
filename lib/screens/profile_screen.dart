import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:proyecto/screens/message_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String myUserId;
  final String userId;
  const ProfileScreen({required this.myUserId, required this.userId, Key? key})
      : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  DocumentSnapshot? _userData;
  String? _userName;
  String? _avatarUrl;
  List<DocumentSnapshot>? _userPublications;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  void _fetchUserData() async {
    try {
      // Obtener datos del usuario desde Firestore
      final userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      // Obtener avatar del usuario desde Firestore
      final avatarData = await FirebaseFirestore.instance
          .collection('avatars')
          .doc(widget.userId)
          .get();

      // Obtener publicaciones del usuario desde Firestore
      final userPublications = await FirebaseFirestore.instance
          .collection('publicaciones')
          .where('idUser', isEqualTo: widget.userId)
          .get();

      setState(() {
        _userData = userData;
        _userName = userData['nombre'];
        _avatarUrl = avatarData.exists ? avatarData['imageUrl'] : null;
        _userPublications = userPublications.docs;
      });
    } catch (error) {
      print('Error al obtener los datos del usuario: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _userName != null ? Text(_userName!) : Text('Perfil'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MessageScreen(
                    myUserId: widget.myUserId,
                    userId: widget.userId,
                  ),
                ),
              );
            },
            icon: Icon(Icons.message_outlined),
          ),
        ],
      ),
      body: _userData != null
          ? _buildProfile()
          : Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildProfile() {
    final userData = _userData!.data() as Map<String, dynamic>;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 7,
                  offset: Offset(0, 3), // changes position of shadow
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundImage:
                  _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
              child: _avatarUrl == null
                  ? Icon(Icons.person,
                      size: 50) // Icono de persona si no hay avatar
                  : null, // No hay child si hay avatar
            ),
          ),
          SizedBox(height: 20),
          Text(
            '${userData['nombre']}',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 2),
          Text(
            '${userData['email']}',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 2),
          Text(
            '${userData['rol']}',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 20),
          Text(
            'Publicaciones:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          _userPublications != null
              ? _buildUserPublications()
              : Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildUserPublications() {
    _userPublications!.sort((a, b) {
      // Ordenar por fecha descendente
      final fechaA = DateTime.parse(a['fecha']);
      final fechaB = DateTime.parse(b['fecha']);
      return fechaB.compareTo(fechaA);
    });

    return Expanded(
      child: ListView.builder(
        itemCount: _userPublications!.length,
        itemBuilder: (context, index) {
          final publicationData =
              _userPublications![index].data() as Map<String, dynamic>;
          final hasImage = publicationData['imageUrl'] != null;

          // Formatear la fecha
          final fecha = DateTime.parse(publicationData['fecha']);
          final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(fecha);

          return Card(
            margin: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    publicationData['descripcion'],
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(formattedDate), // Fecha formateada
                  SizedBox(height: 10),
                  if (hasImage)
                    Image.network(
                      publicationData['imageUrl'],
                      fit: BoxFit.cover,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
