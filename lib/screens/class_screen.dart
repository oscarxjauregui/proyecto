import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyecto/screens/group_main_screen.dart';

class ClassScreen extends StatefulWidget {
  final String userId;

  const ClassScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<ClassScreen> createState() => _ClassScreenState();
}

class _ClassScreenState extends State<ClassScreen> {
  TextEditingController _searchController = TextEditingController();
  TextEditingController _classNameController = TextEditingController();
  TextEditingController _classDescriptionController = TextEditingController();

  String? currentUserId;
  List<String> _userClassIds = [];
  String _userRole = '';

  @override
  void initState() {
    super.initState();
    currentUserId = widget.userId;
    _fetchUserRole();
    _fetchUserClasses();
  }

  Future<void> _fetchUserRole() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();
    if (userDoc.exists) {
      setState(() {
        _userRole = userDoc.data()?['rol'] ?? '';
      });
    }
  }

  Future<void> _fetchUserClasses() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('class-user')
        .where('userId', isEqualTo: currentUserId)
        .get();
    final userClassIds =
        querySnapshot.docs.map((doc) => doc['classId'] as String).toList();
    setState(() {
      _userClassIds = userClassIds;
    });
  }

  void _showCreateClassBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _classNameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre de la clase',
                  ),
                ),
                SizedBox(height: 20.0),
                TextField(
                  controller: _classDescriptionController,
                  decoration: InputDecoration(
                    labelText: 'Descripción de la clase',
                  ),
                ),
                SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: () {
                    _createClass();
                  },
                  child: Text('Guardar'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _createClass() async {
    final String className = _classNameController.text.trim();
    final String classDescription = _classDescriptionController.text.trim();
    if (className.isNotEmpty) {
      // Añadir la clase a la colección 'classes'
      final classRef = FirebaseFirestore.instance.collection('classes').doc();
      classRef.set({
        'nombre': className,
        'descripcion': classDescription,
        'callID': Random().nextInt(9999),
        'idAdmin': currentUserId, // Añadir el campo 'idAdmin'
      }).then((_) {
        // Agregar el ID de la clase a la colección 'class-user'
        FirebaseFirestore.instance.collection('class-user').add({
          'classId': classRef.id,
          'userId': currentUserId,
        }).then((_) {
          // Éxito al agregar el ID de la clase en 'class-user'
          print('ID de la clase agregado en class-user');
        }).catchError((error) {
          // Error al agregar el ID de la clase en 'class-user'
          print('Error al agregar el ID de la clase: $error');
        });
      }).catchError((error) {
        // Error al agregar la clase en 'classes'
        print('Error al agregar la clase: $error');
      });
    }
    await Future.delayed(Duration(seconds: 1));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ClassScreen(
          userId: widget.userId,
        ),
      ),
    );
  }

  void _showJoinClassBottomSheet(BuildContext context, String classId) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '¿Quieres unirte a esta clase?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: () async {
                  bool isMember = await _isUserInClass(classId, currentUserId!);
                  if (isMember) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'No te puedes unir, ya eres miembro de esta clase.'),
                      ),
                    );
                    Navigator.pop(context);
                  } else {
                    _joinClass(classId);
                    Navigator.pop(context);
                  }
                },
                child: Text('Unirme'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Cerrar'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _isUserInClass(String classId, String userId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('class-user')
        .where('classId', isEqualTo: classId)
        .where('userId', isEqualTo: userId)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  void _joinClass(String classId) async {
    FirebaseFirestore.instance.collection('class-user').add({
      'classId': classId,
      'userId': currentUserId,
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Te has unido a la clase con éxito.'),
        ),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al unirse a la clase: $error'),
        ),
      );
    });
    await Future.delayed(Duration(seconds: 1));
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClassScreen(
          userId: currentUserId ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Clases'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre de clase...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream:
                  FirebaseFirestore.instance.collection('classes').snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final classes = snapshot.data?.docs ?? [];
                final searchText = _searchController.text.toLowerCase();
                final filteredClasses = classes.where((classDoc) {
                  final classData = classDoc.data() as Map<String, dynamic>;
                  final className = classData['nombre']?.toLowerCase() ?? '';
                  return _userClassIds.contains(classDoc.id) &&
                      className.contains(searchText);
                }).toList();

                if (filteredClasses.isEmpty) {
                  return Center(
                    child: Text(
                      'No hay clases disponibles',
                      style: TextStyle(fontSize: 18),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredClasses.length,
                  itemBuilder: (context, index) {
                    final classData =
                        filteredClasses[index].data() as Map<String, dynamic>;
                    final classId = filteredClasses[index].id;
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GroupMainScreen(
                              idGroup: classId,
                              myUserId: currentUserId ?? '',
                            ),
                          ),
                        );
                      },
                      child: Card(
                        margin: EdgeInsets.all(8.0),
                        child: ListTile(
                          title: Text(classData['nombre'] ?? ''),
                          subtitle: Text(classData['descripcion'] ?? ''),
                          trailing: FutureBuilder<int>(
                            future: _getClassUserCount(classId),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return SizedBox.shrink();
                              }
                              if (snapshot.hasError) {
                                return Text('Error');
                              }
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('${snapshot.data ?? 0} usuarios'),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _userRole == 'Maestro'
          ? FloatingActionButton(
              onPressed: () {
                _showCreateClassBottomSheet(context);
              },
              child: Icon(Icons.add),
            )
          : null,
    );
  }

  Future<int> _getClassUserCount(String classId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('class-user')
          .where('classId', isEqualTo: classId)
          .get();
      return querySnapshot.size;
    } catch (e) {
      print('Error al obtener el número de usuarios de la clase: $e');
      return 0;
    }
  }
}
