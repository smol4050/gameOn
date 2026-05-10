import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/colors.dart'; // Ajusta la ruta a tus colores

class GlobalNotificationWrapper extends StatefulWidget {
  final Widget child; // Recibe tu pantalla principal

  const GlobalNotificationWrapper({super.key, required this.child});

  @override
  State<GlobalNotificationWrapper> createState() => _GlobalNotificationWrapperState();
}

class _GlobalNotificationWrapperState extends State<GlobalNotificationWrapper> {
  // Guardamos la hora en la que se abre la app para NO mostrar notificaciones viejas
  final DateTime _appStartTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _listenForNewNotifications();
  }

  void _listenForNewNotifications() {
    // 1. Verificamos si hay un usuario logueado en tiempo real
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        // 2. Escuchamos la colección de notificaciones SOLO para ese usuario
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .where('date', isGreaterThan: _appStartTime) // ¡El truco! Solo las creadas después de abrir la app
            .snapshots()
            .listen((snapshot) {
              
          // 3. Por cada cambio en la base de datos...
          for (var change in snapshot.docChanges) {
            // Si es un documento "Añadido" (una nueva notificación en vivo)
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data() ?? {};
              _showInAppNotification(data['title'], data['message']);
            }
          }
        });
      }
    });
  }

  void _showInAppNotification(String? title, String? message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 10,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFF232734), // Fondo oscuro Premium
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_active_rounded, 
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title ?? 'Nueva notificación',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                  ),
                  if (message != null && message.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
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
  Widget build(BuildContext context) {
    // Retornamos el hijo intacto. Este widget es invisible, solo procesa lógica de fondo.
    return widget.child; 
  }
}