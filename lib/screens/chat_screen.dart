import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../theme/colors.dart';
import 'user_badge_name.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MessageBubble extends StatelessWidget {
  final bool isMe;
  final String message;
  final String time;
  final double screenWidth;
  final double screenHeight;

  const MessageBubble({
    super.key,
    required this.isMe,
    required this.message,
    required this.time,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: (screenHeight * 0.016).r),
        constraints: BoxConstraints(maxWidth: screenWidth * 0.72),
        padding: EdgeInsets.symmetric(
          horizontal: (screenWidth * 0.04).r,
          vertical: (screenHeight * 0.014).r,
        ),
        decoration: BoxDecoration(
          gradient: isMe
              ? const LinearGradient(
                  colors: [AppColors.primary, AppColors.primary])
              : null,
          color: isMe ? null : AppColors.chatBubbleOther,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(screenWidth * 0.05),
            topRight: Radius.circular(screenWidth * 0.05),
            bottomLeft:
                Radius.circular(isMe ? screenWidth * 0.05 : screenWidth * 0.01),
            bottomRight:
                Radius.circular(isMe ? screenWidth * 0.01 : screenWidth * 0.05),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(
                color: AppColors.textLight.withValues(alpha: 0.9),
                fontSize: (screenWidth * 0.038).clamp(13.0, 16.0).sp,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: (screenHeight * 0.007).h),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                time,
                style: TextStyle(
                  color: AppColors.textLight.withValues(alpha: 0.7),
                  fontSize: (screenWidth * 0.028).clamp(10.0, 12.0).sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  static String? activeChatId;

  final String otherUserEmail;
  final String otherUserName;
  final String? otherUserRole;

  const ChatScreen({
    super.key,
    required this.otherUserEmail,
    required this.otherUserName,
    this.otherUserRole,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;

  late String chatId;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    final emails = [currentUser?.email ?? '', widget.otherUserEmail]..sort();
    chatId = emails.join('_');
    ChatScreen.activeChatId = chatId;
  }

  @override
  void dispose() {
    ChatScreen.activeChatId = null;
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    final senderEmail = currentUser?.email;
    if (text.isEmpty ||
        currentUser == null ||
        senderEmail == null ||
        _isSending) {
      return;
    }

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      final chatRef =
          FirebaseFirestore.instance.collection('chats').doc(chatId);

      await chatRef.collection('messages').add({
        'text': text,
        'senderEmail': senderEmail,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Obtener el rol del usuario actual para guardarlo en la metadata del chat
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      final currentUserRole =
          currentUserDoc.data()?['role']?.toString() ?? 'normal';

      await chatRef.set({
        'participants': [senderEmail, widget.otherUserEmail],
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'userNames': {
          senderEmail: currentUser?.displayName ?? 'Usuario',
          widget.otherUserEmail: widget.otherUserName,
        },
        'userRoles': {
          senderEmail: currentUserRole,
          widget.otherUserEmail: widget.otherUserRole ?? 'normal',
        }
      }, SetOptions(merge: true));

      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: widget.otherUserEmail)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        final otherUserId = userQuery.docs.first.id;
        final myName = currentUser?.displayName ?? 'Un usuario';

        await FirebaseFirestore.instance
            .collection('users')
            .doc(otherUserId)
            .collection('notifications')
            .add({
          'title': 'Nuevo mensaje de $myName',
          'message': text,
          'date': FieldValue.serverTimestamp(),
          'type': 'chat',
          'chatId': chatId,
          'read': false,
        });
      }
    } catch (e) {
      if (!mounted) return;
      _messageController.text = text;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('No pudimos enviar el mensaje: $e'),
            backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final screenWidth = size.width;
    final screenHeight = size.height;
    final inputPadding = screenWidth * 0.04;
    final inputHeight = (screenHeight * 0.058).clamp(46.0, 56.0);

    return Scaffold(
      backgroundColor: AppColors.chatBackground,
      appBar: AppBar(
        backgroundColor: AppColors.chatBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: UserBadgeName(
          name: widget.otherUserName,
          role: widget.otherUserRole,
          textStyle: TextStyle(
            color: AppColors.textLight,
            fontWeight: FontWeight.bold,
            fontSize: (screenWidth * 0.045).clamp(16.0, 20.0).sp,
          ),
          iconSize: 20.0,
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('No pudimos cargar el chat.',
                        style: TextStyle(color: AppColors.textSecondary)),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay mensajes aun. Di hola!',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  padding: EdgeInsets.symmetric(
                      horizontal: (screenWidth * 0.04).r,
                      vertical: (screenHeight * 0.024).r),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final rawData = messages[index].data();
                    if (rawData is! Map<String, dynamic>) {
                      return const SizedBox.shrink();
                    }
                    final isMe = rawData['senderEmail'] == currentUser?.email;
                    final text = rawData['text']?.toString() ?? '';

                    String timeStr = '';
                    final timestamp = rawData['timestamp'];
                    if (timestamp is Timestamp) {
                      timeStr = DateFormat('HH:mm').format(timestamp.toDate());
                    }

                    return MessageBubble(
                      isMe: isMe,
                      message: text,
                      time: timeStr,
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: inputPadding.r, vertical: (screenHeight * 0.014).r),
            decoration: BoxDecoration(
              color: AppColors.chatSurface,
              border: Border(
                  top: BorderSide(
                      color: AppColors.textSecondary.withValues(alpha: 0.1))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      constraints: BoxConstraints(minHeight: inputHeight),
                      decoration: BoxDecoration(
                        color: AppColors.chatBackground,
                        borderRadius:
                            BorderRadius.circular((screenWidth * 0.06).r),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: AppColors.textLight),
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Escribe un mensaje...',
                          hintStyle:
                              const TextStyle(color: AppColors.textSecondary),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: (screenWidth * 0.05).r,
                            vertical: (inputHeight * 0.26).r,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: (screenWidth * 0.03).w),
                  GestureDetector(
                    onTap: _isSending ? null : _sendMessage,
                    child: Container(
                      padding: EdgeInsets.all((screenWidth * 0.035).r),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isSending
                            ? AppColors.textSecondary
                            : AppColors.primary,
                      ),
                      child: Icon(
                        Icons.send_rounded,
                        color: AppColors.textLight,
                        size: (screenWidth * 0.05).r,
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
