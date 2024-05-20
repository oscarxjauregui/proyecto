import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyecto/screens/groups_screen.dart';
import 'package:proyecto/services/avatar_firebase.dart';

class GroupDetailScreen extends StatefulWidget {
  final String idGroup;
  final String myUserId;

  const GroupDetailScreen({
    required this.idGroup,
    required this.myUserId,
    Key? key,
  }) : super(key: key);

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  DocumentSnapshot? _groupData;
  List<DocumentSnapshot> _groupUsers = [];
  TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _fetchGroupData();
    _fetchGroupUsers();
  }

  void _fetchGroupData() async {
    try {
      final groupData = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.idGroup)
          .get();

      setState(() {
        _groupData = groupData;
        _isAdmin = groupData['idAdmin'] == widget.myUserId;
      });
    } catch (error) {
      print('Error al obtener los datos del grupo: $error');
    }
  }

  void _fetchGroupUsers() async {
    try {
      final groupUserSnapshot = await FirebaseFirestore.instance
          .collection('group-user')
          .where('groupId', isEqualTo: widget.idGroup)
          .get();

      final userIds =
          groupUserSnapshot.docs.map((doc) => doc['userId']).toList();
      final userDocs = await Future.wait(
        userIds.map((userId) =>
            FirebaseFirestore.instance.collection('users').doc(userId).get()),
      );

      setState(() {
        _groupUsers = userDocs;
      });
    } catch (error) {
      print('Error al obtener los usuarios del grupo: $error');
    }
  }

  void _deleteGroup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar eliminación'),
          content: Text(
              '¿Estás seguro de que deseas eliminar este grupo? Esta acción no se puede deshacer.'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('Eliminar'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.idGroup)
            .delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Grupo eliminado con éxito.')),
        );
        // Navigator.pop(context);
        _navigation();
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar el grupo: $error')),
        );
      }
    }
  }

  void _navigation() async {
    await Future.delayed(Duration(seconds: 1));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GroupsScreen(
          userId: widget.myUserId,
        ),
      ),
    );
  }

  void _addPerson() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Agregar persona al grupo',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
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
                  SizedBox(height: 16),
                  Expanded(
                    child: _buildUserList(),
                  ),
                ],
              ),
            );
          },
        );
      },
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
          return !_groupUsers.any((groupUser) => groupUser.id == id) &&
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
                _addUserToGroup(filteredUsers[index]);
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  void _addUserToGroup(DocumentSnapshot userSnapshot) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar adición'),
          content: Text(
              '¿Estás seguro de que deseas agregar a este usuario al grupo?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('Agregar'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('group-user').add({
          'groupId': widget.idGroup,
          'userId': userSnapshot.id,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Usuario agregado al grupo.')),
        );
        _fetchGroupUsers(); // Actualizar la lista de usuarios del grupo
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al agregar usuario al grupo: $error')),
        );
      }
    }
  }

  void _leaveGroup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar abandono'),
          content: Text('¿Estás seguro de que deseas abandonar este grupo?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('Abandonar'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        final groupUserSnapshot = await FirebaseFirestore.instance
            .collection('group-user')
            .where('groupId', isEqualTo: widget.idGroup)
            .where('userId', isEqualTo: widget.myUserId)
            .get();

        if (groupUserSnapshot.docs.isNotEmpty) {
          await groupUserSnapshot.docs.first.reference.delete();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Has abandonado el grupo.')),
          );
          _navigation();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No estás en el grupo.')),
          );
        }
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al abandonar el grupo: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalles del Grupo'),
        actions: [
          if (_isAdmin) ...[
            IconButton(
              icon: Icon(Icons.person_add),
              onPressed: _addPerson,
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: _deleteGroup,
            ),
          ] else ...[
            IconButton(
              icon: Icon(Icons.exit_to_app),
              onPressed: _leaveGroup,
            ),
          ],
        ],
      ),
      body: _groupData != null
          ? _buildGroupDetails()
          : Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildGroupDetails() {
    final groupData = _groupData!.data() as Map<String, dynamic>;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nombre:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            groupData['nombre'] ?? 'Nombre no disponible',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 16),
          Text(
            'Descripción:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            groupData['descripcion'] ?? 'Descripción no disponible',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 20),
          Text(
            'Usuarios en el grupo:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.all(8.0),
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
            child: _groupUsers.isNotEmpty
                ? ListView.builder(
                    itemCount: _filteredGroupUsers().length,
                    itemBuilder: (context, index) {
                      final userData = _filteredGroupUsers()[index].data()
                          as Map<String, dynamic>;
                      return GestureDetector(
                        onTap: () {
                          // Manejar la acción cuando se selecciona un usuario
                          // Por ejemplo, navegar a la pantalla de perfil del usuario
                        },
                        child: Card(
                          margin: EdgeInsets.symmetric(
                              vertical: 10, horizontal: 10),
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ListTile(
                              leading: FutureBuilder(
                                future: AvatarFirebase().consultarAvatar(
                                    _filteredGroupUsers()[index].id),
                                builder: (context,
                                    AsyncSnapshot<DocumentSnapshot> snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return CircularProgressIndicator();
                                  }
                                  if (!snapshot.hasData ||
                                      snapshot.data!.data() == null) {
                                    return CircleAvatar(
                                      backgroundColor: Colors.grey[300],
                                      child: Icon(Icons.person,
                                          color: Colors.white),
                                    );
                                  }
                                  final avatarData = snapshot.data!.data()
                                      as Map<String, dynamic>;
                                  final avatarUrl = avatarData['imageUrl'];
                                  return CircleAvatar(
                                    backgroundImage: avatarUrl != null
                                        ? NetworkImage(avatarUrl)
                                        : null,
                                    child: avatarUrl == null
                                        ? Icon(Icons.person)
                                        : null,
                                  );
                                },
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    userData['nombre'],
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(' '),
                                  Text(
                                    userData['rol'],
                                    style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(userData['email'],
                                      style: TextStyle(color: Colors.grey)),
                                  if (userData['rol'] == 'Estudiante')
                                    Text('Semestre: ${userData['semestre']}'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : Center(child: Text('No hay usuarios en este grupo')),
          ),
        ],
      ),
    );
  }

  List<DocumentSnapshot> _filteredGroupUsers() {
    if (_searchText.isEmpty) {
      return _groupUsers;
    }
    return _groupUsers.where((user) {
      final userData = user.data() as Map<String, dynamic>;
      final name = userData['nombre'].toString().toLowerCase();
      final email = userData['email'].toString().toLowerCase();
      return name.contains(_searchText.toLowerCase()) ||
          email.contains(_searchText.toLowerCase());
    }).toList();
  }
}
