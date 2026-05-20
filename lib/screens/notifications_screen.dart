import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../theme/colors.dart';
import 'chat_screen.dart';
import 'confirmar_unirse_screen.dart';
import '../main.dart'; // 🔹 IMPORTANTE: Importamos las llaves globales

// 🔹 LÓGICA PURA PARA PRUEBAS (Decide la pantalla destino)
class NotificationLogic {
  static String determinarPantallaDestino(String? type) {
    if (type == 'chat') return 'ChatScreen';
    if (type == 'match' || type == 'event') return 'ConfirmarUnirseScreen';
    return 'Unknown';
  }
}

// 🔹 ENRUTADOR CENTRAL DE NOTIFICACIONES (Sin Context)
class NotificationHelper {
  static Future<void> handleNotificationTap(Map<String, dynamic> data) async {
    final type = data['type']?.toString();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || type == null) return;

    final pantallaDestino = NotificationLogic.determinarPantallaDestino(type);

    try {
      if (pantallaDestino == 'ChatScreen') {
        final chatId = data['chatId'];
        if (chatId == null) return;

        final chatDoc = await FirebaseFirestore.instance.collection('chats').doc(chatId).get();
        if (chatDoc.exists) {
          final chatData = chatDoc.data() as Map<String, dynamic>;
          final participants = List<String>.from(chatData['participants'] ?? []);
          
          final otherUserEmail = participants.firstWhere((e) => e != currentUser.email, orElse: () => '');
          
          if (otherUserEmail.isNotEmpty) {
            final userNames = Map<String, dynamic>.from(chatData['userNames'] ?? {});
            final userRoles = Map<String, dynamic>.from(chatData['userRoles'] ?? {});
            
            // 🔹 FIX: Navegamos usando navigatorKey en lugar de context
            navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => ChatScreen(
              otherUserEmail: otherUserEmail,
              otherUserName: userNames[otherUserEmail] ?? 'Usuario',
              otherUserRole: userRoles[otherUserEmail]?.toString(),
            )));
          }
        }
      } else if (pantallaDestino == 'ConfirmarUnirseScreen') {
        final isEvent = type == 'event';
        final targetId = data['matchId'] ?? data['eventId']; 
        if (targetId == null) return;

        final collectionName = isEvent ? 'events' : 'matches';
        final doc = await FirebaseFirestore.instance.collection(collectionName).doc(targetId).get();
        
        if (doc.exists) {
          // 🔹 FIX: Navegamos usando navigatorKey
          navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => ConfirmarUnirseScreen(
            matchId: targetId,
            matchData: doc.data() as Map<String, dynamic>,
          )));
        } else {
          // 🔹 FIX: Usamos scaffoldMessengerKey
          scaffoldMessengerKey.currentState?.showSnackBar(
            const SnackBar(content: Text('Esta actividad ya no está disponible.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error al redirigir desde notificación: $e');
    }
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final screenWidth = size.width;
    final screenHeight = size.height;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Notificaciones',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: (screenWidth * 0.05).clamp(18.0, 22.0),
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: user == null
          ? const Center(child: Text('Inicia sesión para ver tus notificaciones'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('notifications')
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('Error al cargar'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return _buildEmptyState(screenWidth, screenHeight);

                return ListView.builder(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    if (data is! Map<String, dynamic>) return const SizedBox.shrink();
                    
                    return GestureDetector(
                      onTap: () {
                        // Al estar dentro de la pantalla, podemos llamar la lógica
                        NotificationHelper.handleNotificationTap(data);
                      },
                      child: _buildNotificationCard(
                        data,
                        screenWidth: screenWidth,
                        screenHeight: screenHeight,
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> data, {required double screenWidth, required double screenHeight}) {
    final rawDate = data['date'];
    final date = rawDate is Timestamp ? rawDate.toDate() : DateTime.now();

    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.014),
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: screenWidth * 0.025,
            offset: Offset(0, screenHeight * 0.005),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(screenWidth * 0.025),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_active_outlined, color: AppColors.primary, size: screenWidth * 0.05),
          ),
          SizedBox(width: screenWidth * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['title']?.toString() ?? 'Notificación',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: (screenWidth * 0.04).clamp(14.0, 17.0)),
                ),
                SizedBox(height: screenHeight * 0.005),
                Text(
                  data['message']?.toString() ?? '',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: (screenWidth * 0.035).clamp(12.0, 15.0)),
                ),
                SizedBox(height: screenHeight * 0.009),
                Text(
                  DateFormat('dd MMM, hh:mm a', 'es').format(date),
                  style: TextStyle(color: Colors.grey, fontSize: (screenWidth * 0.03).clamp(10.0, 13.0)),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildEmptyState(double screenWidth, double screenHeight) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: screenWidth * 0.2, color: Colors.grey.withValues(alpha: 0.5)),
          SizedBox(height: screenHeight * 0.018),
          Text('No tienes notificaciones aún', style: TextStyle(color: Colors.grey, fontSize: (screenWidth * 0.04).clamp(14.0, 17.0))),
        ],
      ),
    );
  }
}