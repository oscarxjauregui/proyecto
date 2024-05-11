import 'package:flutter/material.dart';

class HomeClienteScreen extends StatefulWidget {
  final String myIdUser;

  const HomeClienteScreen({required this.myIdUser, Key? key}) : super(key: key);

  @override
  State<HomeClienteScreen> createState() => _HomeClienteScreenState();
}

class _HomeClienteScreenState extends State<HomeClienteScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Cliente'),
      ),
    );
  }
}
