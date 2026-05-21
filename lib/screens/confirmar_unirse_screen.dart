import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../theme/colors.dart';
import 'main_navigation_screen.dart';
import 'chat_screen.dart';
import 'user_badge_name.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ConfirmarUnirseScreen extends StatefulWidget {
  final String matchId;
  final Map<String, dynamic> matchData;
  final bool isEvent;

  const ConfirmarUnirseScreen({
    super.key,
    required this.matchId,
    required this.matchData,
    this.isEvent = false,
  });

  @override
  State<ConfirmarUnirseScreen> createState() => _ConfirmarUnirseScreenState();
}

class _ConfirmarUnirseScreenState extends State<ConfirmarUnirseScreen> {
  bool _isJoined = false;
  bool _isLoading = false;
  String _userRole = 'normal';

  // Nuevas variables para almacenar los datos en vivo
  String _collectionName = 'matches';
  Map<String, dynamic> _liveData = {};
  bool _isFetchingData = true;

  @override
  void initState() {
    super.initState();
    _liveData = Map.from(widget.matchData);
    _loadLiveMatchData();
  }

  // Descubre si es un partido o un evento y descarga la info completa
  Future<void> _loadLiveMatchData() async {
    try {
      var doc = await FirebaseFirestore.instance
          .collection('matches')
          .doc(widget.matchId)
          .get();
      if (doc.exists) {
        _collectionName = 'matches';
        if (mounted) setState(() => _liveData = doc.data() ?? {});
      } else {
        doc = await FirebaseFirestore.instance
            .collection('events')
            .doc(widget.matchId)
            .get();
        if (doc.exists) {
          _collectionName = 'events';
          if (mounted) setState(() => _liveData = doc.data() ?? {});
        }
      }
    } catch (e) {
      debugPrint('Error cargando datos en vivo: $e');
    } finally {
      if (mounted) {
        setState(() => _isFetchingData = false);
        _checkIfJoined();
      }
    }
  }

