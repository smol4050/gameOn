import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../theme/colors.dart'; // Ajusta la ruta a tus colores

// ==========================================
// 1. TU COMPONENTE MESSAGE BUBBLE
// ==========================================
class MessageBubble extends StatelessWidget {
  final bool isMe;
  final String message;
  final String time;

  const MessageBubble({
    super.key,
    required this.isMe,
    required this.message,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          gradient: isMe
              ? const LinearGradient(
                  colors: [
                    Color(0xFF7B61FF),
                    Color(0xFF5B8CFF),
                  ],
                )
              : null,
          color: isMe ? null : const Color(0xFF232734),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                time,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. PANTALLA PRINCIPAL DEL CHAT (1 a 1)
// ==========================================
class ChatScreen extends StatefulWidget {
  static String? activeChatId;

  final String otherUserEmail; // El email de la persona con la que chateas
  final String otherUserName; // Nombre para mostrar en el AppBar

  const ChatScreen({
    super.key,
    required this.otherUserEmail,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;
  
  late String chatId;

  @override
  void initState() {
    super.initState();
    // Generamos un ID único combinando los emails alfabéticamente
    final emails = [currentUser?.email ?? '', widget.otherUserEmail];
    emails.sort(); 
    chatId = emails.join('_'); // Ejemplo: a@gmail.com_b@gmail.com
    
    ChatScreen.activeChatId = chatId; // Registramos que estamos en este chat
  }

  @override
  void dispose() {
    ChatScreen.activeChatId = null; // Limpiamos al salir
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || currentUser == null) return;

    _messageController.clear(); 

    // 1. Guardamos el mensaje en el chat combinado
    await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      'participants': [currentUser!.email, widget.otherUserEmail],
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'userNames': {
        currentUser!.email: currentUser!.displayName ?? 'Usuario',
        widget.otherUserEmail: widget.otherUserName,
      }
    }, SetOptions(merge: true));

    // 2. Buscamos el ID del otro usuario basado en su email para enviarle la notificación
    final userQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: widget.otherUserEmail)
        .limit(1)
        .get();

    if (userQuery.docs.isNotEmpty) {
      final otherUserId = userQuery.docs.first.id;
      final myName = currentUser!.displayName ?? 'Un usuario';

      // 3. Le enviamos la notificación
      await FirebaseFirestore.instance
          .collection('users')
          .doc(otherUserId)
          .collection('notifications')
          .add({
        'title': 'Nuevo mensaje de $myName',
        'message': text,
        'date': FieldValue.serverTimestamp(),
        'type': 'chat', // Clave para el filtro del Wrapper
        'chatId': chatId, // El ID del chat para silenciarlo si está abierto
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181A20),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181A20),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.otherUserName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ZONA DE MENSAJES
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay mensajes aún. ¡Di hola!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true, 
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;
                    // Comparamos usando el email
                    final bool isMe = data['senderEmail'] == currentUser?.email;
                    final text = data['text'] ?? '';
                    
                    String timeStr = '';
                    if (data['timestamp'] != null) {
                      final date = (data['timestamp'] as Timestamp).toDate();
                      timeStr = DateFormat('HH:mm').format(date);
                    }

                    return MessageBubble(
                      isMe: isMe,
                      message: text,
                      time: timeStr,
                    );
                  },
                );
              },
            ),
          ),

          // ZONA DE INPUT
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF232734),
              border: Border(
                top: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF181A20),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Escribe un mensaje...',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}