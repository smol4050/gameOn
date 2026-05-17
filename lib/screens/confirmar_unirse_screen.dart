import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../theme/colors.dart';
import 'main_navigation_screen.dart';
import 'chat_screen.dart';

class ConfirmarUnirseScreen extends StatefulWidget {
  final String matchId;
  final Map<String, dynamic> matchData;

  const ConfirmarUnirseScreen({
    super.key,
    required this.matchId,
    required this.matchData,
  });

  @override
  State<ConfirmarUnirseScreen> createState() => _ConfirmarUnirseScreenState();
}

class _ConfirmarUnirseScreenState extends State<ConfirmarUnirseScreen> {
  bool _isJoined = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkIfJoined();
  }

  Future<void> _checkIfJoined() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('agenda')
          .doc(widget.matchId)
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
      final matchRef =
          FirebaseFirestore.instance.collection('matches').doc(widget.matchId);
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
          'sport': widget.matchData['sport'] ?? widget.matchData['category'],
          'location': widget.matchData['location'],
        });

        transaction.set(playerRef, {
          'name': finalName,
          'email': user.email ?? '',
          'photoUrl': finalPhotoUrl,
          'rating': 5.0,
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
              backgroundColor: Colors.red),
        );
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
      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.014),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(screenWidth * 0.025),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(screenWidth * 0.03),
            ),
            child:
                Icon(icon, color: AppColors.primary, size: screenWidth * 0.058),
          ),
          SizedBox(width: screenWidth * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: (screenWidth * 0.032).clamp(11.0, 14.0),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: screenHeight * 0.005),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: (screenWidth * 0.04).clamp(14.0, 17.0),
                    color: const Color(0xFF1F2937),
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
    final data = widget.matchData;
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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(
                    horizontal: pagePadding, vertical: screenHeight * 0.012),
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: (screenWidth * 0.07).clamp(24.0, 30.0),
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.032),
                  Container(
                    padding: EdgeInsets.all(screenWidth * 0.05),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(screenWidth * 0.06),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
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
                  SizedBox(height: screenHeight * 0.035),
                  Text(
                    'Disponibilidad de cupos',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: (screenWidth * 0.045).clamp(16.0, 19.0),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.018),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          '$joined de $total jugadores',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.grey, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text('${(progress * 100).toInt()}% lleno',
                          style: const TextStyle(fontWeight: FontWeight.bold))
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.014),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(screenWidth * 0.025),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: screenHeight * 0.016,
                      color: progress >= 1.0 ? Colors.red : AppColors.primary,
                      backgroundColor: Colors.grey.shade200,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.035),
                  Text(
                    'Jugadores Inscritos',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: (screenWidth * 0.045).clamp(16.0, 19.0),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.018),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('matches')
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
                            style: TextStyle(color: Colors.grey));
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
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                  SizedBox(height: screenHeight * 0.024),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(pagePadding),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: screenWidth * 0.025,
                    offset: Offset(0, -screenHeight * 0.005),
                  )
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: buttonHeight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isJoined ? Colors.red : AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.04),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _isLoading ? null : _toggleAction,
                    child: _isLoading
                        ? SizedBox(
                            width: screenWidth * 0.06,
                            height: screenWidth * 0.06,
                            child: const CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 3),
                          )
                        : Text(
                            _isJoined
                                ? 'CANCELAR ASISTENCIA'
                                : 'CONFIRMAR Y UNIRME',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: (screenWidth * 0.04).clamp(14.0, 17.0),
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
    final ratingValue = player['rating'];
    final rating = ratingValue is num ? ratingValue.toDouble() : 5.0;
    final isMe = playerId == currentUserId;
    final avatarRadius = screenWidth * 0.055;

    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.014),
      padding: EdgeInsets.all(screenWidth * 0.03),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
          SizedBox(width: screenWidth * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: (screenWidth * 0.038).clamp(13.0, 16.0),
                    color: const Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: screenHeight * 0.005),
                Row(
                  children: [
                    Icon(Icons.star_rounded,
                        color: Colors.amber, size: screenWidth * 0.04),
                    SizedBox(width: screenWidth * 0.01),
                    Text(
                      rating.toStringAsFixed(1),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: (screenWidth * 0.032).clamp(11.0, 14.0),
                        color: Colors.grey,
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
                  size: screenWidth * 0.05,
                ),
                onPressed: onChatPressed,
              ),
            )
          else
            SizedBox(width: screenWidth * 0.1),
        ],
      ),
    );
  }
}
