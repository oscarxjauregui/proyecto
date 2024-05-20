import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:proyecto/screens/message_screen.dart';
import 'package:proyecto/services/avatar_firebase.dart';

class MessageListScreen extends StatefulWidget {
  final String myUserId;

  const MessageListScreen({Key? key, required this.myUserId}) : super(key: key);

  @override
  State<MessageListScreen> createState() => _MessageListScreenState();
}

class _MessageListScreenState extends State<MessageListScreen> {
  final Map<String, String> _userNames = {};
  final Map<String, Map<String, dynamic>> _lastMessages = {};
  final Set<String> _displayedUserIds = {};
  final AvatarFirebase _avatarFirebase = AvatarFirebase();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mensajes'),
      ),
      body: _buildMessageList(),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('messages')
          .where('ids', arrayContains: widget.myUserId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final messages = snapshot.data?.docs ?? [];
        _lastMessages.clear(); // Limpiar mensajes para evitar duplicados

        for (final message in messages) {
          final messageData = message.data() as Map<String, dynamic>;
          final ids = List<String>.from(messageData['ids'] ?? []);
          final otherUserId =
              ids.firstWhere((id) => id != widget.myUserId, orElse: () => '');

          if (otherUserId.isNotEmpty &&
              !_lastMessages.containsKey(otherUserId)) {
            final messageText = messageData['message'] ?? '';
            final messageDate = messageData['timestamp'] != null
                ? (messageData['timestamp'] as Timestamp).toDate()
                : null;

            _lastMessages[otherUserId] = {
              'message': messageText,
              'date': messageDate,
            };
          }
        }

        return ListView.builder(
          itemCount: _lastMessages.length,
          itemBuilder: (context, index) {
            final otherUserId = _lastMessages.keys.elementAt(index);
            final userName = _userNames[otherUserId] ?? '';

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(otherUserId)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink(); // Esperar los datos
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                final userData = snapshot.data?.data() as Map<String, dynamic>;
                final userName = userData['nombre'] ?? 'Usuario';
                _userNames[otherUserId] = userName;

                final lastMessageData = _lastMessages[otherUserId];
                final lastMessage = lastMessageData != null
                    ? lastMessageData['message'] ?? 'No hay mensajes'
                    : 'No hay mensajes';
                final lastMessageDate =
                    lastMessageData != null ? lastMessageData['date'] : null;

                return _buildListTile(context, userName, lastMessage,
                    lastMessageDate, otherUserId);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildListTile(BuildContext context, String userName,
      String lastMessage, dynamic lastMessageDate, String otherUserId) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessageScreen(
              userId: otherUserId,
              myUserId: widget.myUserId,
            ),
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.all(8.0),
        child: ListTile(
          leading: FutureBuilder<DocumentSnapshot>(
            future: _avatarFirebase.consultarAvatar(otherUserId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircleAvatar(
                  child: Icon(
                    Icons.person,
                    size: 35,
                  ),
                );
              }
              if (snapshot.hasError) {
                return CircleAvatar(
                  child: Icon(
                    Icons.person,
                    size: 35,
                  ),
                );
              }

              final avatarData = snapshot.data?.data() as Map<String, dynamic>?;

              if (avatarData != null && avatarData.containsKey('imageUrl')) {
                return CircleAvatar(
                  backgroundImage:
                      NetworkImage(avatarData['imageUrl'] as String),
                );
              } else {
                return CircleAvatar(
                  child: Icon(
                    Icons.person,
                    size: 35,
                  ),
                );
              }
            },
          ),
          title: Text(userName),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(lastMessage),
              if (lastMessageDate != null)
                Text(
                  DateFormat('dd-MM-yyyy HH:mm')
                      .format(lastMessageDate as DateTime),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
