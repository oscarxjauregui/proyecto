import 'package:flutter/material.dart';

class MessageScreen extends StatefulWidget {
  final String myUserId;
  final String userId;
  const MessageScreen({required this.myUserId, required this.userId, Key? key})
      : super(key: key);

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userId),
      ),
    );
  }
}
