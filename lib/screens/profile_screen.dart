import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  final String myUserId;
  final String userId;
  const ProfileScreen({required this.myUserId, required this.userId, Key? key})
      : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userId),
      ),
    );
  }
}
