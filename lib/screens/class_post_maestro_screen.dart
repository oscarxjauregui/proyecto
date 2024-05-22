import 'package:flutter/material.dart';

class ClassPostMaestroScreen extends StatefulWidget {
  final String classId;
  final String myUserId;
  final Map<String, dynamic> publicacion;
  const ClassPostMaestroScreen({
    required this.myUserId,
    required this.classId,
    required this.publicacion,
    Key? key,
  }) : super(key: key);

  @override
  State<ClassPostMaestroScreen> createState() => _ClassPostMaestroScreenState();
}

class _ClassPostMaestroScreenState extends State<ClassPostMaestroScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Maestro'),
      ),
    );
  }
}
