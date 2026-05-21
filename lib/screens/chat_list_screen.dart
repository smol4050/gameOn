import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../theme/colors.dart';
import 'chat_screen.dart';
import 'user_badge_name.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final screenWidth = size.width;
    final screenHeight = size.height;
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentEmail = currentUser?.email;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.textLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Mensajes',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: (screenWidth * 0.055).clamp(18.0, 23.0).sp,
          ),
        ),
        centerTitle: true,
      ),
      body: currentEmail == null
          ? const Center(child: Text('Inicia sesion para ver tus mensajes.'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('participants', arrayContains: currentEmail)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                      child: Text('No pudimos cargar tus chats.'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState(screenWidth, screenHeight);
                }

                final docs = snapshot.data!.docs.toList();
                docs.sort((a, b) {
                  final dataA = a.data() as Map<String, dynamic>? ?? {};
                  final dataB = b.data() as Map<String, dynamic>? ?? {};
                  final timeA = dataA['lastMessageTime'] as Timestamp?;
                  final timeB = dataB['lastMessageTime'] as Timestamp?;

                  if (timeA == null && timeB == null) return 0;
                  if (timeA == null) return 1;
                  if (timeB == null) return -1;
                  return timeB.compareTo(timeA);
                });

                return ListView.builder(
                  padding: EdgeInsets.all((screenWidth * 0.05).r),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final rawData = docs[index].data();
                    if (rawData is! Map<String, dynamic>) {
                      return const SizedBox.shrink();
                    }

                    final participants =
                        List<String>.from(rawData['participants'] ?? []);
                    participants.remove(currentEmail);
                    final otherUserEmail = participants.isNotEmpty
                        ? participants.first
                        : 'Desconocido';
                    final userNames =
                        rawData['userNames'] as Map<String, dynamic>? ?? {};
                    final otherUserName =
                        userNames[otherUserEmail]?.toString() ??
                            otherUserEmail.split('@')[0];
                    final userRoles =
                        rawData['userRoles'] as Map<String, dynamic>? ?? {};
                    final otherUserRole = userRoles[otherUserEmail]?.toString();
                    final lastMessage =
                        rawData['lastMessage']?.toString() ?? '';
                    final timestamp = rawData['lastMessageTime'] as Timestamp?;

                    var timeStr = '';
                    if (timestamp != null) {
                      final date = timestamp.toDate();
                      final now = DateTime.now();
                      timeStr = date.day == now.day &&
                              date.month == now.month &&
                              date.year == now.year
                          ? DateFormat('HH:mm').format(date)
                          : DateFormat('dd MMM').format(date);
                    }

                    return _buildChatTile(
                      context,
                      otherUserEmail,
                      otherUserName,
                      lastMessage,
                      timeStr,
                      otherUserRole,
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildChatTile(
    BuildContext context,
    String email,
    String name,
    String lastMessage,
    String time,
    String? role, {
    required double screenWidth,
    required double screenHeight,
  }) {
    final avatarSize = (screenWidth * 0.14).clamp(50.0, 60.0);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
                otherUserEmail: email,
                otherUserName: name,
                otherUserRole: role),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: (screenHeight * 0.018).r),
        padding: EdgeInsets.all((screenWidth * 0.04).r),
        decoration: BoxDecoration(
          color: AppColors.textLight,
          borderRadius: BorderRadius.circular((screenWidth * 0.06).r),
          boxShadow: [
            BoxShadow(
              color: AppColors.textSecondary.withValues(alpha: 0.03),
              blurRadius: screenWidth * 0.025,
              offset: Offset(0, screenHeight * 0.005),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: (screenWidth * 0.055).clamp(18.0, 23.0).sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            SizedBox(width: (screenWidth * 0.04).w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: UserBadgeName(
                          name: name,
                          role: role,
                          textStyle: TextStyle(
                            fontSize:
                                (screenWidth * 0.043).clamp(15.0, 18.0).sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      SizedBox(width: (screenWidth * 0.02).w),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: (screenWidth * 0.03).clamp(10.0, 13.0).sp,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: (screenHeight * 0.007).h),
                  Text(
                    lastMessage,
                    style: TextStyle(
                      fontSize: (screenWidth * 0.035).clamp(12.0, 15.0).sp,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(double screenWidth, double screenHeight) {
    final iconBox = screenWidth * 0.25;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: (screenWidth * 0.1).r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: iconBox.w,
              height: iconBox.h,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.chat_bubble_outline_rounded,
                  size: (iconBox * 0.4).r, color: AppColors.primary),
            ),
            SizedBox(height: (screenHeight * 0.028).h),
            Text(
              'No tienes mensajes',
              style: TextStyle(
                fontSize: (screenWidth * 0.05).clamp(18.0, 22.0).sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: (screenHeight * 0.012).h),
            Text(
              'Tus conversaciones con otros jugadores apareceran aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: (screenWidth * 0.038).clamp(13.0, 16.0).sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
