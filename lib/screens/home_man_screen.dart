import 'package:flutter/material.dart';

class HomeManScreen extends StatefulWidget {
  final String myIdUser;

  const HomeManScreen({required this.myIdUser, Key? key}) : super(key: key);

  @override
  State<HomeManScreen> createState() => _HomeManScreenState();
}

class _HomeManScreenState extends State<HomeManScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Manicurista'),
      ),
    );
  }
}
