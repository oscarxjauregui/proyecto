import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
      ),
      items: roles.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
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
      ),
      items: carreras.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
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
        title: Text('Registrarse'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 80),
                TextFormField(
                  controller: _nombreController,
                  keyboardType: TextInputType.name,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Ingresa el nombre',
                    labelText: 'Nombre',
                  ),
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
                      hintText: 'Ingresa el semestre',
                      labelText: 'Semestre',
                    ),
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa un correo electronico';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Ingresa el correo',
                    labelText: 'Correo',
                  ),
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingresa tu contraseña';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Ingresa la contraseña',
                    labelText: 'Contraseña',
                  ),
                ),
                SizedBox(height: 10),
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
                  child: Text('Registrarse'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
