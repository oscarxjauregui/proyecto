import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:proyecto/services/email_auth_firebase.dart';
import 'package:proyecto/services/user_firebase.dart';

class SignUpAuthScreen extends StatefulWidget {
  final String nombre;
  final String email;
  final String fotoUrl;

  const SignUpAuthScreen({
    required this.nombre,
    required this.email,
    required this.fotoUrl,
    Key? key,
  }) : super(key: key);

  @override
  State<SignUpAuthScreen> createState() => _SignUpAuthScreenState();
}

class _SignUpAuthScreenState extends State<SignUpAuthScreen> {
  final UsersFirebase _usersFirebase = UsersFirebase();
  late TextEditingController _nombreController;
  late TextEditingController _emailController;
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
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.nombre);
    _emailController = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _semestreController.dispose();
    super.dispose();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> insertar(Map<String, dynamic> data) async {
    try {
      DocumentReference docRef = await _firestore.collection('users').add(data);
      return docRef.id; // Devuelve el ID del documento creado
    } catch (e) {
      throw 'Error al insertar en Firestore: $e';
    }
  }

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
        backgroundColor: Colors.green,
        title: Text(
          'Registrarse',
          style: GoogleFonts.lobster(
            fontSize: 30,
          ),
        ),
      ),
      body: Container(
        color: Color.fromARGB(255, 251, 252, 252),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),
                  if (widget.fotoUrl.isNotEmpty)
                    CircleAvatar(
                      backgroundImage: NetworkImage(widget.fotoUrl),
                      radius: 50,
                    ),
                  const SizedBox(height: 20),
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
                          TextStyle(color: Color.fromARGB(255, 5, 5, 5)),
                    ),
                    style: TextStyle(color: Colors.black),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingrese el nombre';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  dropdownRol,
                  if (_selectedRol == 'Estudiante') ...[
                    const SizedBox(height: 10),
                    dropdownCarrera,
                    const SizedBox(height: 10),
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
                      style: TextStyle(color: Colors.black),
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
                  const SizedBox(height: 10),
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
                    style: const TextStyle(color: Colors.black),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa un correo electronico';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  // TextFormField(
                  //   controller: _passwordController,
                  //   obscureText: true,
                  //   decoration: InputDecoration(
                  //     border: OutlineInputBorder(),
                  //     filled: true,
                  //     fillColor: Colors.white.withOpacity(0.2),
                  //     hintText: 'Ingresa la contraseña',
                  //     labelText: 'Contraseña',
                  //     hintStyle:
                  //         const TextStyle(color: Color.fromARGB(255, 7, 7, 7)),
                  //     labelStyle: const TextStyle(
                  //         color: Color.fromARGB(255, 11, 11, 11)),
                  //   ),
                  //   style: const TextStyle(color: Colors.black),
                  //   validator: (value) {
                  //     if (value == null || value.isEmpty) {
                  //       return 'Por favor, ingresa tu contraseña';
                  //     }
                  //     return null;
                  //   },
                  // ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final user = {
                          'nombre': _nombreController.text,
                          'email': _emailController.text,
                          'rol': _selectedRol,
                          'avatar': widget.fotoUrl,
                        };
                        if (_selectedRol == 'Estudiante') {
                          user['carrera'] = _selectedCarrera;
                          user['semestre'] = _semestreController.text;
                        }
                        String userId = await _usersFirebase.insertarObtId(user);
                        // Imprimir el ID del documento creado en la colección 'users'
                        print('Registro exitoso');
                        print('ID del documento creado en users: $userId');
                        _emailAuthFirebase.signUpUser(
                          email: _emailController.text,
                          password: _passwordController.text,
                        );
                        print('Registro exitoso');
                        print('Id: $userId');
                        Navigator.pop(context);
                      }
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                          const Color.fromARGB(195, 27, 98, 51)),
                      padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                          EdgeInsets.all(10)),
                      textStyle: MaterialStateProperty.all<TextStyle>(
                          const TextStyle(fontSize: 30)),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10))),
                    ),
                    child: const Text(
                      'Registrarse',
                      style: TextStyle(color: Colors.white, fontSize: 20),
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
