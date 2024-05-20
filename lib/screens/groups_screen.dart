import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyecto/screens/group_main_screen.dart';

class GroupsScreen extends StatefulWidget {
  final String userId;

  const GroupsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  TextEditingController _searchController = TextEditingController();
  TextEditingController _groupNameController = TextEditingController();
  TextEditingController _groupDescriptionController = TextEditingController();

  String? currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = widget.userId;
  }

  void _showCreateGroupBottomSheet(BuildContext context) {
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
                  controller: _groupNameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre del grupo',
                  ),
                ),
                SizedBox(height: 20.0),
                TextField(
                  controller: _groupDescriptionController,
                  decoration: InputDecoration(
                    labelText: 'Descripción del grupo',
                  ),
                ),
                SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: () {
                    _createGroup();
                    // Navigator.pop(context);
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

  void _createGroup() async {
    final String groupName = _groupNameController.text.trim();
    final String groupDescription = _groupDescriptionController.text.trim();
    if (groupName.isNotEmpty) {
      // Añadir el grupo a la colección 'groups'
      final groupRef = FirebaseFirestore.instance.collection('groups').doc();
      groupRef.set({
        'nombre': groupName,
        'descripcion': groupDescription,
        'callID': Random().nextInt(9999),
      }).then((_) {
        // Agregar el ID del grupo a la colección 'group-user'
        FirebaseFirestore.instance.collection('group-user').add({
          'groupId': groupRef.id,
          'userId': currentUserId,
        }).then((_) {
          // Éxito al agregar el ID del grupo en 'group-user'
          print('ID del grupo agregado en group-user');
        }).catchError((error) {
          // Error al agregar el ID del grupo en 'group-user'
          print('Error al agregar el ID del grupo: $error');
        });
      }).catchError((error) {
        // Error al agregar el grupo en 'groups'
        print('Error al agregar el grupo: $error');
      });
    }
    await Future.delayed(Duration(seconds: 1));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GroupsScreen(
          userId: widget.userId,
        ),
      ),
    );
  }

  void _showJoinGroupBottomSheet(BuildContext context, String groupId) {
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
                '¿Quieres unirte a este grupo?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: () async {
                  bool isMember = await _isUserInGroup(groupId, currentUserId!);
                  if (isMember) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'No te puedes unir ya eres miembro de este grupo.'),
                      ),
                    );
                    Navigator.pop(context);
                  } else {
                    _joinGroup(groupId);
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

  Future<bool> _isUserInGroup(String groupId, String userId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('group-user')
        .where('groupId', isEqualTo: groupId)
        .where('userId', isEqualTo: userId)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  void _joinGroup(String groupId) async {
    FirebaseFirestore.instance.collection('group-user').add({
      'groupId': groupId,
      'userId': currentUserId,
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Te has unido al grupo con éxito.'),
        ),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al unirse al grupo: $error'),
        ),
      );
    });
    await Future.delayed(Duration(seconds: 1));
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupsScreen(
          userId: currentUserId ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Grupos'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre de grupo...',
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
                  FirebaseFirestore.instance.collection('groups').snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final groups = snapshot.data?.docs ?? [];
                final searchText = _searchController.text.toLowerCase();
                final filteredGroups = groups.where((group) {
                  final groupData = group.data() as Map<String, dynamic>;
                  final groupName = groupData['nombre']?.toLowerCase() ?? '';
                  return groupName.contains(searchText);
                }).toList();
                return ListView.builder(
                  itemCount: filteredGroups.length,
                  itemBuilder: (context, index) {
                    final groupData =
                        filteredGroups[index].data() as Map<String, dynamic>;
                    final groupId = filteredGroups[index].id;
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GroupMainScreen(
                              idGroup: groupId,
                              myUserId: currentUserId ?? '',
                            ),
                          ),
                        );
                      },
                      child: Card(
                        margin: EdgeInsets.all(8.0),
                        child: ListTile(
                          title: Text(groupData['nombre'] ?? ''),
                          subtitle: Text(groupData['descripcion'] ?? ''),
                          trailing: FutureBuilder<int>(
                            future: _getGroupUserCount(groupId),
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
                                  IconButton(
                                    icon: Icon(Icons.add),
                                    onPressed: () {
                                      _showJoinGroupBottomSheet(
                                          context, groupId);
                                    },
                                  ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCreateGroupBottomSheet(context);
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Future<int> _getGroupUserCount(String groupId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('group-user')
          .where('groupId', isEqualTo: groupId)
          .get();
      return querySnapshot.size;
    } catch (e) {
      print('Error al obtener el número de usuarios del grupo: $e');
      return 0;
    }
  }
}
