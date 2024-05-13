import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_signin_button/button_list.dart';
import 'package:flutter_signin_button/button_view.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:proyecto/screens/Home_cliente_screen.dart';
import 'package:proyecto/screens/home_man_screen.dart';
import 'package:proyecto/screens/signUp_screen.dart';
import 'package:proyecto/services/email_auth_firebase.dart';
import 'package:proyecto/services/user_firebase.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final EmailAuthFirebase _authFirebase = EmailAuthFirebase();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final UsersFirebase _usersFirebase = UsersFirebase();

  @override
  Widget build(BuildContext context) {
    final txtEmail = TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        hintText: 'Ingresa el correo',
        labelText: 'Correo institucional',
      ),
    );
    final txtPassword = TextFormField(
      controller: _passwordController,
      keyboardType: TextInputType.text,
      obscureText: true,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        hintText: 'Ingresa la contraseña',
        labelText: 'Contraseña',
      ),
    );

    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              child: Container(
                padding: EdgeInsets.all(10),
                height: 500,
                width: MediaQuery.of(context).size.width,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    txtEmail,
                    const SizedBox(height: 10),
                    txtPassword,
                    const SizedBox(height: 10),
                    SignInButton(
                      Buttons.Email,
                      onPressed: () async {
                        final email = _emailController.text.trim();
                        final password = _passwordController.text.trim();
                        final success = await _authFirebase.signInUser(
                          email: email,
                          password: password,
                        );
                        if (success) {
                          final userSnapshot =
                              await _usersFirebase.consultarPorEmail(email);
                          if (userSnapshot.docs.isNotEmpty) {
                            final userData = userSnapshot.docs.first.data()
                                as Map<String, dynamic>?; // Corrección aquí
                            final userRole = userData?['rol'];
                            if (userRole != null) {
                              if (userRole == 'Cliente') {
                                final userId = userSnapshot.docs.first.id;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HomeClienteScreen(
                                      myIdUser: userId,
                                    ),
                                  ),
                                );
                              } else if (userRole == 'Manicurista') {
                                final userId = userSnapshot.docs.first.id;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HomeClienteScreen(
                                      myIdUser: userId,
                                    ),
                                  ),
                                );
                              } else {
                                print('Error: Rol de usuario no reconocido');
                              }
                            } else {
                              print('Error: Rol de usuario no encontrado');
                            }
                          } else {
                            print(
                                'Error: No se encontró ningún usuario con el correo electrónico proporcionado');
                          }
                        } else {
                          print('Error al iniciar sesión');
                        }
                      },
                    ),
                    SignInButton(
                      Buttons.Google,
                      onPressed: () {
                        signInWithGoogle();
                      },
                    ),
                    SignInButton(
                      Buttons.Facebook,
                      onPressed: () {},
                    ),
                    SignInButton(
                      Buttons.GitHub,
                      onPressed: () {},
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SignUpScreen(),
                          ),
                        );
                      },
                      child: Text('Crear cuenta'),
                    ),
                    TextButton(
                      onPressed: () {
                        // Implementa la lógica para recuperar la contraseña aquí
                      },
                      child: Text('Olvidé mi contraseña'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);

        // Handle success, e.g., navigate to a new page
        print(userCredential.user?.displayName);
      } else {
        // Handle error, e.g., show snackbar
        print('Error al iniciar sesión con Google');
      }
    } catch (e) {
      print('Error al iniciar sesión con Google: $e');
    }
  }
}
