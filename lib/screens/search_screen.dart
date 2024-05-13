import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyecto/screens/profile_screen.dart';
import 'package:proyecto/services/avatar_firebase.dart';

class SearchScreen extends StatefulWidget {
  final String myIdUser;
  const SearchScreen({required this.myIdUser, Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _searchText = '';
  TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inicio'),
      ),
      body: Column(
        children: [
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
                hintText: 'Buscar por nombre o email',
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
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
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
          return id != widget.myIdUser &&
              (name.contains(_searchText.toLowerCase()) ||
                  email.contains(_searchText.toLowerCase()));
        }).toList();

        return ListView.builder(
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final userData =
                filteredUsers[index].data() as Map<String, dynamic>;
            return GestureDetector(
              onTap: () {
                // Manejar la acción cuando se selecciona un usuario
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(
                      myUserId: widget.myIdUser,
                      userId: filteredUsers[index].id,
                    ),
                  ),
                );
                // _handleUserTap(userData);
              },
              child: Card(
                margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: FutureBuilder(
                      future: AvatarFirebase()
                          .consultarAvatar(filteredUsers[index].id),
                      builder:
                          (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        }
                        if (!snapshot.hasData ||
                            snapshot.data!.data() == null) {
                          return CircleAvatar(
                            backgroundColor: Colors.grey[300],
                            child: Icon(Icons.person, color: Colors.white),
                          );
                        }
                        final avatarData =
                            snapshot.data!.data() as Map<String, dynamic>;
                        final avatarUrl = avatarData['imageUrl'];
                        return CircleAvatar(
                          backgroundImage: avatarUrl != null
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: avatarUrl == null ? Icon(Icons.person) : null,
                        );
                      },
                    ),
                    title: Row(
                      children: [
                        Text(
                          userData['nombre'],
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(' '),
                        Text(
                          userData['rol'],
                          style: TextStyle(
                              fontWeight: FontWeight.normal, fontSize: 12),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      userData['email'],
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
