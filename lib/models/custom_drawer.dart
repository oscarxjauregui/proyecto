import 'package:flutter/material.dart';
import 'package:proyecto/screens/login_screen.dart';
import 'package:proyecto/screens/myuser_screen.dart';

class CustomDrawer extends StatelessWidget {
  final String? myIdUser;
  final String? userName;
  final String? userEmail;
  final String? avatarUrl;
  final Function(int)? onMenuItemTap;

  const CustomDrawer({
    Key? key,
    this.myIdUser,
    this.userName,
    this.userEmail,
    this.avatarUrl,
    this.onMenuItemTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            currentAccountPicture: avatarUrl != null
                ? CircleAvatar(
                    backgroundImage: NetworkImage(avatarUrl!),
                  )
                : CircleAvatar(
                    child: Icon(
                      Icons.person,
                      size: 50,
                    ),
                  ),
            accountName: Text(userName ?? 'Cargando...'),
            accountEmail: Text(userEmail ?? 'Cargando...'),
          ),
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Mi perfil'),
            subtitle: Text('Ver mi perfil'),
            onTap: () {
              onMenuItemTap?.call(0);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MyUserScreen(
                    userId: myIdUser ?? '',
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.message_outlined),
            title: Text('Mensajes'),
            subtitle: Text('ver los mensajes'),
            onTap: () {
              onMenuItemTap?.call(1);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MyUserScreen(
                    userId: myIdUser ?? '',
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.date_range_outlined),
            title: Text('Citas'),
            subtitle: Text('Ver mis citas'),
            onTap: () {
              onMenuItemTap?.call(2);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MyUserScreen(
                    userId: myIdUser ?? '',
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.groups),
            title: Text('Grupos'),
            subtitle: Text('Ver todos los grupos'),
            onTap: () {
              onMenuItemTap?.call(3);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MyUserScreen(
                    userId: myIdUser ?? '',
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.groups_outlined),
            title: Text('Mis grupos'),
            subtitle: Text('Ver mis grupos'),
            onTap: () {
              onMenuItemTap?.call(4);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MyUserScreen(
                    userId: myIdUser ?? '',
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.exit_to_app),
            title: Text('Salir'),
            subtitle: Text('Cerrar sesión'),
            onTap: () {
              onMenuItemTap?.call(5);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
