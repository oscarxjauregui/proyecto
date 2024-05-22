import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyecto/screens/class_detail_screen.dart';
import 'package:proyecto/services/avatar_firebase.dart';

class AddToClass extends StatefulWidget {
  final String myUserId;
  final String classId;
  const AddToClass({
    required this.classId,
    required this.myUserId,
    Key? key,
  }) : super(key: key);

  @override
  State<AddToClass> createState() => _AddToClassState();
}

class _AddToClassState extends State<AddToClass> {
  TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agregar personas'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_outlined),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ClassDetailScreen(
                  myUserId: widget.myUserId,
                  idClass: widget.classId,
                ),
              ),
            );
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Buscar usuario...',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchText = '';
                    });
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: _buildUserList(),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error al cargar usuarios'));
        }
        final List<DocumentSnapshot> users = snapshot.data!.docs;
        final filteredUsers = users.where((user) {
          final userData = user.data() as Map<String, dynamic>;
          final id = user.id;
          final name = userData['nombre'].toString().toLowerCase();
          final email = userData['email'].toString().toLowerCase();
          // Filtrar el usuario actual
          return id != widget.myUserId &&
              (name.contains(_searchText.toLowerCase()) ||
                  email.contains(_searchText.toLowerCase()));
        }).toList();

        return ListView.builder(
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final userData =
                filteredUsers[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: FutureBuilder(
                future:
                    AvatarFirebase().consultarAvatar(filteredUsers[index].id),
                builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircleAvatar(
                      backgroundColor: Colors.grey[300],
                      child: Icon(Icons.person, color: Colors.white),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.data() == null) {
                    return CircleAvatar(
                      backgroundColor: Colors.grey[300],
                      child: Icon(Icons.person, color: Colors.white),
                    );
                  }
                  final avatarData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  final avatarUrl = avatarData['imageUrl'];
                  return CircleAvatar(
                    backgroundImage:
                        avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null ? Icon(Icons.person) : null,
                  );
                },
              ),
              title: Text(userData['nombre']),
              subtitle: Text(userData['email']),
              onTap: () {
                _confirmAddToClass(filteredUsers[index].id, userData['nombre']);
              },
            );
          },
        );
      },
    );
  }

  void _confirmAddToClass(String userId, String userName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar'),
          content: Text('¿Estás seguro de agregar a $userName a esta clase?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _addToClass(userId, userName);
              },
              child: Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  void _addToClass(String userId, String userName) async {
    try {
      // Check if user already exists in class
      final existingUserSnapshot = await FirebaseFirestore.instance
          .collection('class-user')
          .where('userId', isEqualTo: userId)
          .where('classId', isEqualTo: widget.classId)
          .get();

      if (existingUserSnapshot.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$userName ya está en esta clase')),
        );
        return;
      }

      // Add user to class
      await FirebaseFirestore.instance.collection('class-user').add({
        'classId': widget.classId,
        'userId': userId,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$userName agregado a la clase')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al agregar $userName: $error')),
      );
    }
  }
}