  Future<void> _checkIfJoined() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists && mounted) {
        setState(() => _userRole = userDoc.data()?['role'] ?? 'normal');
      }

      final doc = await FirebaseFirestore.instance
          .collection(_collectionName)
          .doc(widget.matchId)
          .collection('players')
          .doc(user.uid)
          .get();

      if (mounted) setState(() => _isJoined = doc.exists);
    } catch (e) {
      debugPrint('Error verificando asistencia: $e');
    }
  }

  Future<void> _toggleAction() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesion para unirte.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    var changed = false;
    var newlyJoined = false;
    String? feedback;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userDoc.data();
      final dbName = userData?['name'];
      final dbPhoto = userData?['photoUrl'];
      final dbRole = userData?['role'];
      final finalName = (dbName is String && dbName.isNotEmpty)
          ? dbName
          : user.displayName ?? 'Jugador';
      final finalPhotoUrl = (dbPhoto is String && dbPhoto.isNotEmpty)
          ? dbPhoto
          : user.photoURL ?? '';

      final userAgendaRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('agenda')
          .doc(widget.matchId);

      final matchRef = FirebaseFirestore.instance
          .collection(_collectionName)
          .doc(widget.matchId);
      final playerRef = matchRef.collection('players').doc(user.uid);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final matchSnap = await transaction.get(matchRef);
        if (!matchSnap.exists) {
          feedback = 'Este partido ya no esta disponible.';
          return;
        }

        final matchData = matchSnap.data() ?? {};
        final joinedSlots = (matchData['joinedSlots'] as num?)?.toInt() ?? 0;
        final totalSlots = (matchData['totalSlots'] as num?)?.toInt() ?? 0;
        final playerSnap = await transaction.get(playerRef);

        if (_isJoined || playerSnap.exists) {
          transaction.delete(userAgendaRef);
          transaction.delete(playerRef);
          transaction.update(matchRef, {
            'joinedSlots': FieldValue.increment(joinedSlots > 0 ? -1 : 0),
          });
          changed = true;
          newlyJoined = false;
          return;
        }

        if (totalSlots > 0 && joinedSlots >= totalSlots) {
          feedback = 'El partido ya no tiene cupos disponibles.';
          return;
        }

        final notificationRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .doc();

        transaction.set(notificationRef, {
          'title': 'Te has unido',
          'message':
              'Te has inscrito correctamente a: ${widget.matchData['title'] ?? 'Partido'}',
          'date': FieldValue.serverTimestamp(),
          'type': 'join',
          'read': false,
        });

        transaction.set(userAgendaRef, {
          'matchId': widget.matchId,
          'title': widget.matchData['title'],
          'date': widget.matchData['date'],
          'sport': _liveData['sport'] ??
              _liveData['category'] ??
              widget.matchData['sport'] ??
              widget.matchData['category'],
          'location': widget.matchData['location'],
          'type': _collectionName,
        });

        transaction.set(playerRef, {
          'name': finalName,
          'email': user.email ?? '',
          'photoUrl': finalPhotoUrl,
          'rating': 5.0,
          'role': dbRole ?? 'normal',
          'joinedAt': FieldValue.serverTimestamp(),
        });

        transaction.update(matchRef, {'joinedSlots': FieldValue.increment(1)});
        changed = true;
        newlyJoined = true;
      });

      if (!mounted) return;

      if (changed) {
        setState(() => _isJoined = newlyJoined);
      } else if (feedback != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(feedback!)));
      }

      if (newlyJoined && mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (_) => const MainNavigationScreen(initialIndex: 2)),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error en la transaccion: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('No pudimos actualizar tu asistencia: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteActivity() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar actividad?'),
        content: const Text(
            'Esta acción es irreversible. Se cancelará la actividad y se notificará a todos los jugadores inscritos.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar',
                  style: TextStyle(
                      color: AppColors.error, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final matchRef = FirebaseFirestore.instance
          .collection(_collectionName)
          .doc(widget.matchId);

      // 1. Obtener todos los jugadores inscritos
      final playersSnap = await matchRef.collection('players').get();
      final batch = FirebaseFirestore.instance.batch();

      // 2. Iterar sobre ellos para borrarlos de su agenda y mandarles notificación
      for (var playerDoc in playersSnap.docs) {
        final playerId = playerDoc.id;

        final agendaRef = FirebaseFirestore.instance
            .collection('users')
            .doc(playerId)
            .collection('agenda')
            .doc(widget.matchId);
        batch.delete(agendaRef);

        final notificationRef = FirebaseFirestore.instance
            .collection('users')
            .doc(playerId)
            .collection('notifications')
            .doc();
        batch.set(notificationRef, {
          'title': 'Actividad Cancelada',
          'message':
              'El organizador ha cancelado: ${_liveData['title'] ?? widget.matchData['title'] ?? 'la actividad'}',
          'date': FieldValue.serverTimestamp(),
          'type': 'cancel',
          'read': false,
        });
      }

      // 3. Borrar el documento principal de la actividad
      batch.delete(matchRef);
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Actividad eliminada correctamente')));
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (_) => const MainNavigationScreen(initialIndex: 0)),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error eliminando actividad: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    required double screenWidth,
    required double screenHeight,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: (screenHeight * 0.014).r),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all((screenWidth * 0.025).r),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular((screenWidth * 0.03).r),
            ),
            child: Icon(icon,
                color: AppColors.primary, size: (screenWidth * 0.058).r),
          ),
          SizedBox(width: (screenWidth * 0.04).w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: (screenWidth * 0.032).clamp(11.0, 14.0).sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: (screenHeight * 0.005).h),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: (screenWidth * 0.04).clamp(14.0, 17.0).sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final screenWidth = size.width;
    final screenHeight = size.height;
    final pagePadding = screenWidth * 0.06;
    final data = _liveData;
    if (_isFetchingData) {
      return const Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body:
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    final title = data['title']?.toString() ?? 'Partido sin titulo';
    final location =
        data['location']?.toString() ?? 'Ubicacion no especificada';
    final price = data['price']?.toString() ?? 'Gratis';
    final sport =
        data['sport']?.toString() ?? data['category']?.toString() ?? 'Deporte';
    final creator = data['creatorName']?.toString() ?? 'Organizador de la App';
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    String dateStr = 'Fecha por definir';
    if (data['date'] is Timestamp) {
      final date = (data['date'] as Timestamp).toDate();
      dateStr = DateFormat('EEEE dd MMMM, hh:mm a', 'es').format(date);
    } else if (data['date'] != null) {
      dateStr = data['date'].toString();
    }

    final joined = (data['joinedSlots'] as num?)?.toInt() ?? 0;
    final total = ((data['totalSlots'] as num?)?.toInt() ?? 10).clamp(1, 9999);
    final progress = (joined / total).clamp(0.0, 1.0);
    final buttonHeight = (screenHeight * 0.064).clamp(52.0, 62.0);

    final isCreator = currentUserId == data['creatorId'];
    final isAdmin = _userRole == 'admin';
    final canDelete = isCreator || isAdmin;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
        actions: [
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: _isLoading ? null : _deleteActivity,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(
                    horizontal: pagePadding.r,
                    vertical: (screenHeight * 0.012).r),
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: (screenWidth * 0.07).clamp(24.0, 30.0).sp,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: (screenHeight * 0.032).h),
                  Container(
                    padding: EdgeInsets.all((screenWidth * 0.05).r),
                    decoration: BoxDecoration(
                      color: AppColors.textLight,
                      borderRadius:
                          BorderRadius.circular((screenWidth * 0.06).r),
                      boxShadow: [
                        BoxShadow(
                          color:
                              AppColors.textSecondary.withValues(alpha: 0.03),
                          blurRadius: screenWidth * 0.025,
                          offset: Offset(0, screenHeight * 0.005),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                            icon: Icons.calendar_today_rounded,
                            title: 'Fecha y Hora',
                            value: dateStr,
                            screenWidth: screenWidth,
                            screenHeight: screenHeight),
                        _buildInfoRow(
                            icon: Icons.location_on_rounded,
                            title: 'Ubicacion',
                            value: location,
                            screenWidth: screenWidth,
                            screenHeight: screenHeight),
                        _buildInfoRow(
                            icon: Icons.sports_soccer_rounded,
                            title: 'Deporte',
                            value: sport,
                            screenWidth: screenWidth,
                            screenHeight: screenHeight),
                        _buildInfoRow(
                            icon: Icons.attach_money_rounded,
                            title: 'Costo',
                            value: price,
                            screenWidth: screenWidth,
                            screenHeight: screenHeight),
                        _buildInfoRow(
                            icon: Icons.person_rounded,
                            title: 'Organizado por',
                            value: creator,
                            screenWidth: screenWidth,
                            screenHeight: screenHeight),
                      ],
                    ),
                  ),
                  SizedBox(height: (screenHeight * 0.035).h),
                  Text(
                    'Disponibilidad de cupos',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: (screenWidth * 0.045).clamp(16.0, 19.0).sp,
                    ),
                  ),
                  SizedBox(height: (screenHeight * 0.018).h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          '$joined de $total jugadores',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text('${(progress * 100).toInt()}% lleno',
                          style: const TextStyle(fontWeight: FontWeight.bold))
                    ],
                  ),
                  SizedBox(height: (screenHeight * 0.014).h),
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular((screenWidth * 0.025).r),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: screenHeight * 0.016,
                      color:
                          progress >= 1.0 ? AppColors.error : AppColors.primary,
                      backgroundColor: AppColors.progressTrack,
                    ),
                  ),
                  SizedBox(height: (screenHeight * 0.035).h),
                  Text(
                    'Jugadores Inscritos',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: (screenWidth * 0.045).clamp(16.0, 19.0).sp,
                    ),
                  ),
                  SizedBox(height: (screenHeight * 0.018).h),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection(_collectionName)
                        .doc(widget.matchId)
                        .collection('players')
                        .orderBy('joinedAt')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Text('No pudimos cargar jugadores.');
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.data!.docs.isEmpty) {
                        return const Text('Se el primero en unirte',
                            style: TextStyle(color: AppColors.textSecondary));
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final doc = snapshot.data!.docs[index];
                          final rawPlayer = doc.data();
                          if (rawPlayer is! Map<String, dynamic>) {
                            return const SizedBox.shrink();
                          }
                          final playerEmail =
                              rawPlayer['email']?.toString() ?? '';

                          return PlayerCardWidget(
                            player: rawPlayer,
                            playerId: doc.id,
                            currentUserId: currentUserId,
                            screenWidth: screenWidth,
                            screenHeight: screenHeight,
                            onChatPressed: () {
                              if (playerEmail.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'No se puede iniciar chat: usuario sin email registrado.')),
                                );
                                return;
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    otherUserEmail: playerEmail,
                                    otherUserName:
                                        rawPlayer['name']?.toString() ??
                                            'Jugador',
                                    otherUserRole:
                                        rawPlayer['role']?.toString(),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                  SizedBox(height: (screenHeight * 0.024).h),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(pagePadding.r),
              decoration: BoxDecoration(
                color: AppColors.textLight,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textSecondary.withValues(alpha: 0.05),
                    blurRadius: screenWidth * 0.025,
                    offset: Offset(0, -screenHeight * 0.005),
                  )
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: buttonHeight.h,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isJoined ? AppColors.error : AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular((screenWidth * 0.04).r),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _isLoading ? null : _toggleAction,
                    child: _isLoading
                        ? SizedBox(
                            width: (screenWidth * 0.06).w,
                            height: (screenWidth * 0.06).h,
                            child: const CircularProgressIndicator(
                                color: AppColors.textLight, strokeWidth: 3),
                          )
                        : Text(
                            _isJoined
                                ? 'CANCELAR ASISTENCIA'
                                : 'CONFIRMAR Y UNIRME',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontWeight: FontWeight.w800,
                              fontSize:
                                  (screenWidth * 0.04).clamp(14.0, 17.0).sp,
                            ),
                          ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class PlayerCardWidget extends StatelessWidget {
  final Map<String, dynamic> player;
  final String playerId;
  final String? currentUserId;
  final VoidCallback onChatPressed;
  final double screenWidth;
  final double screenHeight;

  const PlayerCardWidget({
    super.key,
    required this.player,
    required this.playerId,
    required this.currentUserId,
    required this.onChatPressed,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  Widget build(BuildContext context) {
    final name = player['name']?.toString() ?? 'Jugador';
    final photoUrl = player['photoUrl']?.toString() ?? '';
    final role = player['role']?.toString();
    final ratingValue = player['rating'];
    final rating = ratingValue is num ? ratingValue.toDouble() : 5.0;
    final isMe = playerId == currentUserId;
    final avatarRadius = screenWidth * 0.055;

    return Container(
      margin: EdgeInsets.only(bottom: (screenHeight * 0.014).r),
      padding: EdgeInsets.all((screenWidth * 0.03).r),
      decoration: BoxDecoration(
        color: AppColors.textLight,
        borderRadius: BorderRadius.circular((screenWidth * 0.04).r),
        border: Border.all(color: AppColors.progressTrack),
        boxShadow: [
          BoxShadow(
            color: AppColors.textSecondary.withValues(alpha: 0.02),
            blurRadius: screenWidth * 0.02,
            offset: Offset(0, screenHeight * 0.002),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: avatarRadius,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage:
                photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
            child: photoUrl.isEmpty
                ? const Icon(Icons.person, color: AppColors.primary)
                : null,
          ),
          SizedBox(width: (screenWidth * 0.03).w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserBadgeName(
                  name: name,
                  role: role,
                  textStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: (screenWidth * 0.038).clamp(13.0, 16.0).sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: (screenHeight * 0.005).h),
                Row(
                  children: [
                    Icon(Icons.star_rounded,
                        color: AppColors.warning, size: (screenWidth * 0.04).r),
                    SizedBox(width: (screenWidth * 0.01).w),
                    Text(
                      rating.toStringAsFixed(1),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: (screenWidth * 0.032).clamp(11.0, 14.0).sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          if (!isMe)
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppColors.primary,
                  size: (screenWidth * 0.05).r,
                ),
                onPressed: onChatPressed,
              ),
            )
          else
            SizedBox(width: (screenWidth * 0.1).w),
        ],
      ),
    );
  }
}
