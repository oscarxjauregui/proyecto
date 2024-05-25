import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:proyecto/services/email_auth_firebase.dart';
import 'package:proyecto/services/user_firebase.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final UsersFirebase _usersFirebase = UsersFirebase();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _semestreController = TextEditingController();
  final EmailAuthFirebase _emailAuthFirebase = EmailAuthFirebase();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final List<String> roles = ['Estudiante', 'Maestro'];
  final List<String> carreras = [
    'Administración',
    'Ambiental',
    'Bioquímica',
    'Electrónica',
    'Gestión empresarial',
    'Industrial',
    'Mecánica',
    'Mecatrónica',
    'Química',
    'Semiconductores',
    'Sistemas computacionales'
  ];

  String? _selectedRol;
  String? _selectedCarrera;

  @override
  Widget build(BuildContext context) {
    final dropdownRol = DropdownButtonFormField<String>(
      value: _selectedRol,
      onChanged: (String? newValue) {
        setState(() {
          _selectedRol = newValue;
        });
      },
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        hintText: 'Seleccione un rol',
        labelText: 'Rol',
        hintStyle: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
        labelStyle: TextStyle(color: Color.fromARGB(255, 7, 7, 7)),
      ),
      items: roles.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value, style: TextStyle(color: Colors.black)),
        );
      }).toList(),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Seleccione un rol';
        }
        return null;
      },
    );

    final dropdownCarrera = DropdownButtonFormField<String>(
      value: _selectedCarrera,
      onChanged: (String? newValue) {
        setState(() {
          _selectedCarrera = newValue;
        });
      },
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        hintText: 'Seleccione una carrera',
        labelText: 'Carrera',
        hintStyle: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
        labelStyle: TextStyle(color: Color.fromARGB(255, 1, 1, 1)),
      ),
      items: carreras.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value, style: TextStyle(color: Colors.black)),
        );
      }).toList(),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Seleccione una carrera';
        }
        return null;
      },
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green, // Cambia el color del AppBar a verde
        title: Text(
          'Registrarse',
          style: GoogleFonts.lobster(
            fontSize: 30, // Cambia el tamaño de la letra según lo necesites
          ),
        ),
      ),
      body: Container(
        color: Color.fromARGB(255, 251, 252,
            252), // Fondo de color sólido que cubre toda la pantalla
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),
                  const Icon(
                    Icons.person_add,
                    size: 150,
                    color: Color.fromARGB(
                        255, 52, 183, 4), // Color del icono de usuario
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: _nombreController,
                    keyboardType: TextInputType.name,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                      hintText: 'Ingresa el nombre',
                      labelText: 'Nombre',
                      hintStyle: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                      labelStyle:
                          TextStyle(color: const Color.fromARGB(255, 5, 5, 5)),
                    ),
                    style: TextStyle(color: Colors.white),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingrese el nombre';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10),
                  dropdownRol,
                  if (_selectedRol == 'Estudiante') ...[
                    SizedBox(height: 10),
                    dropdownCarrera,
                    SizedBox(height: 10),
                    TextFormField(
                      controller: _semestreController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.2),
                        hintText: 'Ingresa el semestre',
                        labelText: 'Semestre',
                        hintStyle: TextStyle(
                            color: const Color.fromARGB(255, 6, 6, 6)),
                        labelStyle: const TextStyle(
                            color: Color.fromARGB(255, 9, 9, 9)),
                      ),
                      style: TextStyle(color: Colors.white),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingrese el semestre';
                        }
                        final semestre = int.tryParse(value);
                        if (semestre == null || semestre < 1 || semestre > 12) {
                          return 'Ingrese un semestre válido (1-12)';
                        }
                        return null;
                      },
                    ),
                  ],
                  SizedBox(height: 10),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                      hintText: 'Ingresa el correo',
                      labelText: 'Correo',
                      hintStyle:
                          const TextStyle(color: Color.fromARGB(255, 9, 9, 9)),
                      labelStyle:
                          const TextStyle(color: Color.fromARGB(255, 8, 8, 8)),
                    ),
                    style: const TextStyle(color: Colors.white),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa un correo electronico';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                      hintText: 'Ingresa la contraseña',
                      labelText: 'Contraseña',
                      hintStyle:
                          const TextStyle(color: Color.fromARGB(255, 7, 7, 7)),
                      labelStyle: const TextStyle(
                          color: Color.fromARGB(255, 11, 11, 11)),
                    ),
                    style: const TextStyle(color: Colors.white),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, ingresa tu contraseña';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final user = {
                          'nombre': _nombreController.text,
                          'email': _emailController.text,
                          'rol': _selectedRol,
                          'avatar': '',
                        };
                        if (_selectedRol == 'Estudiante') {
                          user['carrera'] = _selectedCarrera;
                          user['semestre'] = _semestreController.text;
                        }
                        await _usersFirebase.insertar(user);
                        _emailAuthFirebase.signUpUser(
                          email: _emailController.text,
                          password: _passwordController.text,
                        );
                        print('Registro exitoso');
                        Navigator.pop(context);
                      }
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all<Color>(
                          const Color.fromARGB(195, 27, 98,
                              51)), // Cambia el color de fondo del botón
                      padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
                          EdgeInsets.all(10)), // Ajusta el padding del botón
                      textStyle: WidgetStateProperty.all<TextStyle>(const TextStyle(
                          fontSize:
                              30)), // Cambia el estilo del texto dentro del botón
                      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  10))), // Agrega bordes redondeados al botón
                      // Puedes agregar más propiedades aquí según tus necesidades de decoración
                    ),
                    child: const Text(
                      'Registrarse',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize:
                              20), // Cambia el color del texto dentro del botón
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
