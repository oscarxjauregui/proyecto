import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_signin_button/button_list.dart';
import 'package:flutter_signin_button/button_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:proyecto/screens/Home_cliente_screen.dart';
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
  final _authFirebase = EmailAuthFirebase();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usersFirebase = UsersFirebase();

  @override
  Widget build(BuildContext context) {
    final txtEmail = TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: 'Correo institucional',
        prefixIcon: Icon(Icons.email),
      ),
    );

    final txtPassword = TextFormField(
      controller: _passwordController,
      keyboardType: TextInputType.text,
      obscureText: true,
      decoration: InputDecoration(
        labelText: 'Contraseña',
        prefixIcon: Icon(Icons.lock),
      ),
    );

    return Scaffold(
      body: Container(
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
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
              SizedBox(height: 10),
              Image.asset(
                'lib/assets/images/SL1.png',
                height: 200,
                width: 100,
              ),
              SizedBox(height: 20),
              txtEmail,
              SizedBox(height: 15),
              txtPassword,
              SizedBox(height: 15),
              ElevatedButton(
                onPressed: () async {
                  // Your login logic here
                },
                child: Text('Iniciar sesión'),
              ),
              SignInButton(
                Buttons.Google,
                onPressed: () {
                  // Google sign in logic here
                },
              ),
              SignInButton(
                Buttons.Facebook,
                onPressed: () {
                  // Facebook sign in logic here
                },
              ),
              SignInButton(
                Buttons.GitHub,
                onPressed: () {
                  // Github sign in logic here
                },
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignUpScreen(),
                    ),
                  );
                },
                child: Text('Crear cuenta'),
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
                child: Text('Olvidé mi contraseña'),
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
                child: Text('Reenviar código de autenticación'),
              ),
            ],
          ),
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

        // Obtener los datos del usuario autenticado con Google
        final String email = userCredential.user?.email ?? '';
        final String? name = userCredential.user?.displayName;
        final String? photoUrl = userCredential.user?.photoURL;

        // Consultar si el email ya está registrado en la colección 'users'
        final userSnapshot = await _usersFirebase.consultarPorEmail(email);
        if (userSnapshot.docs.isNotEmpty) {
          // Si el email ya está registrado, obtener el ID del usuario y navegar a HomeScreen
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
          // Si el email no está registrado, navegar a la pantalla de registro con los datos de Google
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SignUpAuthScreen(
                email: email,
                nombre: name ?? '',
                fotoUrl: photoUrl ?? '',
              ),
            ),
          );
        }
      } else {
        // Manejar error, e.g., mostrar snackbar
        print('Error al iniciar sesión con Google');
      }
    } catch (e) {
      print('Error al iniciar sesión con Google: $e');
    }
  }

  Future<void> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;
        final AuthCredential credential =
            FacebookAuthProvider.credential(accessToken.tokenString);

        final UserCredential userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);

        // Obtener el email del usuario autenticado con Facebook
        final String email = userCredential.user?.email ?? '';

        // Consultar si el email ya está registrado en la colección 'users'
        final userSnapshot = await _usersFirebase.consultarPorEmail(email);
        if (userSnapshot.docs.isNotEmpty) {
          // Si el email ya está registrado, obtener el ID del usuario y navegar a HomeScreen
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
          // Si el email no está registrado, navegar a la pantalla de registro
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SignUpScreen(),
            ),
          );
        }
      } else {
        // Manejar otros estados de resultado, e.g., LoginStatus.cancelled, LoginStatus.failed
        print('Error al iniciar sesión con Facebook: ${result.status}');
      }
    } catch (e) {
      print('Error al iniciar sesión con Facebook: $e');
    }
  }

  Future<void> signInWithGithub() async {
    try {
      // Crear una instancia del proveedor de autenticación de GitHub
      GithubAuthProvider githubAuthProvider = GithubAuthProvider();

      // Iniciar sesión con el proveedor de autenticación de GitHub
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithProvider(githubAuthProvider);

      // Obtener el email del usuario autenticado con GitHub
      final String email = userCredential.user?.email ?? '';

      // Consultar si el email ya está registrado en la colección 'users'
      final userSnapshot = await _usersFirebase.consultarPorEmail(email);
      if (userSnapshot.docs.isNotEmpty) {
        // Si el email ya está registrado, obtener el ID del usuario y navegar a HomeClienteScreen
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
        // Si el email no está registrado, navegar a la pantalla de registro
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SignUpScreen(),
          ),
        );
      }
    } catch (e) {
      print('Error al iniciar sesión con GitHub: $e');
    }
  }
}
