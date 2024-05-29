import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class ReenviarCodigoScreen extends StatefulWidget {
  const ReenviarCodigoScreen({Key? key}) : super(key: key);

  @override
  _ReenviarCodigoScreenState createState() => _ReenviarCodigoScreenState();
}

class _ReenviarCodigoScreenState extends State<ReenviarCodigoScreen> {
  final TextEditingController _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Reenviar Código',
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
                _reenviarCodigoVerificacion(_emailController.text.trim());
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors
                    .green, // Cambia el color del texto del botón aquí si es necesario
              ),
              child: Text(
                'Reenviar Código de Autenticación',
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

  Future<void> _reenviarCodigoVerificacion(String email) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Correo de Verificación Enviado'),
              content: Text('Se ha enviado un correo de verificación a $email. '
                  'Por favor, revise su bandeja de entrada y siga las instrucciones.'),
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
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Usuario No Encontrado'),
              content: Text(
                  'No se encontró un usuario con ese correo electrónico, o el correo ya está verificado.'),
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
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error al Enviar Correo de Verificación'),
            content: Text(
                'Se produjo un error al intentar enviar el correo de verificación. '
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
      print('Error al enviar correo de verificación: $e');
    }
  }
}
