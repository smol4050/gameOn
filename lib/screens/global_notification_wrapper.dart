import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/colors.dart';
import 'chat_screen.dart';

class GlobalNotificationWrapper extends StatefulWidget {
  final Widget child;

  const GlobalNotificationWrapper({super.key, required this.child});

  @override
  State<GlobalNotificationWrapper> createState() =>
      _GlobalNotificationWrapperState();
}

class _GlobalNotificationWrapperState extends State<GlobalNotificationWrapper> {
  final DateTime _appStartTime = DateTime.now();
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<QuerySnapshot>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _listenForNewNotifications();
  }

  void _listenForNewNotifications() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      _notificationSubscription?.cancel();
      _notificationSubscription = null;

      if (user == null) return;

      _notificationSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('date', isGreaterThan: _appStartTime)
          .snapshots()
          .listen((snapshot) {
        for (final change in snapshot.docChanges) {
          if (change.type != DocumentChangeType.added) continue;
          final data = change.doc.data() ?? {};
          if (data['type'] == 'chat' &&
              data['chatId'] == ChatScreen.activeChatId) {
            continue;
          }
          _showInAppNotification(
            data['title']?.toString(),
            data['message']?.toString(),
          );
        }
      });
    });
  }

  void _showInAppNotification(String? title, String? message) {
    if (!mounted) return;

    final size = MediaQuery.sizeOf(context);
    final screenWidth = size.width;
    final screenHeight = size.height;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 10,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.05),
        ),
        backgroundColor: const Color(0xFF232734),
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            Container(
              padding: EdgeInsets.all(screenWidth * 0.025),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_active_rounded,
                color: AppColors.primary,
                size: screenWidth * 0.058,
              ),
            ),
            SizedBox(width: screenWidth * 0.035),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title ?? 'Nueva notificacion',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: (screenWidth * 0.038).clamp(13.0, 16.0),
                    ),
                  ),
                  if (message != null && message.isNotEmpty) ...[
                    SizedBox(height: screenHeight * 0.005),
                    Text(
                      message,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: (screenWidth * 0.032).clamp(11.0, 14.0),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
