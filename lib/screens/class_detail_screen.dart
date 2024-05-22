import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyecto/screens/add_to_class.dart';
import 'package:proyecto/screens/class_screen.dart';
import 'package:proyecto/services/avatar_firebase.dart';

class ClassDetailScreen extends StatefulWidget {
  final String idClass;
  final String myUserId;

  const ClassDetailScreen({
    required this.idClass,
    required this.myUserId,
    Key? key,
  }) : super(key: key);

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  DocumentSnapshot? _classData;
  List<DocumentSnapshot> _classUsers = [];
  TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _fetchClassData();
    _fetchClassUsers();
  }

  void _fetchClassData() async {
    try {
      final classData = await FirebaseFirestore.instance
          .collection('class')
          .doc(widget.idClass)
          .get();

      setState(() {
        _classData = classData;
        _isAdmin = classData['idAdmin'] == widget.myUserId;
      });
    } catch (error) {
      print('Error al obtener los datos de la clase: $error');
    }
  }

  void _fetchClassUsers() async {
    try {
      final classUserSnapshot = await FirebaseFirestore.instance
          .collection('class-user')
          .where('classId', isEqualTo: widget.idClass)
          .get();

      final userIds =
          classUserSnapshot.docs.map((doc) => doc['userId']).toList();
      final userDocs = await Future.wait(
        userIds.map((userId) =>
            FirebaseFirestore.instance.collection('users').doc(userId).get()),
      );

      setState(() {
        _classUsers = userDocs;
      });
    } catch (error) {
      print('Error al obtener los usuarios de la clase: $error');
    }
  }

  void _deleteClass() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar eliminación'),
          content: Text(
              '¿Estás seguro de que deseas eliminar esta clase? Esta acción no se puede deshacer.'),
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
            .collection('class')
            .doc(widget.idClass)
            .delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Clase eliminada con éxito.')),
        );
        // _navigation();
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar la clase: $error')),
        );
      }
      Navigator.pop(context);
      Navigator.pop(context);
      // Navigator.pop(context);
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => ClassScreen(
      //       userId: widget.idClass,
      //     ),
      //   ),
      // );
    }
  }

  // void _navigation() async {
  //   await Future.delayed(Duration(seconds: 1));
  //   Navigator.pushReplacement(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => ClassDetailScreen(
  //         myUserId: widget.myUserId,
  //         idClass: widget.idClass,
  //       ),
  //     ),
  //   );
  // }

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
                    'Agregar persona a la clase',
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
          return !_classUsers.any((classUser) => classUser.id == id) &&
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
                if (_isAdmin) {
                  _showGradeDialog(filteredUsers[index]);
                }
              },
            );
          },
        );
      },
    );
  }

  void _showGradeDialog(DocumentSnapshot user) async {
    final TextEditingController _parcial1Controller = TextEditingController();
    final TextEditingController _parcial2Controller = TextEditingController();
    final TextEditingController _parcial3Controller = TextEditingController();
    final TextEditingController _parcial4Controller = TextEditingController();

    // Verificar si el usuario ya tiene calificaciones en Firebase
    final existingGradesSnapshot = await FirebaseFirestore.instance
        .collection('clase-calificacion')
        .where('userId', isEqualTo: user.id)
        .where('classId', isEqualTo: widget.idClass)
        .limit(1)
        .get();

    if (existingGradesSnapshot.docs.isNotEmpty) {
      // Si el usuario ya tiene calificaciones, cargarlas en el cuadro de texto
      final existingGrades = existingGradesSnapshot.docs.first.data();
      _parcial1Controller.text = existingGrades['parcial1'].toString();
      _parcial2Controller.text = existingGrades['parcial2'].toString();
      _parcial3Controller.text = existingGrades['parcial3'].toString();
      _parcial4Controller.text = existingGrades['parcial4'].toString();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Container(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Calificaciones para ${user['nombre']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _parcial1Controller,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Parcial 1',
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: _parcial2Controller,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Parcial 2',
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: _parcial3Controller,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Parcial 3',
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: _parcial4Controller,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Parcial 4',
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          _saveGrades(user.id, {
                            'userId': user.id, // Agregar userId al documento
                            'classId':
                                widget.idClass, // Agregar classId al documento
                            'parcial1': _parcial1Controller.text.isNotEmpty
                                ? int.parse(_parcial1Controller.text)
                                : 0,
                            'parcial2': _parcial2Controller.text.isNotEmpty
                                ? int.parse(_parcial2Controller.text)
                                : 0,
                            'parcial3': _parcial3Controller.text.isNotEmpty
                                ? int.parse(_parcial3Controller.text)
                                : 0,
                            'parcial4': _parcial4Controller.text.isNotEmpty
                                ? int.parse(_parcial4Controller.text)
                                : 0,
                          });
                          Navigator.pop(context);
                        },
                        child: Text('Guardar'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _saveGrades(String userId, Map<String, dynamic> grades) async {
    try {
      // Verificar si el usuario ya tiene calificaciones registradas
      final existingGradesSnapshot = await FirebaseFirestore.instance
          .collection('clase-calificacion')
          .where('userId', isEqualTo: userId)
          .where('classId', isEqualTo: widget.idClass)
          .limit(1)
          .get();

      if (existingGradesSnapshot.docs.isNotEmpty) {
        // Si ya tiene calificaciones, actualizar el documento existente
        await existingGradesSnapshot.docs.first.reference.update(grades);
      } else {
        // Si no tiene calificaciones, crear un nuevo documento
        await FirebaseFirestore.instance
            .collection('clase-calificacion')
            .doc('${widget.idClass}_$userId') // Nuevo ID de documento
            .set({...grades, 'userId': userId, 'classId': widget.idClass});
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Calificaciones guardadas con éxito.')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar calificaciones: $error')),
      );
    }
  }

  void _leaveClass() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar abandono'),
          content: Text('¿Estás seguro de que deseas abandonar esta clase?'),
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
        final classUserSnapshot = await FirebaseFirestore.instance
            .collection('class-user')
            .where('classId', isEqualTo: widget.idClass)
            .where('userId', isEqualTo: widget.myUserId)
            .get();

        if (classUserSnapshot.docs.isNotEmpty) {
          await classUserSnapshot.docs.first.reference.delete();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Has abandonado la clase.')),
          );
          // _navigation();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No estás en la clase.')),
          );
        }
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al abandonar la clase: $error')),
        );
      }
      Navigator.pop(context);
      Navigator.pop(context);
      Navigator.pop(context);
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => ClassScreen(
      //       userId: widget.idClass,
      //     ),
      //   ),
      // );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalles de la Clase'),
        actions: [
          if (_isAdmin) ...[
            IconButton(
              icon: Icon(Icons.person_add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddToClass(
                      myUserId: widget.myUserId,
                      classId: widget.idClass,
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: _deleteClass,
            ),
          ] else ...[
            IconButton(
              icon: Icon(Icons.exit_to_app),
              onPressed: _leaveClass,
            ),
          ],
        ],
      ),
      body: _classData != null
          ? _buildClassDetails()
          : Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildClassDetails() {
    final classData = _classData!.data() as Map<String, dynamic>;

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
            classData['nombre'] ?? 'Nombre no disponible',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 16),
          Text(
            'Descripción:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            classData['descripcion'] ?? 'Descripción no disponible',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 20),
          Text(
            'Usuarios en la clase:',
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
            child: _classUsers.isNotEmpty
                ? ListView.builder(
                    itemCount: _filteredClassUsers().length,
                    itemBuilder: (context, index) {
                      final userData = _filteredClassUsers()[index].data()
                          as Map<String, dynamic>;
                      return GestureDetector(
                        onTap: () {
                          if (_isAdmin) {
                            _showGradeDialog(_filteredClassUsers()[index]);
                          }
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
                                    _filteredClassUsers()[index].id),
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
                : Center(child: Text('No hay usuarios en esta clase')),
          ),
        ],
      ),
    );
  }

  List<DocumentSnapshot> _filteredClassUsers() {
    if (_searchText.isEmpty) {
      return _classUsers;
    }
    return _classUsers.where((user) {
      final userData = user.data() as Map<String, dynamic>;
      final name = userData['nombre'].toString().toLowerCase();
      final email = userData['email'].toString().toLowerCase();
      return name.contains(_searchText.toLowerCase()) ||
          email.contains(_searchText.toLowerCase());
    }).toList();
  }
}
