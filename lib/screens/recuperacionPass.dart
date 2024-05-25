import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Recuperar Contraseña',
          style: GoogleFonts.lobster(
            fontSize: 24.0,
            color: Colors.white, // Cambia el color aquí si es necesario
          ),
        ),
        backgroundColor: Colors
            .green, // Cambia el color de fondo de la AppBar aquí si es necesario
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Agrega un icono al inicio del formulario
            Icon(Icons.help_outline, size: 50, color: Colors.green),
            SizedBox(height: 50),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
              ),
            ),
            const SizedBox(height: 16.0),
            // Cambia los colores y la fuente del botón
            ElevatedButton(
              onPressed: () {
                _resetPassword(_emailController.text.trim());
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors
                    .green, // Cambia el color del texto del botón aquí si es necesario
              ),
              child: Text(
                'Enviar Correo de Recuperación',
                style: GoogleFonts.comicNeue(
                  fontSize: 18.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Correo de Recuperación Enviado'),
            content: Text('Se ha enviado un correo electrónico a $email. '
                'Siga las instrucciones en el correo para restablecer su contraseña.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error al Enviar Correo de Recuperación'),
            content: Text(
                'Se produjo un error al intentar enviar el correo de recuperación. '
                'Por favor, inténtelo de nuevo más tarde.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
      print('Error al enviar correo de recuperación: $e');
    }
  }
}
