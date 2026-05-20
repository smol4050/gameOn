import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/colors.dart';
import 'chat_screen.dart';
import 'notifications_screen.dart';

// 🔹 LÓGICA PURA EXTRAÍDA PARA TESTING (Cumple con los criterios de testing aislado)
class NotificationBannerLogic {
  static bool deberiaMostrarNotificacion({
    required DateTime fechaNotificacion,
    required DateTime fechaInicioApp,
    required String? tipo,
    required String? chatIdActivo,
    required String? chatIdNotificacion,
  }) {
    // Regla 1: Ignorar si la notificación fue emitida antes de encender la aplicación
    if (fechaNotificacion.isBefore(fechaInicioApp)) return false;
    
    // Regla 2: Si el usuario ya está chateando activamente en esa misma sala, no interrumpir con un PushUp
    if (tipo == 'chat' && chatIdActivo != null && chatIdActivo == chatIdNotificacion) {
      return false;
    }
    
    return true;
  }
}

class GlobalNotificationWrapper extends StatefulWidget {
  final Widget child;
  const GlobalNotificationWrapper({super.key, required this.child});

  @override
  State<GlobalNotificationWrapper> createState() => _GlobalNotificationWrapperState();
}

class _GlobalNotificationWrapperState extends State<GlobalNotificationWrapper> with SingleTickerProviderStateMixin {
  final DateTime _appStartTime = DateTime.now();
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<QuerySnapshot>? _notificationSubscription;

  // Variables de control del PushUp superior personalizado
  Map<String, dynamic>? _currentNotificationData;
  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    
    // Configuración de la física y duración del banner desplegable
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.6), // Totalmente oculto arriba del notch/isla dinámica
      end: Offset.zero,             // Posición visible natural de la UI
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack, // Efecto rebote premium de Push Notification
    ));

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
          
          final rawDate = data['date'];
          final dateNotif = rawDate is Timestamp ? rawDate.toDate() : DateTime.now();

          // Invocación de la lógica pura para decidir si la alerta debe materializarse
          final mostrar = NotificationBannerLogic.deberiaMostrarNotificacion(
            fechaNotificacion: dateNotif,
            fechaInicioApp: _appStartTime,
            tipo: data['type']?.toString(),
            chatIdActivo: ChatScreen.activeChatId,
            chatIdNotificacion: data['chatId']?.toString(),
          );

          if (mostrar) {
            _triggerPushUpNotification(data);
          }
        }
      });
    });
  }

  void _triggerPushUpNotification(Map<String, dynamic> data) {
    _dismissTimer?.cancel();
    
    setState(() {
      _currentNotificationData = data;
    });

    // Desplegar banner hacia abajo
    _animationController.forward(from: 0.0);

    // Desvanecimiento automático a los 5 segundos de no interactuar
    _dismissTimer = Timer(const Duration(seconds: 5), () {
      _ocultarBanner();
    });
  }

  void _ocultarBanner() {
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _currentNotificationData = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _notificationSubscription?.cancel();
    _dismissTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final screenWidth = size.width;

    return Stack(
      children: [
        // Capa 0: Mantiene la persistencia de toda la navegación de la App intacta
        widget.child,

        // Capa 1: Inyección aérea del banner PushUp por encima de los Scaffold y NavBars
        if (_currentNotificationData != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: SlideTransition(
                position: _offsetAnimation,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: 8),
                  child: GestureDetector(
                    onTap: () {
                      final data = _currentNotificationData;
                      _ocultarBanner();
                      if (data != null) {
                        NotificationHelper.handleNotificationTap(data);
                      }
                    },
                    child: Material(
                      elevation: 12,
                      color: const Color(0xFF232734),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
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
                                    _currentNotificationData!['title']?.toString() ?? 'Notificación',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 15,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _currentNotificationData!['message']?.toString() ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      decoration: TextDecoration.none,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.touch_app_rounded, color: Colors.white30, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}