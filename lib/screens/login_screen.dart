import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_signin_button/button_list.dart';
import 'package:flutter_signin_button/button_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:proyecto/screens/Home_cliente_screen.dart';
import 'package:proyecto/screens/home_man_screen.dart';
import 'package:proyecto/screens/recuperacionPass.dart';
import 'package:proyecto/screens/reesend_code.dart';
import 'package:proyecto/screens/signUp_screen.dart';
import 'package:proyecto/screens/signup_auth_screen.dart';
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
      style: const TextStyle(
        fontSize: 16,
        color: Colors.black,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        hintText: 'Ingresa el correo',
        labelText: 'Correo institucional',
        hintStyle: const TextStyle(
          color: Colors.grey,
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          color: Colors.black,
          fontSize: 16,
        ),
        prefixIcon: const Icon(Icons.email, color: Colors.green),
      ),
    );

    final txtPassword = TextFormField(
      controller: _passwordController,
      keyboardType: TextInputType.text,
      obscureText: true,
      style: const TextStyle(
        fontSize: 16,
        color: Colors.black,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        hintText: 'Ingresa la contraseña',
        labelText: 'Contraseña',
        hintStyle: const TextStyle(
          color: Colors.grey,
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          color: Colors.black,
          fontSize: 16,
        ),
        prefixIcon: const Icon(Icons.lock, color: Colors.green),
      ),
    );

    return Scaffold(
      body: Container(
        color: Colors.blue,
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Iniciar sesión',
                style: GoogleFonts.lobster(
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Image.asset(
                'lib/assets/images/SL1.png',
                height: 200,
                width: 100,
              ),
              const SizedBox(height: 20),
              txtEmail,
              const SizedBox(height: 15),
              txtPassword,
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: () async {
                  final email = _emailController.text.trim();
                  final password = _passwordController.text.trim();

                  if (email.isEmpty || password.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Por favor, llena todos los campos'),
                      ),
                    );
                    return;
                  }

                  try {
                    final success = await _authFirebase.signInUser(
                      email: email,
                      password: password,
                    );
                    if (success) {
                      final userSnapshot =
                          await _usersFirebase.consultarPorEmail(email);
                      if (userSnapshot.docs.isNotEmpty) {
                        final userData = userSnapshot.docs.first.data()
                            as Map<String, dynamic>?;
                        final userRole = userData?['rol'];
                        if (userRole != null) {
                          final userId = userSnapshot.docs.first.id;
                          if (userRole == 'Estudiante') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HomeClienteScreen(
                                  myIdUser: userId,
                                ),
                              ),
                            );
                          } else if (userRole == 'Maestro') {
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Error al iniciar sesión'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (e is FirebaseAuthException) {
                      String errorMessage;
                      if (e.code == 'user-not-found' ||
                          e.code == 'wrong-password') {
                        errorMessage =
                            'Correo electrónico o contraseña incorrectos';
                      } else {
                        errorMessage = 'El email o contraseña son incorrectos';
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(errorMessage),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('El email o contraseña son incorrectos'),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Iniciar sesión'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SignInButton(
                Buttons.Google,
                onPressed: () {
                  //   signInWithGoogle();
                },
              ),
              SignInButton(
                Buttons.Facebook,
                onPressed: () {
                  //   signInWithFacebook();
                },
              ),
              SignInButton(
                Buttons.GitHub,
                onPressed: () {
                  //  signInWithGithub();
                },
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignUpScreen(),
                    ),
                  );
                },
                child: const Text('Crear cuenta'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ForgotPasswordPage(),
                    ),
                  );
                },
                child: const Text('Olvidé mi contraseña'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReenviarCodigoScreen(),
                    ),
                  );
                },
                child: const Text('Reenviar código de autenticación'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    decoration: TextDecoration.underline,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
